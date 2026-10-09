# 工作单元

工作单元（Unit of Work）把一次请求内的所有实体变更收集起来，**统一在请求结束前一次性持久化**，保证同一事务、同一时点提交。页面（`public/index.php`）与 API（`public/api.php`）入口的路由闭包默认被 `unit_of_work()` 包裹；`cli` / `sse` 入口不自动包裹。业务代码里没有 `save()`，也不要手动提交。

## 自动包裹

`public/index.php`、`public/api.php` 的 `if_verify(...)` 中，用 `unit_of_work()` 包裹了后续路由动作的执行：

```php
// public/index.php / public/api.php（节选）
if_verify(function ($action, $args) {
    return unit_of_work(function () use ($action, $args) {
        return call_user_func_array($action, $args);
    });
});
```

> 完整实现还包含重定向与响应格式处理，见[控制器](controller.md)。

因此路由闭包内创建/修改实体后：

```php
if_post('/user', function () {
    $user = user::create(input('name'));   // 只是标记「新建」
    $user->age = 18;                        // 标记「已修改」
    return $user;
    // 闭包结束 → unit_of_work 统一 INSERT
});
```

## 核心函数

### unit_of_work

```php
unit_of_work(Closure $action)
```

在单个工作单元中执行闭包：

1. 开始时清空本地缓存、清理钩子
2. 执行闭包并收集期间产生的全部实体变更（闭包抛异常时清空缓存后原样重抛）
3. 闭包正常结束 → 逐个实体判定变更类型：新建 → INSERT、修改 / 软删除 → UPDATE、物理删除 → DELETE；SQL 顺序即缓存条目顺序
4. 多条写入包在一个 `db_transaction` 中执行（单条则直接执行）；每条写入要求受影响行数为 1，否则抛 `UNITOFWORK_DEFAULT_ERROR`（消息 `data in unit of work is expired`）并整批回滚
5. 成功 → 调用 `if_unit_of_work_executed` 钩子；异常 → 调用 `if_unit_of_work_disturbed` 钩子后重抛

```php
$result = unit_of_work(function () {
    $order = order::create();
    $order->amount = 100;
    return $order;
});
```

> **不要嵌套调用**：内层 `unit_of_work` 在开始与结束时都会清空本地缓存，外层已收集的实体变更会随之丢失。一个请求只包一层——入口已经包好了。

### if_unit_of_work_executed

```php
if_unit_of_work_executed($action = null)
```

**成功钩子**的容器 getter / setter：注册一个在工作单元**执行完成且未抛异常**时自动调用的闭包（不要求产生了写入 SQL）。

- 传入闭包 → 注册并返回
- 传入空数组 → 重置为 `null`
- 无参调用 → 返回当前已注册的闭包（未注册返回 `null`）

框架在 `unit_of_work()` 中自动调用该闭包并清理。

```php
if_unit_of_work_executed(function () {
    log_notice('unit of work committed');
});
```

### if_unit_of_work_disturbed

```php
if_unit_of_work_disturbed($action = null)
```

**异常钩子**的容器 getter / setter：注册一个在工作单元**执行期间抛出异常**时调用的闭包（含业务闭包自身抛的异常，不限于提交阶段）。用法与 `if_unit_of_work_executed` 相同；触发时闭包收到一个参数（抛出的异常），随后框架重新抛出该异常。注意捕获范围是 PHP `Exception` 层级，`Error` 不会触发该钩子。

```php
if_unit_of_work_disturbed(function ($ex) {
    log_exception($ex);
});
```

### clean_unit_of_work_delegate

```php
clean_unit_of_work_delegate()
```

清空 `if_unit_of_work_executed` 与 `if_unit_of_work_disturbed` 两个钩子。框架在钩子触发后自动调用。

### unit_of_work_db_config_key

```php
unit_of_work_db_config_key(?string $config_key = null)
```

工作单元数据库配置键的 getter / setter。无参调用返回当前配置键（默认 `'entity'`，与 [DAO](dao.md) 的 `$db_config_key` 对齐）；传入 `$config_key` 设置并返回。

它决定**哪些实体会被持久化**：提交时只写入 DAO 配置键与该值一致的实体（`$dao->get_db_config_key() === $config_key`），不一致的**直接跳过**（既不写入也不报错）；用于跨库场景下把不同库的实体分组提交。

```php
unit_of_work_db_config_key('order_db');
```

## 乐观锁

实体写入 UPDATE 时，SQL 附带版本条件：

```sql
update `user` set `name` = ?, `version` = ?, `update_time` = ?, `delete_time` = ? where `id` = ? and `version` = ?
```

- `version` 写入实体当前值 `+ 1`（应用层算出绑定值）；`update_time` / `delete_time` 随每次 UPDATE 一并刷新
- WHERE 的 `version = :old_version` 确保只有版本未变时才更新；影响行数不为 1（版本被其他请求改过，或行已不存在）→ 抛 `UNITOFWORK_DEFAULT_ERROR`（消息 `data in unit of work is expired`），**本批变更整体回滚**（多条写入在同一事务中）
- 冲突方需重新读取最新数据再操作（重试）

因此**依赖乐观锁的业务必须先查出实体再修改**，不要跳过 `find_by_*` 直接更新：

```php
if_put('/user/*', function ($user_id) {
    $user = dao('user')->find_by_id($user_id);   // 带出当前 version
    $user->name = input('name');                  // 提交时 where version = 旧值
    return $user;
});
```

## ID 生成器

### generate_id

```php
generate_id($mark = 'idgenter')
```

基于 Redis 生成全局唯一、单调递增的 ID（ID 生成器，`orm_unitofwork.php`）。`entity::init()` 创建实体时自动调用，因此**主键不依赖 MySQL 自增**，天然支持分布式与提前获得主键。

- `$mark` 决定 Redis 键名（`{mark}_last_id`，走 `idgenter` 中间件），可在 `config/redis.php` 的 `midwares` 中配置不同的生成器实例
- 同一标记下生成的 ID 随 Redis 递增，跨请求唯一；`entity::generate_id()` 以实体类名为标记 → **每张表一套独立序列**

```php
$id = generate_id();               // '7452960075132936193'
$id = user::generate_id();         // 以实体类名为标记，表级独立序列
```

### entity:restep-last-id

**无参数**的 CLI 命令：扫描 `entity` 中间件的全部数据表（跳过迁移表），把每张表的 ID 生成器游标重置为当前表内最大 `id`——下一个生成的 ID 从 `max_id + 1` 开始；空表则删除游标。常用于导入 / 重建数据后让新 ID 不与旧数据冲突。执行时逐表打印表名与重置后的游标值：

```bash
php public/cli.php entity:restep-last-id
```

## 设计要点

- **不调用 save()**：实体修改只是标记，持久化统一由工作单元完成
- **多条写入包在一个 `db_transaction`**：提交阶段产生的多条 SQL 同进同退，单条则直接执行
- **`delete()` 只是标记**：软删除不立即执行 SQL，提交时由工作单元生成 UPDATE 写入 `delete_time`
- **不要嵌套**：内层 `unit_of_work` 会清空本地缓存，外层已收集的变更会丢失——一个请求只在入口包一层
