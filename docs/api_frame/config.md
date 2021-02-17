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
