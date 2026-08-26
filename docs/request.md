# 请求

本框架不提供对象化 Request，而是提供一组**全局函数**直接读取当前请求的各类输入。所有输入读取函数都基于原始 `$_REQUEST` / `$_COOKIE` / `$_SERVER`，不区分 `GET` / `POST`（`$_REQUEST` 合并了两者）。

## 输入读取

### input_safe

```php
input_safe(string $name, $default = null)
```

读取请求参数并做 **HTML 实体转义**，防止 XSS。返回 `htmlspecialchars()` 处理后的值，适合直接输出到 HTML 页面。

```php
$name = input_safe('name');  // '<script>' → '&lt;script&gt;'
```

### input

```php
input(string $name, $default = null)
```

读取请求参数原始值。键不存在时返回 `$default`。

```php
$page = input('page', 1);          // 默认值 1
$name = input('name');             // 未传为 null
$all  = input();                   // 无键时返回全部参数数组
```

### input_list

```php
input_list(...$names)
```

一次读取多个请求参数，返回以参数名为键的数组。键不存在时值为 `null`。

```php
$params = input_list('name', 'age', 'gender');
// ['name' => '张三', 'age' => '18', 'gender' => null]
```

### input_json

```php
input_json($name, $default = null)
```

读取请求参数，并 `json_decode` 解析为 PHP 数组/对象。常用于提交 JSON 字符串的字段。

```php
$items = input_json('items');       // '["a","b"]' → ['a', 'b']
$items = input_json('items', []);   // 解析失败返回默认值
```

### input_json_list

```php
input_json_list(...$names)
```

一次读取多个参数并逐个 `json_decode`，返回以参数名为键的数组。

```php
$arr = input_json_list('meta', 'tags');
```

### input_xml

```php
input_xml($name, $default = null)
```

读取请求参数，并解析为 XML 结构（`simplexml_load_string` 后再转数组）。常用于对接外部系统传 XML 的场景。

```php
$xml = input_xml('body');   // '<xml><a>1</a></xml>' → ['a' => '1']
```

### input_xml_list

```php
input_xml_list(...$names)
```

一次读取多个参数并逐个解析 XML，返回以参数名为键的数组。

### input_post_raw

```php
input_post_raw()
```

读取 `php://input` 的原始 POST 请求体字符串，不经过任何解析。适用于接收 JSON、XML 或文件流等原始体。

```php
$raw = input_post_raw();   // 原始字符串
$arr = json_decode($raw, true);
```

### input_file

```php
input_file($name, $default = [])
```

读取上传文件信息，返回 `$_FILES[$name]` 数组；键不存在返回 `$default`（默认 `[]`）。

```php
$file = input_file('avatar');   // ['name' => 'a.png', 'tmp_name' => '/tmp/xxx', ...]
$none = input_file('missing');  // []
```

## Cookie 读取

### cookie_safe

```php
cookie_safe(string $name, $default = null)
```

读取 Cookie 并做 HTML 实体转义，防止 XSS。

```php
$theme = cookie_safe('theme');
```

### cookie

```php
cookie(string $name, ?string $default = null): ?string
```

读取 Cookie 原始值。

```php
$session_id = cookie('session_id');
```

### cookie_list

```php
cookie_list(...$names)
```

一次读取多个 Cookie，返回以键为名的数组。

```php
$cookies = cookie_list('token', 'uid');
```

## 服务器信息

### server_safe

```php
server_safe($name, $default = null)
```

读取 `$_SERVER` 变量并做 HTML 实体转义。

```php
$agent = server_safe('HTTP_USER_AGENT');
```

### server

```php
server($name, $default = null)
```

读取 `$_SERVER` 变量原始值。

```php
$host = server('HTTP_HOST');
```

### server_list

```php
server_list(...$names)
```

一次读取多个 `$_SERVER` 变量，返回以键为名的数组。

### is_https

```php
is_https(): bool
```

判断当前请求是否为 HTTPS。返回 `true` / `false`。

```php
if (is_https()) {
    // 强制跳转 https
}
```

### is_ajax

```php
is_ajax(): bool
```

判断当前请求是否为 AJAX（通过 `HTTP_X_REQUESTED_WITH: XMLHttpRequest` 判断）。返回 `true` / `false`。

```php
if (is_ajax()) {
    return json(['ok' => true]);
}
```

### uri

```php
uri(): string
```

返回当前请求的 URI 路径（不含域名与查询串）。

```php
$path = uri();   // 例如 '/user/123'
```

### refer_uri

```php
refer_uri(): string
```

返回来源页面 URI（`HTTP_REFERER`），常用于跳回上一页。

```php
$back = refer_uri() ?? '/';
```

### uri_info

```php
uri_info(?string $name = null)
```

解析当前 URI 的各组成部分。不传参返回整个信息数组（包含 scheme、host、path、query 等）；传入 `$name` 返回指定部分。

```php
$path = uri_info('path');     // '/user/123'
$query = uri_info('query');   // 'a=1&b=2'
```

### request_method

```php
request_method()
```

返回当前请求方法大写字符串：`GET`、`POST`、`PUT`、`DELETE` 等。

```php
if (request_method() === 'POST') {
    // ...
}
```

### ip

```php
ip(): string
```

返回客户端 IP 地址。优先读取真实 IP 头（`HTTP_X_REAL_IP` / `HTTP_X_FORWARDED_FOR`），回退到 `REMOTE_ADDR`。

```php
$client_ip = ip();
```
