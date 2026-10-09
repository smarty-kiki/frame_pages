# 请求

本框架不提供对象化 Request，而是提供一组**全局函数**直接读取当前请求的各类输入。所有输入读取函数都基于原始超全局变量（`$_GET` / `$_POST` / `$_COOKIE` / `$_SERVER` / `php://input`），没有请求对象，也没有额外的解析层。

## 输入读取

### input_safe

```php
input_safe(string $name, $default = null)
```

读取请求参数并做 **HTML 实体转义**，防止 XSS。返回 `filter_input(FILTER_SANITIZE_SPECIAL_CHARS)` 处理后的值，适合直接输出到 HTML 页面。

```php
$name = input_safe('name');  // '<script>' → '&lt;script&gt;'
```

### input

```php
input(string $name, $default = null)
```

读取请求参数原始值，按 `$_POST` → `$_GET` 顺序查找。键不存在时返回 `$default`。

```php
$page = input('page', 1);          // 默认值 1
$name = input('name');             // 未传为 null
```

### input_list

```php
input_list(...$names)
```

一次读取多个请求参数，**按传入顺序返回值的数组**（不是以参数名为键）。键不存在时对应值为 `null`。

```php
list($name, $age, $gender) = input_list('name', 'age', 'gender');
// ['张三', '18', null]
```

### input_json

```php
input_json($name, $default = null)
```

把 `php://input` 的原始请求体整体 `json_decode` 后取值，用于**提交 JSON body** 的接口（首次调用时解析一次并静态缓存，`$name` 支持 `a.b` 点号路径）。解析失败或键不存在时返回 `$default`。

```php
// 请求体 {"items": ["a","b"]}
$items = input_json('items');       // ['a', 'b']
$items = input_json('items', []);   // 解析失败返回默认值
```

### input_json_list

```php
input_json_list(...$names)
```

一次从 JSON body 读取多个键，按传入顺序返回值数组。

```php
list($meta, $tags) = input_json_list('meta', 'tags');
```

### input_xml

```php
input_xml($name, $default = null)
```

把 `php://input` 的原始请求体整体解析为 XML 结构（`simplexml_load_string` 后转数组），用于**提交 XML body** 的接口（`$name` 支持 `a.b` 点号路径）。

```php
// 请求体 <xml><a>1</a></xml>
$xml = input_xml('a');   // '1'
```

### input_xml_list

```php
input_xml_list(...$names)
```

一次从 XML body 读取多个键，按传入顺序返回值数组。

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

一次读取多个 Cookie，按传入顺序返回值数组。

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

一次读取多个 `$_SERVER` 变量，按传入顺序返回值数组。

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

判断当前请求是否为 AJAX（`X-Requested-With: XMLHttpRequest`，或表单带 `VAR_AJAX_SUBMIT` 参数）。返回 `true` / `false`。

```php
if (is_ajax()) {
    return json(['ok' => true]);
}
```

### uri

```php
uri(): string
```

返回当前请求的**完整 URL**（协议 + host + 路径 + 查询串）：

```php
$url = uri();   // 例如 'https://example.com/user/123?from=list'
```

路由匹配用的是其中的路径部分，见 `uri_info('path')`。

### refer_uri

```php
refer_uri(): string
```

返回来源页面 URI（`HTTP_REFERER`），常用于跳回上一页；无 referer 时返回空字符串。

```php
$back = refer_uri();
```

### uri_info

```php
uri_info(?string $name = null)
```

解析 `uri()` 得到的完整 URL（`parse_url`，首次解析后静态缓存）。不传参返回整个信息数组（scheme、host、port、path、query 等）；传入 `$name` 返回指定部分。

```php
$path  = uri_info('path');    // '/user/123'
$query = uri_info('query');   // 'from=list'
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

返回客户端 IP 地址。按 `HTTP_CLIENT_IP` → `HTTP_X_FORWARDED_FOR` → `REMOTE_ADDR` 顺序取值，并用正则提取第一个 IPv4；都取不到时返回 `'unknown'`。

```php
$client_ip = ip();
```
