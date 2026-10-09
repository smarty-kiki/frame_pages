# 拦截器

拦截器用于在路由动作执行前后注入通用逻辑（登录校验、参数过滤、日志统计、防重复提交等）。本框架的拦截器建立在 `if_verify` 之上，**没有独立的拦截器类体系**，用「包裹路由分发的闭包」实现。

## 拦截器的签名与契约

```php
if_verify(function ($action, $args) {
    // $action：命中路由的闭包；$args：* 捕获到的参数数组
    // 返回值 = 本次请求的响应输出（非 null 才会被输出）
});
```

- **放行**：执行 action 并把结果透传回来——`return call_user_func_array($action, $args);`
- **拦截**：不调用 `$action`，直接返回自己的响应（页面入口返回字符串、API 入口返回 `json(...)` 字符串、SSE 见下文）
- **重定向**：`redirect('/login'); return null;`——不输出内容，跳转由 `if_any` 的 `trigger_redirect()` 执行
- ⚠ 不要「返回 action 本身」（如 `return $action;`）：闭包对象会被当作响应输出，触发 `Object of class Closure could not be converted to string` 致命错误

## 全局拦截器

入口已经注册了默认的 `if_verify`：页面/API 入口用它包裹 `unit_of_work()` 并处理入口对应的响应格式，SSE 入口默认不注册。而 `if_verify` **单槽注册、后注册整体替换先注册**，所以追加全局拦截器的正确姿势是取出当前实现、包一层：

```php
// interceptor/base.php
$next = if_verify();   // 取出入口注册的默认实现

if_verify(function ($action, $args) use ($next) {

    // 前置逻辑
    if (! is_login()) {
        redirect('/login');
        return null;
    }

    // 放行：透传内层（unit_of_work + 响应格式）的结果
    return $next($action, $args);
});
```

## 拦截器目录约定

拦截器放在 `interceptor/` 目录，在入口文件预留的 `// init interceptor` 位置引入（默认 `if_verify` 注册之后、业务路由加载之前）：

```php
// public/index.php
include ROOT_DIR.'/interceptor/base.php';
```

多个拦截器文件都按「取出当前实现再包裹」的写法，**最后注册的最先执行**（洋葱模型：前置逻辑后进先出、后置逻辑反序收尾）；也可以自行在一个文件里组合多个拦截逻辑。

API 入口的拦截器同理，拦截响应需要自己拼出接口信封（返回 `json(...)` 的字符串会被直接输出，不会再经过入口的 `{code, msg, data}` 包装）：

```php
// public/api.php
$next = if_verify();

if_verify(function ($action, $args) use ($next) {

    if (is_ajax() === false) {
        header('Content-type: application/json');

        return json([
            'code' => 1001,
            'msg'  => '只接受 AJAX 请求',
            'data' => [],
        ]);
    }

    return $next($action, $args);
});
```

## SSE 入口的拦截器

`public/sse.php` 默认没有注册 `if_verify`，直接注册即可；返回值的消费方式与其他入口不同——`true` 关流、Generator 逐事件流式发送、普通值一次性发送后关流（见 [SSE](sse.md)）：

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

- **异常**：拦截器内抛出的异常同样由入口注册的 `if_has_exception` 处理器兜底——业务校验用 `otherwise()` 断言，系统异常落到错误页 / 错误 JSON，详见[错误](error.md)
- **事务边界**：`unit_of_work()` 在入口 verify 的**内层**，且只收集它执行期间动过的实体统一提交；拦截器在 `$next(...)` 之外对 Entity 做的改动**不会持久化**。需要落库的写入放在 `$next` 调用链内（即控制器闭包里）

## 设计要点

- 拦截器只是闭包，遵循「简单优于灵活」：不用继承、不用注解、不用中间件管道
- `if_verify` 单槽注册：追加拦截器一律「取出当前实现 → 包裹 → 重新注册」，直接注册会顶掉入口的默认实现（`unit_of_work` 与响应格式），除非有意接管整个请求处理
- 执行顺序：包裹者在外层，最后注册的最先执行
