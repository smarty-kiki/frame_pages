# 实体

实体（Entity）采用 **Active Record** 模式：一个实体类对应一张数据表，实例的属性对应表的字段，**对象即行**——修改实例，由[工作单元](unitofwork.md)在请求结束时统一持久化；查询能力由 [DAO](dao.md) 提供。实体继承 `entity` 基类。

## 五个系统字段

每张表都必须包含以下五个系统字段（由 `migrate:make` 自动生成，见[迁移](migrate.md)）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | bigint unsigned | 主键，由全局 ID 生成器产生（不依赖自增） |
| `version` | int | 乐观锁版本号，`unit_of_work` 提交时校验 |
| `create_time` | datetime(3) | 创建时间（毫秒精度） |
| `update_time` | datetime(3) | 更新时间 |
| `delete_time` | datetime(3) | 软删除时间，非 `null` 表示已删除 |

## 声明一个实体类

```php
<?php
// domain/entity/user.php

class user extends entity
{
    public $structs = [
        'name'   => '',
        'age'    => 0,
    ];

    public static function create(string $name): user
    {
        $user = parent::init();   // 初始化系统字段并标记「新建」
        $user->name = $name;
        return $user;
    }
}
```

- `$structs` 声明业务字段与默认值，系统字段（id/version/create_time/update_time/delete_time）无需声明
- 静态工厂方法（如 `create`）内部调用 `parent::init()` 创建实例
- 可选声明 `public static $null_entity_mock_attributes = [];`，为 `null_entity` 访问属性时提供默认值

## 生命周期方法

### init

```php
protected static function init()
```

创建实体的静态入口：把 `$structs` 复制到 `attributes`、生成 `id`、`version` 置为初始值（0，使 `just_new()` 为真）、写入 `create_time` / `update_time`、`delete_time` 置 `null`，并注册到本地缓存（同时复位 `just_deleted` / `just_restored` / `just_force_deleted` 标记）。所有业务工厂方法在内部调用它。

```php
$user = user::init();
$user->name = '张三';
```

### generate_id

```php
final public static function generate_id()
```

生成该实体的全局唯一主键 ID。底层调用全局 `generate_id(get_called_class())`，以实体类名作为 ID 生成器标记（见[工作单元](unitofwork.md)）。`init()` 内部自动调用。

```php
$id = user::generate_id();
```

### just_new / just_updated

```php
final public function just_new()
final public function just_updated()
```

查询实体的持久化状态：`just_new()` 返回 `version` 是否仍为初始值 `0`（新建、尚未入库）；`just_updated()` 返回 `attributes`（内存当前值）与 `structs`（数据库快照，新实体为声明默认值）是否不一致——不一致说明有未提交变更，`unit_of_work` 据此生成 UPDATE。

```php
if ($user->just_new()) {
    // 新插入
}
```

### is_deleted / is_not_deleted

```php
final public function is_deleted()
final public function is_not_deleted()
```

判断实体是否处于软删除状态（`delete_time` 非空）。

```php
if ($user->is_not_deleted()) {
    // 正常数据
}
```

### just_deleted

```php
final public function just_deleted()
```

返回该实体是否刚刚执行了软删除（本次请求内标记）。

### just_restored

```php
final public function just_restored()
```

返回该实体是否刚刚标记了「恢复软删除」（本次请求内标记），`unit_of_work` 据此生成 UPDATE 清空 `delete_time`。

### delete

```php
public function delete()
```

**标记软删除**：置 `just_deleted` 为真（并复位 `just_restored`）、把 `delete_time` 写为当前时间。真正的落库由 `unit_of_work` 在提交时生成 UPDATE（写入 `delete_time`）。

```php
$user->delete();   // 交给 unit_of_work 自动持久化
```

### restore

```php
final public function restore()
```

**恢复软删除**（内存中 `delete_time` 一律置回 `null`），按当前状态分三种情形：

- 撤销本次请求内刚 `delete()`、尚未提交的删除 → 清除 `just_deleted` 标记，提交时**不产生 SQL**（删除本就没落库）
- 恢复一条已落库的软删除记录 → 标记 `just_restored`，`unit_of_work` 提交时生成 UPDATE 清空 `delete_time`
- 记录本就未被软删除（且没有待提交的删除）→ 无操作

已软删除的记录默认查不到，需用 `dao('user', true)`（`$with_deleted = true`，见 [DAO](dao.md)）带出来后恢复：

```php
$user = dao('user', true)->find_by_id($user_id);   // 含软删除记录
$user->restore();                                   // 提交时 UPDATE 清空 delete_time
```

### just_force_deleted

```php
final public function just_force_deleted()
```

返回该实体是否刚刚执行了物理删除标记。

### force_delete

```php
final public function force_delete()
```

**标记物理删除**：置 `just_force_deleted` 为真，`unit_of_work` 提交时生成 `DELETE FROM` 真正删除该行，不可恢复。

```php
$user->force_delete();
```

### is_null / is_not_null

```php
public function is_null()
public function is_not_null()
```

判断实体是否为 `null_entity` 空对象。正常实体 `is_null()` 永远返回 `false`，`null_entity` 返回 `true`。DAO 查询不到记录时返回 `null_entity`（而非 `null`），配合此方法可以安全地链式访问，避免 NPE。

```php
$user = dao('user')->find_by_id($id);
if ($user->is_null()) {
    return render('error/404');
}
```

### get_dao

```php
final public function get_dao()
```

获取实体对应的 DAO 实例，用于从实体出发进行关联查询。

```php
$dao = $user->get_dao();
```

## 序列化

### jsonSerialize

```php
public function jsonSerialize(): array
```

实现 `JsonSerializable` 接口：实体在 `json()`、API 入口自动包装、`echo json_encode(...)` 时序列化为数组，包含五个系统字段 + 全部业务字段。Entity 可直接 `return` 给 API 入口包装成 JSON。

```php
return $user;   // API 入口自动 json_encode
```

### serialize / unserialize

```php
public function serialize()
public function unserialize($serialized)
```

实现 `Serializable` 接口。序列化时**排除 `relationships` 关系缓存**，避免循环引用。

### __serialize / __unserialize

```php
public function __serialize(): array
public function __unserialize(array $data): void
```

PHP 7.4+ 序列化魔术方法，同样排除 `relationships`。

## 属性访问魔术方法

实体的字段与关系访问统一由魔术方法实现，读写分流清晰。

### __get

```php
public function __get($property)
```

读取属性，优先级链：

1. `get_{property}()` 方法（子类自定义访问器）
2. 已加载的关系缓存（`relationships`）
3. **懒加载关系**：首次访问关系属性时，通过 `relationship_ref` 查询并缓存
4. `attributes` 中的原始值

```php
echo $user->name;        // 业务字段
$orders = $user->orders; // 懒加载关系
```

读取未在 `$structs` 中声明的字段会触发 PHP 未定义索引警告（在入口的错误处理器下会被转成异常）。

### __set

```php
final public function __set($property, $value)
```

赋值分流：

1. 如果是**关系属性** → 调用 `relationship_ref->update()` 维护外键，再缓存到 `relationships`
2. 如果是**业务字段** → 直接写入 `attributes`，标记为脏（`just_updated()` 为真），`unit_of_work` 据此生成 UPDATE

```php
$user->name = '李四';       // 业务字段
$user->creator = $admin;    // 关系属性 → 自动维护外键
```

业务字段必须先在 `$structs` 中声明——向未声明的属性赋值会被**静默忽略**。

### __unset

```php
final public function __unset($property)
```

仅允许 unset 已加载的关系缓存，不支持删除 `attributes` 中的字段，否则抛异常。

### __isset

```php
final public function __isset($property)
```

判断字段/关系/访问器是否存在。

## 关系

关系通过**实体类上的方法**定义（方法内调用 `has_one` / `belongs_to` / `has_many` 注册关系元数据），再通过**属性访问**触发懒加载，实现「对象导航」风格的关联查询。底层由 `relationship_ref` 抽象基类（`load` / `batch_load` / `update`）驱动。给关系属性赋值时由 `update()` 维护外键：`has_one` 先把旧子实体的外键置 `0` 再指向本实体，`belongs_to` 写入本实体的外键（赋空则置 `0`），`has_many` 给新旧集合里所有子实体写入本实体 id。

**三个关系方法的签名一致**：第一个参数 `$relationship_name` 是关系名（即触发懒加载的属性名），后两个参数均可省略、按约定推导。

### has_one

```php
protected function has_one($relationship_name, ?string $entity_name = null, ?string $foreign_key = null)
```

一对一：**子实体**通过 `$foreign_key` 指向本实体。`$entity_name` 默认取关系名；`$foreign_key` 默认推导为 `{本实体名}_id`。

```php
class user extends entity
{
    public function profile()
    {
        return $this->has_one('profile', 'user_profile', 'user_id');
    }
}

$profile = $user->profile;   // 触发懒加载，目标实体
```

### belongs_to

```php
protected function belongs_to($relationship_name, ?string $entity_name = null, ?string $foreign_key = null)
```

多对一（反向一对一）：本实体的外键指向目标实体。`$entity_name` 默认取关系名；`$foreign_key` 默认推导为 `{目标实体名}_id`。

```php
class order extends entity
{
    public function user()
    {
        return $this->belongs_to('user');   // 目标 user，外键 user_id
    }
}

$user = $order->user;
```

### has_many

```php
protected function has_many($relationship_name, ?string $entity_name = null, ?string $foreign_key = null)
```

一对多：目标实体有多条记录引用本实体。`$entity_name` 默认取关系名；`$foreign_key` 默认推导为 `{本实体名}_id`。

```php
class user extends entity
{
    public function orders()
    {
        return $this->has_many('orders', 'order', 'user_id');
    }
}

$orders = $user->orders;   // [order, order, ...]
```

### `_with_deleted` 变体

每个关系定义时会**自动注册一个包含软删除记录的变体**，关系名后追加 `_with_deleted` 后缀（常量 `ENTITY_RELATIONSHIP_DELETED_SUFFIX`）：

```php
$orders = $user->orders_with_deleted;   // 含软删除订单
```

### relationship_batch_load

```php
public function relationship_batch_load($relationship_name, array $from_entities)
```

批量加载关系防止 N+1：一次把 `$from_entities` 中所有实体的 `$relationship_name` 关系加载出来（底层 `IN` 查询）。关系未定义时抛异常。

```php
$users = dao('user')->find_all();
$users[0]->relationship_batch_load('orders', $users);   // 一次加载全部订单
```

全局版 `relationship_batch_load($entities, $relationship_chain)` 支持**链式**加载（如 `'creator.orders'` 先加载 creator 再加载 orders），见[DAO](dao.md)。

## 空对象模式

### null_entity

```php
null_entity
```

查询不到记录时 DAO 返回的空对象（`id` 固定为 `0`），保证「无值」场景下调用方代码仍然安全，避免 NPE。

### null_entity::create

```php
public static function create(?string $mock_entity_name = null)
```

创建空对象。传入 `$mock_entity_name`（如 `'user'`）后，访问属性时若该实体的 `null_entity_mock_attributes` 声明了对应默认值则返回之。

### null_entity::is_null

```php
public function is_null()
```

空对象返回 `true`。

### null_entity::__call

```php
public function __call($method, $args)
```

空对象上调用任意方法都静默忽略，不报错。

### null_entity::__get

```php
public function __get($property)
```

空对象上读取任意属性返回一个新的 `null_entity`，实现**链式 null 传播**：`$post->creator->name` 中 `creator` 为空对象时继续返回空对象而非报错。

```php
$user = dao('user')->find_by_id(999);   // 不存在 → null_entity
$name = $post->creator->name;           // null_entity，不报错
if ($user->is_not_null()) {
    // 存在才处理
}
```

### null_entity::__toString

```php
public function __toString()
```

空对象转字符串返回 `'空'`。

```php
echo $user;   // '空'
```
