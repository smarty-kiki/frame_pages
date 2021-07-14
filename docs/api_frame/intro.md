# 介绍

`api_frame` 是使用 `frame` 组装的满足单层 `http api` 服务场景的快速开发框架，拥有请求响应、`orm`、`orm` 持久化、缓存、命令行、队列、数据结构升级工具等能力

# 目录结构

```
.
├── LICENSE
├── README.md
├── bootstrap.php             // 框架领域层、公用组件的加载和配置
├── command                   // 命令行工具目录
│   └── queue_job            // 队列任务声明文件的目录
│       └── load.php
├── config                    // 配置文件目录
│   ├── development          // 开发环境配置
│   └── production           // 线上环境配置
├── controller                // 控制器文件目录
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
│   │   └── production
│   └── tool                   // 开发、发布、部署脚本工具
├── public                     // 入口目录
│   ├── cli.php
│   └── index.php
└── util                       // 通用类库目录
```
