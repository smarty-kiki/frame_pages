# 目录结构

`php-vibe-coding-frame` 项目的完整目录结构如下，标注了每个目录和关键文件的用途。

```
php-vibe-coding-frame/
├── bootstrap.php            # 公共引导：定义常量、include 11 个 frame 核心文件（队列实现二选一）、注册 config 目录、加载 util/domain/queue_job
├── CLAUDE.md                # 根级 AI 编码约定
├── LICENSE                  # MIT（版权 2026）
├── README.md                # 项目介绍 / 快速上手 / 设计理念
├── frame/                   # ★框架核心库（只读，禁止修改）
│   ├── base_function.php    # 数组/字符串/配置/HTTP/日期/单例工具函数
│   ├── orm_entity.php       # entity 基类 + null_entity + 关系体系 + dao 基类 + 本地缓存
│   ├── otherwise.php        # 断言与业务异常
│   ├── database_mysql.php   # PDO 连接池、读写分离、事务、simple 系列
│   ├── cache_redis.php      # Redis 连接池、KV/Hash/List/Bitmap
│   ├── lock_cache.php       # 分布式锁（singly_run 互斥 / serially_run 排队）
│   ├── clickhouse.php       # ClickHouse 分析库（ch_* 系列）
│   ├── queue_beanstalk.php  # Beanstalkd 队列（纯 socket 协议 + worker）
│   ├── queue_kafka.php      # Kafka 队列（php-rdkafka；与 beanstalk 版二选一加载）
│   ├── orm_unitofwork.php   # 工作单元 + Redis ID 生成器
│   ├── log.php              # JSON Lines 日志
│   ├── trace.php            # 全链路 trace（trace_id / span 体系）
│   ├── php_fpm.php          # 路由/输入/响应/重定向/视图/异常（HTTP）
│   ├── view_blade.php       # 轻量 Blade 引擎
│   ├── cli_command.php      # CLI 命令注册与参数解析
│   ├── sse.php              # SSE 流式服务
│   └── CLAUDE.md            # frame/ 目录文档（API 速查表）
├── config/                  # PHP 数组配置 + 环境覆盖
│   ├── mysql.php            # MySQL（migrate / entity / default 三个库位）
│   ├── redis.php            # Redis（default / idgenter / lock 三个库位）
│   ├── beanstalk.php        # Beanstalkd 连接
│   ├── kafka.php            # Kafka 连接（brokers / flush 超时）
│   ├── queue.php            # 队列 tube/topic 映射与消费参数
│   ├── clickhouse.php       # ClickHouse（default / migrate 两个库位）
│   ├── blade.php            # Blade 编译路径
│   ├── log.php              # 日志路径 + service 名
│   ├── error_code.php       # 业务错误码文案
│   ├── development/         # ENV=development 覆盖（mysql 连接、blade compiled_cache=false）
│   ├── test/                # ENV=test 覆盖（mysql/clickhouse/queue/log/blade，独立实例）
│   └── production/          # ENV=production 覆盖（默认）
├── public/                  # Web 根目录（nginx root）
│   ├── index.php            # 页面入口（HTML）
│   ├── api.php              # API 入口（JSON）
│   ├── cli.php              # CLI 入口
│   ├── sse.php              # SSE 入口
│   └── assets/              # css/js/img 静态资源（nginx 直接返回，缓存 30 天）
├── controller/              # 页面路由（闭包，返回 HTML 字符串）
│   └── base.php             # 首页 /health_check
├── controller_api/          # API 路由（闭包，路由以 /api/ 开头，返回 JSON）
│   └── base.php             # /api/error_code_maps
├── controller_sse/          # SSE 业务（sse_route 命中即分发）
│   └── echo.php             # 示例：/echo 逐字流式返回 text 参数
├── domain/                  # 领域层
│   ├── entity/              # Active Record 实体（demo.php 示例）
│   ├── dao/                 # 数据访问对象（demo_dao 示例）
│   ├── knowledge/           # 复杂业务逻辑封装（纯函数）
│   ├── autoload.php         # classmap（spl_autoload_register）
│   └── load.php             # 入口
├── command/                 # CLI 命令
│   ├── entity.php           # entity:restep-last-id
│   ├── migration/
│   │   ├── migrate.php      # MySQL 迁移命令（8 个）
│   │   ├── migrate_clickhouse.php  # ClickHouse 分析库迁移命令
│   │   ├── sql/             # 迁移 SQL 文件 + merged/ 归档
│   │   └── clickhouse_sql/  # ClickHouse 迁移 SQL 文件
│   └── queue/
│       ├── queue.php        # 队列命令（beanstalk 版，7 个）
│       ├── queue_kafka.php  # 队列命令（kafka 版，4 个）
│       └── queue_job/       # 队列任务定义（load.php + demo.php + demo_kafka.php）
├── interceptor/             # 拦截器（if_verify 全局、局部显式调用）
├── view/                    # Blade 模板
│   ├── index/               # 首页
│   ├── error/               # 404.php / 500.php
│   ├── layout/              # 公共布局约定（header/footer/pagination，按需创建）
│   └── blade/               # 编译缓存（自动生成）
├── util/                    # 外部能力封装（支付/短信/OSS，纯函数 + classmap）
│   ├── load.php
│   └── autoload.php
└── project/                 # 部署配置与工具脚本
    ├── config/              # 各环境的 nginx、caddy、supervisor、php_fpm_pool、bash 配置
    │   ├── development/     # 开发环境（nginx、supervisor + queue_job_watch、SSE pool、bash 补全）
    │   ├── test/            # 测试环境（nginx、caddy、supervisor、SSE pool、cron.d）
    │   └── production/      # 生产环境（nginx、caddy、supervisor、cron.d）
    └── tool/                # 启动/重命名/classmap/ClickHouse/部署脚本
```

## 核心约定

- **类名、函数名使用蛇形小写**，Entity 类名与表名一致（单数名词），DAO 类名为 `{entity_name}_dao`
- 无 Composer autoload，基于 `classmap.sh` 生成的 `autoload.php` 做类加载
- `frame/` 为核心库，代码只读，禁止修改
- 队列实现（`queue_beanstalk.php` / `queue_kafka.php`）**二选一加载**：两套实现函数同名，由 `bootstrap.php` 决定 include 哪个
