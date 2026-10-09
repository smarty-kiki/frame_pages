# 控制器

我们需要声明控制器来响应指定请求，在本框架中，**控制器与路由是同时出现的**：控制器文件统一放在按入口区分的目录下，路由闭包直接写在文件里，在对应入口文件中 `include` 引入。

## 三类入口与返回约定

框架通过 `public/` 下的三个 HTTP 入口承接不同场景，**入口决定响应格式**：

| 入口 | 控制器目录 | 返回约定 |
|------|-----------|---------|
| `public/index.php` | `controller/` | 返回字符串 → HTML 响应（`Content-Type: text/html`）；返回非字符串会抛异常，落到 `view/error/500` |
| `public/api.php` | `controller_api/` | 任意返回值（数组/Entity/标量）→ 统一包装成 `{code, msg, data}` JSON 响应 |
| `public/sse.php` | `controller_sse/` | 闭包返回 Generator，每个 `yield` 发一个流式 `data:` 事件 |

**页面与 API 入口的路由闭包默认包裹在 `unit_of_work()` 中**（由入口注册的 `if_verify` 实现），创建 Entity、修改属性后无需手动 `save()`，闭包结束时自动持久化；`cli` / `sse` 入口不自动包裹，需手动调用。

## 声明一个控制器

```php
// controller/index.php

if_get('/', function () {
    return 'hello world';
});

// controller_api/base.php

if_get('/api/error_code_maps', function () {
    return config('error_code');
});
```

然后在对应入口文件中引入：

```php
// public/index.php

include CONTROLLER_DIR.'/base.php';
include CONTROLLER_DIR.'/user.php';

// public/api.php

include API_DIR.'/base.php';
```

## 页面入口的编排顺序

`public/index.php` 的编排顺序如下（注册顺序即生效顺序）：

1. 加载 `bootstrap.php` + `frame/php_fpm.php` + `frame/view_blade.php`
2. `trace_begin_request()`：生成/透传 trace_id，并回写 `X-Request-Id` 响应头（见[链路追踪](trace.md)）
3. 定义 `CONTROLLER_DIR`、`VIEW_DIR`，设置 `view_path` 与 `view_compiler(blade_view_compiler_generate())`
4. 注册错误/异常处理：`set_error_handler('http_err_action', E_ALL)` → `set_exception_handler('http_ex_action')` → `register_shutdown_function('http_fatal_err_action')`
5. `if_not_found(...)`：未命中路由时渲染 `view/error/404`
6. `if_has_exception(...)`：渲染 `view/error/500`，传入 `code`、`message`；`business_exception` 与 `{错误码}---{描述}` 结构的断言失败记模块日志，其余 `log_exception`
7. `if_verify(...)`：闭包接收 `($action, $args)`，在 `unit_of_work()` 中执行 action——`has_redirect()` 则返回 null（由 `if_any` 统一跳转）→ 字符串则 `Content-Type: text/html` 输出 → 非字符串抛出「页面路由必须返回字符串」异常，提示迁移到 `controller_api/`
8. `include controller/base.php` 等业务路由文件（`// init interceptor` 位置用于引入[拦截器](interceptor.md)）
9. `not_found()` 触发 404

## API 入口的编排顺序

`public/api.php` 的编排顺序如下：

1. `Access-Control-Allow-Origin: *`；`OPTIONS` 预检返回 204 + `Allow-Methods: GET, POST, PUT, DELETE, OPTIONS` + `Allow-Headers: Content-Type` 后 `exit`（预检短路，不产生 trace 日志）
2. 加载 `bootstrap.php` + `frame/php_fpm.php`；`trace_begin_request()`；定义 `API_DIR`，注册错误/异常处理（同页面入口）
3. `if_not_found(...)`：返回 `{code: 404, msg: 'Not Found', data: []}` JSON
4. `if_has_exception(...)`：返回 `{code, msg, data: []}` JSON；`business_exception` 与 `{错误码}---{描述}` 结构的断言失败记模块日志，其余 `log_exception`
5. `if_verify(...)`：闭包接收 `($action, $args)`，在 `unit_of_work()` 中执行 action——`has_redirect()` 则返回 null；否则以 `{code: 0, msg: '', data: $data}` JSON 输出
6. `include controller_api/base.php` 等业务路由文件（`// init interceptor` 位置用于引入[拦截器](interceptor.md)）
7. `not_found()` 触发 404

所以 API 控制器闭包中返回任意内容，框架都会包装成如下格式返回 `json`：

```json
{
  "code": 0,  // 异常码
  "msg" : "", // 异常消息
  "data": "", // controller 返回内容的 json 结构
}
```

示例：

```php
if_get('/api/order/*', function ($order_id) {
    return dao('order')->find_by_id($order_id);
});
```

返回：

```json
{
  "code": 0,
  "msg": "",
  "data": {
    "id": 1,
    "amount": 100.00
  }
}
```

## 框架已经提供的接口

#### /health_check

框架默认提供的健康检查路由（`controller/base.php`，页面入口），返回**纯文本** `ok`，适合直接探测服务存活：

```php
if_get('/health_check', function () {
    return 'ok';
});
```

> 该文件同时定义了首页 `/`（渲染 `view/index/index` 的 hello world 页面）。

#### /api/error_code_maps

框架默认提供的获取错误码字典的接口（`controller_api/base.php`），返回：

```json
{
  "code": 0,
  "msg": "",
  "data": {
    "USER_NOT_FOUND": "user not found"
  }
}
```
