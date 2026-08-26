# 队列

本框架的队列基于 **Beanstalkd**（通过纯 socket 协议通信，不依赖 PHP 扩展），用于异步处理耗时任务。

与常见的「投递时指定队列名」不同，本框架是**先注册、后投递**：任务在启动阶段用 `queue_job()` 注册（声明处理闭包、优先级、重试策略、所在 tube），业务代码只需用 `queue_push()` 按**任务名**投递数据，投递到哪个 tube 由注册信息决定。

## 核心概念

- **任务**（Job）：一段可序列化的数据（通常是 PHP 数组），放在 tube 中等待消费
- **Tube**：队列管道，任务按 tube 隔离，worker 可监听指定 tube
- **Worker**：常驻进程，`queue:worker` 命令启动，从 tube 取出任务、执行对应注册闭包、标记完成
- **Buried**：任务重试耗尽仍失败被埋藏，可人工查看/重新投递

## 注册任务

在 `command/queue/queue_job/` 目录下注册任务处理函数，`load.php` 统一引入：

```php
<?php
// command/queue/queue_job/demo.php

queue_job('demo', function ($data, $id) {
    sleep(1);
    log_module('queue', 'demo successful!');
    return true;
}, 10, [1, 1, 1], 'default');
```

### queue_job

```php
queue_job($job_name, closure $closure, $priority = 10, $retry = [], $tube = 'default', $config_key = 'default')
```

**注册任务**：把处理闭包与投递参数存入容器。**不投递任何消息**，只在进程启动时声明。

- `$job_name` 任务名，`queue_push()` 按此名投递
- `$closure` 处理闭包，接收两个参数：`$data`（投递的数据）、`$id`（任务 id）。返回 `true` 表示成功；返回非真或抛异常视为失败
- `$priority` 优先级（Beanstalkd 数值越小越先执行）
- `$retry` **重试策略**：延时秒数数组。任务失败时按已重试次数（releases）取对应延时重新投递；次数超过数组长度则埋藏（bury）
- `$tube` 该任务所在的 tube
- `$config_key` beanstalk 配置键（`config/beanstalk.php` 的 midwares 键）

### queue_jobs

```php
queue_jobs(?array $jobs = null)
```

任务容器的 getter / setter。无参调用返回全部已注册任务；传入数组则整体替换。

```php
$all = queue_jobs();   // ['demo' => ['closure' => ..., 'priority' => 10, ...]]
```

### queue_job_pickup

```php
queue_job_pickup($job_name)
```

按任务名取回注册信息（闭包、优先级、重试、tube、config_key）。

## 投递任务

### queue_push

```php
queue_push($job_name, array $data = [], $delay = 0)
```

按任务名投递一条任务。tube / 优先级 / 重试策略均来自该任务注册时的配置，**不需要（也不能）在此指定**。`$delay` 为延迟执行秒数。返回新建任务在队列中的 id。

```php
queue_push('demo', ['to' => 'a@b.com', 'content' => '欢迎']);
queue_push('demo', ['mobile' => '138...'], 60);   // 60 秒后投递
```

## 消费任务

### queue_watch

```php
queue_watch($tube = 'default', $config_key = 'default', $memory_limit = 1048576)
```

worker 主循环：无限 `reserve` 任务并执行对应闭包。**阻塞等待**，不消费任务就一直在循环里。

- 闭包返回 `true` → `delete` 删除任务
- 闭包返回非真或抛异常 → 按该任务的 `retry` 策略释放或埋藏
- 每次循环前触发 `queue_finish_action` 钩子（用于回收连接）
- 内存占用超过 `$memory_limit`（字节）→ 抛异常退出（由 supervisor 拉起）
- 收到 `SIGTERM` 信号 → 处理完当前任务后优雅退出

```php
queue_watch('default', 'default', 1048576 * 128);
```

### queue_job_touch

```php
queue_job_touch()
```

**延长当前任务的 TTR**（Time To Run）：防止长任务因执行超时被 Beanstalkd 重新置为 ready。长任务处理中应定期调用。无参数，作用于当前 worker 正在执行的任务。

```php
queue_job('big_report', function ($data) {
    foreach ($chunks as $chunk) {
        queue_job_touch();   // 每处理一块续一次命
        // 处理...
    }
    return true;
});
```

## 暂停与状态

### queue_pause

```php
queue_pause($tube = 'default', $config_key = 'default', $delay = 3600)
```

暂停指定 tube：`$delay` 秒内不向 worker 派发任务。

```php
queue_pause('mail', 'default', 3600);   // 暂停邮件队列 1 小时
```

### queue_status

```php
queue_status($tube = 'default', $config_key = 'default')
```

查看指定 tube 的统计信息（`stats-tube` 原始输出）：ready / delayed / buried 任务数、total-jobs 等。

```php
echo queue_status('default');
```

## 任务完成钩子

### queue_finish_action

```php
queue_finish_action(?closure $action = null)
```

注册「每次 worker 循环 reserve 前」执行的钩子闭包，通常用于连接资源回收。`queue:worker` 命令用它注册了 `local_cache_delete_all`、`beanstalk_close`、`cache_close`、`db_close`。

### queue_finish_action_trigger

```php
queue_finish_action_trigger()
```

触发任务完成钩子。框架在 worker 每次循环前自动调用。

## 连接

### beanstalk_close

```php
beanstalk_close()
```

关闭 Beanstalkd 连接，释放资源。

### `_beanstalk_*`

内部纯 socket 协议函数：`_beanstalk_connection`、`_beanstalk_put`、`_beanstalk_reserve`、`_beanstalk_release`、`_beanstalk_bury` 等，框架内部使用，业务代码无需直接调用。

## CLI 命令

### queue:worker

```bash
php public/cli.php queue:worker --tube=mail --config_key=default --memory_limit=134217728
```

启动常驻 worker 消费指定 tube。`--tube` 目标管道，`--config_key` beanstalk 配置键，`--memory_limit` 内存上限（字节，默认 128MB，超过自动退出重启，防内存泄漏）。生产由 supervisor 守护（见[开发环境](environment.md)）。

### queue:status

```bash
php public/cli.php queue:status --tube=mail --config_key=default
```

查看队列状态：指定 tube 的任务分布。

### queue:pause

```bash
php public/cli.php queue:pause --tube=mail --config_key=default --delay=3600
```

暂停指定 tube（等价 `queue_pause`），并阻塞等待 `$delay` 秒。

### queue:peek-buried

```bash
php public/cli.php queue:peek-buried --tube=mail --config_key=default
```

**交互式**处理 buried 任务：逐条打印任务内容，询问 `kick`（重新投递）或 `delete`（删除）。

### queue:ready-to-buried

```bash
php public/cli.php queue:ready-to-buried --tube=mail --config_key=default
```

灾难恢复场景：把指定 tube 中所有 ready（待消费）任务快速转为 buried 状态，先确认后持续执行。

### queue:buried-dump

```bash
php public/cli.php queue:buried-dump --tube=mail --config_key=default
```

把 buried 任务逐条导出到 dump 文件（`/tmp/queue_buried_flush_tube_{tube}_{time}.dump`）并从队列中删除，便于排查/恢复。

### queue:dump-import

```bash
php public/cli.php queue:dump-import --file_path=/tmp/queue_buried_flush_tube_mail_xxx.dump
```

把导出文件中的任务重新导入队列（进入 ready 状态），任务 id 会重新生成。
