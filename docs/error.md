# 错误

本框架的错误处理分两层：**业务错误**用 `otherwise()` 断言抛出，携带错误码与文案；**系统错误**（PHP 错误 / 未捕获异常）由 `if_has_exception` 注册的处理器统一渲染。

## 错误码

错误码文案统一放在 `config/error_code.php` 中维护，键为英文大写错误码，值为中文/英文文案：

```php
// config/error_code.php
return [
    'USER_NOT_FOUND'   => '用户不存在',
    'ORDER_ALREADY_PAID' => '订单已支付',
];
```

文案支持 `{param}` 占位符，由 `otherwise_error_code` 的第三个参数按顺序替换。

## otherwise

```php
otherwise($assertion, $description = 'assertion is not true', $exception_class_name = 'exception', $exception_code = 'OTHERWISE_DEFAULT')
```

**断言函数**：当 `$assertion` 为假时抛出一个携带 `$exception_code` 的 `business_exception`，`$description` 作为错误消息。这是本框架最常用的业务校验写法，等价于「断言不成立则抛业务异常」。

```php
otherwise(is_login(), '请先登录', 'business_exception', 'NOT_LOGIN');
```

- `$assertion` 为真则放行；为假则抛出异常
- `$exception_class_name` 传入 `'business_exception'` 时抛出业务异常，页面/API 入口会把它渲染成带错误码的响应
- 错误码建议在 `config/error_code.php` 中定义，文案里可带 `{param}` 占位符

## otherwise_error_code

```php
otherwise_error_code($error_code, $assertion, array $replace_contents = [])
```

**基于错误码字典的断言**：`$assertion` 为假时抛 `business_exception`，错误码为 `$error_code`，错误消息从 `config/error_code.php` 中读取该错误码对应的文案；`$replace_contents` 按顺序替换文案中的 `{param}` 占位符。

```php
// config/error_code.php
// 'USER_NOT_FOUND' => '用户 {id} 不存在'

otherwise_error_code('USER_NOT_FOUND', $user !== null, [$user_id]);
// 用户不存在时抛出：'用户 123 不存在'
```

文案中没有 `{param}` 时也可以只传前两个参数：

```php
otherwise_error_code('ORDER_ALREADY_PAID', $order->paid_at === null);
```

## business_exception

```php
business_exception
```

框架内置的业务异常类（`otherwise.php` 中定义）。带有 `error_code` 属性，可通过以下函数读取：

```php
throw new business_exception('订单已支付', 'ORDER_ALREADY_PAID');
```

页面/API 入口在 `if_has_exception` 中识别 `business_exception`：**不写系统异常日志**（或单独记 business_exception 日志），只把 `error_code` 与消息作为响应的 `code` / `msg` 返回，浏览器/调用方据此判断业务失败原因。

## otherwise_get_error_info

```php
otherwise_get_error_info(throwable $ex)
```

从异常对象中提取错误信息数组。返回的数组包含错误码与消息，供统一渲染使用：

```php
$info = otherwise_get_error_info($ex);
// ['code' => 'USER_NOT_FOUND', 'message' => '用户不存在']
```

## otherwise_get_error_message

```php
otherwise_get_error_message(throwable $ex)
```

从异常对象中提取错误消息字符串：

```php
$message = otherwise_get_error_message($ex);
```

## OTHERWISE_MESSAGE_DELIMITER

```php
OTHERWISE_MESSAGE_DELIMITER = '---'
```

错误消息分隔符常量。`otherwise` 抛出的 `business_exception` 消息中，错误码文案与占位符替换内容用 `---` 分隔拼接，`otherwise_get_error_message` 会据此解析出最终文案。

## 系统错误处理

### if_has_exception

```php
if_has_exception(?closure $action = null): ?closure
```

注册请求过程中抛异常的统一处理。入口文件中已注册：

- 页面入口：渲染 `view/error/500`，传入 `code`、`message`
- API 入口：返回 `{code, msg, data: []}` JSON，`business_exception` 记 business_exception 日志，其余 `log_exception`

### http_err_action / http_ex_action / http_fatal_err_action

对应 PHP 的 `set_error_handler` / `set_exception_handler` / `register_shutdown_function`，把 PHP 错误转成异常交给 `if_has_exception` 渲染。详见[响应](response.md)。

### log_exception

```php
log_exception(throwable $ex)
```

把异常堆栈写入 `config/log.php` 配置的 `exception_path` 日志文件，用于排查系统级错误。

## 错误响应格式

API 入口的错误响应与成功响应同构：

```json
{
  "code": "USER_NOT_FOUND",
  "msg": "用户 123 不存在",
  "data": []
}
```

- `code`：错误码（`business_exception` 为具体错误码，系统异常为 500）
- `msg`：错误消息
- `data`：空数组
