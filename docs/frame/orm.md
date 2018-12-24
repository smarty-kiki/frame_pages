# ORM

ORM 是提供了一个可在编程语言里使用的 “虚拟对象数据库”，[这里](https://zh.wikipedia.org/wiki/对象关系映射)有更多的说明，此处不展开讲解，使用时直接加载 `command.php`，示例：
```php
include FRAME_DIR.'/entity.php';
```
任何技术抽象，都会对性能有一定的损失，在现代信息系统开发中，性能的主要瓶颈在于数据结构设计及优化、逻辑实现中的 I/O 复杂度，框架会以 “不引入含糊边界” 的原则来尝试给出每个逻辑模式的 “唯一答案”，以下会针对 ORM 的入门使用及常见的模式进行分享








### 声明一个实体
声明一个实体需要声明 2 个类，一个是继承 `dao` 类的负责持久化的对象，另一个是继承 `entity` 的实体类：
```php
class customer_dao extends dao
{
    protected $table_name = 'customer'; // 实体对应的表名
    protected $db_config_key = 'default'; // 实体对应的数据库配置
}


class customer extends entity
{
    /**
     * structs 声明这个实体所具有的属性、id、version、create_time、update_time、delete_time 框架已经自动实现，无需业务实体中声明
     * 
     * @var mixed
     * @access public
     */
    public $structs = [
        'name' => '',
        'age'  => '',
    ];

    /**
     * create 方法是实体的创建方法，因为不同的实体的 create 可能基于不同的参数，所以没有定为父类的 abstract 方法
     * 
     * @param mixed $name 
     * @param mixed $age 
     * @static
     * @access public
     * @return customer
     */
    public static function create($name, $age)
    {
        $c = parent::init(); // 父类初始化
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









### 基于 ORM 的简单 CRUD 怎么实现
```php
// create
$customer = customer::create($name, $age);

// read
$customer = dao('customer')->find($id);

// update
$customer->name = 'kiki';
$customer->age  = 20;

// soft delete
$customer->delete();

// delete
$customer->force_delete();
```







### 实体上的一些方法

```php
/**
 * is_deleted 判断是否被软删除
 * 
 * @access public
 * @return void
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
 * force_delete 删除动作
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

### ORM 的关联关系

关联关系是将实体-联系数据模型中的 3 种一般性约束（一对一、一对多、多对多约束）加入到对从属关系的描述而形成的结果，含 `belongs_to`、`has_one`、`has_many` 三种，关于三种关系如何使用，在本文档不展开讨论，声明关联关系是在实体的构造方法中，如：
```php
class order extends entity
{
    public $structs = [
        'customer_id' => '',
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
    关联的实体类型，不传则以 relationship_name 作为关联的实体类型

- foreign_key:  
    外键名，不传则赋予默认值，has_one/has_many 为当前实体的类型外加 id，如 order_id，belongs_to 为关联实体的类型外加 id，

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
 * find_by_condition 通过查询条件语句查询第一个实体，condition 是抛去 select 和 where 关键词的 sql_template，可以传入 order by，该方法访问控制为 protected，仅提供给 dao 做方法封装时使用，禁止外部直接使用
 * 
 * @param mixed $condition 
 * @param array $binds 
 * @access protected
 * @return entity
 */
protected function find_by_condition($condition, array $binds = [])

/**
 * find_by_sql 通过查询 sql_template 来查询第一个实体，需要注意的是为了确保实体不是贫血实体，一定要确保查询出所有列
 * 
 * @param mixed $sql_template 
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
 * find_all_by_column 通过简单条件来获得多个实体，简单条件的使用方法见 [框架能力/数据库/简单函数]
 * 
 * @param array $columns 
 * @access public
 * @return array
 */
public function find_all_by_column(array $columns = [])

/**
 * find_all_by_condition 与 find_by_condition 类似，是提供给 dao 封装方法时使用的多实体获取方法
 * 
 * @param mixed $condition 
 * @param array $binds 
 * @access protected
 * @return array
 */
protected function find_all_by_condition($condition, array $binds = [])

/**
 * find_all_by_sql 与 find_by_sql 类似，是提供给 dao 封装方法时使用的多实体获取方法
 * 
 * @param mixed $sql_template 
 * @param array $binds 
 * @access protected
 * @return array
 */
protected function find_all_by_sql($sql_template, array $binds = [])
```
获取实体需要通过该类的 dao 类来，所以在调用以上方法时先需要拿到 dao 实例，框架提供了单例的方法来获取 dao 实例，使用时如下：
```php
$order = dao('order')->find($id);
```
