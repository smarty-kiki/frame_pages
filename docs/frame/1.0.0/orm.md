# orm

`orm` 是提供了一个可在编程语言里使用的 “虚拟对象数据库”，[这里](https://zh.wikipedia.org/wiki/对象关系映射)有更多的说明，此处不展开讲解，使用时直接加载 `entity.php`，示例：
```php
include FRAME_DIR.'/entity.php';
```
任何技术抽象，都会对性能有一定的损失，在信息系统开发中，性能的主要瓶颈在于数据结构设计及优化、逻辑实现中的 `I/O` 复杂度，框架会以 “不引入含糊边界” 为原则来尝试给出每个逻辑模式的 “唯一答案”，以下会针对 `orm` 的入门使用及常见的模式进行分享








### 声明一个实体
声明一个实体需要同时声明 `2` 个类，一个是继承 `dao` 类的负责持久化的对象，另一个是继承 `entity` 的实体类：
```php
class customer_dao extends dao
{
    protected $table_name = 'customer'; // 实体对应的表名
    protected $db_config_key = 'default'; // 实体对应的数据库配置
}


class customer extends entity
{
    /**
     * structs 声明这个实体所具有的属性，id、version、create_time、update_time、delete_time 框架已经自动实现，无需业务实体中声明
     *
     * @var mixed
     * @access public
     */
    public $structs = [
        'name' => '',
        'age'  => '',
    ];

    /**
     * create 方法是实体的创建方法，由开发者自己实现，因为不同的实体的 create 可能基于不同的参数，所以没有定为父类的 abstract 方法
     *
     * @param mixed $name
     * @param mixed $age
     * @static
     * @access public
     * @return customer
     */
    public static function create($name, $age)
    {
        $c = parent::init(); // 必须调用父类的初始化方法来构造
        $c->name = $name;
        $c->age  = $age;

        return $c;
    }
}
```

在数据库中创建 `customer` 表：
```sql
CREATE TABLE `customer` (
    `id` bigint(20) NOT NULL,
    `version` int(11) NOT NULL,
    `create_time` datetime DEFAULT NULL,
    `update_time` datetime DEFAULT NULL,
    `delete_time` datetime DEFAULT NULL,
    `name` varchar(45) NOT NULL,
    `age` int(11) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```









### 基于 `orm` 的简单 `crud` 怎么实现
```php
// create
$customer = customer::create($name, $age);

// read
$customer = dao('customer')->find($id); // 在后续着重讲解

// update
$customer->name = 'kiki';
$customer->age  = 20;

// soft delete
$customer->delete();

// delete
$customer->force_delete();
```







### 实体父类提供的方法

```php
/**
 * is_deleted 判断是否被软删除
 *
 * @access public
 * @return boolean
 */
public function is_deleted()

/**
 * delete 软删除动作
 *
 * @access public
 * @return void
 */
public function delete()

/**
 * restore 软删除恢复
 *
 * @access public
 * @return void
 */
public function restore()

/**
 * force_delete 硬删除动作
 *
 * @access public
 * @return void
 */
public function force_delete()

/**
 * is_null 判断实体是否是 null_entity
 *
 * @access public
 * @return void
 */
public function is_null()

/**
 * is_not_null 判断实体是否不是 null_entity
 *
 * @access public
 * @return void
 */
public function is_not_null()
```

### `orm` 的关联关系

关联关系是将实体-联系数据模型中的 `3` 种一般性约束（一对一、一对多、多对多约束）加入到对从属关系的描述而形成的结果，含 `belongs_to`、`has_one`、`has_many` 三种，声明关联关系是在实体的构造方法中，如：
```php
class order extends entity
{
    public $structs = [
        'customer_id' => '', // 这里声明关联关系外键
    ];

    public function __construct()
    {
        $this->belongs_to('customer'); // 这里声明关联关系
    }

    public static function create(customer $customer)
    {
        $o = parent::init();

        $o->customer = $customer;

        return $o;
    }
}
```
使用时当做属性来使用即可，如：
```php
$customer_name = $order->customer->name;
```
关系声明的三种方法如：
```php
protected function has_one($relationship_name, $entity_name = null, $foreign_key = null)
protected function belongs_to($relationship_name, $entity_name = null, $foreign_key = null)
protected function has_many($relationship_name, $entity_name = null, $foreign_key = null)
```
##### 参数
- relationship_name:  
    关联关系名

- entity_name:  
    关联的实体类型，不传则以 `relationship_name` 作为关联的实体类型，例如，一对多关系时，关联关系名为复数，需要声明关联实体类型

- foreign_key:  
    外键名，不传则赋予默认值，`has_one/has_many` 默认值为当前实体的类型外加 `id`，如 `order_id`，`belongs_to` 默认值为关联实体的类型外加 `id`，

### 获取实体

框架的 `dao` 类中提供了一些常用的实体获取方法，如：
```php
/**
 * find 通过单个或者多个 id 获取实体，单个 id 时返回单个实体，未查到对应数据时返回 null_entity，多个 id 查询会返回以 id 为 key 的实体数组，未查到的不会在数组中
 *
 * @param mixed $id_or_ids
 * @access public
 * @return mix
 */
public function find($id_or_ids)

/**
 * find_by_condition 通过查询条件语句查询第一个实体，condition 是抛去 select 和 where 关键词的 sql_template，可以传入 order by，该方法访问控制为 protected，仅提供给 dao 做方法封装时使用，禁止外部直接使用。注意使用该方法时需要自行构造软删除条件查询语句，通过  $this->with_deleted 可获取当前实体是否开启了软删除
 *
 * @param string $condition
 * @param array $binds
 * @access protected
 * @return entity
 */
protected function find_by_condition($condition, array $binds = [])

/**
 * find_by_sql 通过查询 sql_template 来查询第一个实体，需要注意的是为了确保实体不是贫血实体，一定要确保查询出所有列。注意,使用该方法时需要自行构造软删除条件查询语句，通过  $this->with_deleted 可获取当前 dao 是否需要查询软删除实体
 *
 * @param string $sql_template
 * @param array $binds
 * @access protected
 * @return entity
 */
protected function find_by_sql($sql_template, array $binds = [])

/**
 * find_all 获取表中的全量实体，排序以 id 正序，返回的数组以 id 为 key
 *
 * @access public
 * @return array
 */
public function find_all()

/**
 * find_all_by_column 通过简单条件来获得多个实体，简单条件的使用方法见 [框架能力/数据库/简单函数]，返回的数组以 id 为 key
 *
 * @param array $columns
 * @access public
 * @return array
 */
public function find_all_by_column(array $columns = [])

/**
 * find_all_by_condition 与 find_by_condition 类似，是提供给 dao 封装方法时使用的多实体获取方法。注意，使用该方法时需要自行构造软删除条件查询语句，通过  $this->with_deleted 可获取当前 dao 是否需要查询软删除实体，返回的数组以 id 为 key
 *
 * @param string $condition
 * @param array $binds
 * @access protected
 * @return array
 */
protected function find_all_by_condition($condition, array $binds = [])

/**
 * find_all_by_sql 与 find_by_sql 类似，是提供给 dao 封装方法时使用的多实体获取方法。注意，使用该方法时需要自行构造软删除条件查询语句，通过  $this->with_deleted 可获取当前 dao 是否需要查询软删除实体
 *
 * @param string $sql_template
 * @param array $binds
 * @access protected
 * @return array
 */
protected function find_all_by_sql($sql_template, array $binds = [])
```
获取实体需要通过对应的 `dao` 类来，所以在调用以上方法时先需要拿到 `dao` 实例，框架提供了单例的方法来获取 `dao` 实例，使用时如下：
```php
$order = dao('order')->find($id);
```
### 将实体直接转为 `json`
在实现 `api` 项目时，经常需要将一个实体直接转换为 `json` 字符串，`entity` 已经实现了 `JsonSerializable` 接口，可直接传入 `json_encode` 来转换，如：
```php
json_encode($order);
```
如果是个包含实体的数组也可直接进行转换，如：
```php
json_encode($orders);
```
如果除了实体的属性外还需要添加一些字段，则可以在实体中通过声明 `json_attributes` 属性来实现，如：
```php
class customer extends entity
{
    ...

    protected $json_attributes = [
        'is_rich' => '',
        'age'      => 18,
    ];

    ...

    protected function get_is_rich()
    {
        return $this->balance >= 10000000;
    }
}
```
上述例子则会在实体 `customer` 转为的 `json` 中加入 `age` 和 `is_rich` 键值，`age` 为固定的 `18`，`is_rich` 为转换时基于 `get_is_rich` 方法计算出来的结果

### `getter` 和 `setter`
当需要在获取一个值时加工后再返回，或者获取一个不存在的属性但却需要返回内容时，在实体中实现 `get_xxx()` 即可，如：
```php
public function get_display_name()
{
    return "[ID:{$this->id}]{$this->name}";
}
```
这样便可以通过获取属性的方式来使用，如：
```php
$customer->display_name;
```
当需要在设置属性时先进行加工再赋值，或者一个赋值会同时设置多个属性时，在实体中实现 `set_xxx()` 即可，如：
```php
public function set_birthday($birthday)
{
    $birthday = datetime($birthday);
    $this->age = datetime_diff(datetime(), $birthday, '%y');
    
    return $birthday;
}
```
这样在设置属性的时候，就会被调用执行，如：
```php
$customer->birthday = '1999-01-01';
```

### 懒加载和预加载
实体中关联的其他实体，只有在第一次使用时才会加载，这个即是懒加载策略，`has_many` 关系会在使用时全部加载。如果要获取多级的关联，可以一直通过 `->` 来获取，但如果中间有 `has_many` 关系，需要用到 `foreach` 时，就会产生与数据量相关的 `sql` 条数，会影响到执行性能，如：
```php
$school = dao('school')->find(1); // 此处 1 条 select 语句查询 school
foreach ($school->grades as $grade) { // 此处 1 条 select 语句查询 grade，假设查出了 6 个 grade
    foreach ($grade->teachers as $teacher) { // 此处会有 6 条 select 查询每个 grade 的 teacher
        echo $teacher->name;
    }
}
```
上述逻辑会产生 `8` 条 `sql`，这会影响到执行性能，如果在遍历前使用预加载，则会合并部分 `sql`，提前准备好对象关系，如：
```php
$school = dao('school')->find(1); // 此处 1 条 select 语句查询 school
relationship_batch_load($school, 'grades.teachers'); // 此处 2 条 select 语句，分别查询 grade 和 teacher
foreach ($school->grades as $grade) { // 此处没有 sql 执行
    foreach ($grade->teachers as $teacher) { // 此处没有 sql 执行
        echo $teacher->name;
    }
}
```
上述逻辑会产生 `3` 条 `sql`，对于面向对象编程，预加载会在代码的可读性和执行性能中找到一个良好的平衡点。