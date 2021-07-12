# 配置

`api_frame` 框架的所有配置文件都保存在`config`目录中，不同组件或者业务模块的配置建议放在不同的文件中，文件夹根目录放置各环境的公用配置，根目录下可以创建名为对应环境名的文件夹，环境文件夹下可配置在环境下的专属配置。如：
```php
// config/beanstalk.php

return [
    'midwares' => [
        'default' => 'local',
        'queue' => 'local',
    ],

    'resources' => [
        'local' => [
            'host' => '127.0.0.1',
            'port' => 11300,
            'timeout' => 1,
        ],
    ],
];

// config/production/beanstalk.php

return [
    'resources' => [
        'local' => [
            'host' => '192.168.1.123',
        ],
    ],
];
```
如上配置当环境为 `production` 时，获取到的配置为：
```php
return [
    'midwares' => [
        'default' => 'local',
        'queue' => 'local',
    ],

    'resources' => [
        'local' => [
            'host' => '192.168.1.123',
            'port' => 11300,
            'timeout' => 1,
        ],
    ],
];
```
### 配置文件的内容格式
配置文件可以有两种不同的内容形式，一种为完全自定义的形式，如：
```php
// config/debuger.php
return [
    'debug' => true,
    'whatever' => false,
];
```
自定义的形式通常用于业务逻辑抽出来的配置，这类配置可以直接通过 `config` 方法获取，如：
```php
$debug_config = config('debuger');
var_dump($debug_config['whatever']); // false
```
另一种格式通常用于使用 `I/O` 组件的中间件，如 `db`、`cache`、`queue` 等，如：
```php
// config/beanstalk.php

return [
    'midwares' => [
        'default' => 'local',
        'queue' => 'local',
    ],

    'resources' => [
        'local' => [
            'host' => '127.0.0.1',
            'port' => 11300,
            'timeout' => 1,
        ],
    ],
];

// config/production/beanstalk.php

return [
    'resources' => [
        'local' => [
            'host' => '192.168.1.123',
        ],
    ],
];
```
组件内部在使用时，会这样来使用，如：
```php
$config = config_midware('beanstalk', 'queue');
```
这样首先会读取配置中 `midwares` 定义的组件与 `resource` 的关系，再获取在 `resources` 中对应的配置，假设环境为 `production` 会获取：
```php
$config = [
    'host' => '192.168.1.123',
    'port' => 11300,
    'timeout' => 1,
];
```