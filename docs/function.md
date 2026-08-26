# 辅助函数

`frame/base_function.php` 提供了一批无依赖的纯函数辅助工具，覆盖配置、数组、字符串、HTTP 请求、日期、通用工具。它们面向「业务直接调用」，与框架其他部分正交。

## 配置

### config_dir

```php
config_dir(?string $dir = null)
```

注册 / 读取配置根目录。传入 `$dir` 时追加一个配置目录并返回全部目录数组；无参调用返回已注册的目录数组。框架在 `bootstrap.php` 中已调用 `config_dir(ROOT_DIR.'/config')`。

```php
config_dir(ROOT_DIR.'/config');
$dirs = config_dir();   // [ROOT_DIR.'/config']
```

### config

```php
config($file_name)
```

加载配置文件：在**每个配置目录**下依次读取 `config/{file}.php` 与 `config/{env()}/{file}.php`，用 `array_replace_recursive` 合并，结果静态缓存。返回配置数组。

```php
$mysql = config('mysql');              // 合并开发/生产覆盖后的完整配置
$log   = config('log');                // ['exception_path' => '/tmp/php_exception.log', ...]
```

### config_midware

```php
config_midware($file_name, $midware_name)
```

`midwares → resources` 间接寻址：取 `midwares[$midware_name]` 作为资源键，再从 `resources[$resource_key]` 取实际连接参数。I/O 组件（mysql / redis / beanstalk）通过它拿到真实连接配置：

```php
$local_mysql = config_midware('mysql', 'default');
$lock_redis  = config_midware('redis', 'lock');
```

### config_preload

```php
config_preload()
```

预加载全部配置文件（扫描配置目录及环境目录下所有 `.php`），消除首次 `config()` 调用的 IO 开销。返回预加载的配置名数组。

```php
config_preload();
```

### env

```php
env()
```

返回当前环境名，默认 `production`。读取 `$_SERVER['ENV']`，由 nginx `fastcgi_param ENV development;` 等注入切换。

```php
$env = env();   // 'development' | 'production'
```

### is_env

```php
is_env($env)
```

判断当前是否为指定环境。

```php
if (is_env('development')) {
    // 仅开发环境执行
}
```

## 数组

### array_get

```php
array_get($array, $key, $default = null)
```

按点分路径读取数组值，支持嵌套。

```php
array_get(['a' => ['b' => 1]], 'a.b');   // 1
array_get($arr, 'a.b.c', '默认');          // 不存在时返回默认值
```

### array_set

```php
array_set($array, $key, $value)
```

按点分路径设置数组值，自动创建中间层级。**返回新数组**（不修改原数组）；`$key` 为 `null` 时整体替换数组。

```php
$arr = array_set([], 'a.b', 1);   // ['a' => ['b' => 1]]
```

### array_exists

```php
array_exists($array, $key)
```

判断点分路径是否存在。

```php
array_exists(['a' => 1], 'a');    // true
array_exists(['a' => 1], 'a.b');  // false
```

### array_forget

```php
array_forget(&$array, $keys)
```

按点分路径删除数组元素。`$keys` 支持字符串或字符串数组批量删除。

```php
$arr = ['a' => ['b' => 1, 'c' => 2]];
array_forget($arr, 'a.b');         // ['a' => ['c' => 2]]
array_forget($arr, ['a.c']);       // ['a' => []]
```

### array_divide

```php
array_divide($array)
```

把关联数组拆成两个数组：键数组 + 值数组。

```php
list($keys, $values) = array_divide(['a' => 1, 'b' => 2]);
// $keys = ['a', 'b'], $values = [1, 2]
```

### array_build

```php
array_build($array, $callback)
```

遍历数组，回调接收 `($key, $value)` 返回 `[新key, 新value]` 构建新关联数组；新 key 为 `null` 时追加为索引数组。

```php
$mapped = array_build($users, function ($key, $user) {
    return [$user['id'], $user['name']];
});
// [id => name]
```

### array_indexed

```php
array_indexed(array $array, closure $callback)
```

构建**两层分组**：回调返回 `[索引, 新key, 新value]`，结果为 `$result[索引][新key] = 新value`。

```php
$grouped = array_indexed($rows, function ($key, $row) {
    return [$row['status'], $row['id'], $row['name']];
});
// ['paid' => ['1' => '张三'], 'refund' => [...]]
```

### array_list

```php
array_list(array $array, array $keys)
```

`array_get` 的批量版：按 `$keys`（可含点号）从同一个数组中读取多个值。

```php
array_list(['a' => ['b' => 1]], ['a.b', 'c']);   // [1, null]
```

### array_transfer

```php
array_transfer(array $array, array $rules)
```

按映射规则重组数组。`$rules` 为 `[来源key => 目标key]`，来源与目标 key 均支持点号。

```php
array_transfer(['id' => 1, 'nickname' => '张三'], ['id' => 'user_id', 'nickname' => 'name']);
// ['user_id' => 1, 'name' => '张三']
```

## 字符串

以下三个截断函数按字符数（`mb_*`）截断，并带省略符。

### str_tail_cut

```php
str_tail_cut($string, $len, $suffix = '...')
```

**尾部截断**：保留开头 `$len` 个字符，过长时以 `$suffix` 结尾。

```php
str_tail_cut('php-vibe-coding-frame', 10);   // 'php-vibe-...'
```

### str_head_cut

```php
str_head_cut($string, $len, $prefix = '...')
```

**头部截断**：保留末尾 `$len` 个字符，过长时以 `$prefix` 开头。

```php
str_head_cut('php-vibe-coding-frame', 10);   // '...ing-frame'
```

### str_middle_cut

```php
str_middle_cut($string, $len, $middle = '...')
```

**中间截断**：保留首尾，中间以 `$middle` 替代。

```php
str_middle_cut('php-vibe-coding-frame', 12);   // 'php-...rame'
```

### starts_with / ends_with

```php
starts_with($haystack, $needles)
ends_with($haystack, $needles)
```

判断字符串是否以 `$needles`（支持字符串或字符串数组，任一命中即真）开头 / 结尾。

```php
starts_with('api/user', 'api/');          // true
ends_with('user_dao', ['_dao', '_service']);  // true
```

### str_finish / str_begin

```php
str_finish($value, $cap)
str_begin($value, $cap)
```

确保字符串以 `$cap` 结尾 / 开头。内部先去除末尾 / 开头重复的 `$cap` 再补齐，避免重复。

```php
str_finish('view/', '/');       // 'view/'
str_begin('/api/user', '/api/');  // '/api/user'
```

## HTTP 请求

### http

```php
http($args)
```

发起 HTTP 请求（基于 curl）。`$args` 可以是 **URL 字符串**（GET）或**配置数组**。配置数组支持：`url`、`method`（不传时：有 `data` 为 POST，无 `data` 为 GET）、`data`、`header`、`cookie`、`timeout`（默认 3）、`retry`（默认 3）、`option`（curl 选项）、`timeouted`（超时回调），以及**按 HTTP 状态码命名的回调**（如 `200 => function($res, $code) {...}`、`0 => function($res, $code, $errno)` 兜底）。返回响应体字符串或回调结果。

```php
$html = http('https://api.example.com/user?id=1');

$res = http([
    'url' => 'https://api.example.com/login',
    'method' => 'POST',
    'data' => ['name' => '张三'],
    'timeout' => 5,
    '200' => fn ($body, $code) => json_decode($body, true),   // 2xx 自动解析
]);
```

### http_json

```php
http_json($args)
```

发起 HTTP 请求并把响应体 `json_decode(..., true)` 后返回。参数同 `http()`。

```php
$data = http_json(['url' => 'https://api.example.com/user', 'data' => ['id' => 1]]);
```

### http_xml

```php
http_xml($args)
```

发起 HTTP 请求并把响应体解析为 XML 结构后返回。常用于对接第三方系统。

```php
$res = http_xml('https://api.example.com/status');
```

## 日期时间

### datetime

```php
datetime($expression = null, $format = 'Y-m-d H:i:s')
```

格式化时间。`$expression` 缺省为当前时间；传数字视为时间戳；传字符串交给 `strtotime` 解析。`$format` 为输出格式。

```php
datetime();                                     // '2026-08-26 10:30:00'
datetime('+1 day', 'Y-m-d');
datetime(1724628600, 'Y-m-d H:i');
```

### datetime_diff

```php
datetime_diff($datetime1, $datetime2, $format = '%ts')
```

计算两个日期时间字符串的差。`$format` 支持 `DateInterval::format` 的常规占位符，**额外支持总差异占位符**：`%td`（总天数）、`%th`（总小时）、`%tm`（总分钟）、`%ts`（总秒数）。

```php
datetime_diff('2026-08-01 00:00:00', '2026-08-26 12:00:00', '%td天 %th小时');
datetime_diff('10:00:00', '12:30:00', '%ts');   // 9000
```

## 通用工具

### dd

```php
dd(...$args)
```

`dump and die`：`var_dump` 所有参数并 `die`，调试专用。

```php
dd($user, $order);
```

### trace

```php
trace($message = 'exception for trace')
```

抛出并捕获一个异常，把调用栈输出到异常日志（`log_exception`），用于调试定位。

```php
trace('reached here');   // 日志中记录此处调用栈
```

### value

```php
value($value)
```

返回传入值本身；若传入的是闭包则执行并返回其结果。

```php
value('hello');                    // 'hello'
value(fn () => 'hello');           // 'hello'
```

### closure_id

```php
closure_id($closure)
```

返回闭包的唯一标识（基于反射对闭包字符串取 `md5`）。文件路径和行号变更会影响标识。

```php
$id = closure_id($closure);
```

### is_url

```php
is_url($path)
```

判断字符串是否为合法 URL。额外匹配 `#`、`//`、`mailto:`、`tel:` 等特殊协议前缀。

```php
is_url('https://php-frame.cn');   // true
is_url('#anchor');                // true
```

### unparse_url

```php
unparse_url(array $parsed)
```

把 `parse_url` 返回的数组拼回 URL 字符串。

```php
unparse_url(parse_url('https://a.com/p?x=1'));
```

### url_transfer

```php
url_transfer($url, closure $transfer_action)
```

修改 URL 的查询参数并返回新 URL。回调接收 `$url_info` 数组（`query` 已 `parse_str` 成数组便于直接修改），返回修改后的数组。

```php
url_transfer('https://a.com/p', function ($url_info) {
    $url_info['query']['page'] = 2;
    return $url_info;
});   // 'https://a.com/p?page=2'
```

### instance

```php
instance($class_name, array $args = [])
```

获取类的单例实例；`$args` 为构造参数。

```php
$obj = instance('some_class', ['a', 'b']);
```

### json

```php
json($data = [])
```

`json_encode($data, JSON_UNESCAPED_UNICODE)` 封装，返回 JSON 字符串（不转义中文）。

```php
$str = json(['name' => '张三']);   // '{"name":"张三"}'
```

### option_define

```php
option_define(...$options)
```

按顺序把选项定义为值为 `2^0, 2^1, 2^2…` 的常量，用于位运算组合。

```php
option_define('OPT_A', 'OPT_B', 'OPT_C');   // OPT_A=1, OPT_B=2, OPT_C=4
```

### has_option

```php
has_option($options, $define)
```

判断 `$options` 是否包含 `$define` 位（`$options` 可为多个选项的位或结果）。

```php
$flags = OPT_A | OPT_C;
has_option($flags, OPT_B);   // false
has_option($flags, OPT_C);   // true
```

### not_empty / not_null

```php
not_empty($mixed)
not_null($mixed)
```

判断值非空 / 非 null。

```php
if (not_empty($name)) { ... }
if (not_null($user)) { ... }
```

### all_empty / all_null / all_not_empty / all_not_null / has_empty / has_null

```php
all_empty(...$args)     // 全部为空
all_null(...$args)      // 全部为 null
all_not_empty(...$args) // 全部非空
all_not_null(...$args)  // 全部非 null
has_empty(...$args)     // 存在至少一个为空
has_null(...$args)      // 存在至少一个为 null
```

多值批量校验：

```php
if (all_not_null($name, $age, $gender)) {
    // 所有参数都传了
}

if (has_empty($a, $b)) {
    // 至少有一个为空
}
```
