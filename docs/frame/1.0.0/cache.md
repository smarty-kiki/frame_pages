# 缓存

提供缓存的操作能力，框架中 `cache` 目录下的文件为基于具体组件的实现，如 `memcache.php`、`redis.php`，使用时按需要载入，示例：
```php
include FRAME_DIR.'/cache/redis.php';
```
组件使用时会按照配置机制加载对应的组件配置，示例:
```php
// config/redis.php
return [

    'midwares' => [ // 配置 `key` 与 `resource` 的映射关系
        'default' => 'local',
        'idgenter' => 'local',
        'lock' => 'local',
    ],

    'resources' => [
        'local' => [
            //
            // Create connection with:
            // 'sock' => '/var/run/redis.sock',
            // Or
            //  'host' => '127.0.0.1',
            //  'port' => 6379,
            //

            'host' => '127.0.0.1',
            'port' => 6379,

            'timeout' => 1,

            // Authenticate the connection using a password:
            // 'database' => 0,

            //
            // Authenticate the connection using a password:
            // 'auth' => 'foobared',

            'options' => [
                Redis::OPT_SERIALIZER => Redis::SERIALIZER_PHP,
            ],
        ],
    ]
];
```
例如，配置 `key` 为 `default` 时，会读取 `midwares` 部分的映射关系，最终加载的是 `resource` 中的 `local` 配置


### 获取缓存
----
```php
mix cache_get($key, $config_key = 'default')
```
##### 参数
- key:
    要获取的 `key`

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
返回存在缓存中的数据

##### 示例
```php
$res = cache_get('key');
```






### 批量获取多个缓存值
----
```php
array cache_multi_get(array $keys, $config_key = 'default')
```
##### 参数
- keys:
    要获取的多个 `key`

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
返回存在缓存中的数据，返回结果为数组，数组的 `key` 为对应的缓存 `key`

##### 示例
```php
$res = cache_multi_get([
    'key1', 'key2'
]);
```








### 写入缓存值
----
```php
boolean cache_set($key, $value, $expires = 0, $config_key = 'default')
```
##### 参数
- key:
    要写入的 `key`

- value:
    要写入的数据

- expires:
    保存的时间，单位秒，不传或传入 `0` 时为永久不过期

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
写入成功返回 `true`

##### 示例
```php
cache_set('key1', 'hello cache', 100);
cache_set('key2', 'hello cache forever');
```





### 添加缓存值
----
```php
boolean cache_add($key, $value, $expires = 0, $config_key = 'default')
```
##### 参数
- key:
    要写入的 `key`

- value:
    要写入的数据

- expires:
    保存的时间，单位秒，不传或传入 `0` 时为永久不过期

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
若 `key` 原先在缓存中不存在，并且写入成功返回 `true`，否则返回 `false`

##### 示例
```php
cache_add('key1', 'hello cache', 100);
cache_add('key2', 'hello cache forever');
```






### 替换缓存值
----
```php
boolean cache_replace($key, $value, $expires = 0, $config_key = 'default')
```
##### 参数
- key:
    要写入的 `key`

- value:
    要写入的数据

- expires:
    保存的时间，单位秒，不传或传入 `0` 时为永久不过期

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
若 `key` 原先在缓存中存在，并且替换成功返回 `true`，否则返回 `false`

##### 示例
```php
cache_replace('key1', 'hello cache', 100);
cache_replace('key2', 'hello cache forever');
```







### 删除缓存
----
```php
boolean cache_delete($key, $config_key = 'default')
```
##### 参数
- key:
    要删除的 `key`

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
删除成功返回 `true`

##### 示例
```php
cache_delete('key1');
```








### 缓存批量删除
----
```php
boolean cache_multi_delete(array $keys, $config_key = 'default')
```
##### 参数
- keys:
    要删除的 `keys`

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
删除成功返回 `true`

##### 示例
```php
cache_multi_delete([
    'key1', 'key2'
]);
```





### 缓存计数增加
----
```php
int cache_increment($key, $number = 1, $expires = 0, $config_key = 'default')
```
##### 参数
- key:
    要计数增加的 `key`

- number:
    要计数增加的值

- expires:
    保存的时间，单位秒，不传或传入 `0` 时为永久不过期，每次增加，保存时间会刷新为最后的过期时间

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
返回增加后的数值

##### 示例
```php
$number = cache_increment('counter1');
```











### 缓存计数减少
----
```php
int cache_decrement($key, $number = 1, $expires = 0, $config_key = 'default')
```
##### 参数
- key:
    要计数增加的 `key`

- number:
    要计数减少的值

- expires:
    保存的时间，单位秒，不传或传入 `0` 时为永久不过期，每次减少，保存时间会刷新为最后的过期时间

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
返回减少后的数值

##### 示例
```php
$number = cache_decrement('counter1');
```










### 查询当前有效的缓存 `key`
----
```php
array cache_keys($pattern = '*', $config_key = 'default')
```
##### 参数
- pattern:
    用以搜索 `key`，支持通配符，如 `customer_*`

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
返回查询到的所有缓存 `key`

##### 示例
```php
$keys = cache_keys('counter*');
```








### 写入缓存哈希表中
----
```php
boolean cache_hmset($key, array $array, $expires = 0, $config_key = 'default')
```
##### 参数
- key:
    要写入的 `key`

- array:
    要写入的数据，数组键值为需要存入的哈希表的 `field` 值，`value` 即为对应的 `value` 值

- expires:
    保存的时间，单位秒，不传或传入 `0` 时为永久不过期

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
写入成功返回 `true`

##### 示例
```php
cache_hmset('customer', [
    'name' => 'kiki',
]);
```






### 获取缓存哈希表
----
```php
array cache_hmget($key, array $fields, $config_key = 'default')
```
##### 参数
- key:
    要获取的 `key`

- fields:
    要获取的哈希表 `field`

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
返回查询出来的哈希表结果，为数组类型，数组的 `key` 为指定的 `field`

##### 示例
```php
$customer_info = cache_hmget('customer', [
    'name',
]);
```







### 写入缓存列表
----
```php
int cache_lpush($key, $values, $expires = 0, $config_key = 'default')
```
##### 参数
- key:
    要写入的列表的 `key`

- values:
    要写入列表的值，可以是一个值，也可以是一个包含值的数组

- expires:
    保存的时间，单位秒，不传或传入 `0` 时为永久不过期

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
推入后列表中的内容数量

##### 示例
```php
// 写入一个
cache_lpush('task_list', 'task1');
// 写入多个
cache_lpush('task_list', [
    'task1',
    'task2',
    'task3',
]);
```







### 获取缓存列表，列表为空时等待，后进先出
----
```php
mix cache_blpop($keys, $wait_time = 0, $config_key = 'default')
```
##### 参数
- keys:
    要获取的列表的 `keys`，可直接传值，也可以传一个包含列表 `key` 的数组

- wait_time:
    如若列表为空，等待获取下一个值的等待时间，单位秒，不传或传入 `0` 时为永久等待，要注意缓存配置中的连接超时时间

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
当 `keys` 传入单个 `key` 时，返回值为该列表被写入的最后一个值，当等待超时时，获取到 `null`
当 `keys` 传入包含多个 `key` 的数组时，返回值为数组，会有一对键值，键为列表的 `key`，值为该列表被写入的最后一个值，当等待超时时，获取到空数组

##### 示例
```php
// 获取一个列表
cache_blpop('task_list');
// 获取多个列表
cache_blpop(['task_list', 'task_list2']);
```








### 写入缓存位图中
----
```php
int cache_setbit($key, $offset, $value, $config_key = 'default')
```
##### 参数
- key:
    位图的 `key`

- offset:
    要改写的位偏移量值

- value:
    要改写的值，只能为 0 或 1

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
写入前的值，之前未存在时为 0

##### 示例
```php
cache_setbit('test', 8, 1);
```







### 获取缓存位图某个偏移量的值
----
```php
int cache_getbit($key, $offset, $config_key = 'default')
```
##### 参数
- key:
    位图的 `key`

- offset:
    要获取的位偏移量值

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
指定偏移量下的值，没有该偏移量返回为 0

##### 示例
```php
$value = cache_getbit('test', 1);
```











### 获取缓存位图中 1 值的个数
----
```php
int cache_bitcount($key, $start = 0, $end = -1, $config_key = 'default')
```
##### 参数
- key:
    位图的 `key`

- start:
    统计范围的起始字节偏移量，注意不是位偏移量，闭区间

- end:
    统计范围的结束字节偏移量，注意不是位偏移量，闭区间

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
值为 1 的位个数

##### 示例
```php
$count = cache_bitcount('test');
```











### 缓存计算多个位图 `AND`、`OR`、`NOT`、`XOR` 的结果位图
----
```php
int cache_bitop($destkey, $operation, $keys, $config_key = 'default')
```
##### 参数
- destkey:
    计算结果放入的 `key`

- operation:
    逻辑运算符 `AND`、`OR`、`NOT`、`XOR` 中的一个，可以小写

- keys:
    计算的多个位图 `key` 数组

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
成功时返回 1

##### 示例
```php
cache_bitop(‘result’, 'or', ['test1', 'test2']);
```











### 获取缓存位图中下一个目标值的字节偏移量
----
```php
int cache_bitpos($key, $bit, $start = 0, $end = -1, $config_key = 'default')
```
##### 参数
- key:
    位图的 `key`

- bit:
    `1` 或者 `0`

- start:
    查找范围的起始字节偏移量，注意不是位偏移量，闭区间

- end:
    查找范围的结束字节偏移量，注意不是位偏移量，闭区间

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
字节偏移量值

##### 示例
```php
$byte_offset = cache_bitpos('test', 1);
```











### 重命名缓存 `key`
----
```php
boolean cache_rename($old_key, $new_key, $config_key = 'default')
```
##### 参数
- old_key:
    当前的缓存 `key`

- new_key:
    要改为的新 `key`

- config_key:
    缓存服务对应的配置 `key`

##### 返回值
成功时返回 `true`，失败时返回 `false`

##### 示例
```php
cache_rename('old_key', 'new_key');
```







### 关闭当前保持的所有缓存服务的连接
----
```php
void cache_close()
```
通常不需要主动释放，常在队列 `worker` 等常驻内存的进程逻辑中使用
