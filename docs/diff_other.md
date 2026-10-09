# 与 Laravel 的差异

本框架与 Laravel 走的是完全不同的两条路线：Laravel 是「全功能、约定、容器」的完整生态，本框架是「显式、轻量、纯函数」的单层 MVC。选择本框架意味着放弃 Laravel 的大部分组件，换取更低的启动开销、更直白的代码路径与对 Vibe Coding 更友好的心智模型。

## 关键差异对照

| | php-vibe-coding-frame | Laravel |
|------|------|------|
| 路由 | 闭包直接注册在 `controller/*.php` | `routes/web.php` 指向 Controller 类方法 |
| 控制器 | 闭包即控制器 | Controller 类 + 方法 |
| DI | 无，依赖显式 `include` | 服务容器自动注入 |
| ORM | 自定义 ActiveRecord + UoW | Eloquent |
| 配置 | PHP 数组 + 环境覆盖 | `.env` + `config/*.php` |
| 模板 | 自实现 Blade（输出 / 控制流 / 包含） | 完整 Blade + 组件系统 |
| 类加载 | class map（`spl_autoload_register`） | Composer PSR-4 |
| 启动方式 | Docker 一键启动 | `php artisan serve` / Sail |
| 适用场景 | 中小型项目、快速原型、API 服务 | 大型项目、全功能 Web 应用 |
| 启动开销 | 仅 include ~10 个核心文件 | 启动数百个类，注册数十个 ServiceProvider |
| 内存占用 | 低（无容器、无绑定、无注解缓存） | 较高（容器绑定、facade、事件监听器常驻） |
| 请求延迟 | 毫秒级，无需路由/配置缓存预热 | 生产环境必须靠路由缓存 + 配置缓存 + Octane 优化 |
| 类加载 | class map 直接 `include`，O(1) 查找 | Composer PSR-4，需扫描目录 / 转储 classmap |
| 部署形态 | PHP-FPM 原生友好，无需常驻进程 | FPM 下性能一般，生产常需 Octane/Swoole 加持 |

## 对应关系

Laravel 的概念在本框架中的对应实现：

| Laravel | php-vibe-coding-frame |
|------|------|
| `Route::get()` | `if_get()` |
| Controller 方法 | 路由闭包 |
| `Request` 对象 | 全局函数 `input()` / `request_method()` / `uri()` |
| `Response` 对象 | 入口约定的返回值（字符串 → HTML、数组 → JSON） |
| Eloquent Model | `entity` 基类 + `dao` 基类 |
| 事务（DB::transaction） | `unit_of_work()` |
| 中间件 | `if_verify()` 注册的拦截器闭包 |
| `.env` | `config/{env()}/{file}.php` 覆盖 |
| Composer autoload | `classmap.sh` 生成的 `autoload.php` |
| `php artisan` | `php public/cli.php` |
| Blade 布局继承（`@extends` / `@section` / `@yield`） | `@include('layout/header')` 组合 |
| `Cache` / `Redis` facade | `cache_*()` 函数族（见[缓存](cache.md)） |
| `Queue::push()` | `queue_push()` 投递 + `queue:worker` 消费（Beanstalkd / Kafka 两套，见[队列](queue.md)） |
| `php artisan migrate` | `migrate:*` 命令 + `command/migration/sql` 下的 SQL 文件（见[数据迁移](migrate.md)） |
| `Log::info()` | `log_notice()` / `log_module()`（JSON Lines，见[日志](log.md)） |
| `Cache::lock()` | `singly_run()` / `serially_run()`（见[锁](lock.md)） |
| 无直接对应（靠 Telescope / 第三方包） | 内置链路追踪 `trace_*`（W3C Trace Context，日志 / SQL / 队列 / 出站请求全链路，见[链路追踪](trace.md)） |
| 无直接对应 | 内置 SSE 流式推送（`sse_route()` + Generator，见[SSE](sse.md)） |
| 需第三方扩展 | 内置 ClickHouse 查询（`ch_*()`）与迁移（`clickhouse:*`，见[ClickHouse](clickhouse.md)） |

## 设计取舍

- **不要的组件**：ServiceProvider、Facade、事件系统、任务调度器、重量级消息系统（自带 Beanstalkd / Kafka 两套轻量队列）、验证器（用 `otherwise` 断言代替）、迁移生成器（用 SQL 文件代替）
- **换来什么**：一个请求只需 `include` 约 10 个核心文件，内存与延迟开销极低，代码路径全部可静态追踪
- **代价**：生态与第三方包很少，复杂场景（如权限、多租户、队列调度）需要自己封装，这正是**纯函数 + 静态方法**的用武之地

## 编码约定差异

```php
// Laravel：类方法 + 依赖注入
class UserController extends Controller
{
    public function show(Request $request, UserService $service)
    {
        return User::find($request->id);
    }
}
```

```php
// php-vibe-coding-frame：闭包 + 全局函数
if_get('/user/*', function ($user_id) {
    return dao('user')->find_by_id($user_id);
});
```

两种方式各有适用场景，本框架的定位是：**中小型项目、快速原型、API 服务**——在这些场景下，闭包路由与纯函数能显著降低理解成本与上线时间。
