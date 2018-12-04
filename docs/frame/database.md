# 数据库

提供数据库的操作能力，框架中 database 目录下的文件为基于具体组件的实现，如 mysql.php、oracle.php，使用时按需要载入，示例：
```php
include FRAME_DIR.'/database/mysql.php';
```
组件使用时会按照配置机制加载对应的组件配置，示例:
```php
// config/mysql.php
return [
    'default' => [
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
    ],

    'options' => [
        PDO::ATTR_CASE => PDO::CASE_NATURAL,
        PDO::ATTR_ORACLE_NULLS => PDO::NULL_NATURAL,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_STRINGIFY_FETCHES => false,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_PERSISTENT => false,
    ],
];
```

### 设置数据库连接强制 write 库
----
```php
boolean db_force_type_write($bool = null)
```
##### 参数
- bool:  
    是否强制用 write 库的布尔值，如果不传不会改变当前配置，依然会返回当前布尔状态  

##### 返回值
返回当前的布尔状态









### 查询
----
```php
array db_query($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    sql 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 key  

##### 返回值
返回查询结果的数组

##### 示例
```php
$order_infos = db_query('select * from order where status = :status', [
    ':status' => 'VALID',
]);
```










### 查询首条数据
----
```php
array db_query_first($sql_template, array $binds = [], $config_key = 'default')
```
##### 参数
- sql_template:  
    sql 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 key  

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
    查询的列名

- sql_template:  
    sql 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 key  

##### 返回值
返回列值数组

##### 示例
```php
$customer_names = db_query_column('name', 'select * from customer where status = :status', [
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
    sql 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 key  

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
    sql 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 key  

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
    sql 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 key  

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
    sql 模版

- binds:  
    数据绑定

- config_key:  
    数据库对应的配置 key  

##### 返回值
返回插入的数据主键

##### 示例
```php
db_insert('insert into customer (name, age) values (:name, :age)', [
    ':name' => 'kiki',
    ':age'  => 20,
]);
```














```php
function db_write($sql_template, array $binds = [], $config_key = 'default')
```

```php
function db_structure($sql, $config_key = 'default')
```

```php
function db_transaction(closure $action, $config_key = 'default')
```

```php
function db_close()
```

```php
function db_simple_where_sql(array $wheres)
```

```php
function db_simple_insert($table, array $data, $config_key = 'default')
```

```php
function db_simple_multi_insert($table, array $datas, $config_key = 'default')
```

```php
function db_simple_update($table, array $wheres, array $data, $config_key = 'default')
```

```php
function db_simple_delete($table, array $wheres, $config_key = 'default')
```

```php
function db_simple_query($table, array $wheres, $option_sql = 'order by id', $config_key = 'default')
```

```php
function db_simple_query_first($table, array $wheres, $option_sql = '', $config_key = 'default')
```

```php
function db_simple_query_indexed($table, $indexed, array $wheres, $option_sql = 'order by id', $config_key = 'default')
```

```php
function db_simple_query_value($value, $table, array $wheres, $config_key = 'default')
```
