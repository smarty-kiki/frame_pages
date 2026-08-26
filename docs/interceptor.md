# 拦截器

拦截器用于在路由动作执行前后注入通用逻辑（登录校验、参数过滤、日志统计、防重复提交等）。本框架的拦截器建立在 `if_verify` 之上，**没有独立的拦截器类体系**，用「注册在具体路由之前的闭包」实现。

## 全局拦截器

在 `public/index.php`（或 `public/api.php`）中、所有路由声明**之前**调用 `if_verify(...)`，注册一个对当前入口所有路由生效的全局拦截器。

```php
// public/index.php
if_verify(function (closure $run) {
    // 前置逻辑
    if (!is_login()) {
        return redirect('/login');   // 未登录直接重定向，不再执行后续路由
    }
    // 执行后续匹配到的路由动作
    $result = $run();
    // 后置逻辑
    return $result;
});
```

`$run` 闭包即「继续执行后续路由」的入口：

- 调用 `$run()` 才继续处理请求，不调用则中断
- 中断时返回任意值（如 `redirect(...)`）即作为本次请求的响应
- `$run()` 返回后可以追加后置逻辑（记录日志、统计耗时等）

## 拦截器目录约定

框架预留了 `interceptor/` 目录放置拦截器逻辑，统一在入口文件的 `if_verify` 中引入：

```php
// public/index.php
include INTERCEPTOR_DIR.'/base.php';   // 内含 if_verify(...) 调用
```

这样多个拦截器可以拆到不同文件，按 `include` 顺序决定执行顺序。

## 局部拦截器

不需要全局生效时，直接在具体路由闭包内显式调用拦截逻辑：

```php
if_post('/order', function () {
    if (!verify_token()) {
        return json(['code' => 1001, 'msg' => 'token 无效']);
    }
    // 业务逻辑
});
```

## API 入口的拦截器

`public/api.php` 同样使用 `if_verify` 注册拦截器，区别在于返回值会被包装成 JSON：

```php
// public/api.php
if_verify(function (closure $run) {
    if (is_ajax() === false) {
        return json(['code' => 1001, 'msg' => '只接受 AJAX 请求']);
    }
    return $run();
});
```

## 与错误处理的关系

`if_verify` 包裹的闭包运行在 `unit_of_work()` 中，且受 `if_has_exception` 注册的异常处理器保护——拦截器内抛出的 `business_exception` 同样会被转换成业务错误响应。详见[错误](error.md)。

## 设计要点

- 拦截器只是闭包，遵循「简单优于灵活」：不用继承、不用注解、不用中间件管道
- 全局拦截器**先注册先执行**，多个 `if_verify` 按注册顺序嵌套执行
- 拦截器内修改的 Entity 属于同一个工作单元，闭包正常结束自动持久化
