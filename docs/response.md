# 响应

框架的响应由**入口决定**：页面入口把字符串当 HTML 输出，API 入口把返回值包装成 `{code, msg, data}` JSON。本页介绍响应相关的函数与响应式行为。

## 返回约定

- 页面入口（`public/index.php`）：路由闭包**返回字符串** → `Content-Type: text/html` 输出；返回非字符串判为编程错误抛 500
- API 入口（`public/api.php`）：闭包返回**任意值**（数组 / Entity / 标量）→ 统一包装成 `{code: 0, msg: '', data: $data}` JSON 输出
- 重定向：`return redirect(...)` → 响应阶段发送 `Location` 头跳转

## JSON 输出（API 入口自动）

API 入口（`public/api.php`）会先发送 `Content-Type: application/json`，再把路由闭包的**任意返回值**（数组 / Entity / 标量）包装成 `{code, msg, data}` 输出：

```php
// public/api.php
if_any('/api/time', function () {
    return ['now' => date('Y-m-d H:i:s')];
});
// 输出: {"code":0,"msg":"","data":{"now":"..."}}
```

`json()` 本身是一个 `json_encode` 辅助函数（不设置响应头），详见[辅助函数](function.md)。API 入口内部就是用 `json()` 对包装结果编码。

## render

```php
render(string $view, array $args = [])
```

渲染 Blade 模板并返回 HTML 字符串。`$view` 为相对 `view_path()` 目录的模板路径（不含 `.php` 后缀），`$args` 为传入模板的变量。模板语法见[视图](view.md)。

```php
if_get('/user/list', function () {
    return render('user/list', ['users' => dao('user')->find_all()]);
});
```

页面入口直接 `return render(...)` 即可输出 HTML。

## include_view

```php
include_view(string $view, array $args = [])
```

在模板内部包含另一个模板（对应 Blade 的 `@include`），复用公共布局或片段。等价于把子模板渲染结果嵌入当前模板：

```php
<!-- view/index.php -->
<?php include_view('layout/header'); ?>
```

## view_path

```php
view_path(?string $path = null): string
```

获取/设置视图根目录。无参调用返回当前 `view_path()`；传入 `$path` 则设置新目录并返回。框架在 `public/index.php` 中已设置为 `VIEW_DIR`。

```php
view_path('/var/www/app/view');   // 设置视图目录
echo view_path();                 // 读取视图目录
```

## view_compiler

```php
view_compiler(?closure $closure = null): ?closure
```

获取/设置视图编译器。框架在页面入口中已把 `blade_view_compiler_generate()` 注册为编译器，`render()` 时会把模板内容交给该闭包编译。

```php
view_compiler(blade_view_compiler_generate());  // 注册 Blade 编译器
```

## cache_with_etag

```php
cache_with_etag($etag)
```

以 `ETag` 形式启用页面缓存：输出时附带 `ETag` 头；若请求头 `If-None-Match` 与 `$etag` 相同，返回 `304 Not Modified`，浏览器直接使用本地缓存。

```php
if_get('/index', function () {
    $html = render('index');
    return cache_with_etag(md5($html)) . $html;
});
```

## 异常响应

以下三个函数在 `public/index.php` / `public/api.php` 中作为 PHP 错误与异常的**处理器**注册，把未捕获的错误转成 HTTP 响应。

### if_has_exception

```php
if_has_exception(?closure $action = null): ?closure
```

注册「请求过程中抛异常」时的统一处理闭包。`$action` 收到一个包含异常信息的数组参数。页面入口用它渲染 `error/500`，API 入口用它返回 `{code, msg}` JSON：

```php
// public/index.php
if_has_exception(function (array $exception) {
    return render('error/500', $exception);
});
```

传入的 `$exception` 数组通常包含 `code`、`message` 等字段。

### http_err_action

```php
http_err_action($error_type, $error_message, $error_file, $error_line, $error_context = null)
```

`set_error_handler` 的处理器签名。把 PHP 运行期错误（类型、消息、文件、行号、错误上下文）拼成一条消息，交给 `http_ex_action` 处理，最终由 `if_has_exception` 注册的闭包渲染。

```php
set_error_handler('http_err_action', E_ALL);
```

### http_ex_action

```php
http_ex_action($ex)
```

`set_exception_handler` 的处理器签名。把未捕获异常交给 `if_has_exception` 注册的闭包渲染，同时写入异常日志（`log_exception`）。

```php
set_exception_handler('http_ex_action');
```

### http_fatal_err_action

```php
http_fatal_err_action()
```

`register_shutdown_function` 的处理器签名。捕获 `E_ERROR` 等致命错误（此时脚本已终止，只能靠 shutdown 兜底），同样交给 `if_has_exception` 渲染。

```php
register_shutdown_function('http_fatal_err_action');
```
