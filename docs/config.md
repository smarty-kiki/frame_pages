# 配置

框架的所有配置文件都保存在 `config` 目录中，不同组件或者业务模块的配置建议放在不同的文件中。文件夹根目录放置各环境的公用配置，根目录下可以创建名为对应环境名的文件夹（`development`、`production`），环境文件夹下可配置在该环境下的专属配置，**环境配置会按数组递归合并覆盖公用配置**。

## 加载机制

- `bootstrap.php` 中 `config_dir(ROOT_DIR.'/config')` 注册配置根目录
- `config($file_name)` 依次加载 `config/{file}.php` 和 `config/{env()}/{file}.php`，用 `array_replace_recursive` 合并，结果静态缓存
- `env()` 取 `$_SERVER['ENV']`，**默认 `production`**；nginx/php-fpm 通过 `fastcgi_param ENV development;` 切换

完整函数说明见[辅助函数](function.md)。

## midwares → resources 模式

使用 `I/O` 组件（`mysql`、`redis`、`beanstalk` 等）的配置，采用 `midwares → resources` 标准写法：

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
            'read'   => ['/var/run/mysqld/mysqld.sock'],  // 读库；数字 = TCP 端口，字符串 = unix socket，多元素时随机选
            'write'  => ['/var/run/mysqld/mysqld.sock'],  // 写库
            'schema' => ['/var/run/mysqld/mysqld.sock'],  // 结构库（DDL）
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

`read`、`write`、`schema` 三个库位实现了**读写分离**：查询走 `read`，写入走 `write`，DDL 走 `schema`。生产环境覆盖为 TCP `['127.0.0.1' => 3306]`。

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

### config/blade.php

```php
return [
    'compiled_path' => ROOT_DIR.'/view/blade/',
];
```

- `config/development/blade.php`：`['compiled_cache' => false]`（开发不缓存编译结果，走 stream wrapper）
- `config/production/blade.php`：`['compiled_cache' => true]`（写文件缓存）

### config/log.php

```php
return [
    'exception_path' => '/tmp/php_exception.log',
    'notice_path'    => '/tmp/php_notice.log',
    'module_path'    => '/tmp/php_module.log',
];
```

### config/error_code.php

```php
return [
    'USER_NOT_FOUND' => 'user not found',
];
```

键 = 英文大写错误码，值 = 文案，支持 `{param}` 占位符（由 `otherwise_error_code` 第三个参数替换）。
