# 日志

本框架提供轻量的文件日志（`frame/log.php`）：三类日志各自写入独立文件，统一 **JSON Lines** 格式（一行一条 JSON、UTF-8），字段口径对齐全链路 trace，便于采集与检索。路径与 `service` 名在 `config/log.php` 中配置（见[配置](config.md)）。

## 日志配置

```php
// config/log.php
return [
    'service' => 'php-vibe-coding-frame',   // 每条日志的 service 字段
    'exception_path' => '/tmp/php_exception.log',   // 异常日志
    'notice_path'    => '/tmp/php_notice.log',       // 通知日志
    'module_path'    => '/tmp/php_module.log',       // 模块日志
];
```

开发环境 `after_env_start.sh` 会自动初始化这三个文件并授权 `www-data`。

## 日志行格式

每条日志是一行 JSON，固定字段如下，另合并各函数传入的上下文字段：

| 字段 | 说明 |
|------|------|
| `@timestamp` | UTC 时间，毫秒精度（`Y-m-d\TH:i:s.v\Z`，如 `2026-08-26T02:30:00.123Z`） |
| `level` | 级别：`error` / `notice` / `info` |
| `channel` | 来源：`exception` / `notice` / 模块名 |
| `message` | 消息正文 |
| `trace_id` / `span_id` / `parent_span_id` | 当前链路上下文，无上下文时为 `null`（见[链路追踪](trace.md)） |
| `service` | `config('log')['service']` |
| `env` | 当前环境名（`env()`） |
| `host` | `gethostname()` |

```json
{"@timestamp":"2026-08-26T02:30:00.123Z","level":"notice","channel":"notice","message":"订单 1001 已支付","trace_id":"5f2c...","span_id":"a1b2...","parent_span_id":null,"service":"php-vibe-coding-frame","env":"production","host":"web-01"}
```

`message` 与 `stack` **不截断**：截断是采集 / 存储层的职责，源头截断不可逆，会让排障时缺堆栈。

## log_exception

```php
log_exception(throwable $ex)
```

写入异常日志（`exception_path`）：`level` 为 `error`、`channel` 为 `exception`，消息为异常 message，附加字段：`exception`（异常类名）、`file`（`文件:行号`）、`stack`（完整调用栈）。入口的异常处理器捕获未捕获异常时自动调用，业务代码也可主动记录。

```php
try {
    // ...
} catch (throwable $ex) {
    log_exception($ex);
    throw $ex;
}
```

## log_notice

```php
log_notice($message)
```

写入通知日志（`notice_path`）：`level` 为 `notice`、`channel` 为 `notice`。适合记录业务关键节点（下单、支付回调、任务执行等）。

```php
log_notice('订单 '.$order_id.' 已支付');
```

## log_module

```php
log_module($module, $message)
```

写入模块日志（`module_path`）：`level` 为 `info`、`channel` 为 `$module`，便于按模块归类检索。

```php
log_module('queue', '任务执行完成');
log_module('payment', '微信回调参数异常');
```

## 与错误处理的关系

- `business_exception`（业务异常）由入口单独记录或跳过，不作为系统异常刷屏（见[错误](error.md)）
- 未捕获的 PHP 异常 / 错误经入口的异常处理器转成响应并调用 `log_exception`（见[错误](error.md)）
