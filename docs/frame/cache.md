# 缓存

提供缓存的操作能力

### 获取缓存
----
```php
mix cache_get($key, $config_key = 'default')
```
##### 参数
- key:  
    缓存的 key  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
返回存在缓存中的数据








### 批量获取多个缓存值
----
```php
array cache_multi_get(array $keys, $config_key = 'default')
```
##### 参数
- keys:  
    要获取的多个 key  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
返回存在缓存中的数据，返回结果为数组，数组的 key 为对应的缓存 key








### 写入缓存值
----
```php
boolean cache_set($key, $value, $expires = 0, $config_key = 'default')
```
##### 参数
- key:  
    要写入的 key  

- value:  
    要写入的数据  

- expires:  
    保存的时间，单位秒  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
写入成功返回 true







### 添加缓存值
----
```php
boolean cache_add($key, $value, $expires = 0, $config_key = 'default')
```
##### 参数
- key:  
    要写入的 key  

- value:  
    要写入的数据  

- expires:  
    保存的时间，单位秒  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
若 key 原先在缓存中不存在，并且写入成功返回 true，否则返回 false







### 替换缓存值
----
```php
boolean cache_replace($key, $value, $expires = 0, $config_key = 'default')
```
##### 参数
- key:  
    要写入的 key  

- value:  
    要写入的数据  

- expires:  
    保存的时间，单位秒  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
若 key 原先在缓存中存在，并且替换成功返回 true，否则返回 false








### 删除缓存
----
```php
boolean cache_delete($key, $config_key = 'default')
```
##### 参数
- key:  
    要删除的 key  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
删除成功返回 true









### 缓存批量删除
----
```php
boolean cache_multi_delete(array $keys, $config_key = 'default')
```
##### 参数
- keys:  
    要删除的 keys  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
删除成功返回 true





### 缓存计数增加
----
```php
int cache_increment($key, $number = 1, $expires = 0, $config_key = 'default')
```
##### 参数
- key:  
    要计数增加的 key  

- number:  
    要计数增加的值  

- expires:  
    保存的时间，单位秒  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
返回增加后的数值











### 缓存计数减少
----
```php
int cache_decrement($key, $number = 1, $expires = 0, $config_key = 'default')
```
##### 参数
- key:  
    要计数增加的 key  

- number:  
    要计数减少的值  

- expires:  
    保存的时间，单位秒  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
返回减少后的数值











### 查询当前有效的缓存 key
----
```php
array cache_keys($pattern = '*', $config_key = 'default')
```
##### 参数
- pattern:  
    用以搜索 key，支持通配符，如 customer_*  

- config_key:  
    缓存服务对应的配置 key  

##### 返回值
返回查询到的所有缓存 key












### 缓存服务的 socket 连接关闭
----
```php
void cache_close()
```
通常不需要主动释放，常在队列 worker 等常驻内存的进程逻辑中使用
