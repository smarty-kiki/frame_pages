# 介绍

api_frame 是使用 frame 组装的满足单层 http api 服务场景的快速开发框架，拥有请求响应、ORM、ORM 持久化、缓存、命令行、队列、数据结构升级工具等机制

# 目录结构

```
.
├── LICENSE
├── README.md
├── bootstrap.php             // 框架领域层、公用组件的加载和配置
├── command                   // 命令行工具目录
│   ├── controller.php       // controller 相关功能命令
│   ├── description.php      // 描述文件相关功能命令
│   ├── entity.php           // 实体相关功能命令
│   ├── migrate.php          // 数据结构迁移相关功能命令
│   ├── migration            // 数据结构迁移文件的目录
│   ├── queue.php            // 队列相关命令
│   └── queue_job            // 队列任务声明文件的目录
│       └── load.php
├── config                    // 配置文件目录
│   ├── beanstalk.php
│   ├── development          // 开发环境配置
│   ├── log.php
│   ├── mongodb.php
│   ├── mysql.php
│   ├── production           // 线上环境配置
│   └── redis.php
├── controller                // 控制器文件目录
│   └── index.php
├── domain                    // 领域层文件目录
│   ├── autoload.php         // 领域层类自动加载文件
│   ├── dao                  // dao 文件目录
│   ├── description          // 描述文件目录
│   ├── entity               // 实体文件目录
│   ├── knowledge            // 知识文件目录
│   └── load.php
├── frame -> ../frame         // 核心框架
├── interceptor               // 拦截器文件目录
├── project                   // 开发、发布、部署相关工具及配置
│   ├── config                // 各环境组件配置
│   │   ├── development
│   │   │   ├── nginx
│   │   │   │   └── api_frame.conf
│   │   │   └── supervisor
│   │   │       └── queue_worker.conf
│   │   └── production
│   │       ├── nginx
│   │       │   └── api_frame.conf
│   │       └── supervisor
│   │           └── queue_worker.conf
│   └── tool                   // 开发、发布、部署脚本工具
│       ├── classmap.sh
│       ├── dep_build.sh
│       ├── naming_project.sh
│       ├── start_description_fast_demo.sh
│       └── start_dev_server.sh
├── public                     // 入口目录
│   ├── cli.php
│   └── index.php
└── util                       // 通用类库目录
    └── load.php
```
