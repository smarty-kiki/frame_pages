# 缓存

提供缓存的操作能力，框架中 `cache` 目录下的文件为基于具体组件的实现，如 `memcache.php`、`redis.php`，使用时按需要载入，示例：  
```php
include FRAME_DIR.'/cache/redis.php';
```
组件使用时会按照配置机制加载对应的组件配置，示例:  
```php
// config/redis.php
return [
    'default' => [
        //
        // 配置连接如 sock
        //  'sock' => '/var/run/redis.sock',
        // 或
        //  'host' => '127.0.0.1',
        //  'port' => 6379,
        //

        'host' => '127.0.0.1',
        'port' => 6379,

        'timeout' => 1,

        // 指定 database
        // 'database' => 0,

        //
        // redis auth
        // 'auth' => 'foobared',

        'options' => [
            Redis::OPT_SERIALIZER => Redis::SERIALIZER_PHP,
        ],
    ],
];
```

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








### 关闭当前保持的所有缓存服务的连接
----
```php
void cache_close()
```
通常不需要主动释放，常在队列 `worker` 等常驻内存的进程逻辑中使用
