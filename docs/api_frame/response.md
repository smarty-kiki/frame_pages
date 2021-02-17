# 响应

响应通常通过 `header`、`cookie`、`body` 来返回给客户端

### `header` 的设置
`header` 的设置 `PHP` 原生提供了以下方法：

* [header](http://php.net/manual/en/function.header.php)
* [headers_list](http://php.net/manual/en/function.headers-list.php)
* [headers_sent](http://php.net/manual/en/function.headers-sent.php)
* [header_remove](http://php.net/manual/en/function.header-remove.php)
* [http_response_code](http://php.net/manual/en/function.http-response-code.php)

框架实现了一些常用场景的快捷方法：

* [声明未命中所有路由](frame/0.1/http?id=声明未命中所有路由)
* [页面重定向](frame/0.1/http?id=页面重定向)
* [使用 http 的 etag 缓存](frame/0.1/http?id=使用-http-的-etag-缓存)
