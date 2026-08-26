# 工作单元

工作单元（Unit of Work）把一次请求内的所有实体变更收集起来，**统一在请求结束前一次性持久化**，保证同一事务、同一时点提交。本框架所有路由闭包默认被 `unit_of_work()` 包裹，业务代码无需（也不应）手动调用 `save()`。

## 自动包裹

`public/index.php`、`public/api.php` 的 `if_verify(...)` 中，用 `unit_of_work()` 包裹了后续路由动作的执行：

```php
if_verify(function (closure $run) {
    return unit_of_work(function () use ($run) {
        return $run();
    });
});
```

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

1. 收集闭包执行期间所有实体（`entity`）的变更
2. 闭包正常结束 → 按**实体创建顺序**逐个持久化（INSERT / UPDATE / 软删除），全部成功后提交
3. 任意实体写入失败 → 回滚已写入部分，抛出异常交给 `if_has_exception` 渲染
4. 支持嵌套：内层工作单元收集的实体交还外层统一提交

```php
$result = unit_of_work(function () {
    $order = order::create();
    $order->amount = 100;
    return $order;
});
```

### if_unit_of_work_executed

```php
if_unit_of_work_executed($action = null)
```

**提交成功钩子**的容器 getter / setter：注册一个在工作单元**成功提交后**调用的闭包。

- 传入闭包 → 注册并返回
- 传入空数组 → 重置为 `null`
- 无参调用 → 返回当前已注册的闭包（未注册返回 `null`）

框架在 `unit_of_work()` 提交成功后自动调用该闭包并清理。

```php
if_unit_of_work_executed(function () {
    log_notice('unit of work committed');
});
```

### if_unit_of_work_disturbed

```php
if_unit_of_work_disturbed($action = null)
```

**提交失败钩子**的容器 getter / setter：注册一个在工作单元**提交抛异常时**调用的闭包。用法与 `if_unit_of_work_executed` 相同；触发时闭包收到一个参数（抛出的异常），随后框架重新抛出该异常。

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

工作单元数据库配置键的 getter / setter。无参调用返回当前配置键（默认 `'default'`）；传入 `$config_key` 设置并返回。

它决定**哪些实体会被持久化**：提交时只写入 DAO 配置键与该值一致的实体（`$dao->get_db_config_key() === $config_key`），用于跨库场景下把不同库的实体分组提交。

```php
unit_of_work_db_config_key('order_db');
```

### _unit_of_work_write

```php
_unit_of_work_write($sql_template, array $binds = [], $config_key = 'default')
```

框架内部方法：执行一条写入 SQL 并**校验影响行数恰为 1**，否则抛乐观锁异常（`UNITOFWORK_DEFAULT_ERROR`）。`unit_of_work()` 提交时对每个实体调用它，乐观锁冲突由此暴露。

## 乐观锁

实体写入 UPDATE 时，SQL 附带版本条件：

```sql
update `user` set `name` = ?, `version` = `version` + 1 where `id` = ? and `version` = ?
```

- `version` 从当前实体的 `version` 字段读取，`=` 条件确保只有版本未变时才更新
- 若提交时数据库中的 `version` 已被其他请求修改，则 UPDATE 影响 0 行 → 框架判定为并发冲突，抛出异常，本次变更整体回滚
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

- `$mark` 为 ID 生成器标记，可在 `config/redis.php` 的 `midwares` 中配置不同的生成器实例
- 同一标记下生成的 ID 随 Redis 递增，跨请求唯一

```php
$id = generate_id();               // '7452960075132936193'
$id = generate_id('order_idgenter');
```

### entity:restep-last-id

CLI 命令，重置某个 ID 生成器的起始值，常用于重建数据后让新 ID 不与旧数据冲突：

```bash
php public/cli.php entity:restep-last-id --config_key=default --mark=idgenter --step=1000000000
```

## 设计要点

- **不调用 save()**：实体修改只是标记，持久化统一由工作单元完成
- **一个请求一个事务**：闭包内所有实体写入要么全成功、要么全回滚
- **软删除同样收集**：`delete()` / `restore()` 只是标记，提交时统一落库
- 本框架没有数据库事务嵌套层，`unit_of_work` 的提交走 `db_transaction`
