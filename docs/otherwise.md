# 断言

断言（otherwise）是本框架业务校验的核心：**用一行断言声明「前提条件」**，条件不成立就抛异常中断。比手写 `if + throw` 更声明式，也更适合 Vibe Coding——把校验规则直接写出来。

本页专注断言函数本身；断言抛出的异常如何被页面 / API 入口转换成响应，见[错误](error.md)。

## otherwise

```php
otherwise($assertion, $description = 'assertion is not true', $exception_class_name = 'exception', $exception_code = 'OTHERWISE_DEFAULT')
```

**核心断言函数**：当 `$assertion` 为假时抛异常，异常类由 `$exception_class_name` 决定，异常消息为 `{错误码}---{描述}` 拼接结构（错误码 `$exception_code`、描述 `$description`，分隔符常量 `OTHERWISE_MESSAGE_DELIMITER` 为 `---`；PHP 异常 code 固定传 `-1`，业务错误码编码在消息里）。

```php
otherwise($user !== null, '用户不存在');
otherwise(is_login(), '请先登录');
otherwise($amount > 0, '金额必须大于 0');
```

参数说明：

- `$assertion`：任意可判断真假的表达式。为真 → 放行；为假 → 抛异常
- `$description`：异常消息文案
- `$exception_class_name`：异常类名。传 `'business_exception'` 抛业务异常（推荐）；默认 `'exception'` 抛普通异常
- `$exception_code`：异常错误码，编码进异常消息（`{错误码}---{描述}`）。业务异常的错误码建议在 `config/error_code.php` 中定义

业务校验的标准写法：

```php
otherwise($user !== null, '用户不存在', 'business_exception', 'USER_NOT_FOUND');
```

## otherwise_error_code

```php
otherwise_error_code($error_code, $assertion, array $replace_contents = [])
```

**基于错误码字典的断言**：`$assertion` 为假时抛 `business_exception`，错误码固定为 `$error_code`，错误消息从 `config/error_code.php` 读取该错误码对应文案，抛出的消息为 `{错误码}---{替换后的文案}`；`$replace_contents` 是**键值对**（键 = 文案中的占位符，值 = 替换内容），逐个 `str_replace` 替换。

```php
// config/error_code.php
// 'USER_NOT_FOUND' => '用户 {id} 不存在'

otherwise_error_code('USER_NOT_FOUND', $user !== null, ['{id}' => $user_id]);
// 失败时消息：'用户 123 不存在'
```

文案不含占位符时无需第三个参数：

```php
otherwise_error_code('ORDER_ALREADY_PAID', $order->paid_at === null);
```

## business_exception

```php
business_exception
```

业务异常类（定义于 `otherwise.php`，是 `exception` 的标记子类，自身不携带额外属性）。`otherwise` / `otherwise_error_code` 抛出它时，错误码与文案以 `{错误码}---{描述}` 结构编码在异常消息里，由 `otherwise_get_error_info()` 解析出来。页面 / API 入口在异常处理器中识别它：

- **不当作系统错误**：不写异常日志，改记模块日志（channel 为 `business_exception`）
- 解析出的错误码与消息作为响应的 `code` / `msg` 返回

也可以直接手动抛出（消息按同样结构组织，错误码才能被解析出来）：

```php
throw new business_exception('ORDER_ALREADY_PAID---订单已支付', -1);
```

## otherwise_get_error_info

```php
otherwise_get_error_info(throwable $ex)
```

从异常对象提取错误信息数组：消息为 `{错误码}---{描述}` 结构时按 `---` 拆出 `['code' => 错误码, 'message' => 描述]`；没有该结构时取异常自身的 code 与完整消息。入口的错误处理器用它在 `if_has_exception` 中构造错误响应。

```php
$info = otherwise_get_error_info($ex);
// ['code' => 'USER_NOT_FOUND', 'message' => '用户 123 不存在']
```

## otherwise_get_error_message

```php
otherwise_get_error_message(throwable $ex)
```

从异常对象提取错误消息字符串：消息为 `{错误码}---{描述}` 结构时返回描述部分，否则返回异常的完整消息。

```php
$message = otherwise_get_error_message($ex);
```

## 设计要点

- 断言函数是**纯函数**，只负责「校验 + 抛异常」，不包含业务副作用
- 配合 `unit_of_work`：断言在路由闭包内抛出 `business_exception` → 工作单元回滚 → 错误响应返回，一次请求不会留下半截数据
- 错误码统一在 `config/error_code.php` 维护，便于前端对接与多语言
