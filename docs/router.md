# 路由

本框架的路由即闭包：**路由规则与控制器动作在同一条声明中绑定**，规则用字符串匹配当前请求 `uri` 与 `request method`，命中则执行闭包。

## 路由规则

- 规则字符串与当前 `uri` 完全相等即命中，例如 `/user`
- 规则中含 `*` 为通配符，匹配任意个任意字符，例如 `/api/order/*` 命中 `/api/order/123`
- `*` 位置捕获的参数按顺序传给闭包，例如规则 `/user/*` 命中 `/user/123` 时闭包收到 `$user_id = '123'`

## 方法路由

### if_any

```php
if_any(string $rule, closure $action)
```

当 `uri` 与 `$rule` 匹配时执行 `$action` 闭包，**不限制请求方法**。返回值直接传给框架统一处理（页面入口返回字符串、API 入口包装成 JSON）。

```php
if_any('/any', function () {
    return '匹配任意方法';
});
```

### if_get

```php
if_get(string $rule, closure $action)
```

仅当请求方法为 `GET` 且 `uri` 与 `$rule` 匹配时执行 `$action`。这是最常用的页面/查询路由。

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

仅当请求方法为 `POST` 且 `uri` 与 `$rule` 匹配时执行 `$action`。通常用于新增/提交。

```php
if_post('/user', function () {
    $user = user::create(input('name'));
    return json(['id' => $user->id]);
});
```

### if_put

```php
if_put(string $rule, closure $action)
```

仅当请求方法为 `PUT` 且 `uri` 与 `$rule` 匹配时执行 `$action`。通常用于更新。

```php
if_put('/user/*', function ($user_id) {
    $user = dao('user')->find_by_id($user_id);
    $user->name = input('name');
    return $user;  // unit_of_work 自动持久化
});
```

### if_delete

```php
if_delete(string $rule, closure $action)
```

仅当请求方法为 `DELETE` 且 `uri` 与 `$rule` 匹配时执行 `$action`。通常用于删除。

```php
if_delete('/user/*', function ($user_id) {
    $user = dao('user')->find_by_id($user_id);
    $user->delete();
    return json(['deleted' => $user->id]);
});
```

## 全局钩子

### if_verify

```php
if_verify(?closure $action = null): ?closure
```

注册一个**通用动作**，在所有具体路由声明**之前**调用。`$action` 闭包接收 `unit_of_work` 包装后的「执行后续路由动作」的闭包作为参数：

```php
if_verify(function (closure $run) {
    // 全局逻辑：登录校验、参数过滤、统计等
    if (!is_login()) {
        redirect('/login');
        return null;
    }
    return $run();   // 继续执行后续匹配到的路由
});
```

- 在 `unit_of_work()` 包裹下执行后续动作，整个请求内的 Entity 修改统一持久化
- 可用于实现全局拦截器，详见[拦截器](interceptor.md)

### if_not_found

```php
if_not_found(?closure $action = null): ?closure
```

注册未命中任何路由时的兜底动作。`$action` 闭包可接收一个「404 动作」参数，调用后返回 404 响应：

```php
// public/index.php
if_not_found(function (closure $action) {
    return render('error/404', ['title' => '页面不存在']);
});
```

若未传入 `$action`，则采用框架默认 404 行为。

### not_found

```php
not_found(?closure $action = null)
```

主动触发 404 动作。在所有路由声明完之后调用，让「未匹配」最终落到 404：

```php
// public/index.php 末尾
not_found();
```

若传入了 `$action`，则自定义该次 404 的处理。

## 匹配信息

### route

```php
route(string $rule): array
```

解析当前 `uri` 是否匹配规则 `$rule`，返回捕获信息。匹配成功返回包含捕获参数与原始规则信息的数组；失败返回空数组。

```php
$match = route('/user/*');
if ($match) {
    print_r($match);  // ['rule' => '/user/*', 'captures' => ['123'], ...]
}
```

### matched_rule

```php
matched_rule(?string $rule = null): ?string
```

获取/设置当前请求匹配到的规则字符串。无参调用返回上一次命中的路由规则；传入 `$rule` 则显式设置。

```php
$current = matched_rule();   // 例如 '/user/123'
```

## flush_action

```php
flush_action(closure $action, array $args = [], ?closure $verify = null)
```

立即执行一个动作闭包，可选带参和带 verify。框架内部用它在校验通过后执行匹配到的路由动作：

```php
flush_action(function ($id) {
    return "id = {$id}";
}, ['123']);
```

## 重定向

重定向采用**两段式**设计：`redirect()` 只记录重定向目标，真正的跳转由 `trigger_redirect()` 在响应阶段执行。

### redirect

```php
redirect(?string $uri = null, bool $forever = false): array
```

记录一次重定向。`$uri` 为跳转地址；`$forever = true` 时返回 301（永久重定向），否则 302（临时）。返回一个数组，通常直接 `return` 给框架：

```php
if_get('/logout', function () {
    return redirect('/login');
});
```

无参调用 `redirect()` 可读取当前是否处于重定向状态。

### has_redirect

```php
has_redirect()
```

判断当前请求是否已经记录过重定向。常配合 `if_verify` 或控制器收尾逻辑判断是否需要跳转。

```php
if_verify(function (closure $run) {
    $result = $run();
    if (has_redirect()) {
        return $result;  // 已记录重定向，交回框架触发跳转
    }
    return $result;
});
```

### trigger_redirect

```php
trigger_redirect($uri = null, $forever = false)
```

真正执行重定向：发送 `Location` 头（`forever` 为 `true` 时附带 301 状态码）并 `exit`。框架在 `unit_of_work()` 提交后检测到 `has_redirect()` 时自动调用。

```php
trigger_redirect('/login', true);  // 立即 301 跳转
```
