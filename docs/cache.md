# 缓存

本框架基于 Redis 封装了一套全局函数式的缓存 API，覆盖字符串、Hash、List、Bitmap 等常用数据结构。连接参数在 `config/redis.php` 中配置（见[配置](config.md)）。

所有函数末尾的 `$config_key` 指定使用哪个 midwares 键（默认 `'default'`）。

## 字符串 KV

### cache_get

```php
cache_get($key, $config_key = 'default')
```

读取缓存值（自动反序列化）。键不存在返回 `null`。

```php
$data = cache_get('user:1');
```

### cache_multi_get

```php
cache_multi_get(array $keys, $config_key = 'default')
```

一次读取多个键（MGET），返回 `[键 => 值]` 数组，不存在的键值为 `null`。

```php
$data = cache_multi_get(['user:1', 'user:2', 'user:3']);
```

### cache_set

```php
cache_set($key, $value, $expires = 0, $config_key = 'default')
```

写入缓存。`$value` 会被 PHP 序列化存储；`$expires` 为过期秒数，`0` 表示永不过期。返回 `true` / `false`。

```php
cache_set('user:1', $user_data, 3600);   // 1 小时后过期
cache_set('config:version', '20260826');
```

### cache_add

```php
cache_add($key, $value, $expires = 0, $config_key = 'default')
```

仅当键**不存在**时写入（SETNX）。成功返回 `true`，键已存在返回 `false`。常用于防并发、幂等标记。

```php
$locked = cache_add('pay:lock:1001', 1, 30);   // 加锁成功才返回 true
```

### cache_replace

```php
cache_replace($key, $value, $expires = 0, $config_key = 'default')
```

仅当键**已存在**时覆盖写入。键不存在返回 `false`。

```php
cache_replace('user:1', $updated, 3600);
```

### cache_delete

```php
cache_delete($key, $config_key = 'default')
```

删除缓存键，返回 `true` / `false`。

```php
cache_delete('user:1');
```

### cache_multi_delete

```php
cache_multi_delete(array $keys, $config_key = 'default')
```

一次删除多个键。

```php
cache_multi_delete(['user:1', 'user:2']);
```

### cache_increment

```php
cache_increment($key, $number = 1, $expires = 0, $config_key = 'default')
```

原子自增，`$number` 为增量（可传负数实现自减）。返回自增后的值。常用于计数器、库存。

```php
$page_view = cache_increment('page_view:20260826');
cache_increment('stock:1001', -1);   // 自减
```

### cache_decrement

```php
cache_decrement($key, $number = 1, $expires = 0, $config_key = 'default')
```

原子自减，`$number` 为减量。返回自减后的值。

```php
cache_decrement('coupon:1001');
```

### cache_keys

```php
cache_keys($pattern = '*', $config_key = 'default')
```

按通配符匹配模式列出键名（`KEYS pattern`）。`*` 匹配任意字符，默认列出全部键。

```php
$keys = cache_keys('user:*');
```

## Hash

### cache_hmset

```php
cache_hmset($key, array $array, $expires = 0, $config_key = 'default')
```

批量设置 Hash 的多个字段。

```php
cache_hmset('user:1001', ['name' => '张三', 'age' => 18]);
```

### cache_hmget

```php
cache_hmget($key, array $fields, $config_key = 'default')
```

一次读取 Hash 的多个字段，返回 `[字段 => 值]`。

```php
$info = cache_hmget('user:1001', ['name', 'age']);
```

## List

### cache_lpush

```php
cache_lpush($key, $values, $expires = 0, $config_key = 'default')
```

从列表**左侧**压入元素。`$values` 可为单个值或值数组（一次压入多个）。返回列表长度。

```php
cache_lpush('notify_queue', $notify);
cache_lpush('notify_queue', ['a', 'b', 'c']);
```

### cache_blpop

```php
cache_blpop($keys, $wait_time = 0, $config_key = 'default')
```

阻塞式弹出：从 `$keys` 的**第一个非空列表**左侧弹出元素。`$wait_time` 为阻塞秒数（`0` 表示永久阻塞）。

- `$keys` 传单个键字符串 → 弹出成功返回值，超时返回 `null`
- `$keys` 传数组 → 成功返回 `[键 => 值]`，超时返回 `[]`

```php
$task = cache_blpop('notify_queue', 5);        // '...'
$pair = cache_blpop(['queue_a', 'queue_b'], 5); // ['queue_a' => '...']
```

## Bitmap

### cache_setbit

```php
cache_setbit($key, $offset, $value, $config_key = 'default')
```

设置位图第 `$offset` 位的值（0 / 1），返回旧值。常用于签到、在线状态、去重标记。

```php
cache_setbit('signin:20260826:1001', 1, 1);   // 用户 1001 已签到
```

### cache_getbit

```php
cache_getbit($key, $offset, $config_key = 'default')
```

读取位图第 `$offset` 位的值（0 / 1）。

```php
$signed = cache_getbit('signin:20260826:1001', 1);
```

### cache_bitcount

```php
cache_bitcount($key, $start = 0, $end = -1, $config_key = 'default')
```

统计位图区间内值为 1 的位数。`$start` / `$end` 为**字节偏移**（非位偏移），`-1` 表示末尾。

```php
$days = cache_bitcount('signin:20260826:1001');   // 已签到天数
```

### cache_bitop

```php
cache_bitop($destkey, $operation, $keys, $config_key = 'default')
```

位运算（`AND` / `OR` / `XOR` / `NOT`），结果写入 `$destkey`。常用于用户标签集合运算。

```php
cache_bitop('all_active', 'OR', ['active:a', 'active:b']);
```

### cache_bitpos

```php
cache_bitpos($key, $bit, $start = 0, $end = -1, $config_key = 'default')
```

查找位图区间内第一个值为 `$bit` 的位偏移。`$start` / `$end` 为字节偏移。

```php
$first_signed = cache_bitpos('signin:20260826:1001', 1);
```

## 其他

### cache_rename

```php
cache_rename($old_key, $new_key, $config_key = 'default')
```

重命名缓存键。

```php
cache_rename('user:1', 'user:1001');
```

### cache_close

```php
cache_close()
```

关闭 Redis 连接池，释放连接。通常无需手动调用（worker 在任务间会通过 `queue_finish_action` 自动调用）。
