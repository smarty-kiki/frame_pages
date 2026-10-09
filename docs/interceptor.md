# 拦截器

拦截器用于在路由动作执行前后注入通用逻辑（登录校验、参数过滤、日志统计、防重复提交等）。本框架没有独立的拦截器类体系，拦截逻辑就是**普通函数**：全局拦截写成函数放 `interceptor/`、由入口唯一的 `if_verify` 闭包调用；局部拦截在路由闭包内显式调用。

## 全局拦截器

`if_verify` **只允许注册一次**：入口（`public/index.php` / `public/api.php`）已经用它把路由闭包包进 `unit_of_work` 与响应处理，重复注册会抛 `IF_VERIFY_ALREADY_REGISTERED` 直接报错（不会静默顶掉入口的注册）。所以全局拦截不自行注册 `if_verify`，而是写成校验函数，由入口已注册的闭包调用：

```php
// interceptor/base.php —— 校验函数：不通过时登记 redirect 并返回 false
function verify_global()
{
    if (get_current_user()->is_null()) {
        redirect('/login');
        return false;
    }
    return true;
}
```

```php
// public/index.php 的 if_verify 闭包（唯一注册）——拦截调用加在这里
if (! verify_global()) {
    return null;   // 已登记 redirect：不输出响应体，随后自动 302
}
```

校验函数的返回值约定：

- **放行**：返回 `true`，流程继续
- **跳转拦截**：`redirect('/login')` 登记跳转后返回 `false`，调用方 `return null` 不输出响应体，跳转由 `if_any` 的 `trigger_redirect()` 执行 302
- **响应拦截**：调用方拿到 `false` 时也可以直接返回自己的响应（页面入口返回字符串、API 入口返回 `json(...)` 字符串、SSE 见下文）

**入口闭包的契约**（入口已写好，一般只需添加拦截调用）：在路由匹配之后、路由动作执行之前调用（未命中路由的请求不经过它），接收命中路由的闭包 `$action` 与 `*` 捕获的参数数组 `$args`；闭包的**返回值即本次请求的响应输出**（非 `null` 时打印并 `flush()`），因此闭包内必须自行调用 `$action` 并把结果返回。

> ⚠ 不要把闭包本身当返回值（如 `return $action;`）：闭包对象会被当作响应输出，触发 `Object of class Closure could not be converted to string` 致命错误。

## 拦截器目录约定

拦截器放在 `interceptor/` 目录，入口已定义 `INTERCEPTOR_DIR` 常量并在 `// init interceptor` 位置 `include`（默认在 `if_verify` 注册之后、业务路由加载之前）；加载后函数即可被入口闭包调用：

```php
// public/index.php
define('INTERCEPTOR_DIR', ROOT_DIR.'/interceptor');
include INTERCEPTOR_DIR.'/base.php';
```

按功能模块拆分文件，每个文件只放纯函数定义：通用/全局拦截放 `base.php`，按模块命名 `auth.php`、`ratelimit.php`、`cors.php` 等；多个校验函数的执行顺序 = 入口闭包内的调用顺序，一览无余。拦截函数保持轻量，复杂逻辑下沉到 `domain/` 或 `util/`。

API 入口同理：API 拦截器与页面拦截器通常不同（API 鉴权、限流等），拆成独立文件、在 `public/api.php` 的闭包内调用；拦截响应需自行准备响应头并拼出接口信封（返回的 `json(...)` 字符串会被入口直接输出，不会再经过 `{code, msg, data}` 包装）：

```php
// interceptor/api_auth.php
function verify_api_token()
{
    if (! api_token_ok()) {
        header('Content-type: application/json');
        return false;
    }
    return true;
}
```

```php
// public/api.php 的 if_verify 闭包（唯一注册）
if (! verify_api_token()) {
    return json(['code' => 1001, 'msg' => 'token 无效', 'data' => []]);
}
```

## SSE 入口的拦截器

`public/sse.php` 默认没有注册 `if_verify`，按需直接注册即可；返回值的消费方式与其他入口不同——`true` 关流、Generator 逐事件流式发送、普通值一次性发送后关流（见 [SSE](sse.md)）：

```php
// public/sse.php 的 // init interceptor 位置
if_verify(function ($action, $args) {

    if (! sse_token_ok()) {
        return ['error' => 'unauthorized'];   // 普通返回值：一次性发送后关流
    }

    return call_user_func_array($action, $args);   // 放行：返回 Generator 即流式迭代
});
```

## 局部拦截器

不需要全局生效时，直接在具体路由闭包内显式调用拦截逻辑，最直接也最常用：

```php
if_post('/api/order', function () {
    if (! verify_token()) {
        return ['code' => 1001, 'msg' => 'token 无效'];
    }
    // 业务逻辑
});
```

## 与错误处理、事务的关系

- **异常**：拦截函数内抛出的异常同样由入口注册的 `if_has_exception` 处理器兜底——业务校验用 `otherwise()` 断言，系统异常落到错误页 / 错误 JSON，详见[错误](error.md)
- **事务边界**：`unit_of_work()` 在入口闭包的**内层**，且只收集它执行期间动过的实体统一提交；全局拦截函数在 `unit_of_work()` 之外运行，其中对 Entity 的改动**不会持久化**。需要落库的写入放在路由闭包内（即 `unit_of_work` 执行期间）

## 设计要点

- 拦截器只是普通函数 + 一个入口闭包：不用继承、不用注解、不用中间件管道
- `if_verify` 只允许注册一次：入口已用它完成 `unit_of_work` 包裹与响应处理，重复注册抛 `IF_VERIFY_ALREADY_REGISTERED`；全局拦截一律写成函数由入口闭包调用，不要另行注册
- 执行顺序：全局拦截按入口闭包内的调用顺序执行；局部拦截在路由闭包内显式调用，读路由代码即见完整链路
