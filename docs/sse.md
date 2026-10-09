# SSE 流式服务

SSE（Server-Sent Events）允许服务器向浏览器**单向持续推送**数据，本框架通过 `public/sse.php` 入口提供流式服务。业务写在 `controller_sse/` 目录，用 Generator（yield）描述推送序列——每个 `yield` 发一个 SSE `data:` 事件。

## SSE 入口

- 路由由 `sse_route()` 注册，控制器文件放在 `controller_sse/`，由 `public/sse.php` 引入
- web server 对 `/sse/` 分流到 `sse.php` 并关闭缓冲、放宽超时（nginx 的 `location ^~ /sse/` 与 Caddy 的 `handle /sse/*` 两套配置，见[环境](environment.md)），保证长连接不被截断
- 开发环境使用独立 FPM pool（`pm=ondemand`、`request_terminate_timeout=0`），长流不被杀掉
- 入口编排：OPTIONS 预检直接 `204` + CORS 放行 → `trace_begin_request()`（一条流一个 trace 上下文）→ 注册 404 与异常兜底 → 引入 `controller_sse/` 下的业务文件 → 末尾 `not_found()` 触发 404

## 声明一个 SSE 路由

```php
<?php
// controller_sse/echo.php

sse_route('/echo', function ($params) {
    $text = $params['text'] ?? 'hello';
    foreach (str_split($text) as $char) {
        yield $char;   // 逐字推送
        usleep(1000000);
    }
    yield true;   // 流结束
});
```

### sse_route

```php
sse_route($path, closure $closure)
```

注册 SSE 路由：`$path` 匹配剥离 `/sse` 前缀后的请求路径（业务路由不写 `/sse`），**命中当前请求即立即分发执行并结束请求**（不做注册与遍历）。`$closure` 接收 `$params`：query string 与 JSON POST body 合并（不区分 GET / POST；body 非 JSON 时并入表单参数）。

```php
sse_route('/progress', function ($params) {
    foreach (range(1, 100) as $i) {
        yield ['percent' => $i];   // 推送 JSON 数据
        usleep(50000);
    }
    yield true;
});
```

### 分发与返回约定

路由闭包按返回值分发：

- 返回 **Generator** → 同步迭代，每个 `yield` 发一个 SSE `data:` 事件（流式主用法）
- 返回 `true`（严格 bool）→ 不发送数据，直接关闭流
- 返回其他非 `null` 值 → 一次性发送后关闭流
- 返回 `null` → 视为闭包内已自行 `sse_send` / `sse_close`，结束后补关闭

Generator 内部：

- `yield true`（严格 bool）＝ 流结束：该值不发送，其后代码**不再执行**
- `yield null` → 跳过不发；其他值 → 走 `sse_send`
- Generator 自然结束（没有 `yield true`）＝ 流结束
- 客户端断开（`connection_aborted()`）→ 停止流

### sse_send

```php
sse_send($data, $event = null)
```

发一个 SSE 事件：`$data` 是字符串时原样输出，其他类型 `json()` 编码；多行内容逐行输出为多条 `data:` 行。`$event` 指定事件名（输出 `event:` 行），客户端可用 `EventSource.addEventListener` 监听。内容 `echo` 后立即 `flush`，保证实时到达。

`$event` 用于区分同一流里的不同消息类型：

```php
sse_route('/chat', function ($params) {
    foreach (fetch_chat_lines() as $line) {
        sse_send($line, 'chat');          // 事件名 chat
        sse_send(['typing' => false]);    // 默认事件 message
    }
    yield true;
});
```

约定：`sse_send(true)`（严格 bool）＝ 流结束，关闭流、不发送数据。

### sse_close

```php
sse_close()
```

主动关闭流：置流结束标记后停止输出（FPM 模式下没有 socket 可关，脚本结束由 FPM 关闭响应，客户端收到 EOF 即流结束）。关闭后继续调用 `sse_send` 不再输出。

## 流式环境

分发时框架自动设置流式响应环境：

- 响应头：`Content-Type: text/event-stream; charset=utf-8`、`Cache-Control: no-cache`、`X-Accel-Buffering: no`（通知 nginx 关闭该响应的缓冲）、`Access-Control-Allow-Origin: *`
- `set_time_limit(0)`：长流不受 `max_execution_time` 限制
- 关闭输出缓冲与压缩、开启隐式 flush：每次 `flush` 立即到达 web server → 客户端
- 关闭错误回显（`display_errors=0`）：notice / warning 被 echo 进流会破坏 SSE 帧（错误仍写入 FPM 错误日志）

跨域预检（OPTIONS 请求）由入口直接 `204` + CORS 放行（允许 `GET, POST, OPTIONS`）。

## 拦截器与错误

- `if_verify` 可按需注册（鉴权、日志等）：分发前包装路由闭包，注册的拦截器收到 `($closure, [$params])` 并返回闭包的执行结果。与页面 / API 入口的 `if_verify` 同名但**各自独立实现**（三类入口不会同时加载）
- 路由闭包抛异常 → `if_has_exception` 注册的处理器。`public/sse.php` 默认注册：`business_exception`（或消息含 `---` 分隔符）记模块日志 `business_exception`，其余 `log_exception` 记异常日志——然后发一条 `{"error": 消息}` 事件并关闭流
- 未命中任何 `sse_route` → `not_found()`：`404` + `if_not_found` 注册的处理（未注册时 `text/plain` 的 `Not Found`）

## 客户端示例

```html
<script>
const source = new EventSource('/sse/echo?text=hello');
source.onmessage = (e) => console.log(e.data);
</script>
```
