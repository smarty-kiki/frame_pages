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

## 客户端示例

```html
<script>
const source = new EventSource('/sse/echo?text=hello');
source.onmessage = (e) => console.log(e.data);
</script>
```
