# 队列

提供队列能力，框架中 `queue` 目录下的文件为基于具体组件的队列实现，如 `beanstalk.php`，使用时按需要载入，示例：
```php
include FRAME_DIR.'/queue/beanstalk.php';
```
组件使用时会按照配置机制加载对应的组件配置，示例：
```php
// config/beanstalk.php
return [
    'midwares' => [
        'default' => 'local',
        'queue' => 'local',
    ],

    'resources' => [
        'local' => [
            'host' => '127.0.0.1',
            'port' => 11300,
            'timeout' => 1,
        ],
    ],
];
```









### 注册每个任务执行完之后会执行的逻辑，通常用于连接资源回收
----
```php
closure queue_finish_action(closure $action = null)
```
##### 参数
- action:  
    在 `job` 执行完之后被执行的逻辑闭包

##### 返回值
当前生效的逻辑闭包

##### 示例
```php
queue_finish_action(function () {
    cache_close();
    db_close();
});
```











### 注册队列任务
----
```php
void queue_job($job_name, closure $closure, $priority = 10, $retry = [], $tube = 'default', $config_key = 'default')
```
##### 参数
- job_name:  
    任务名

- closure:  
    任务逻辑闭包，在调用时，会接收到 `queue_push` 时的 `data` 参数内容、当前的 `retry` 次数、当前 `job` 的 `id`

- priority:  
    优先级，数字越小优先级越高

- retry:  
    `job` 执行未返回 `true` 则认为是失败，这个参数定义每次重试较上一次延迟多少秒开始，如 ```[]``` 表示不重试，```[10, 20, 30]``` 表示第一次失败后会在 `10` 秒后执行第二次，第二次失败会在 `20` 秒后执行第三次，第三次失败会在 `30` 秒后执行第四次

- tube:  
    任务所在的管道

- config_key:  
    队列对应的配置

##### 返回值
无

##### 示例
```php
queue_job('hello-world', function ($data, $retry_times, $job_id) {

    // hello-world

    return true;
});
```











### 推入一个队列任务
----
```php
string queue_push($job_name, array $data = [], $delay = 0)
```
##### 参数
- job_name:  
    任务名

- data:  
    数据

- delay:  
    延迟多少秒执行

##### 返回值
队列任务 id

##### 示例
```php
queue_push('hello-world');
```
