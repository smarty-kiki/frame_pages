# 请求

在处理用户请求时我们需要处理用户通过 http 的 path、header、query、body、cookie 传入的参数

### path 中数据的获取

通过在路由中使用通配符来匹配请求，逻辑闭包定义的形参用来接收获取到的参数，形参按通配符顺序来接收。如：
```php
if_get('/posts/*/comments/*', function ($post_id, $comment_id)
{
    // do sth for showing post comment
});
```

### header 中数据的获取
TODO

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

### cookie 中数据的获取

