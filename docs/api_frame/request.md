# 请求

在处理用户请求时我们需要处理用户通过 `http` 的 `path`、`header`、`query`、`cookie`、`body` 传入的参数

### path 中数据的获取

通过在路由中使用通配符来匹配请求，逻辑闭包定义的形参用来接收获取到的参数，形参按通配符顺序来接收。如：
```php
if_get('/posts/*/comments/*', function ($post_id, $comment_id)
{
    // do sth for showing post comment
});
```

### header 中数据的获取
在 `PHP` 中，`header` 被放入`server` 数据中，可以通过 `server_safe`、`server`、`server_list` 方法来获取相关数据，如:
```php
list(
    $h->content_length,
    $h->content_type
) = server_list('CONTENT_LENGTH', 'CONTENT_TYPE');
```
框架实现了一些常用场景的快捷方法：

* [获取本次请求是否是 https](frame/0.1/http?id=获取本次请求是否是-https)
* [获取当前 uri](frame/0.1/http?id=获取当前-uri)
* [获取具体的 uri 信息](frame/0.1/http?id=获取具体的-uri-信息)
* [获取请求来源 ip](frame/0.1/http?id=获取请求来源-ip)

### cookie 中数据的获取
通过 `cookie_safe`、`cookie`、`cookie_list` 方法来获取客户端传来的 cookie 数据，如:
```php
list(
    $o->name,
    $o->age
) = cookie_list('name', 'age');
```

### query 中数据的获取

在 controller 中使用 input 系列函数来获取 query 的参数。如：
```php
// 用户请求 /?name=kiki&age=20
if_get('/', function ()
{
    // 此处举例用 input_list，更多的函数查看文档的 "http 入口" 部分
    list($name, $age) = input_list('name', 'age');
});
```

### body 中数据的获取

`http body` 的获取，常用的是 `form` 表单提交格式的内容获取，如:
```php
$name = input('name');
```
如若全部拿出 `body` 收到的值来操作，可以这样:
```php
$body_content = input_post_raw();
```
如若 `body` 中的内容是特定字面量格式，可以直接用对应方法快捷获取，如:
```php
$name = input_json('data.name');
$name = input_xml('data.name');
```
