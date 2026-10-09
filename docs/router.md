# 路由

本框架的路由即闭包：**路由规则与控制器动作在同一条声明中绑定**，规则字符串匹配当前请求路径（`uri_info('path')`，不含域名与查询串），命中则执行闭包、随后 `exit`——**同一请求只会命中第一条匹配的规则**。

## 路由规则

- 规则字符串与当前请求路径**完全相等**即命中，例如 `/user` 只命中 `/user`，不命中 `/user/123`
- 规则中的 `*` 是通配符，匹配**一个路径段**（至少 1 个、不含 `/` 的字符）：`/api/order/*` 命中 `/api/order/123`，**不命中** `/api/order/123/items`（多段）或 `/api/order/`（空段）
- 每个 `*` 捕获一段，按出现顺序作为参数传给闭包，值为字符串：规则 `/user/*` 命中 `/user/123` 时，闭包收到 `$user_id = '123'`
- **命中即执行并终止**：通配规则要写在更具体的规则之后。例如 `/user/list` 必须声明在 `/user/*` 之前，否则请求 `/user/list` 会先被 `/user/*` 捕获（`$user_id = 'list'`），后面的 `/user/list` 永远轮不到

## 方法路由

方法路由（`if_get` 等）命中后：执行 `$action(...$args)`，返回值交给入口注册的 `if_verify`（页面/API 入口即 `unit_of_work()` + 响应格式）处理后输出，再做一次重定向检查和 `exit`。方法不匹配时直接跳过（`return`），继续检查后续声明。

### if_any

```php
if_any(string $rule, closure $action)
```

当路径与 `$rule` 匹配时执行 `$action` 闭包，**不限制请求方法**。

```php
if_any('/any', function () {
    return '匹配任意方法';
});
```

### if_get

```php
if_get(string $rule, closure $action)
```

仅当请求方法为 `GET` 且路径与 `$rule` 匹配时执行 `$action`。最常用的页面/查询路由。

```php
if_get('/', function () {
    return 'hello world';
});

if_get('/user/*', function ($user_id) {
    return dao('user')->find_by_id($user_id);
});
```

### if_post

```php
if_post(string $rule, closure $action)
```

仅当请求方法为 `POST` 且路径与 `$rule` 匹配时执行 `$action`。通常用于新增/提交。

```php
if_post('/api/user', function () {
    $user = user::create(input('name'));
    return $user;  // Entity 实现了 JsonSerializable → 包装成 JSON（API 入口）
});
```

### if_put

```php
if_put(string $rule, closure $action)
```

仅当请求方法为 `PUT` 且路径与 `$rule` 匹配时执行 `$action`。通常用于更新。

```php
if_put('/api/user/*', function ($user_id) {
    $user = dao('user')->find_by_id($user_id);
    $user->name = input('name');
    return $user;  // unit_of_work 自动持久化
});
```

### if_delete

```php
if_delete(string $rule, closure $action)
```

仅当请求方法为 `DELETE` 且路径与 `$rule` 匹配时执行 `$action`。通常用于删除。

```php
if_delete('/api/user/*', function ($user_id) {
    $user = dao('user')->find_by_id($user_id);
    $user->delete();
    return ['deleted' => $user->id];
});
```

## 全局钩子

### if_verify

```php
if_verify(?closure $action = null): ?closure
```

注册/获取**全局验证闭包**（路由守卫）。命中路由后、执行 action 前调用，闭包签名为 `($action, $args)`：`$action` 是命中路由的闭包，`$args` 是 `*` 捕获到的参数数组。

**闭包的返回值即本次请求的响应输出**：非 null 会被直接输出（页面/API 入口 `echo` + `flush`，SSE 入口按返回类型分发），null 则不输出。因此：

- **放行** = 执行 action 并把结果透传回来：`return call_user_func_array($action, $args);`
- **拦截** = 不调用 `$action`，返回自己的响应（如鉴权失败时 `redirect('/login'); return null;`，跳转交给 `trigger_redirect()`）
- ⚠ 不要把闭包本身当返回值（如 `return $action;`）：闭包对象会被当作响应输出，触发 `Object of class Closure could not be converted to string` 致命错误

`if_verify` **只允许注册一次**：页面与 API 入口已注册默认实现（`unit_of_work()` 包裹 + 入口对应的响应格式），重复注册会抛 `IF_VERIFY_ALREADY_REGISTERED` 直接报错（不会静默顶掉入口的注册）。全局拦截不另行注册，而是写成 `interceptor/` 里的校验函数（返回 `true` 放行 / `false` 拦截），由入口唯一的 `if_verify` 闭包调用：

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

完整说明与三类入口的示例见[拦截器](interceptor.md)。

> SSE 入口（`public/sse.php`）默认**不注册** `if_verify`，拦截逻辑按需注册；`frame/sse.php` 中的 `if_verify` 与 `frame/php_fpm.php` 的同名但各自独立实现，两个模块不会同时加载。

### if_not_found

```php
if_not_found(?closure $action = null): ?closure
```

注册未命中任何路由时的兜底动作。三个入口都已注册默认实现：页面入口渲染 `error/404`、API 入口返回 `{code: 404, msg: 'Not Found', data: []}` JSON、SSE 入口返回纯文本 `Not Found`。注册的闭包在兜底触发时通常无参调用：

```php
if_not_found(function () {
    return render('error/404');
});
```

### not_found

```php
not_found(?closure $action = null)
```

主动触发 404：先发 404 响应头，再执行兜底动作。入口在所有路由文件加载完后调用 `not_found()`，让「未匹配任何路由」最终落到 404：

```php
// public/index.php 末尾
not_found();
```

传入 `$action` 时，本次 404 直接执行该闭包（不再走注册的兜底）。

## 匹配信息

### route

```php
route(string $rule): array
```

用规则 `$rule` 匹配当前请求路径，返回 `[$matched, $args]` 二元组，配合 `list()` 使用：

```php
list($matched, $args) = route('/user/*');

if ($matched) {
    // $args 例如 ['123']
}
```

`$matched` 为 bool，`$args` 是各 `*` 依次捕获到的字符串数组（未命中为空数组）。`if_any` 的第一行就是它。

### matched_rule

```php
matched_rule(?string $rule = null): ?string
```

获取/设置当前请求命中的**规则字符串**。`if_any` 命中时自动登记，无参调用读取：

```php
$current = matched_rule();   // 例如 '/user/*'（登记的是命中的规则，不是请求路径）
```

## flush_action

```php
flush_action(closure $action, array $args = [], ?closure $verify = null)
```

立即执行动作闭包，参数与 verify 都可选。`if_any` 通过它执行命中路由：

```php
flush_action(function ($id) {
    return "id = {$id}";
}, ['123']);
```

`$verify` 不为 null 时以 `$verify($action, $args)` 调用：**verify 的返回值才是输出**——非 null 时 `echo` 并 `flush()`，null 则什么都不输出。`if_any` 传入的就是 `if_verify()` 注册的全局验证闭包。

## 重定向

重定向采用**两段式**设计：`redirect()` 只在闭包内记录目标（不发 header），等动作执行完、工作单元提交事务之后，由 `if_any` 调用 `trigger_redirect()` 真正跳转——先提交、后跳转，事务不会因为跳转而丢。

### redirect

```php
redirect(?string $uri = null, bool $forever = false): array
```

记录一次重定向。`$uri` 为跳转地址；`$forever = true` 时返回 301（永久重定向），否则 302（临时）。返回记录数组，控制器里直接 `return` 即可：

```php
if_get('/logout', function () {
    return redirect('/login');
});
```

入口注册的 verify 检测到 `has_redirect()` 后不再输出该数组，交给 `if_any` 的 `trigger_redirect()` 跳转。无参调用 `redirect()` 返回当前记录（未记录时为空数组）。

### has_redirect

```php
has_redirect(): bool
```

判断当前请求是否已记录重定向。入口 verify 在工作单元结束后用它决定是否跳过响应输出：

```php
$data = call_user_func_array($action, $args);

if (has_redirect()) {
    return null;   // 已记录跳转：不输出内容，等 trigger_redirect()
}
```

### trigger_redirect

```php
trigger_redirect($uri = null, $forever = false)
```

发送 `Location` 响应头执行跳转（`$forever = true` 时附带 301 状态码）。无参调用使用 `redirect()` 记录的目标；目标为空则什么都不做。

**只发 header、不 `exit`**：`if_any` 调用它之后自己 `exit`；在 `if_any` 执行链之外手动调用时，记得自己补 `exit`：

```php
redirect('/login');
trigger_redirect();
exit;
```
