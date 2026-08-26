# 开发环境

框架内置了一套基于 `docker` 的开发环境，对 `linux`、`mac` 用户格外友好。

## 启动开发环境

在项目根目录执行环境启动脚本：

```bash
sh project/tool/start_development_server.sh   # 需要 Docker + 输入 sudo 密码
```

该脚本会拉取开发环境镜像 `registry.cn-shenzhen.aliyuncs.com/smarty/harness_engineering_php_env`，启动容器并映射 `80`、`3306`、`12345`、`12346` 端口，把项目挂载到容器内的 `/var/www/php-vibe-coding-frame`，并设置 `ENV=development`、`PRJ_HOME`、`TIMEZONE` 环境变量。

启动完成后：

- 打开浏览器访问 `http://127.0.0.1/` 可以看到 "hello world" 页面
- `3306` 端口已映射到开发机，可直接用客户端工具连接 `127.0.0.1:3306` 操作数据库（账号 `default` / 密码 `password`）
- 需要从外部再次进入容器可使用 `docker exec -ti <容器名> /bin/bash`

## 工具脚本

`project/tool/` 下的脚本清单及作用：

```bash
project/tool/start_development_server.sh           // 启动开发环境（在开发机上执行）
project/tool/start_development_server.bat          // Windows 版启动脚本
project/tool/classmap.sh <目录>                    // 扫描指定目录下的类生成 autoload.php
project/tool/naming_project.sh <新名称>             // 一键重命名项目（配置文件、脚本、README、CLAUDE.md）
project/tool/development/before_env_start.sh       // 容器启动前：软链 nginx site、supervisor conf、SSE fpm pool 到系统目录
project/tool/development/after_env_start.sh        // 容器启动后：初始化日志文件、建库授权、执行迁移、配置 cli 补全
project/tool/development/queue_job_watch_by_md5.sh // 每 1s 对 queue_job 目录做 md5 比对，变更即重启队列 worker（仅开发）
project/tool/production/after_push.sh              // 生产部署：软链 Caddyfile 并 reload、执行迁移、重启 worker、清理编译缓存
project/tool/production/check_update.sh            // cron 定时：git pull 后有变更则执行 after_push.sh
```

### classmap.sh

扫描目标目录（`domain` / `util`）中符合约定的 PHP 类生成 `autoload.php`。约定：`class`/`abstract class`/`interface` 小写在行首、与类名一个空格、左花括号另起一行；只扫 `.php` 文件；检测重复类名并告警。

### naming_project.sh

一键重命名项目：重命名 nginx/supervisor/caddy 配置文件，`sed` 替换所有脚本、README、全部 CLAUDE.md 中的 `php-vibe-coding-frame` 占位符。通常用于拉取框架项目后快速修改项目名称。

## 环境初始化

`after_env_start.sh` 在容器启动后执行以下动作：

1. 初始化三个日志文件（`/tmp/php_exception.log`、`/tmp/php_notice.log`、`/tmp/php_module.log`）并 `chown www-data`
2. 创建数据库 `default` 并授权账号 `default`/`password`
3. 执行 `migrate:install` + `migrate`
4. 把 `cli` 补全脚本追加到 `~/.bashrc`

## 部署配置

### nginx

开发版 `project/config/development/nginx/php-vibe-coding-frame.conf`：

- `location /` → `try_files ... /index.php`（页面入口）
- `location /assets/` 缓存 30 天
- `location ~ \.php$` fastcgi 到 `unix:/var/run/php-fpm.sock` 并 `fastcgi_param ENV development`
- `location ^~ /api/` → `SCRIPT_FILENAME api.php`（API 入口）
- `location ^~ /sse/` → `SCRIPT_FILENAME sse.php`，`fastcgi_buffering off`、`fastcgi_read_timeout 3600s`、`gzip off`（SSE 入口）

生产版差异：SSE 走普通 php-fpm socket，且无 `ENV` 参数（默认 production）。

### SSE 独立 FPM pool（仅开发）

`project/config/development/php_fpm_pool/sse.conf`：

```
[sse] pool，pm=ondemand，max_children=20，request_terminate_timeout=0（长流不被杀）
监听 unix:/var/run/php-fpm-sse.sock，catch_workers_output=yes
```

### supervisor

- 开发版 `queue_worker`：`numprocs=5`、`stopwaitsecs=5`、`memory_limit=10485760`（10MB）
- 生产版 `queue_worker`：`stopwaitsecs=60` + 日志轮转（10MB）
- `queue_job_watch` 程序：跑 md5 watch 脚本（仅开发）

### Caddy（生产）

`project/config/production/caddy/php-vibe-coding-frame.Caddyfile`：域名 `php-vibe-coding-frame.yao-yang.cn`，TLS 邮箱，root 指向 `public/`，`encode gzip`，`route /CLAUDE.md` 403，`php_fastcgi unix//var/run/php-fpm.sock`。
