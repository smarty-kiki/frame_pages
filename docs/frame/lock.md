# 锁

提供锁能力，框架中 lock 目录下的文件为基于具体组件的实现，如 cache.php，使用时按需要载入，示例：
```php
include FRAME_DIR.'/lock/cache.php';
```
组件使用时需要有对应的配置，如 cache.php 需要有 cache 能力的引入，示例：
```php
include FRAME_DIR.'/cache/redis.php';
```
并且也需要对 cache 能力依赖的组件进行配置：示例：
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

### 独占执行
----
```php
mix singly_run($key, $expire_second, closure $closure, $fail_closure = null)
```
##### 参数
- key:  
    独占标识，同标识的逻辑会独占执行

- expire_second:  
    独占最长锁定时间

- closure:  
    独占执行的逻辑

- fail_closure:  
    未获得独占时执行的逻辑

##### 返回值
执行逻辑返回值

##### 示例
```php
$success = singly_run('deduct_account_'.$account->id, 2, function () use ($account, $price) {
    $account->deduct($price);
    return true;
})
```











### 序列化执行。此方法对锁容器有较大的使用开销，慎用
----
```php
mix serially_run($key, $expire_second, $wait_second, closure $closure, $fail_closure = null)
```
##### 参数
- key:  
    序列化标识，同标识的逻辑会序列化执行

- expire_second:  
    单任务序列化保障的时间

- wait_second:  
    排队的最长等待时间，超时后执行失败逻辑

- closure:  
    序列化执行的逻辑

- fail_closure:  
    超时后执行的逻辑

##### 返回值
执行逻辑返回值

##### 示例
```php
$success = serially_run('goods_inventory_reduce_'.$goods->id, 2, 3, function () use ($goods, $reduce_inventory) {
    $goods->inventory_reduce($reduce_inventory);
    return true;
})
```
