# 数据库

本框架基于 PDO 封装了一套**全局函数式**的数据库访问层，支持连接池、读写分离、事务与预处理绑定。业务代码可以直接使用 `db_*` 函数执行原生 SQL，也可通过 DAO 使用更高层的[实体](entity.md)/[DAO](dao.md)封装。

## 连接池与读写分离

`config/mysql.php` 中每个 resource 定义了 `read` / `write` / `schema` 三个库位（见[配置](config.md)），框架按 SQL 类型自动路由：

- 查询类（`db_query*`、`db_simple_query*`）→ `read` 库
- 写入类（`db_insert`、`db_update`、`db_delete`、`db_write`、`db_simple_*` 写入）→ `write` 库
- 结构类（`db_structure`，DDL，迁移使用）→ `schema` 库，不走读写分离

多个库位时随机选取一个连接。所有函数末尾的 `$config_key` 指定使用哪个 midwares 键（默认 `'default'`）。

**绑定参数约定**：SQL 中绑定参数支持 `:name` 命名占位符；**数组值的绑定会自动展开为 `IN` 子句**，所以 `where id in :ids` + `[':ids' => ['1','2']]` 也能正确生成。

## 查询

### db_query

```php
db_query($sql_template, array $binds = [], $config_key = 'default')
```

执行 SELECT 查询，返回**多行**关联数组（list of row）。

```php
$rows = db_query('select * from user where age > :age', [':age' => 18]);
```

### db_query_first

```php
db_query_first($sql_template, array $binds = [], $config_key = 'default')
```

执行 SELECT 查询，**自动追加 `limit 1`**，返回第一行关联数组；未找到返回 `false`。

```php
$row = db_query_first('select * from user where id = :id', [':id' => $id]);
```

### db_query_column

```php
db_query_column($column, $sql_template, array $binds = [], $config_key = 'default')
```

执行 SELECT 查询，提取每行的 `$column` 列，返回一维数组。

```php
$ids = db_query_column('id', 'select * from user where age > :age', [':age' => 18]);
```

### db_query_value

```php
db_query_value($value, $sql_template, array $binds = [], $config_key = 'default')
```

执行 SELECT 查询，提取**第一行**的 `$value` 列；无结果返回 `null`。

```php
$count = db_query_value('count(*)', 'select count(*) from user');
```

## 写入

### db_insert

```php
db_insert($sql_template, array $binds = [], $config_key = 'default')
```

执行 INSERT，返回 `lastInsertId()`（自增主键的插入 ID；本框架主键多用全局 ID 生成器，此时此值无意义）。

```php
db_insert('insert into user (`id`, `name`) values (:id, :name)', [':id' => '1001', ':name' => '张三']);
```

### db_update

```php
db_update($sql_template, array $binds = [], $config_key = 'default')
```

执行 UPDATE，返回受影响行数。WHERE 条件需自行写全（可借助 `db_simple_where_sql` 拼接）。

```php
db_update('update user set `name` = :name where `id` = :id', [':name' => '李四', ':id' => $id]);
```

### db_delete

```php
db_delete($sql_template, array $binds = [], $config_key = 'default')
```

执行 DELETE，返回受影响行数。

```php
db_delete('delete from user where `id` = :id', [':id' => $id]);
```

### db_write

```php
db_write($sql_template, array $binds = [], $config_key = 'default')
```

执行任意写 SQL（INSERT / UPDATE / DELETE），返回受影响行数。

### db_structure

```php
db_structure($sql, $config_key = 'default')
```

执行结构类 SQL（DDL：create / alter / drop 等），走 `schema` 库位，不做读写分离。迁移命令内部使用。

```php
db_structure('create table `t` (`id` bigint not null)');
```

### db_force_type_write

```php
db_force_type_write(?bool $bool = null)
```

获取 / 设置「强制走写库」开关。无参调用返回当前是否强制写库；传入 `true` / `false` 设置。事务期间框架会自动强制走写库（先写后读一致）。

```php
db_force_type_write(true);   // 强制后续查询走 write
```

## 事务

### db_transaction

```php
db_transaction(closure $action, $config_key = 'default')
```

在事务中执行闭包：闭包内所有写操作同进同退，事务期间自动强制走写库。闭包正常结束自动 `commit`；抛出异常自动 `rollback` 并重新抛出；`finally` 恢复原状态。

```php
db_transaction(function () use ($order) {
    db_insert('insert into order_log (`order_id`, `status`) values (:oid, :st)', [':oid' => $order->id, ':st' => 'created']);
    $order->status = 'paid';
});
```

## 关闭连接

### db_close

```php
db_close()
```

关闭全部 PDO 连接池，释放连接。通常无需调用（请求结束自动释放）。

```php
db_close();
```

## simple 系列

`db_simple_*` 系列简化了「单表 + 简单条件」的常用操作。条件统一用 `$wheres` 数组表示，由 `db_simple_where_sql` 拼装。

### db_simple_where_sql

```php
db_simple_where_sql(array $wheres)
```

把条件数组拼成 WHERE 片段，返回 `[where_clause, binds]` 数组。**值类型决定 SQL 逻辑**：

| `$wheres` 值 | 生成的逻辑 |
|------|------|
| 数组 `['paid', 'refund']` | `IN (...)` |
| `null` | `IS NULL` |
| 字符串 / 数字 `'张三'` | `=` |

条件键（列名）后加空格与 `not` 可反转：`'age not' => [1,2]` → `NOT IN`，`'delete_time not' => null` → `IS NOT NULL`。

```php
list($where, $binds) = db_simple_where_sql([
    'age'          => 18,
    'status'       => ['paid', 'refund'],
    'delete_time'  => null,          // 默认过滤软删除
    'name not'     => 'admin',
]);
// $where = '`age` = :w0age and `status` in :w1status and `delete_time` is null and `name` not in :w3name'
```

### db_simple_insert

```php
db_simple_insert($table, array $data, $config_key = 'default')
```

单行插入，返回 `lastInsertId()`。

```php
db_simple_insert('user', ['id' => '1001', 'name' => '张三']);
```

### db_simple_multi_insert

```php
db_simple_multi_insert($table, array $datas, $config_key = 'default')
```

多行插入：自动合并列名生成单条 INSERT 多值语句。`$datas` 为行数组。

```php
db_simple_multi_insert('user', [
    ['id' => '1', 'name' => '张三'],
    ['id' => '2', 'name' => '李四'],
]);
```

### db_simple_update

```php
db_simple_update($table, array $wheres, array $data, $config_key = 'default')
```

按条件数组更新。

```php
db_simple_update('user', ['id' => '1'], ['name' => '王五']);
```

### db_simple_multi_update

```php
db_simple_multi_update($table, array $datas, $where_column = 'id', $config_key = 'default')
```

批量更新多行：使用 `CASE WHEN` 在**一条 SQL** 中更新不同行的不同值，`$where_column` 指定行定位列。

```php
db_simple_multi_update('user', [
    ['id' => '1', 'name' => '张三'],
    ['id' => '2', 'name' => '李四'],
], 'id');
```

### db_simple_delete

```php
db_simple_delete($table, array $wheres, $config_key = 'default')
```

按条件数组删除。

```php
db_simple_delete('user', ['age' => 0]);
```

### db_simple_query

```php
db_simple_query($table, array $wheres = [], $option_sql = 'order by id', $config_key = 'default')
```

按条件数组查询多行。`$option_sql` 可追加 `order by` / `limit` 等片段。

```php
$rows = db_simple_query('user', ['age' => 18]);
$rows = db_simple_query('user', [], 'order by create_time desc limit 10');
```

### db_simple_query_first

```php
db_simple_query_first($table, array $wheres, $option_sql = '', $config_key = 'default')
```

按条件数组查询第一行。

### db_simple_query_column

```php
db_simple_query_column($table, $column, array $wheres = [], $option_sql = '', $config_key = 'default')
```

按条件数组查询指定列的值列表。

### db_simple_query_indexed

```php
db_simple_query_indexed($table, $indexed, array $wheres = [], $option_sql = 'order by id', $config_key = 'default')
```

按条件数组查询，结果以 `$indexed` 列的值作为返回数组的 key。

```php
$by_id = db_simple_query_indexed('user', 'id', []);
// ['1' => [...], '2' => [...]]
```

### db_simple_query_value

```php
db_simple_query_value($table, $value, array $wheres, $option_sql = '', $config_key = 'default')
```

按条件数组查询单列单值。

```php
$count = db_simple_query_value('user', 'count(*)', ['age' => 18]);
```
