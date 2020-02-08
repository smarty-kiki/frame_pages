# http 入口

提供 http 请求的响应能力

## 标准的 http 请求的响应

标准的 http 请求的响应使用 application.php，示例：  
```php
include FRAME_DIR.'/http/application.php';
```
响应 http 请求时需要配置路由来区分响应，如：  
```php
if_get('/ping', function ()
{
    return 'pong';
});
```
如果需要从 URL 中捕获一个数据，可以按这样来写：  
```php
if_get('/hello/*', function ($who)
{
    return 'hello '.$who;
});
```











### 获取本次请求是否是 https
----
```php
boolean is_https()
```
##### 参数
无

##### 返回值
本次请求是否是 https 的布尔值

##### 示例
```php
$is_https = is_https();
```











### 获取当前 URI
----
```php
string uri()
```
##### 参数
无

##### 返回值
本次请求的 URI

##### 示例
```php
$uri = uri();
```












### 获取具体的 URI 信息
----
```php
mix uri_info($name = null)
```
##### 参数
- name:  
    所需要的具体 URI 信息，不传时返回所有 URI 信息，可选内容有 scheme、host、port、user、pass、path、query、fragment

##### 返回值
本次请求的 URI 信息

##### 示例
```php
$uri_info = uri_info();
$path = uri_info('path');
```














### 注册所有方法请求的响应逻辑
----
```php
void if_any($rule, closure $action)
```
##### 参数
- rule:  
    路由匹配规则

- action:  
    响应逻辑闭包

##### 返回值
无

##### 示例
```php
if_any('/', function ()
{
    return 'hello world';
});
```












### 注册 get 方法请求的响应逻辑
----
```php
void if_get($rule, closure $action)
```
##### 参数
- rule:  
    路由匹配规则

- action:  
    响应逻辑闭包

##### 返回值
无

##### 示例
```php
if_get('/', function ()
{
    return 'hello world';
});
```












### 注册 post 方法请求的响应逻辑
----
```php
void if_post($rule, closure $action)
```
##### 参数
- rule:  
    路由匹配规则

- action:  
    响应逻辑闭包

##### 返回值
无

##### 示例
```php
if_post('/', function ()
{
    return 'hello world';
});
```













### 注册 PUT 方法请求的响应逻辑
----
```php
void if_put($rule, closure $action)
```
##### 参数
- rule:  
    路由匹配规则

- action:  
    响应逻辑闭包

##### 返回值
无

##### 示例
```php
if_put('/', function ()
{
    return 'hello world';
});
```













### 注册 DELETE 方法请求的响应逻辑
----
```php
void if_delete($rule, closure $action)
```
##### 参数
- rule:  
    路由匹配规则

- action:  
    响应逻辑闭包

##### 返回值
无

##### 示例
```php
if_delete('/', function ()
{
    return 'hello world';
});
```














### 注册校验逻辑
----
```php
closure if_verify(closure $action = null)
```
##### 参数
- action:  
    在校验环节需要执行的逻辑闭包，不传时直接返回当前生效的校验逻辑闭包，在校验逻辑执行时，闭包会收到路由匹配到的 action、rule 匹配出来的参数

##### 返回值
当前生效的校验逻辑闭包

##### 示例
```php
if_verify(function ($action, $args) {

    $data = call_user_func_array($action, $args);

    header('Content-type: application/json');

    return json($data);
});
```












### 注册未命中路由的逻辑
----
```php
closure if_not_found(closure $action = null)
```
##### 参数
- action:  
    在请求未有任何路由响应时执行的逻辑闭包，不传时直接返回当前生效的逻辑闭包，在闭包被执行时，闭包会收到调用 not_found 时传入的参数

##### 返回值
当前生效的闭包

##### 示例
```php
if_not_found(function () {
    return json([
        'succ' => false,
        'msg' => '404 not found',
    ]);
});
```














### 声明未命中所有路由
----
```php
void not_found($action = null);
```
##### 参数
- action:  
    在请求未有任何路由响应时执行的逻辑闭包，不传时使用当前用 if_not_found 生效的逻辑闭包

- ...:  
    也可以在调用时传入希望传给当前已生效的逻辑闭包的参数，参数类型与数量不限

##### 返回值
当前生效的闭包

##### 示例
```php
not_found(1, 2, 3);
// 或者
not_found(function () {
    return json([
        'succ' => false,
        'msg' => '404 not found',
    ]);
});
```














### 页面重定向
----
```php
redirect($uri, $forever = false)
```
##### 参数
- uri:  
    重定向的目标 uri

- forever:  
    是否永久重定向（是否是 301 重定向）

##### 返回值
无

##### 示例
```php
redirect('/hello/world');
```














### 获取安全的输入
----
```php
mix input_safe($name, $default = null)
```
##### 参数
- name:  
    获取的输入名

- default:  
    当这个参数没有传时，默认返回的结果

##### 返回值
经过安全转义的输入结果

##### 示例
```php
$content = input_safe('content');
```














### 获取输入
----
```php
mix input($name, $default = null)
```
##### 参数
- input:  
    获取的输入名

- default:  
    当这个参数没有传时，默认返回的结果

##### 返回值
输入结果

##### 示例
```php
$name = input('name');
```













### 一次获取多个输入
----
```php
array input_list(...$names)
```
##### 参数
- ...names:  
    获取的输入名，可输入多个

##### 返回值
按 name 顺序排序的输入结果，默认值为 null

##### 示例
```php
// 变量
list($name, $age) = input_list('name', 'age');
// 数组
list(
    $arr['name'],
    $arr['age']
) = input_list('name', 'age');
// 对象
list(
    $o->name,
    $o->age
) = input_list('name', 'age');
```












### 从 post 的 json 内容中获取指定的值
----
```php
mix input_json($name, $default = null)
```
##### 参数
- name:  
    要获取的 json key，因 json 是多层、多维的，name 可以用点符号来表达多层、多维逻辑，如 data.name

- default:  
    如果没有对应的值返回的默认值

##### 返回值
目标值

##### 示例
```php
$name = input_json('data.name');
```
















### 一次从 json 内容中获取指定的值
----
```php
array input_json_list(...$names)
```
##### 参数
- ...names:  
    要获取的 json key，因 json 是多层、多维的，name 可以用点符号来表达多层、多维逻辑，如 data.name，可输入多个

##### 返回值
按 name 顺序排序的输入结果，默认值为 null

##### 示例
```php
// 变量
list($name, $age) = input_json_list('data.name', 'data.age');
```












### 从 post 的 xml 内容中获取指定的值
----
```php
mix input_xml($name, $default = null)
```
##### 参数
- name:  
    要获取的 xml key，因 xml 是多层、多维的，name 可以用点符号来表达多层、多维逻辑，如 data.name

- default:  
    如果没有对应的值返回的默认值

##### 返回值
目标值

##### 示例
```php
$name = input_xml('data.name');
```
















### 一次从 xml 内容中获取指定的值
----
```php
array input_xml_list(...$names)
```
##### 参数
- ...names:  ,
    要获取的 xml key，因 xml 是多层、多维的，name 可以用点符号来表达多层、多维逻辑，如 data.name，可输入多个

##### 返回值
按 name 顺序排序的输入结果，默认值为 null

##### 示例
```php
// 变量
list($name, $age) = input_xml_list('data.name', 'data.age');
```
















### 获取原生的 body 的内容
----
```php
mix input_post_raw()
```
##### 参数
无

##### 返回值
http 请求的 body 内容

##### 示例
```php
$content = input_post_raw();
```

















### 获取安全的 cookie
----
```php
mix cookie_safe($name, $default = null)
```
##### 参数
- name:  
    获取的 cookie 名

- default:  
    当这个 cookie 没有传时，默认返回的结果

##### 返回值
经过安全转义的 cookie 结果

##### 示例
```php
$content = cookie_safe('customer_key');
```


















### 获取 cookie
----
```php
mix cookie($name, $default = null)
```
##### 参数
- name:  
    获取的 cookie 名

- default:  
    当这个 cookie 没有传时，默认返回的结果

##### 返回值
cookie 结果

##### 示例
```php
$content = cookie('customer_key');
```
















### 一次获取多个 cookie
----
```php
array cookie_list(...$names)
```
##### 参数
- ...names:  
    获取的 cookie 名，可输入多个

##### 返回值
按 name 顺序排序的 cookie 结果，默认值为 null

##### 示例
```php
// 变量
list($name, $age) = cookie_list('name', 'age');
// 数组
list(
    $arr['name'],
    $arr['age']
) = cookie_list('name', 'age');
// 对象
list(
    $o->name,
    $o->age
) = cookie_list('name', 'age');
```

















### 获取安全的 server
----
    ```php
mix server_safe($name, $default = null)
    ```
##### 参数
- name:  
    获取的 server 名

- default:  
    当这个 server 没有传时，默认返回的结果

##### 返回值
经过安全转义的 server 结果

##### 示例
```php
$content = server_safe('CONTENT_LENGTH');
```


















### 获取 server
----
```php
mix server($name, $default = null)
```
##### 参数
- name:  
    获取的 server 名

- default:  
    当这个 server 没有传时，默认返回的结果

##### 返回值
server 结果

##### 示例
```php
$content = server('CONTENT_LENGTH');
```
















### 一次获取多个 server
----
```php
array server_list(...$names)
```
##### 参数
- ...names:  
    获取的 server 名，可输入多个

##### 返回值
按 name 顺序排序的 server 结果，默认值为 null

##### 示例
```php
// 变量
list($content_length, $content_type) = server_list('CONTENT_LENGTH', 'CONTENT_TYPE');

// 数组
list(
    $arr['content_length'],
    $arr['content_type']
) = server_list('CONTENT_LENGTH', 'CONTENT_TYPE');

// 对象
list(
    $o->content_length,
    $o->content_type
) = server_list('CONTENT_LENGTH', 'CONTENT_TYPE');
```



















### 注册模版路径
----
```php
string view_path($path = null)
```
##### 参数
- path:  
    模版所在的目录

##### 返回值
当前生效的模版所在的目录

##### 示例
```php
view_path('/var/www/xxx/view');
```

















### 注册模版编译逻辑
----
```php
closure view_compiler(closure $action = null)
```
##### 参数
- action:  
    在模版 render 时，会调用的编译逻辑闭包，调用闭包时会传入要编译的模版路径，要求返回编译后的模版路径

##### 返回值
当前生效的模版编译逻辑闭包

##### 示例
```php
view_compiler(view_compiler_generate());
```

















### 模版渲染
----
```php
string render($view, $args = [])
```
##### 参数
- view:  
    所要渲染的模版路径，相对与设置的 view_path 的路径，且不需 php 文件后缀，如 index/index

- args:  
    需要传入模版的参数，在模版中直接用数组的 key 作为变量名来使用变量

##### 返回值
渲染结果

##### 示例
```php
render('customer/detail', [
    'name' => 'kiki',
    'age'  => 20,
]);
```




















### 在模版中加载模版 (仅适用于没有使用模版引擎时)
----
```php
void include_view($view, $args = [])
```
##### 参数
- view:  
    所要渲染的模版路径，相对与设置的 view_path 的路径，且不需 php 文件后缀，如 index/index

- args:  
    需要传入模版的参数，在模版中直接用数组的 key 作为变量名来使用变量

##### 返回值
无返回结果，会直接渲染在调用处

##### 示例
```php
<?php include_view('customer/list_cell', [
    'name' => 'kiki',
    'age'  => 20,
]); ?>
```



















### 使用 http 的 etag 缓存
----
```php
void cache_with_etag($etag)
```
##### 参数
- etag:  
    作为 etag 的字符串，建议是某个用以区分数据是否变化的 md5

##### 返回值
无

##### 示例
```php
cache_with_etag(serialize($customer));
```



















### 获取请求来源 ip
----
```php
string ip()
```
##### 参数
无

##### 返回值
请求来源 ip

##### 示例
```php
$ip = ip();
```




















### 注册全局异常处理逻辑
----
```php
closure if_has_exception(closure $action = null)
```
##### 参数
- action:  
    全局异常处理闭包，在遇到未被捕获的异常时生效，闭包会被传入异常对象。可不传。

##### 返回值
当前生效的全局异常处理闭包

##### 示例
```php
if_has_exception(function ($ex) {

    log_exception($ex);

    return json([
        'succ' => false,
        'msg' => $ex->getMessage(),
    ]);
});
```




















### 框架提供的 error_handler，将程序 error 转入到全局异常响应逻辑中
----
```php
void http_err_action($error_type, $error_message, $error_file, $error_line, $error_context = null)
```
##### 参数
- error_type:  
    错误类型

- error_message:  
    错误消息

- error_file:  
    错误发生的代码文件

- error_line:  
    错误发生在代码文件的所在行

- error_context:  
    错误发生的上下文

##### 返回值
无

##### 示例
```php
set_error_handler('http_err_action', E_ALL);
```





















### 框架提供的 exception_handler，将程序 exception 转入到全局异常响应逻辑中
----
```php
void http_ex_action($ex);
```
##### 参数
- ex:  
    异常

##### 返回值
无

##### 示例
```php
set_exception_handler('http_ex_action');
```





















### 框架提供的 shutdown_handler，将程序 shutdown 转入到全局异常响应逻辑中
----
```php
void http_fatel_err_action()
```
##### 参数
无

##### 返回值
无

##### 示例
```php
register_shutdown_function('http_fatel_err_action');
```










## 分布式通讯的 http 请求和响应

TODO
