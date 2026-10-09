# 配置

框架的所有配置文件都保存在 `config` 目录中，不同组件或者业务模块的配置建议放在不同的文件中。文件夹根目录放置各环境的公用配置，根目录下可以创建名为对应环境名的文件夹（`development`、`test`、`production`），环境文件夹下可配置在该环境下的专属配置，**环境配置会按数组递归合并覆盖公用配置**。

## 加载机制

- `bootstrap.php` 中 `config_dir(ROOT_DIR.'/config')` 注册配置根目录
- `config($file_name)` 依次加载 `config/{file}.php` 和 `config/{env()}/{file}.php`，用 `array_replace_recursive` 合并，结果静态缓存
- `env()` 取 `$_SERVER['ENV']`，**默认 `production`**；nginx/php-fpm 通过 `fastcgi_param ENV development;` 切换，CLI 用 `ENV=test php public/cli.php ...` 显式指定

完整函数说明见[辅助函数](function.md)。

## midwares → resources 模式

使用 `I/O` 组件（`mysql`、`redis`、`beanstalk`、`kafka`、`clickhouse` 等）的配置，采用 `midwares → resources` 标准写法：

```php
// config/redis.php

return [
    'midwares' => [
        'default' => 'local',   // 逻辑名 → 资源名
        'idgenter' => 'local',
        'lock' => 'local',
    ],

    'resources' => [
        'local' => [            // 实际连接参数
            'host' => '127.0.0.1',
            'port' => 6379,
            'timeout' => 1,
        ],
    ],
];
```

**环境覆盖只需改 `resources` 中的连接信息，`midwares` 映射不动**。通过 `config_midware('redis', 'default')` 获取 `default` 对应的 resource 配置：

```php
// config/production/redis.php

return [
    'resources' => [
        'local' => [
            'host' => '192.168.1.123',
        ],
    ],
];
```

## 各配置文件结构

### config/mysql.php

```php
return [
    'midwares' => [
        'migrate' => 'local',
        'entity'  => 'local',
        'default' => 'local',
    ],
    'resources' => [
        'local' => [
            'charset'   => 'utf8mb4',
            'collation' => 'utf8mb4_unicode_ci',
            'database'  => 'default',
            'username'  => 'default',
            'password'  => 'password',

            // 连接端点由各环境自己声明（config/{env}/mysql.php）：host => port 走 TCP，字符串值走 unix socket。
            // 这里必须留空——环境覆盖按 key 合并、删不掉基础层的 key，留了就会与环境声明的并存、随机挑一个连错
            'read'   => [],
            'write'  => [],
            'schema' => [],

            'options' => [
                PDO::ATTR_CASE => PDO::CASE_NATURAL,
                PDO::ATTR_ORACLE_NULLS => PDO::NULL_NATURAL,
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_STRINGIFY_FETCHES => false,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_PERSISTENT => false,
            ],
        ],
    ],
];
```

- `read`、`write`、`schema` 三个库位实现了**读写分离**：查询走 `read`，写入走 `write`，DDL 走 `schema`。元素写法：`host => port` 走 TCP、字符串值走 unix socket，多元素时随机挑一个
- 端点都在环境配置里声明：`config/development/mysql.php` 与 `config/test/mysql.php` 走本机 socket，`config/production/mysql.php` 覆盖为 TCP `['127.0.0.1' => 3306]`，测试与生产的库名/账号/密码统一为带项目名的 `php-vibe-coding-frame`
- `midwares` 的三个库位用途不同：`entity` 实体读写（DAO 的 `$db_config_key` 默认值，与工作单元共用连接）、`migrate` 迁移、`default` 自由用途

### config/redis.php

```php
return [
    'midwares' => [
        'default' => 'local',
        'idgenter' => 'local',
        'lock' => 'local',
    ],
    'resources' => [
        'local' => [
            'host' => '127.0.0.1',
            'port' => 6379,
            'timeout' => 1,
            // 可选: 'sock' => ..., 'database' => 0, 'auth' => 'foobared'
            'options' => [
                Redis::OPT_SERIALIZER => Redis::SERIALIZER_PHP,
            ],
        ],
    ],
];
```

`idgenter` 给 ID 生成器（`generate_id()`）、`lock` 给分布式锁（[singly_run / serially_run](lock.md)）用。

### config/beanstalk.php

```php
return [
    'midwares' => [
        'default' => 'local',
        'queue'   => 'local',
    ],
    'resources' => [
        'local' => [
            'host' => '127.0.0.1',
            'port' => 11300,
            'timeout' => 1,
        ],
    ],
];
```

### config/kafka.php

```php
return [
    'midwares' => [
        'default' => 'local',
        'queue'   => 'local',
    ],
    'resources' => [
        'local' => [
            'brokers' => '127.0.0.1:9092',
            'timeout' => 5,           // 连接、元数据与 offset 查询超时（秒）
            // 投递后等回执的上限（秒）：必须大于 message_timeout，否则会把「可能仍会送达」的消息误报成失败
            'flush_timeout' => 15,
            // 单条消息的投递超时（秒）：只有 broker 不可达或 topic 不存在才等满
            'message_timeout' => 10,
        ],
    ],
];
```

队列驱动为 Kafka 时使用（运行环境需装 `php-rdkafka` 扩展），框架固定取 `queue` midware。见[队列](queue.md)。

### config/queue.php

```php
return [
    // ---- beanstalk 驱动 ----
    'tubes' => [
        'default' => 'default',
    ],

    // ---- kafka 驱动 ----
    'topics' => [
        'default' => 'default',
    ],

    // 死信 topic = 真实 topic + 后缀（queue:dead-letter 人工重投）
    'dead_letter_suffix' => '_dead',

    'consumer' => [
        // 消费组名前缀：建新项目时随 naming_project.sh 替换，避免多项目共用一个集群时串组
        'group_prefix' => 'php-vibe-coding-frame',
        // 无已提交 offset 时的起点：earliest（队列语义，worker 不在时投递的任务不丢）/ latest（当事件流用）
        'auto_offset_reset' => 'earliest',
        // 单条消息的处理上限（含进程内重试等待），超时被判离场、触发再均衡
        'max_poll_interval_ms' => 300000,
        'session_timeout_ms' => 45000,
        // 每轮消费的阻塞等待（秒），到点回到循环做内存检查与信号响应
        'consume_timeout' => 5,
    ],
];
```

队列的服务端对象名（tube / topic）不在业务代码里写死：业务侧统一写 key，右边是队列服务里的真实名称，**未映射的 key 直接报错**。各环境覆盖本文件即可换真实对象——`config/test/queue.php` 与 `config/production/queue.php` 都映射为带项目名的 `php-vibe-coding-frame-default`，业务代码不用改。`consumer` 段只有 Kafka 驱动读。

### config/clickhouse.php

```php
return [
    'midwares' => [
        'default' => 'local',
        'migrate' => 'local',
    ],
    'resources' => [
        'local' => [
            'host' => '127.0.0.1',
            'port' => 8123,
            'database' => 'default',
            'username' => 'default',
            'password' => '',
            // 单次 HTTP 请求超时秒数，分析型查询偏慢，默认比 redis 宽松
            'timeout' => 10,
            // 随每次请求下发的 ClickHouse 设置
            // 框架默认会补上 output_format_json_quote_64bit_integers / _decimals（64 位整数与 Decimal
            // 以字符串返回，避免 JSON 走 double 丢精度）；显式设 0 可覆盖回数字类型
            'settings' => [],
        ],
    ],
];
```

`migrate` 库位给 `clickhouse:*` 迁移命令用；测试与生产的 `database` 覆盖为带项目名的 `php-vibe-coding-frame`。见 [ClickHouse](clickhouse.md)。

### config/blade.php

```php
return [
    'compiled_path' => ROOT_DIR.'/view/blade/',
];
```

- `config/development/blade.php`：`['compiled_cache' => false]`（开发不缓存编译结果，走 stream wrapper）
- `config/test/blade.php` 与 `config/production/blade.php`：`['compiled_cache' => true]`（写文件缓存，改了模板要清一次 `view/blade/*.php`）

### config/log.php

```php
return [
    'service' => 'php-vibe-coding-frame',
    'exception_path' => '/tmp/php_exception.log',
    'notice_path'    => '/tmp/php_notice.log',
    'module_path'    => '/tmp/php_module.log',
];
```

- `service` 是日志里的来源服务名，建新项目时随 `naming_project.sh` 替换
- 开发环境落 `/tmp/php_*.log`；`config/test/log.php` 与 `config/production/log.php` 覆盖为 `/var/log/php-vibe-coding-frame/*.log`（目录由部署脚本建好）
- 日志为 JSON Lines 格式，字段与规范见[日志](log.md)

### config/error_code.php

```php
return [
    'USER_NOT_FOUND' => 'user not found',
];
```

键 = 英文大写错误码，值 = 文案，支持 `{param}` 占位符（由 `otherwise_error_code` 第三个参数替换）。
