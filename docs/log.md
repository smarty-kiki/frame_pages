# 日志

本框架提供轻量的文件日志：三类日志各自写入独立文件，日志格式带微秒时间戳与调用位置，方便定位。路径在 `config/log.php` 中配置（见[配置](config.md)）。

## 日志配置

```php
// config/log.php
return [
    'exception_path' => '/tmp/php_exception.log',   // 异常日志
    'notice_path'    => '/tmp/php_notice.log',       // 通知日志
    'module_path'    => '/tmp/php_module.log',       // 模块日志
];
```

开发环境 `after_env_start.sh` 会自动初始化这三个文件并授权 `www-data`。

## log_exception

```php
log_exception(throwable $ex)
```

写入异常日志（`exception_path`）：记录微秒时间戳、异常类、错误码、消息与完整堆栈。框架的错误处理器在捕获未捕获异常时自动调用，业务代码也可主动记录。

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

写入通知日志（`notice_path`）：记录微秒时间戳与消息文本。适合记录业务关键节点（下单、支付回调、任务执行等）。

```php
log_notice('订单 '.$order_id.' 已支付');
```

## log_module

```php
log_module($module, $message)
```

写入模块日志（`module_path`）：在消息前附加 `$module` 标识，便于按模块归类检索。

```php
log_module('queue', '任务执行完成');
log_module('payment', '微信回调参数异常');
```

## _log_prefix

```php
_log_prefix()
```

生成日志行前缀：微秒时间戳 + 调用文件与行号。三个 `log_*` 函数内部调用，用于在日志中定位日志产生的位置。

```php
echo _log_prefix();   // '2026-08-26 10:30:00.123456 [index.php:12]'
```

## 日志行示例

```
2026-08-26 10:30:00.123456 [/var/www/app/controller/user.php:12] 订单 1001 已支付
```

## 与错误处理的关系

- `business_exception`（业务异常）由入口单独记录或跳过，不作为系统异常刷屏（见[错误](error.md)）
- 未捕获的 PHP 异常 / 错误经 `http_ex_action` 等处理器转成响应并调用 `log_exception`
