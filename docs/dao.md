# DAO

DAO（数据访问对象）封装实体的所有数据库操作：查询、写入、分页、计数。本框架的 DAO 继承 `dao` 基类，**只需要声明表名与数据库配置键**，通用方法全部由基类提供。

## 声明一个 DAO

```php
<?php
// domain/dao/user.php

class user_dao extends dao
{
    protected $table_name = 'user';       // 对应数据表名
    protected $db_config_key = 'entity';  // 默认 'entity'（与工作单元同一连接）；跨库 DAO 覆盖它
}
```

**DAO 类名约定**：`{entity 名}_dao`，如实体 `user` → `user_dao`。`$db_config_key` 默认 `entity`，与工作单元默认配置键（`unit_of_work_db_config_key()`）一致，保证实体被工作单元自动收集提交；对应 `config/mysql.php` 的 midwares 键。

## dao()

```php
dao($class_name, $with_deleted = false)
```

获取 DAO 实例的工厂函数。`$class_name` 为实体类名（内部映射到 `{实体名}_dao`，如 `'user'` → `user_dao`）；`$with_deleted = true` 时查询包含软删除记录。DAO 实例按类名单例化（`instance()` 容器），同一次请求内重复获取复用同一实例——`$with_deleted` / `set_with_deleted()` 都作用在这个共享实例上。

```php
$user_dao = dao('user');
$all      = dao('user', true)->find_all();   // 含软删除
```

也可在 DAO 实例上动态开启：

### set_with_deleted

```php
public function set_with_deleted($with_deleted)
```

切换当前 DAO 实例是否查询软删除记录。

```php
dao('user')->set_with_deleted(true);
$all = dao('user')->find_all();
```

## 查询单条

### find_by_id

```php
find_by_id($id)
```

按主键 ID 查询，返回实体；`$id` 为空或不存在返回 `null_entity`。默认过滤软删除，命中后写入本地缓存。

```php
$user = dao('user')->find_by_id('123');
if ($user->is_null()) {
    return render('error/404');
}
```

### find_by_column

```php
find_by_column(array $columns)
```

按条件数组查询单条。`$columns` 为 `[字段 => 值]`（值类型规则见 `db_simple_where_sql`）；未开启 `with_deleted` 时自动追加 `delete_time = null` 过滤。返回实体或 `null_entity`。

```php
$user = dao('user')->find_by_column(['name' => '张三']);
```

### find_by_condition

```php
protected function find_by_condition($condition, array $binds = [])
```

按**原生 WHERE SQL 片段**查询单条（`$condition` 为条件字符串，不含 `where` 关键字），`$binds` 为绑定参数。自动注入软删除过滤（未开启 `with_deleted` 时在条件前拼 `delete_time is null and`），无需手写。子类可继承使用。

```php
class user_dao extends dao
{
    public function find_active_by_name($name)
    {
        return $this->find_by_condition('name = :name and status = :st', [
            ':name' => $name, ':st' => 'active',
        ]);
    }
}
```

### find_by_sql

```php
protected function find_by_sql($sql_template, array $binds = [])
```

单条查询的**内部基方法**：查库并回写本地缓存，不存在返回 `null_entity`。子类自定义查询时调用。

## 查询多条

### find_all_by_ids

```php
find_all_by_ids(array $ids)
```

按主键 ID 数组批量查询，使用 `find_in_set` 排序保证返回顺序与 `$ids` 输入一致；返回数组**以实体 id 为键**。

```php
$users = dao('user')->find_all_by_ids(['1', '2', '3']);
// ['1' => user, '2' => user, '3' => user]
```

### find_all

```php
find_all()
```

查询全部记录（不含软删除），按 `id asc` 排序。返回实体数组（key 为实体 id）。

```php
$users = dao('user')->find_all();
```

### find_all_order_by_id_desc

```php
find_all_order_by_id_desc()
```

按 `id desc` 查询全部记录，最新插入的在前面。

```php
$users = dao('user')->find_all_order_by_id_desc();
```

### find_all_by_column

```php
find_all_by_column(array $columns)
```

按条件数组查询多条，按 `id asc` 排序；`$columns` 为空时等价 `find_all()`。

```php
$users = dao('user')->find_all_by_column(['age' => 18]);
```

### find_all_by_condition

```php
protected function find_all_by_condition($condition, array $binds = [])
```

按原生 WHERE SQL 片段查询多条，自动注入软删除过滤（同上）。

### find_all_by_sql

```php
protected function find_all_by_sql($sql_template, array $binds = [])
```

多条查询的**内部基方法**：查库并回写本地缓存，返回 key 为实体 id 的数组。

### find_all_grouped_entities_by_sql

```php
protected function find_all_grouped_entities_by_sql($group_key, $sql_template, array $binds = [])
```

执行原生 SQL 并把结果按 `$group_key` 列分组，返回 `[分组值 => 实体数组]`。适合一次查询出多个分组的场景。

```php
class order_dao extends dao
{
    public function find_grouped_by_status()
    {
        return $this->find_all_grouped_entities_by_sql(
            'status',
            'select * from `order` where status in :statuses',
            [':statuses' => ['paid', 'refund']]
        );
    }
}
```

## 分页查询

### find_all_paginated_by_current_page_and_column

```php
find_all_paginated_by_current_page_and_column($current_page, $page_size, array $columns)
```

按条件数组分页查询，返回 `list` + `pagination` 结构：

```php
$page = dao('user')->find_all_paginated_by_current_page_and_column(2, 20, ['age' => 18]);

$page['list'];        // [id => user, ...]（key 为实体 id）
$page['pagination'];  // ['page_size' => 20, 'current_page' => 2, 'count' => 99, 'pages' => 5]
```

- `count` 为总记录数（软删除已剔除），`pages` 为总页数（`ceil(count / page_size)`）；`count` 为 0 时直接返回空 `list` 与计数全 0 的结构
- 偏移量为 `page_size * (current_page - 1)`；`list` 侧与 count 侧一致地注入软删除过滤，保证页数与数据对得上

### find_all_paginated_by_current_page_and_condition

```php
find_all_paginated_by_current_page_and_condition($current_page, $page_size, $condition, array $binds = [])
```

按原生 WHERE SQL 片段分页查询，返回结构同上。条件片段会被括号包裹后拼接（防止 `or` 条件破坏软删除过滤的边界）。

```php
$page = dao('user')->find_all_paginated_by_current_page_and_condition(1, 10, 'age > :age', [':age' => 0]);
```

## 计数

### count

```php
count()
```

统计全部记录数（不含软删除）。

```php
$total = dao('user')->count();
```

### count_by_condition

```php
protected function count_by_condition($condition, array $binds = [])
```

按原生 WHERE SQL 片段统计记录数，自动注入软删除过滤（同上）。

## 数据库配置

### get_db_config_key

```php
final public function get_db_config_key()
```

返回 DAO 使用的数据库配置键（`$db_config_key`）。

## SQL 转储

以下三个方法生成实体写入的 SQL 模板与绑定参数（返回 `['sql_template' => ..., 'binds' => ...]`），**不执行**，由 `unit_of_work` 在提交阶段统一执行：

### dump_insert_sql

```php
final public function dump_insert_sql($entity)
```

生成 INSERT SQL：业务字段 + 五个系统字段（`version` 入库为初始值 `+1`，即新建实体落库 `version = 1`）。

```php
$sql = dao('user')->dump_insert_sql($user);
```

### dump_update_sql

```php
final public function dump_update_sql($entity)
```

生成 UPDATE SQL：set 全部脏字段 + `version`（当前值 `+1`）+ 刷新 `update_time`、`delete_time`，WHERE 带乐观锁条件 `id = :id and version = :old_version`。

### dump_delete_sql

```php
final public function dump_delete_sql($entity)
```

生成**物理删除** `DELETE FROM ... WHERE id = :id`，对应 `force_delete()`（软删除走 `dump_update_sql` 写 `delete_time`）。

## 软删除拼接

以下三个 `final protected` 方法供子类自定义查询时拼接软删除过滤，均可传 `$alias`（表别名）：

### with_deleted_and_sql

```php
final protected function with_deleted_and_sql(?string $alias = null)
```

返回一段 SQL 片段，**追加到 WHERE 之后**（AND 连接）。`$alias` 存在时列名带别名前缀。

### with_deleted_where_sql

```php
final protected function with_deleted_where_sql(?string $alias = null)
```

返回整段 WHERE 子句（含 `where` 关键字）。

### with_deleted_where_sql_and

```php
final protected function with_deleted_where_sql_and(?string $alias = null)
```

返回以 ` where` 开头的片段：未开启 `with_deleted` 时为 ` where delete_time is null and`，开启时为 ` where`——用于「`select ... from 表` 之后直接接 `where` + 自定义条件」的场景。

## 本地缓存（Identity Map）

DAO 查询结果会按主键缓存到本地（一次请求内生效），避免同一实体被重复查询。全局函数：

```php
local_cache_set(entity $entity)                      // 缓存实体
local_cache_get($entity_type, $id)                   // 按类型+ID 取缓存实体
local_cache_has($entity_type, $id)                   // 判断是否命中
local_cache_get_all()                                // 取全部缓存
local_cache_delete($entity_type, $id)                // 删除缓存
local_cache_delete_all()                             // 清空全部
local_cache_flush_all()                              // 取出全部缓存并清空
```

缓存键为 `{实体类名}_{id}`，本质是一个请求级的 Identity Map：同一请求内相同实体只从数据库加载一次。工作单元在动作执行前后都会清空本地缓存——缓存只在工作单元的闭包内生效（闭包内重复查询直接复用），闭包结束后统一释放。

## input_entity

```php
input_entity($entity_name, $name = null, $require = false)
```

**从请求参数加载实体**：读取参数 `$name`（默认 `{entity_name}_id`）作为主键，`dao($entity_name)->find_by_id()` 加载并返回实体；找不到则抛 `{实体名大写}_NOT_FOUND` 业务异常（如 `user` → `USER_NOT_FOUND`，错误码需在 `config/error_code.php` 定义）。`$require = true` 时参数缺失同样抛异常；否则返回 `null_entity`。

```php
$user = input_entity('user', 'user_id', true);   // 必须传 user_id 且存在
```

## relationship_batch_load

```php
relationship_batch_load($entities, $relationship_chain)
```

**链式批量加载关系**：一次性把 `$entities` 中所有实体的关系加载出来，避免 N+1。`$entities` 可以是单个实体，也可以是以实体 id 为键的实体数组（如 `find_all()` 的返回）；`$relationship_chain` 用点号分隔，从上一层的加载结果继续逐层加载。

```php
relationship_batch_load($orders, 'creator.orders');   // 先加载每个订单的 creator，再加载每个 creator 的 orders
```
