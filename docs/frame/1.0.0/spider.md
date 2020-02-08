# 蜘蛛

蜘蛛经过配置可以定时的从指定的网络位置获取内容并保存，框架目录 `spider` 中的文件是基于不同组件的实现，如 `beanstalk.php`，使用时按需加载：
```php
include FRAME_DIR.'/spider/beanstalk.php';
```









### 按照 cron_string 获取下一个符合时间规则的时间
----
```php
int spider_cron_string_parse($cron_string, $after_timestamp = null)
```
##### 参数
- cron_string:  
    crontab 时间规则字符串，如 `* * * * *`

- after_timestamp:  
    指定从某个时间戳之后开始寻找，不传默认从当前时间开始找

##### 返回值
下一个符合时间规则的时间戳

##### 示例
```php
$timestamp = spider_cron_string_parse('0 1 * * *');
```











### 注册在蜘蛛任务执行完之后会执行的逻辑，通常用于连接资源回收
----
```php
closure spider_finish_action(closure $action = null)
```
##### 参数
- action:  
    在 job 执行完之后被执行的逻辑闭包

##### 返回值
当前生效的逻辑闭包

##### 示例
```php
spider_finish_action(function () {
    cache_close();
    db_close();
});
```











### 按当前声明的蜘蛛任务的时间规则来触发任务
----
```php
void spider_trigger()
```
##### 参数
##### 返回值
无

##### 示例
```php
spider_trigger();
```











### 蜘蛛任务推入执行队列
----
```php
string spider_job_push($job_name, $url = null, $data = [])
```
##### 参数
- job_name:  
    蜘蛛任务名

- url:  
    指定的抓取 URL，如果没有传，默认使用声明在蜘蛛任务中的 URL

- data:  
    指定的 POST 数据，如果没有传，默认使用声明在蜘蛛任务中的 data

##### 返回值
队列任务 id

##### 示例
```php
spider_job_push('hello-world');
```











### 注册 get 请求的蜘蛛任务
----
```php
void spider_job_get(string $job_name, string $cron_string, string $url, string $format, array $spider_rule, $priority = 10, $retry = [], $config_key = 'default')
```
##### 参数
- job_name:  
    任务名

- cron_string:  
    任务的时间规则

- url:  
    要获取的 URL

- format:  
    要获取的目标格式，如 json、xml、html

- spider_rule:  
    目标格式到要获取的格式的转换关系

- priority:  
    优先级，如果任务堆积，会按照优先级来执行获取任务

- retry:  
    如果当次获取任务失败，

- config_key:  
    依赖组件的配置

##### 返回值
无

##### 示例
```php
spider_job_get('test', '* * * * *', 'http://127.0.0.1/test', 'json', [
    'test' => 'a',
    'test3.a' => 'b',
]);
```











### 注册 post 请求的蜘蛛任务
----
```php
void spider_job_post(string $job_name, string $cron_string, string $url, $data, string $format, array $spider_rule, $priority = 10, $retry = [], $config_key = 'default')
```
##### 参数
- job_name:  
    任务名

- cron_string:  
    任务的时间规则

- url:  
    要获取的 URL

- data:  
    POST 数据

- format:  
    要获取的目标格式，如 json、xml、html

- spider_rule:  
    目标格式到要获取的格式的转换关系

- priority:  
    优先级，如果任务堆积，会按照优先级来执行获取任务

- retry:  
    如果当次获取任务失败，

- config_key:  
    依赖组件的配置

##### 返回值
无

##### 示例
```php
spider_job_post('test', '* * * * *', 'http://127.0.0.1/test', ['name' => 'kiki'], 'json', [
    'test' => 'a',
    'test3.a' => 'b',
]);
```











### 立刻获取，但不存储，get 方法
----
```php
array spider_run_get($url, string $format, array $spider_rule)
```
##### 参数
- url:  
    要获取的 URL

- format:  
    要获取的目标格式，如 json、xml、html

- spider_rule:  
    目标格式到要获取的格式的转换关系

##### 返回值
获取的数据

##### 示例
```php
$data = spider_run_get('http://127.0.0.1/test', 'json', [
    'test' => 'a',
    'test3.a' => 'b',
]);
```











### 立刻获取，但不存储，post 方法
----
```php
array spider_run_post($url, $data, string $format, array $spider_rule)
```
##### 参数
- url:  
    要获取的 URL

- data:  
    POST 数据

- format:  
    要获取的目标格式，如 json、xml、html

- spider_rule:  
    目标格式到要获取的格式的转换关系

##### 返回值
获取的数据

##### 示例
```php
$data = spider_run_post('http://127.0.0.1/test', ['name' => 'kiki'], 'json', [
    'test' => 'a',
    'test3.a' => 'b',
]);
```











### 查询获取到的数据
----
```php
array spider_data_query($job_name, array $selections = [], array $queries = [], array $sorts = [], $offset = 0, $limit = 1000)
```
##### 参数
- job_name:  
    蜘蛛任务名

- selections:  
    查询的字段，要查询的字段是多维数组中的值，可以用点符号来表达，如，data.name

- queries:  
    筛选的条件，[参考这里](https://docs.mongodb.com/manual/tutorial/query-documents/)

- sorts:  
    排序的条件

- offset:  
    查询偏移量

- limit:  
    取多少数据

##### 返回值
查询出来的数据

##### 示例
```php
$datas = spider_data_query('test');
```











### 查询最后一次获取到的数据
----
```php
array spider_last_data_query($job_name)
```
##### 参数
- job_name:  
    蜘蛛任务名

##### 返回值
查询出来的数据

##### 示例
```php
$last_data = spider_last_data_query('test');
```
