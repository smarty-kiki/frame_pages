# 环境

框架有三个环境：`development`、`test`、`production`，由 `$_SERVER['ENV']` 决定（`env()` 读取，**默认 `production`**）。三层同名目录各司其职：应用配置在 `config/{env}/`、部署配置在 `project/config/{env}/`、部署脚本在 `project/tool/` 下。

| 环境 | 用途 | 应用配置 | 部署配置 | 启动 / 部署脚本 |
|------|------|----------|----------|------------------|
| `development` | 本地 Docker 容器开发 | `config/development/` | `project/config/development/` | `project/tool/start_development_server.sh` |
| `test` | 独立测试服务器（与生产同构，域名 + TLS） | `config/test/` | `project/config/test/` | `project/tool/test/after_push.sh` |
| `production` | 生产服务器 | `config/production/` | `project/config/production/` | `project/tool/production/after_push.sh` |

> `test` 环境的一切命令都要显式带 `ENV=test`：不设 `ENV` 时 `env()` 会退回 `production`，迁移与队列 worker 都会打到生产配置上。

## 开发环境（Docker）

框架内置了一套基于 `docker` 的开发环境，对 `linux`、`mac` 用户格外友好。

在项目根目录执行环境启动脚本：

```bash
sh project/tool/start_development_server.sh   # 需要 Docker + 输入 sudo 密码
```

该脚本会拉取开发环境镜像 `registry.cn-shenzhen.aliyuncs.com/smarty/harness_engineering_php_env`，启动容器并映射 `80`、`3306`、`12345`、`12346` 端口，把项目挂载到容器内的 `/var/www/php-vibe-coding-frame`，设置 `ENV=development`、`PRJ_HOME`、`TIMEZONE` 环境变量，并在容器启动前后分别执行 `before_env_start.sh` 与 `after_env_start.sh`。

启动完成后：

- 打开浏览器访问 `http://127.0.0.1/` 可以看到 "hello world" 页面
- `3306` 端口已映射到开发机，可直接用客户端工具连接 `127.0.0.1:3306` 操作数据库（账号 `default` / 密码 `password`）
- 需要从外部再次进入容器可使用 `docker exec -ti <容器名> /bin/bash`

### 环境初始化

`before_env_start.sh` 在容器启动前把配置软链到系统目录（nginx site、supervisor 的 queue worker 与 job watch、SSE 独立 fpm pool）；`after_env_start.sh` 在容器启动后执行：

1. 初始化三个日志文件（`/tmp/php_exception.log`、`/tmp/php_notice.log`、`/tmp/php_module.log`）并 `chown www-data`
2. 创建数据库 `default` 并授权账号 `default`/`password`
3. 执行 `migrate:install` + `migrate`
4. 把 `cli` 补全脚本追加到 `~/.bashrc`

## 测试环境

测试环境是独立服务器，与生产同构（域名 + TLS），只服务测试。应用侧配置在 `config/test/`；发布完成后调用：

```bash
sh project/tool/test/after_push.sh
```

`after_push.sh` 把部署后的全部步骤收在一个脚本里：

1. 建日志目录与文件（`/var/log/php-vibe-coding-frame/`，supervisor 起 worker 时要能打开，PHP 不会自建）
2. 链接 nginx 与 SSE pool 配置并 reload（要用域名 + TLS 时改链 caddy 那份，脚本里有注释）
3. 建测试库与账号——MySQL 库/账号/密码与 ClickHouse 库名统一为带项目名的 `php-vibe-coding-frame`，与 `config/test/` 的配置一致
4. 以 `www-data` 跑 `ENV=test` 的 `migrate:install` + `migrate`，再调 `clickhouse_migrate.sh`
5. 把定时任务拷到 `/etc/cron.d/`
6. 链接 supervisor 配置并 `update` + `restart` 队列 worker
7. 清 Blade 编译缓存

## 工具脚本

`project/tool/` 下的脚本清单及作用：

```bash
project/tool/start_development_server.sh           // 启动开发环境（在开发机上执行）
project/tool/start_development_server.bat          // Windows 版启动脚本
project/tool/classmap.sh <目录>                    // 扫描指定目录下的类生成 autoload.php
project/tool/naming_project.sh <新名称>             // 一键重命名项目（配置文件、脚本、README、CLAUDE.md）
project/tool/clickhouse_migrate.sh                 // ClickHouse 建库 + 跑分析库迁移（测试与生产共用；不可达自动跳过）
project/tool/development/before_env_start.sh       // 容器启动前：软链 nginx site、supervisor conf、SSE fpm pool 到系统目录
project/tool/development/after_env_start.sh        // 容器启动后：初始化日志文件、建库授权、执行迁移、配置 cli 补全
project/tool/development/queue_job_watch_by_md5.sh // 每 1s 对 queue_job 目录做 md5 比对，变更即重启队列 worker（仅开发）
project/tool/production/after_push.sh              // 生产部署：软链 Caddyfile 并 reload、跑迁移、建日志目录、装定时任务、重启 worker、清编译缓存
project/tool/test/after_push.sh                    // 测试部署：建日志目录、链接配置、建库 + 迁移、装定时任务、重启 worker、清编译缓存
```

### classmap.sh

扫描目标目录（`domain` / `util`）中符合约定的 PHP 类生成 `autoload.php`。约定：`class`/`abstract class`/`interface` 小写在行首、与类名一个空格、左花括号另起一行；只扫 `.php` 文件；检测重复类名并告警。

### naming_project.sh

一键重命名项目：重命名 nginx/supervisor/caddy 配置文件，`sed` 替换所有脚本、README、全部 CLAUDE.md 中的 `php-vibe-coding-frame` 占位符。通常用于拉取框架项目后快速修改项目名称。

### clickhouse_migrate.sh

ClickHouse 初始化脚本，测试与生产共用，由各环境的部署脚本以 `www-data` 身份调用：先 `ch_ping()` 探测，**不可达就自动跳过**建库与迁移；可达则按配置里的库名建库（库名做非法字符校验），再依次执行 `clickhouse:install`、`clickhouse:migrate`。建库不走框架的 `ch_write`（库还不存在时连接阶段就会报 `UNKNOWN_DATABASE`），改用 `http()` 直连、不带 `database` 参数。

## 部署配置

### nginx

开发版 `project/config/development/nginx/php-vibe-coding-frame.conf`：

- `location /` → `try_files ... /index.php`（页面入口）
- `location /assets/` 缓存 30 天
- `location ~ \.php$` fastcgi 到 `unix:/var/run/php-fpm.sock` 并 `fastcgi_param ENV 'development'`
- `location ^~ /api/` → `SCRIPT_FILENAME api.php`（API 入口）
- `location ^~ /sse/` → `SCRIPT_FILENAME sse.php`，`fastcgi_buffering off`、`fastcgi_read_timeout 3600s`、`gzip off`（SSE 入口）
- 顶部带全链路 trace 的 `map` 链与 JSON `log_format`（server 块外，随 sites-enabled 在 http 级生效）：`$trace_id` 取客户端 `traceparent` > `X-Request-Id` > `$request_id`，判定正则与 `frame/trace.php` 逐字对齐；`add_header X-Request-Id $trace_id always`（未进 PHP 的响应也带头）+ `fastcgi_hide_header X-Request-Id`，三个 fastcgi location 都传 `fastcgi_param HTTP_X_REQUEST_ID $trace_id`。详见[链路追踪](trace.md)

测试版与开发版同构（显式写 `fastcgi_param ENV 'test'`）；生产版不写 `ENV` 参数（`env()` 默认就是 production）、SSE 走普通 php-fpm socket。三个环境都带 trace 的 `map`/`log_format`。

### SSE 独立 FPM pool（开发与测试）

`project/config/development/php_fpm_pool/sse.conf`（测试版在 `project/config/test/php_fpm_pool/sse.conf`）：

```
[sse] pool，pm=ondemand，max_children=10（2C4G 基准，每路流独占一个 worker），request_terminate_timeout=0（长流不被杀）
监听 unix:/var/run/php-fpm-sse.sock，catch_workers_output=yes + decorate_workers_output=no（保留 JSON 日志行原样）
```

### supervisor

- 开发版 `queue_worker`：`numprocs=5`、`user=root`、`stopwaitsecs=5`、`memory_limit=10485760`（10MB）；另有 `queue_job_watch` 程序跑 md5 watch 脚本（仅开发）
- 测试版 `queue_worker`：`user=www-data`、显式 `ENV=test`、`stopwaitsecs=60` + 日志轮转（10MB，落 `/var/log/php-vibe-coding-frame/queue_worker.log`）
- 生产版 `queue_worker`：`user=www-data`、`stopwaitsecs=60` + 日志轮转
- 三个环境都带一份 Kafka 版模板（`*_queue_worker_kafka.conf`），与 Beanstalk 版**二选一启用**，见[队列](queue.md)

### Caddy（测试与生产）

- 生产版 `php-vibe-coding-frame.Caddyfile`：域名 `php-vibe-coding-frame.yao-yang.cn`，TLS 邮箱，root 指向 `public/`，`encode gzip`（豁免 `/sse/*`）——`/assets/*` 直接文件服务、`/sse/*` 反代到独立 SSE pool 的 `php-fpm-sse.sock`（`flush_interval -1` 禁缓冲）、`/api/*` 固定入口 `api.php`、`/CLAUDE.md` 403、其余走 `php_fastcgi` + `file_server`
- 测试版：域名 `php-vibe-coding-frame-test.yao-yang.cn`，与生产同构，额外在每个入口显式 `env ENV test`（建新项目时记得替换域名）
- Caddy 这两份**不配置** trace 的 `map`/`log_format`：客户端 trace 头由 fastcgi 原样交给 PHP 采用，响应头由 PHP 回写、Caddy 透传

### 定时任务（cron）

测试与生产的定时任务由仓库统一管理：`project/config/{test,production}/cron.d/php-vibe-coding-frame`，启动/部署脚本把它**拷贝**到 `/etc/cron.d/php-vibe-coding-frame`（不是软链——cron 会校验 `/etc/cron.d` 下文件的属主与权限，软链会指回仓库里那个文件）。两条纪律：

- 业务命令用 `www-data` 跑（`分 时 日 月 周 www-data 命令`）：与 web、队列 worker 同一身份，谁写日志都是 www-data
- php 命令写全 `ENV=...` 与 `/usr/bin/php` 绝对路径：cron 的执行环境里没有 `ENV`、`PATH` 也很短，漏了 `ENV` 会退回 production

文件里带了一个 `touch /var/log/php-vibe-coding-frame/cron_heartbeat.log` 的心跳示例和业务命令示例。

### 日志目录的权限

测试与生产的日志目录 `/var/log/php-vibe-coding-frame/`：目录 `2775`（组内可写 + 新建文件继承 `www-data` 组）、文件 `664`，属主 `www-data`，由部署脚本在服务启动前建好，**只建不截断**（`touch` 而不是 `date >`，部署与服务重启不能清掉现场日志）。这套权限是兜底：万一 root 的部署脚本新建了日志文件，部署时那次 `chmod` 会把它掰回来，避免之后 www-data 写不进去。
