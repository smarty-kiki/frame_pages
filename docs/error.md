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

文案可带 `{param}` 占位符，由 `otherwise_error_code` 的第三个参数（键值对）替换。

## otherwise

```php
otherwise($assertion, $description = 'assertion is not true', $exception_class_name = 'exception', $exception_code = 'OTHERWISE_DEFAULT')
```

**断言函数**：`$assertion` 为真则放行，为假则抛出 `{错误码}---{描述}` 结构的异常。这是本框架最常用的业务校验写法，等价于「断言不成立则抛异常」。

```php
otherwise(is_login(), '请先登录', 'business_exception', 'NOT_LOGIN');
```

- `$exception_class_name` 默认 `'exception'`（普通异常），传 `'business_exception'` 抛业务异常；两种情况入口都会按 `{错误码}---{描述}` 结构识别为预期内的业务分支
- 错误码建议在 `config/error_code.php` 中维护，文案里可带 `{param}` 占位符（配合 `otherwise_error_code`）

## otherwise_error_code

```php
otherwise_error_code($error_code, $assertion, array $replace_contents = [])
```

**基于错误码字典的断言**：`$assertion` 为假时抛 `business_exception`，错误码为 `$error_code`，错误消息从 `config/error_code.php` 中读取该错误码对应的文案；`$replace_contents` 是**键值对**（键 = 要替换的占位符，值 = 替换内容）：

```php
// config/error_code.php
// 'USER_NOT_FOUND' => '用户 {id} 不存在'

otherwise_error_code('USER_NOT_FOUND', $user !== null, ['{id}' => $user_id]);
// 用户不存在时抛出：USER_NOT_FOUND---用户 123 不存在
```

文案中没有 `{param}` 时省略第三个参数：

```php
otherwise_error_code('ORDER_ALREADY_PAID', $order->paid_at === null);
```

## business_exception

```php
business_exception
```

框架内置的业务异常类（`otherwise.php` 中定义），`{错误码}---{描述}` 结构的消息可由 `otherwise_get_error_info()` 解析出错误码与文案。日常校验直接使用 `otherwise()` / `otherwise_error_code()` 即可，需要手动抛出时按同样结构组织消息：

```php
throw new business_exception('ORDER_ALREADY_PAID---订单已支付');
```

页面/API 入口在 `if_has_exception` 中按消息结构分流：带 `---` 结构的（`otherwise()` / `otherwise_error_code()` 抛出的都算）视为**预期内的业务分支**，记模块日志（module 名 `business_exception`）；不带结构的才是真异常，记异常日志。响应里把错误码与描述作为 `code` / `msg` 返回，浏览器/调用方据此判断业务失败原因。

## otherwise_get_error_info

```php
otherwise_get_error_info(throwable $ex)
```

从异常对象中提取错误信息数组，供统一渲染使用。消息为 `{错误码}---{描述}` 结构时按结构拆分；没有该结构时取异常自身的 code 与完整消息：

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

## 系统错误处理

### if_has_exception

```php
if_has_exception(?closure $action = null): ?closure
```

注册请求过程中抛异常的统一处理，闭包收到的参数是异常对象。入口文件中已注册：

- 页面入口：渲染 `view/error/500`，传入 `code`、`message`
- API 入口：返回 `{code, msg, data: []}` JSON
- 日志按上文规则分流：`business_exception` 与 `{错误码}---{描述}` 结构的断言失败记模块日志（module 名 `business_exception`），其余 `log_exception`
- SSE 入口：记日志后以 `sse_send(['error' => ...])` 回传错误事件并关流

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

- `code`：业务异常 / 断言失败为 `{错误码}` 部分；系统异常为异常自身的 code（框架包装的 PHP 错误为 0）
- `msg`：错误消息
- `data`：空数组
