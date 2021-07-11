# 非 SQL 存储

提供非 SQL 类的存储能力，框架中 `storage` 目录下的文件为基于具体组件的存储实现，如 `mongodb.php`，使用时按需要载入，示例：
```php
include FRAME_DIR.'/storage/mongodb.php';
```











### 插入数据
----
```php
int storage_insert($table, array $data, $config_key = 'default')
```
##### 参数
- table:  
    写入的表名

- data:  
    单条数据

- config_key:  
    具体组件的配置

##### 返回值
插入数据的条数，通常是 `1`

##### 示例
```php
$res = storage_insert('customer', [
    'name' => 'kiki',
    'age'  => 20,
]);
```











### 批量插入数据
----
```php
int storage_multi_insert($table, array $datas, $config_key = 'default')
```
##### 参数
- table:  
    写入的表名

- datas:  
    数据数组

- config_key:  
    存储对应的配置 `key`

##### 返回值
插入数据的数量

##### 示例
```php
$res = storage_multi_insert('customer', [
    ['name' => 'kiki', 'age' => 20],
    ['name' => 'kiki', 'age' => 20],
    ['name' => 'kiki', 'age' => 20],
    ['name' => 'kiki', 'age' => 20],
    ['name' => 'kiki', 'age' => 20],
    ['name' => 'kiki', 'age' => 20],
]);
```











### 查询数据
----
```php
array storage_query($table, array $selections = [], array $queries = [], array $sorts = [], $offset = 0, $limit = 1000, $config_key = 'default')
```
##### 参数
- table:  
    查询的表名

- selections:  
    查询的字段，要查询的字段是多维数组中的值，可以用点符号来表达，如 `data.name`

- queries:  
    筛选的条件，[参考这里](https://docs.mongodb.com/manual/tutorial/query-documents/)

- sorts:  
    排序的条件

- offset:  
    查询偏移量

- limit:  
    取多少数据

- config_key:  
    具体组件的配置

##### 返回值
返回查询出来的结果

##### 示例
```php
$customers = storage_query('customer', ['_id', 'data.name'], ['data.name' => 'kiki']);
```











### 通过 `id` 查询单条数据
----
```php
$data = storage_find($table, $id, $config_key = 'default')
```
##### 参数
- table:  
    写入的表名

- id:  
    数据的 `id`

- config_key:  
    具体组件的配置

##### 返回值
数据

##### 示例
```php
$customer = storage_find('customer', $id);
```











### 更新数据
----
```php
int storage_update($table, array $queries = [], array $new_data, $config_key = 'default')
```
##### 参数
- table:  
    更新的表名

- queries:  
    目标数据的查询条件

- new_data:  
    新数据

- config_key:  
    具体组件的配置

##### 返回值
更新的数据数量

##### 示例
```php
storage_update('customer', ['data.name' => 'kiki'], ['data.name' => 'other']);
```











### 删除数据
----
```php
int storage_delete($table, array $queries = [], $config_key = 'default')
```
##### 参数
- table:  
    删除的表名

- queries:  
    目标数据的查询条件

- config_key:  
    具体组件的配置

##### 返回值
删除的数据数量

##### 示例
```php
storage_delete('customer', ['data.name' => 'kiki']);
```
