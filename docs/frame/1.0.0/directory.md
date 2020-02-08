# 文件夹结构

frame 核心框架库的目录结构如下，部分组件目录中有 `demo.php` 用以在扩展该框架时仿照

```
├── LICENSE
├── README.md
├── cache (缓存类功能文件目录)
│   ├── memcache.php
│   └── redis.php
├── database (数据库类功能文件目录)
│   ├── mysql.php
│   └── oracle.php
├── dialogue (对话功能文件目录)
│   └── beanstalk.php
├── http (http 入口类功能文件目录)
│   ├── php_fpm (PHP-FPM 下的 http 能力)
│   │   ├── application.php
│   │   ├── distributed_client.php
│   │   └── distributed_service.php
│   └── swoole (Swoole 下的 http 能力)
│       └── application.php
├── lock (锁类功能文件目录)
│   ├── cache.php
├── log (日志类功能文件目录)
│   └── file.php
├── queue (队列类功能文件目录)
│   ├── beanstalk.php
├── spider (爬虫类功能文件目录)
│   └── beanstalk.php
├── storage (非 SQL 类存储功能文件目录)
│   └── mongodb.php
├── view_compiler (模版引擎类存储功能文件目录)
│   └── blade.php
├── command.php (命令行功能)
├── entity.php (ORM 能力)
├── function.php (辅助函数)
├── otherwise.php (断言能力)
└── unitofwork.php (工作单元能力)
```
