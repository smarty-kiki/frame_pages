# SSE 流式服务

SSE（Server-Sent Events）允许服务器向浏览器**单向持续推送**数据，本框架通过 `public/sse.php` 入口提供流式服务。业务写在 `controller_sse/` 目录，用 Generator（yield）描述推送序列。

## SSE 入口

- 路由由 `sse_route()` 注册，控制器文件放在 `controller_sse/`，由 `public/sse.php` 引入
- nginx 对 `location ^~ /sse/` 分流到 `sse.php`，并关闭缓冲（`fastcgi_buffering off`）、放宽超时（`fastcgi_read_timeout 3600s`），保证长连接不被截断（见[开发环境](environment.md)）
- 开发环境使用独立 FPM pool（`pm=ondemand`、`request_terminate_timeout=0`），长流不被杀掉

## 声明一个 SSE 路由

```php
<?php
// controller_sse/echo.php

sse_route('/echo', function () {
    $text = input('text', '');
    for ($i = 0; $i < mb_strlen($text); $i++) {
        yield mb_substr($text, $i, 1);   // 逐字推送
        usleep(100000);
    }
    yield true;   // 流结束
});
```

## sse_route

```php
sse_route($path, closure $closure)
```

注册 SSE 路由。`$path` 为匹配路径（不含 `/sse/` 前缀），`$closure` 为返回 Generator 的闭包。闭包内的 `yield` 会逐个发送给客户端。

```php
sse_route('/progress', function () {
    foreach (range(1, 100) as $i) {
        yield ['percent' => $i];   // 推送 JSON 数据
        usleep(50000);
    }
    yield true;
});
```

## sse_send

```php
sse_send($data, $event = null)
```

手动推送一条消息。`$data` 会被编码为 SSE `data:` 行；`$event` 指定事件名（`event:` 行），客户端可用 `EventSource.addEventListener` 监听不同事件。

```php
sse_route('/chat', function () {
    $lines = fetch_chat_lines();
    foreach ($lines as $line) {
        sse_send($line, 'chat');          // 事件名 chat
        sse_send(['typing' => false]);    // 默认事件 message
    }
    yield true;
});
```

## sse_close

```php
sse_close()
```

主动关闭 SSE 流。

```php
sse_route('/limited', function () {
    $count = 0;
    while (true) {
        $count++;
        if ($count > 10) {
            sse_close();      // 主动断开
            yield true;
            return;
        }
        yield $count;
        usleep(100000);
    }
});
```

## 流结束约定

以下任一写法表示流结束，框架会发送结束标记并关闭连接：

- `yield true`
- `return true`
- `sse_send(true)`

```php
sse_route('/news', function () {
    yield '第一条新闻';
    yield '第二条新闻';
    yield true;          // 结束
});
```

## 内部函数

以下函数为框架内部使用，一般业务代码无需直接调用。

### _sse_dispatch

```php
_sse_dispatch($closure, array $params)
```

SSE 分发入口：解析请求路径、匹配 `sse_route` 注册的路由、设置流式响应头并执行闭包 Generator。由 `public/sse.php` 调用。

### _sse_params

```php
_sse_params()
```

获取 SSE 路由匹配到的路径参数。

### _sse_stream_env

```php
_sse_stream_env()
```

判断当前是否为 SSE 流环境（是否设置了流式响应）。

### _sse_iterate_generator

```php
_sse_iterate_generator($generator)
```

迭代 Generator 并逐个发送 `yield` 的值：每个 `yield` 发一个 SSE `data` 事件，`yield true`（严格 bool）或 Generator 自然结束即调用 `sse_close()` 结束流；客户端断开（`connection_aborted()`）时停止推进。

### _sse_request_path

```php
_sse_request_path()
```

解析当前请求在 SSE 入口内的路由路径。

### _sse_closed

```php
_sse_closed(?bool $closed = null)
```

请求内流结束标记的容器读写：无参调用返回当前是否已关闭；传 `bool` 则设置标记。`sse_close()` 内部即 `_sse_closed(true)`。客户端断开的检测走 `connection_aborted()`，见 `_sse_iterate_generator`。

```php
sse_route('/long', function () {
    while (true) {
        if (_sse_closed()) {   // 客户端断开则退出
            return;
        }
        yield tick();
        usleep(500000);
    }
});
```

## 客户端示例

```html
<script>
const source = new EventSource('/sse/echo?text=hello');
source.onmessage = (e) => console.log(e.data);
</script>
```
