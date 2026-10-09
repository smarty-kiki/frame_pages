# 链路追踪

框架内置一套全链路 trace 上下文（`frame/trace.php`，W3C Trace Context 口径）：入口取客户端传来的 `trace_id`（`traceparent` > `X-Request-Id`），没有就本地生成。日志字段、SQL 注释、Redis 连接名、队列信封、出站请求头都从这里取——同一处理单元全链路同一个 id，跨服务、跨队列串成一条链路。

上下文存在静态容器里：FPM 一请求一执行、CLI 一进程多任务（worker 每取到一个任务重新 `trace_init`），容器随进程用即可。

## 上下文

### trace_id / trace_span_id / trace_parent_span_id

```php
trace_id(): ?string
trace_span_id(): ?string
trace_parent_span_id(): ?string
```

分别返回当前处理单元的 `trace_id`（32 位 hex，全链路同值）、`span_id`（16 位 hex，本次处理单元新生成）、`parent_span_id`（上游的 span，可空）。无上下文时返回 `null`。

### trace_all

```php
trace_all(): array
```

返回完整上下文字段数组（`trace_id` / `span_id` / `parent_span_id`）；无上下文时为空数组。队列投递时信封里携带的就是它（见[队列](queue.md)）。

```php
$context = trace_all();
// ['trace_id' => '...', 'span_id' => '...', 'parent_span_id' => null]
```

## 初始化与重置

### trace_init

```php
trace_init(?string $trace_id = null, ?string $parent_span_id = null): string
```

初始化（或重建）trace 上下文，返回实际采用的 `trace_id`：

- `$trace_id` 为合法的 32 位 hex（不区分大小写）时**原样采用**——合法值不做大小写转换，与 nginx map 的口径逐字对齐，两侧选出的 id 才能逐字符一致；不合法或没传时生成新的小写 id
- `span_id` 固定新生成；`$parent_span_id` 由调用方传（入站 traceparent 的 span 段 / 队列投递方的 span）

CLI 入口（`public/cli.php`）直接 `trace_init()` 新起上下文；队列 worker 每取到一个任务用信封里的 trace 重新 init（见[队列](queue.md)）。

### trace_begin_request

```php
trace_begin_request(): string
```

**HTTP 入口初始化**（`public/index.php` / `public/api.php` / `public/sse.php` 启动时调用）。取 id 的优先级与 nginx 的 map 链逐字一致：`traceparent`（W3C 格式 `00-{32位 trace_id}-...`）> `X-Request-Id`（32 位 hex）> 自生成；`parent_span_id` 只从严格 W3C 格式的 traceparent 里取（`00-{32位}-{16位}-{2位}`）。

初始化后回写 `X-Request-Id` 响应头：Caddy 前置时直接透传给客户端；nginx 前置时被 `fastcgi_hide_header` 隐藏、由 nginx 回写同值（见[环境](environment.md)）。

### trace_reset

```php
trace_reset(): void
```

清空上下文。队列 worker 每处理完一个任务调用——下一轮循环在取到新任务前不带上一个任务的 trace。

## 生成物

### trace_sql_comment

```php
trace_sql_comment(): string
```

生成 SQL 前置注释 `/* trace_id=... span=... */ `，MySQL 的 general_log / slow log 靠它把语句关联到请求；无上下文时返回空串。注释内容仅 hex 与固定分隔符，不扩大注入面。框架把它的返回值自动拼在每条 SQL 前面（见[数据库](database.md)）。

### trace_http_headers

```php
trace_http_headers(): array
```

返回出站请求头数组，用于跨服务透传：

```php
// traceparent 的 span 段是「我」，下游拿它当 parent
['traceparent: 00-{trace_id}-{span_id}-01', 'X-Request-Id: {trace_id}']
```

无上下文时返回空数组。`http()` 发起请求前自动补进 header——调用方显式带了同名头就不覆盖（见[辅助函数](function.md)）。

## 各模块的衔接

- **日志**：每条日志行自带 `trace_id` / `span_id` / `parent_span_id` 字段（见[日志](log.md)）
- **数据库**：SQL 带 `/* trace_id=... */` 前置注释（见[数据库](database.md)）
- **缓存**：Redis 连接名设为 `trace:{trace_id 前 24 位}`（无 trace 为 `app`），Redis 7+ 的 `CLIENT LIST` / SLOWLOG 据此归属命令（见[缓存](cache.md)）
- **队列**：信封携带投递方的 trace，消费方恢复上下文、处理完清理（见[队列](queue.md)）
- **出站请求**：`http()` 自动补 `traceparent` / `X-Request-Id` 头（见[辅助函数](function.md)）
- **web server 日志**：nginx 的 `map` / `log_format` 与 PHP 侧同一套取 id 规则（见[环境](environment.md)）
