# 队列

本框架的队列是**先注册、后投递**：任务在进程启动时用 `queue_job()` 注册（声明处理闭包、重试策略、所在 tube / topic），业务代码用 `queue_push()` 按**任务名**投递数据，投递到哪由注册信息决定。

底层有两套**并列实现，一个项目只用一种**（函数同名，只能加载一个）：默认 **Beanstalkd**（纯 socket 协议，不依赖 PHP 扩展）；另一套 **Kafka**（基于 php-rdkafka 扩展）。业务侧函数名与用法形态不变，切换步骤见下文「切换驱动」。

## 核心概念

- **任务**（Job）：一段可序列化的数据（通常是 PHP 数组），带上任务名放入队列等待消费
- **Tube**（beanstalk 驱动）：队列管道，任务按 tube 隔离，worker 监听指定 tube
- **Topic / 分区**（kafka 驱动）：topic 是逻辑队列，下分多个分区；消息按投递时的 `$key` 决定落哪个分区，**同 key 保序**
- **Worker**：常驻进程，`queue:worker` 命令启动，取出任务、执行对应注册闭包、标记完成
- **消费组**（kafka 驱动）：同组多 worker 自动分摊分区，每条消息只被组内一个 worker 消费
- **失败去处**：beanstalk 重试用尽**埋藏**（bury，人工 kick / delete）；kafka 重试用尽落**死信 topic**（人工查看 / 重投，`queue:dead-letter`）

业务侧统一写 `tube_key` / `topic_key`，真实名称在 `config/queue.php` 里映射——各环境覆盖配置即可换真实对象，业务代码不用改。

## 配置

连接参数在 `config/beanstalk.php` / `config/kafka.php` 中配置，名称映射与消费参数在 `config/queue.php`（见[配置](config.md)）：

```php
// config/queue.php
return [
    // beanstalk 驱动：tube_key → 真实 tube 名
    'tubes' => [
        'default' => 'default',
    ],

    // kafka 驱动：topic_key → 真实 topic 名
    'topics' => [
        'default' => 'default',
    ],

    // 死信 topic = 真实 topic + 后缀
    'dead_letter_suffix' => '_dead',

    'consumer' => [
        // 消费组名前缀：建新项目时随命名脚本替换，避免多项目共用一个集群时串组
        'group_prefix' => 'php-vibe-coding-frame',
        // 无已提交 offset 时的起点：earliest（队列语义，不丢消息）/ latest（当事件流用）
        'auto_offset_reset' => 'earliest',
        // 单条消息的处理上限（含进程内重试等待）：超时被判离场、触发再均衡，长耗时动作应拆小
        'max_poll_interval_ms' => 300000,
        'session_timeout_ms' => 45000,
        // 每轮消费的阻塞等待（秒），到点回到循环做内存检查与信号响应
        'consume_timeout' => 5,
    ],
];
```

- beanstalk：`config/beanstalk.php` 配 `host` / `port` / `timeout`
- kafka：`config/kafka.php` 配 `brokers` / `timeout` / `flush_timeout` / `message_timeout`；`flush_timeout` 必须大于 `message_timeout`，否则会把「可能仍会送达」的消息误报成失败；运行环境需装 php-rdkafka 扩展
- 两套连接配置都是 `midwares → resources` 模式且固定取 `queue` 中间件，**不暴露 `$config_key` 参数**
- kafka 客户端禁用自动建 topic（`allow.auto.create.topics=false`）：topic 名写错立刻报错，不会静默建一个空 topic 空转

### queue_tube

```php
queue_tube($tube_key)
```

（beanstalk 驱动）`tube_key` → 真实 tube 名；未映射抛 `QUEUE_TUBE_NOT_FOUND`。

### queue_topic

```php
queue_topic($topic_key)
```

（kafka 驱动）`topic_key` → 真实 topic 名；未映射抛 `QUEUE_TOPIC_NOT_FOUND`。

### queue_dead_letter_topic

```php
queue_dead_letter_topic($topic_key)
```

（kafka 驱动）返回死信 topic 名：真实 topic + `dead_letter_suffix`。

## 注册任务

在 `command/queue/queue_job/` 目录下注册任务处理函数，`load.php` 统一引入（`bootstrap.php` 启动时加载，web 与 cli 进程都会注册）。

```php
<?php
// command/queue/queue_job/demo.php（beanstalk 驱动）

queue_job('demo', function ($data, $id) {
    sleep(1);
    log_module('queue', 'demo successful!');
    return true;
}, 10, [1, 1, 1], 'default');
```

```php
<?php
// command/queue/queue_job/demo_kafka.php（kafka 驱动）

queue_job('demo', function ($data, $meta) {
    sleep(1);
    log_module('queue', 'demo successful!'.json($meta));
    return true;
}, [1, 1, 1], 'default');
```

### queue_job

```php
// beanstalk 驱动
queue_job($job_name, closure $closure, $priority = 10, $retry = [], $tube_key = 'default')

// kafka 驱动
queue_job($job_name, closure $closure, $retry = [], $topic_key = 'default')
```

**注册任务**：把处理闭包与投递参数存入容器。**不投递任何消息**，只在进程启动时声明；同名任务重复注册会覆盖。

- `$job_name` 任务名，`queue_push()` 按此名投递
- `$closure` 处理闭包，返回 `true` 表示成功；返回非真或抛异常视为失败
  - beanstalk 驱动接收 `$data`（投递的数据）与 `$id`（任务 id）
  - kafka 驱动接收 `$data` 与 `$meta`：`topic` / `partition` / `offset` / `key` / `timestamp`
- `$retry` **重试策略**：延时秒数数组，任务失败时按已失败次数取对应延时后重试；次数超过数组长度后，beanstalk 埋藏（bury）、kafka 投递死信 topic
- `$priority` 优先级（仅 beanstalk，数值越小越先执行）
- `$tube_key` / `$topic_key` 所在 tube / topic 的映射键

### queue_jobs

```php
queue_jobs(?array $jobs = null)
```

任务容器的 getter / setter。无参调用返回全部已注册任务；传入数组则整体替换。

```php
$all = queue_jobs();
// ['demo' => ['closure' => ..., 'retry' => ..., 'tube_key' => 'default']]
// （kafka 版注册信息里是 'topic_key'，且没有 priority）
```

### queue_job_pickup

```php
queue_job_pickup($job_name)
```

按任务名取回注册信息（闭包、重试策略、映射键）；未注册返回 `null`。

## 投递任务

### queue_push

```php
// beanstalk 驱动
queue_push($job_name, array $data = [], $delay = 0)

// kafka 驱动
queue_push($job_name, array $data = [], $key = '')
```

按任务名投递一条任务。tube / topic、优先级、重试策略均来自该任务注册时的配置，**不需要（也不能）在此指定**。信封自动携带投递时的 trace 上下文，消费方据此接上同一条链路（见[链路追踪](trace.md)）。

- beanstalk：`$delay` 为延迟执行秒数；返回新建任务在队列中的 id
- kafka：`$key` 决定落哪个分区——**同 key 保序**（如同一用户的操作按顺序处理）；空 key 的落点由客户端分区器决定，要保序就显式给 key。投递同步等回执：broker 不可达 / topic 不存在 / flush 超时都抛 `QUEUE_PUSH_FAILED`，不静默丢；返回投递回执（含 `topic` / `partition` / `offset`）
- kafka 投递未注册的任务名抛 `QUEUE_JOB_NOT_FOUND`

```php
queue_push('demo', ['to' => 'a@b.com', 'content' => '欢迎']);

// beanstalk：60 秒后投递
queue_push('demo', ['mobile' => '138...'], 60);

// kafka：同 key 保序
queue_push('send_sms', ['mobile' => '138...'], 'user:1001');
```

### queue_raw_push

```php
queue_raw_push($topic_key, array $payload, $key = '')
```

（kafka 驱动）按 `topic_key` 直接投递原始信封，不经任务注册校验——`$payload` 自行组装完整信封（如带 `job_name` / `data` 的结构）。用于管理工具与特殊投递场景。

## 消费任务

### queue_watch

```php
// beanstalk 驱动
queue_watch($tube_key = 'default', $memory_limit = 1048576)

// kafka 驱动
queue_watch($topic_key = 'default', $memory_limit = 1048576, $group = null)
```

worker 主循环：无限取任务并执行对应注册闭包。**阻塞等待**，没有任务时在循环里等。

- 闭包返回 `true` → 成功：beanstalk 删除任务；kafka 提交该条 offset
- 返回非真或抛异常 → 失败：按 `retry` 数组取延时重试（kafka 是在 worker 进程内 `sleep` 退避——等待期间占住分区，长延时应改用死信 + 定时重放）；次数用尽后：beanstalk 埋藏，kafka 投递死信 topic
- 每轮循环前触发 `queue_finish_action` 钩子（用于回收连接资源）
- 内存占用超过 `$memory_limit`（字节）→ 抛 `queue_watch out of memory` 退出（由 supervisor 拉起）
- 收到 `SIGTERM` 信号 → 处理完当前任务后优雅退出
- 取出任务后按信封里的 trace 上下文恢复链路（老信封没有 trace 字段则新起），处理完清理——下一轮不带上一个任务的上下文

kafka 驱动另外：

- `$group` 自定义消费组名（默认 `{group_prefix}-{topic_key}`，见配置）；同组多 worker 自动分摊分区，每条消息只被一个 worker 消费——想广播就各用不同组名
- 订阅前先校验 topic 存在（不存在的 topic 订阅后会一直空转）；分区分配 / 回收与再均衡失败记入模块日志
- offset 在处理成功后才显式提交（关闭自动提交）：worker 崩溃时未提交的消息会重投——**至少一次投递，业务需幂等**
- 信封不是合法 JSON、或任务名未注册 → 落死信并提交（不静默丢，也不卡住分区）
- 死信投递失败 → 记异常后**终止 worker**（消息不能随 offset 提交消失，等 supervisor 拉起后重新消费）

```php
queue_watch('default', 1048576 * 128);
```

### queue_job_touch

```php
queue_job_touch()
```

（beanstalk 驱动）**延长当前任务的 TTR**（Time To Run，投递时固定为 60 秒）：防止长任务因执行超时被 Beanstalkd 重新置为 ready 状态。长任务处理中应定期调用。无参数，作用于当前 worker 正在执行的任务。

```php
queue_job('big_report', function ($data) {
    foreach ($chunks as $chunk) {
        queue_job_touch();   // 每处理一块续一次命
        // 处理...
    }
    return true;
});
```

### queue_finish_action

```php
queue_finish_action(?closure $action = null)
```

注册「每次 worker 循环取任务前」执行的钩子闭包，通常用于连接资源回收。`queue:worker` 命令的注册：beanstalk 版为 `local_cache_delete_all` + `beanstalk_close` + `cache_close` + `db_close`；kafka 版为 `local_cache_delete_all` + `cache_close` + `db_close`——消费者实例要跨轮保持（消费组会籍靠它），不能每轮关闭。

### queue_finish_action_trigger

```php
queue_finish_action_trigger()
```

触发该钩子。框架在 worker 每次循环前自动调用。

## 管理

### queue_status

```php
// beanstalk 驱动
queue_status($tube_key = 'default')

// kafka 驱动
queue_status($topic_key = 'default', $group = null)
```

- beanstalk：返回指定 tube 的统计信息（`stats-tube` 原始输出）：ready / delayed / buried 任务数、total-jobs 等
- kafka：返回每个分区的消费进度数组：`partition` / `group` / `low` / `high` / `committed` / `lag`。未提交过 offset 的分区 `committed` 为 `null`（rdkafka 的 `-1001` 哨兵值已转成 `null`），`lag` 按 `auto_offset_reset` 的起点到末尾估算。rdkafka 拿不到消费组成员列表，要看成员用 `kafka-consumer-groups.sh`

```php
$rows = queue_status('default');
```

### queue_reset_offset

```php
queue_reset_offset($topic_key = 'default', $offset = 'earliest', $partition = null, $group = null)
```

（kafka 驱动）**重置消费位点（回溯重放）**：`$offset` 取 `'earliest'` / `'latest'` / 具体数值；`$partition` 不传则重置全部分区，否则只重置指定分区；未匹配到任何分区抛 `QUEUE_PARTITION_NOT_FOUND`。返回重置后的分区位点列表（`RdKafka\TopicPartition`，可读 `getTopic()` / `getPartition()` / `getOffset()`）。

- **同组 worker 必须先停掉**：组的会籍还在时 broker 会拒绝提交 offset（Unknown member / Illegal generation / rebalance）
- 重置后这些消息会被**重新消费**，业务需自行保证幂等

```php
queue_reset_offset('default', 'earliest');
```

### queue_pause

```php
queue_pause($tube_key = 'default', $delay = 3600)
```

（beanstalk 驱动）暂停指定 tube：`$delay` 秒内不向 worker 派发任务。

```php
queue_pause('mail', 3600);   // 暂停邮件队列 1 小时
```

### beanstalk_close

```php
beanstalk_close()
```

（beanstalk 驱动）关闭 Beanstalkd 连接，释放资源。

### queue_close

```php
queue_close()
```

（kafka 驱动）关闭本进程打开的生产者与消费者，可重复调用。生产者与消费者进程内复用：生产者 `new` 一次要重拉元数据，消费者的消费组会籍靠实例维持（重建会触发再均衡）。

## CLI 命令

队列命令分两套（与驱动对应，`public/cli.php` 里 include 哪套用哪套）。

### beanstalk 驱动

```bash
php public/cli.php queue:worker --tube_key=mail --memory_limit=134217728
php public/cli.php queue:status --tube_key=mail
php public/cli.php queue:pause --tube_key=mail --delay=3600
php public/cli.php queue:peek-buried --tube_key=mail
php public/cli.php queue:ready-to-buried --tube_key=mail
php public/cli.php queue:buried-dump --tube_key=mail
php public/cli.php queue:dump-import --file_path=/tmp/queue_buried_flush_tube_mail_xxx.dump
```

- `queue:worker` 启动常驻 worker 消费指定 tube（`--tube_key` 默认 `default`；`--memory_limit` 内存上限字节数，默认 128MB，超过自动退出重启，防内存泄漏）
- `queue:status` 查看 tube 任务分布；`queue:pause` 暂停派发并阻塞等待 `--delay` 秒
- `queue:peek-buried` **交互式**处理 buried 任务：逐条打印任务内容，询问 `kick`（重新投递）或 `delete`（删除）
- `queue:ready-to-buried` 灾难恢复：确认后把 ready 任务持续转为 buried，除非 `ctrl+c` 停止
- `queue:buried-dump` 把 buried 任务逐条导出到 `/tmp/queue_buried_flush_tube_{tube}_{time}.dump`（每行一条 JSON）并从队列删除
- `queue:dump-import` 把 dump 文件逐行重新投递（`queue_push`，任务 id 重新生成）；解析失败的行记入 `{文件}.log`

### kafka 驱动

```bash
php public/cli.php queue:worker --topic_key=mail --memory_limit=134217728
php public/cli.php queue:status --topic_key=mail
php public/cli.php queue:reset-offset --topic_key=mail --offset=earliest
php public/cli.php queue:dead-letter --topic_key=mail
```

- `queue:worker` 启动常驻 worker（`--topic_key`；`--group` 自定义消费组；`--memory_limit`）；启动时打印所用 topic 与消费组
- `queue:status` 打印分区消费进度表（partition / group / low / committed / high / lag）与 total lag
- `queue:reset-offset` 回溯重放：`--offset=earliest|latest|数值`（默认 `earliest`）、`--partition` 只重置某分区、`--group`；报错含成员 / generation / rebalance 时会提示同组还有 worker 在跑，先停掉同组 worker
- `queue:dead-letter` 查看与重投死信 topic：独立消费组 `{默认组}-dead-letter-tool`、从头开始看、不提交 offset（死信 topic 删不了单条消息，清理靠留存策略，每次都会看到旧消息）；交互式 `skip` / `replay`（重投回原 topic，trace 用当前 CLI 上下文，原 `trace_id` 记入模块日志）/ `quit`

生产环境由 supervisor 守护 worker：beanstalk 用 `php-vibe-coding-frame_queue_worker.conf`，kafka 用 `php-vibe-coding-frame_queue_worker_kafka.conf`（模板见 `project/config/*/supervisor/`）。开发环境另有 `queue_job_watch`：监视任务注册文件，md5 变化后自动重启 worker。见[环境](environment.md)。

## 切换驱动

两套实现并列，**一个项目只用一种**（函数同名，只能加载一个）：默认 Beanstalkd（纯 socket 协议实现），另一套 Kafka（基于 php-rdkafka 扩展）。切换只需换三处 `include` 与 supervisor 的 worker 配置，业务侧函数名与用法形态不变：

1. `bootstrap.php`：`include FRAME_DIR.'/queue_beanstalk.php'` → `queue_kafka.php`
2. `public/cli.php`：`include COMMAND_DIR.'/queue/queue.php'` → `queue_kafka.php`
3. `command/queue/queue_job/load.php`：`demo.php` → `demo_kafka.php`（两套 `queue_job` 的参数口径不同：kafka 版没有 `priority` / `delay`）
4. supervisor worker 配置：换用 `queue_worker_kafka.conf`（见[环境](environment.md)）

两套的差异：

| | beanstalk 驱动 | kafka 驱动 |
|------|------|------|
| 传输 | 纯 socket 协议，无需扩展 | php-rdkafka 扩展 |
| 队列单位 | tube（单队列） | topic（多分区） |
| 并发消费 | 多 worker 竞争取出 | 消费组按分区自动分摊 |
| 优先级 | 支持（数值越小越先执行） | 不支持 |
| 延时投递 | 支持（`$delay`） | 不支持（重试用进程内 sleep 退避） |
| 失败去处 | 重试用尽 bury，人工 kick / delete | 重试用尽落死信 topic，人工查看 / 重投 |
| 回溯重放 | 不支持 | `queue:reset-offset` |
| 连接配置 | `config/beanstalk.php` | `config/kafka.php` |

**Kafka 多出**：消费组（同组多 worker 自动分摊分区）、`queue:status` 的堆积量（lag）与 `queue:reset-offset` 回溯重放、死信 topic（`queue:dead-letter` 查看与重投）；**少掉**：优先级、延时投递、暂停派发与 bury 体系。
