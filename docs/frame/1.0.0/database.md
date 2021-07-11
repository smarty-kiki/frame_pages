# 数据库

提供数据库的操作能力，框架中 `database` 目录下的文件为基于具体组件的实现，如 `mysql.php`、`oracle.php`，使用时按需要载入，示例：
```php
include FRAME_DIR.'/database/mysql.php';
```
组件使用时会按照配置机制加载对应的组件配置，示例:
```php
// config/mysql.php
return [
    'midwares' => [
        'entity' => 'local',
        'default' => 'local',
    ],

    'resources' => [

        'local' => [
            'charset' => 'utf8',
            'collation' => 'utf8_unicode_ci',
            'database' => 'default',
            'username' => 'root',
            'password' => 'password',

            'read' => [
                 //
                 // 配置连接如 sock
                 //  '/var/run/mysqld/mysqld.sock',
                 // 或
                 //  '127.0.0.1' => 3306,
                 // IP 端口可以是有多个，在使用时会随机使用，配置时如
                 //  '192.168.1.1' => 3306,
                 //  '192.168.1.2' => 3306,
                 //
                '/var/run/mysqld/mysqld.sock',
            ],
            'write' => [
                '/var/run/mysqld/mysqld.sock',
            ],
            'schema' => [
                '/var/run/mysqld/mysqld.sock',
            ],

            'options' => [
                PDO::ATTR_CASE => PDO::CASE_NATURAL,
                PDO::ATTR_ORACLE_NULLS => PDO::NULL_NATURAL,
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_STRINGIFY_FETCHES => false,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_PERSISTENT => false,
            ],
        ],
    ],
];

```
例如，配置 `key` 为 `default` 时，会读取 `midwares` 部分的映射关系，最终加载的是 `resource` 中的 `local` 配置  


## 标准函数

标准函数是基础的数据库操作能力。为了让 `sql` 更清爽，让系统监控及防止数据库注入攻击，`sql` 需要拆分为 `sql_template` 和 `binds`，如：  
```php
$sql_template = 'select * from customer where name = :name and age = :age';
$binds = [
    ':name' => 'kiki',
    ':age'  => 20,
];
```
`sql_template` 中的变量需用 `bind key` 来替换，如 `:name`，`bind key` 通常可以直接使用列名命名，若同列有多个条件，需要区分 `bind key`，如：  
```php
$sql_template = 'select * from customer where age >= :age_min and age <= :age_max';
$binds = [
    ':age_min' => 18,
    ':age_max' => 25,
];
```
`sql_template` 中也会需要用到数组，不必写数据数量的 `bind key`，只需要这样既可：  
```php
$sql_template = 'select * from customer where age in :ages';
$binds = [
    ':ages' => [18, 19, 20, 21, 22],
];
```
如果条件中有 `null` 相关逻辑，直接写在 `sql_template` 即可，如：  
```php
$sql_template = 'select * from customer where delete_time is null';
```













### 查询
----
```php
array db_query($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回查询结果的数组

##### 示例
```php
$customer_infos = db_query('select * from customer where age = :age', [
    ':age' => 20,
]);
```










### 查询首条数据
----
```php
array db_query_first($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回首条数据结果

##### 示例
```php
$order_info = db_query_first('select * from order where status = :status', [
    ':status' => 'VALID',
]);
```









### 查询某列的值
---
```php
array db_query_column($column, $sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- column:  
    查询的列名或 `alias` 名

- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回列值数组

##### 示例
```php
$customer_names = db_query_column('name', 'select name from customer where status = :status', [
    ':status' => 'VALID',
]);
```









### 查询某个值
----
```php
mix db_query_value($value, $sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- value:  
    查询的值

- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回指定的值

##### 示例
```php
$customer_cnt = db_query_value('cnt', 'select count(*) cnt from customer where status = :status', [
    ':status' => 'VALID',
]);
```











### 更新数据
----
```php
int db_update($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回更新的数据条数

##### 示例
```php
db_update('update customer set name = :name, age = :age where id = :id', [
    ':name' => 'kiki',
    ':age' => 20,
    ':id' => 1,
]);
```







### 删除数据
----
```php
int db_delete($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回删除的数据条数

##### 示例
```php
db_delete('delete from customer where id = :id', [
    ':id' => 1,
]);
```










### 插入数据
----
```php
mix db_insert($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
如表主键定义为自增，返回插入的数据主键，否则返回值为 `0`

##### 示例
```php
db_insert('insert into customer (name, age) values (:name, :age)', [
    ':name' => 'kiki',
    ':age'  => 20,
]);
```












### 写数据
----
```php
int db_write($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    `sql` 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回写操作影响的数据行数

##### 示例
```php
db_write('insert into customer (name, age) values (:name, :age)', [
    ':name' => 'kiki',
    ':age'  => 20,
]);
```









### 改数据结构
----
```php
int db_structure($sql, $config_key = 'default')
```
##### 参数
- sql:  
    `sql` 语句

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回操作影响的数据行数

##### 示例
```php
db_structure('drop table customer');
```









### 事务闭包
----
```php
mix db_transaction(closure $action, $config_key = 'default')
```
##### 参数
- action:  
    要在闭包中执行的逻辑段闭包

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
闭包中返回的值

##### 示例
```php
db_transaction(function () {
    return db_write('insert into customer (name, age) values (:name, :age)', [
        ':name' => 'kiki',
        ':age'  => 20,
    ]);
});
```








### 关闭所有当前保持的数据库连接
----
```php
void db_close()
```
##### 参数
无

##### 返回值
无

##### 示例
```php
db_close();
```








### 设置数据库连接强制 `write` 库
----
```php
boolean db_force_type_write($bool = null)
```
##### 参数
- bool:  
    是否强制用 `write` 库的布尔值，如果不传不会改变当前配置，依然会返回当前布尔状态  

##### 返回值
返回当前的布尔状态







## 简单函数

简单函数主要是针对 `sql` 的 `where` 条件书写的简化和插入、更新语句的数据拼装，如果追求完全实现 `sql` 所有的能力，会让使用变的复杂、学习成本更高，不如直接使用原生 `sql`，所以简单函数只聚焦在提供高频使用的场景，**表达能力有限**，建议只在小型项目中使用，简化的 `where` 写法有以下几种:  
- 等于
```php
$wheres = [
    'name' => 'kiki',
    'age'  => 20,
];
```
- `in` 数组
```php
$wheres = [
    'name'    => ['kiki', 'other'],
    'age not' => [20, 21],
];
```

- `null`
```php
$wheres = [
    'name'    => null,
    'age not' => null,
];
```

- 大小判断
```php
$wheres = [
    'age >' => 18,
];
```












### 简单插入数据
----
```php
mix db_simple_insert($table, array $data, $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- data:  
    要插入的数据

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
如表主键定义为自增，返回插入的数据主键，否则返回值为 `0`

##### 示例
```php
db_simple_insert('customer', [
    'name' => 'kiki',
    'age'  => 20,
]);
```











### 简单批量插入数据
----
```php
int db_simple_multi_insert($table, array $datas, $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- datas:  
    要插入的多条数据

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回插入的首条数据的主键

##### 示例
```php
db_simple_multi_insert('customer', [
    ['name' => 'kiki', 'age'  => 20,],
    ['name' => 'kiki', 'age'  => 20,],
]);
```













### 简单更新数据
----
```php
int db_simple_update($table, array $wheres, array $data, $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- wheres:  
    目标条目的查询条件

- datas:  
    要更新的数据

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回更新涉及到的数据行数

##### 示例
```php
db_simple_update('customer', 
    ['name' => 'kiki'],
    ['age'  => 20]
);
```













### 简单批量更新数据
----
```php
int db_simple_multi_update($table, array $datas, $where_column = 'id', $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- datas:  
    要更新的数据

- where_column:  
    依据哪个字段来寻找被更新的数据，默认是 `id`

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回更新涉及到的数据行数

##### 示例
```php
db_simple_multi_update('customer', [
    ['id' => 1, 'name' => 'kiki'],
    ['id' => 2, 'name' => 'kiki'],
    ['id' => 3, 'name' => 'kiki'],
]);
```













### 简单删除数据
----
```php
int db_simple_delete($table, array $wheres, $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- wheres:  
    目标条目的查询条件

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回删除了的数据行数

##### 示例
```php
db_simple_delete('customer', 
    ['name' => 'kiki']
);
```










### 简单查询数据
----
```php
array db_simple_query($table, array $wheres, $option_sql = 'order by id', $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- wheres:  
    目标条目的查询条件

- option_sql:  
    目标条目的额外条件，如 `order by`、`limit`

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回查询到的数据

##### 示例
```php
db_simple_query('customer', 
    ['age' => 20],
    'order by name'
);
```











### 简单查询首条数据
----
```php
array db_simple_query_first($table, array $wheres, $option_sql = '', $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- wheres:  
    目标条目的查询条件

- option_sql:  
    目标条目的额外条件，如 `order by`

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回查询到的数据

##### 示例
```php
db_simple_query_first('customer', 
    ['age' => 20],
    'order by name'
);
```












### 简单查询按索引组织结果
----
```php
array db_simple_query_indexed($table, $indexed, array $wheres, $option_sql = 'order by id', $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- indexed:  
    依据哪个字段索引

- wheres:  
    目标条目的查询条件

- option_sql:  
    目标条目的额外条件，如 `order by`、`limit`

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回查询到的数据，结果按照指定的字段索引

##### 示例
```php
db_simple_query_indexed('customer', 'id',
    ['age' => 20],
    'order by name'
);
```













### 简单查询具体单个结果
----
```php
mix db_simple_query_value($table, $value, array $wheres, $option_sql, $config_key = 'default')
```
##### 参数
- table:  
    目标表名

- value:  
    需要获取的值

- wheres:  
    目标条目的查询条件

- option_sql:  
    目标条目的额外条件，如 `order by`、`group by`

- config_key:  
    数据库对应的配置 `key`  

##### 返回值
返回查询到的数据

##### 示例
```php
db_simple_query_value('customer', 'id',
    ['age' => 20],
    'order by name'
);
```
