# 辅助函数

辅助函数提供了一些通用的工具函数，框架中很多组件依赖于此文件，加载示例：
```php
include FRAME_DIR.'/function.php';
```










### 从数组中获取某个值
----
```php
mix array_get($array, $key, $default = null)
```
##### 参数
- array:  
    目标数组

- key:  
    要获取的 array key，因 array 是多层、多维的，key 可以用点符号来表达多层、多维逻辑、如 data.name

- default:  
    如果没有对应的值返回的默认值，可以是闭包，会以闭包的返回值作为默认值，在没有对应的值时才会被执行

##### 返回值
目标值

##### 示例
```php
$name = array_get($data, 'base_info.name', '无名');
```











### 在数组指定位置设置值
----
```php
array array_set($array, $key, $value)
```
##### 参数
- array:  
    被设置的数组

- key:  
    要设置的 array key，因 array 是多层、多维的，key 可以用点符号来表达多层、多维逻辑、如 data.name

- value:  
    要设置的值

##### 返回值
设置值后的新数组

##### 示例
```php
$new_data = array_set($data, 'data.name', 'kiki');
```











### 检查数组中某个 key 是否存在
----
```php
boolean array_exists($array, $key)
```
##### 参数
- array:  
    要检查的数组

- key:  
    要检查的 array key，因 array 是多层、多维的，key 可以用点符号来表达多层、多维逻辑、如 data.name

##### 返回值
boolean

##### 示例
```php
$has_name = array_exists($array, 'data.name');
```











### 去掉数组中的某个值
----
```php
void array_forget(&$array, $keys)
```
##### 参数
- array:  
    目标数组

- keys:  
    要去掉的 array key，因 array 是多层、多维的，key 可以用点符号来表达多层、多维逻辑、如 data.name，key 可以是多个

##### 返回值
无

##### 示例
```php
array_forget($array, 'data.name');
// 或
array_forget($array, ['data.name', 'data.age']);
```











### 获取数组的 keys 和 values
----
```php
array array_divide($array)
```
##### 参数
- array:  
    目标数组

##### 返回值
keys 和 values 的数组

##### 示例
```php
list($keys, $values) =  array_divide($array);
```











### 基于数组构建数组
----
```php
array array_build($array, Closure $callback)
```
##### 参数
- array:  
    来源数组

- callback:  
    构建逻辑的闭包，执行时会给闭包传入数组中的 key、value，闭包需要返回结果数组的 key、value

##### 返回值
数组

##### 示例
```php
$res_array =  array_build($array, function ($key, $value) {
    return [$key, $value];
});
```










### 基于数组构建两层索引结构的数组
----
```php
array array_indexed($array, Closure $callback)
```
##### 参数
- array:  
    来源数组

- callback:  
    构建逻辑的闭包，执行时会给闭包传入数组中的 key、value，闭包需要返回结果数组的 index、key、value

##### 返回值
数组

##### 示例
```php
$res_array =  array_indexed($array, function ($key, $value) {
    return [$value['index_key'], $key, $value];
});
```












### 递归 ksort
----
```php
array array_key_sort($array)
```
##### 参数
- array:  
    待排序的数组

##### 返回值
排好序的数组

##### 示例
```php
$res_array =  array_key_sort($array);
```











### 从数组中获取多个值，array_get 的批量版，通常配合 list 使用
----
```php
array array_list(array $array, array $keys)
```
##### 参数
- array:  
    来源数组

- keys:  
    要获取的 array key 数组，因 array 是多层、多维的，key 可以用点符号来表达多层、多维逻辑、如 data.name

##### 返回值
获取到的值数组

##### 示例
```php
list($name, $age) = array_list($array, ['data.name', 'data.age',]);
```











### 数组转换
----
```php
array array_transfer(array $array, array $rules)
```
##### 参数
- array:  
    来源数组

- rules:  
    rules 学问大，rules 是一个转换关系的描述数组，如：
    ```php
    $rules = [
        'data.name' => 'info.name',
        'data.age'  => 'info.age',
    ];
    ```
    rules 的 key 为从来源数组哪里取值，对应的 value 为存在结果数组的哪个位置

##### 返回值
转换后的数组

##### 示例
```php
$res_array = array_transfer($array, [
    'data.name' => 'info.name',
    'data.age'  => 'info.age',
]);
```











### 字符串尾部省略
----
```php
string str_tail_cut($string, $len, $suffix = '...')
```
##### 参数
- string:  
    目标字符串

- len:  
    最终限制到的长度

- suffix:  
    省略符号

##### 返回值
满足限制长度的字符串

##### 示例
```php
$subtitle = str_tail_cut($subtitle, 20);
```











### 字符串头部省略
----
```php
string str_head_cut($string, $len, $prefix = '...')
```
##### 参数
- string:  
目标字符串

- len:  
最终限制到的长度

- prefix:  
省略符号

##### 返回值
满足限制长度的字符串

##### 示例
```php
$subtitle = str_head_cut($subtitle, 20);
```











### 字符串中部省略
----
```php
string str_middle_cut($string, $len, $middle = '...')
```
##### 参数
- string:  
目标字符串

- len:  
最终限制到的长度

- middle:  
省略符号

##### 返回值
满足限制长度的字符串

##### 示例
```php
$subtitle = str_middle_cut($subtitle, 20);
```











### var_dump 并且 die
----
```php
void dd(...$args)
```
##### 参数
- ...args:  
    可传多个参数，类型不限，会按照参数顺序 var_dump 出来

##### 返回值
无，但是会直接输出出来

##### 示例
```php
dd($params, $this);
```













### 抛出异常并立刻捕获，输出到异常日志中，方便查看逻辑执行的调用链路等
----
```php
void trace($message = 'exception for trace')
```
##### 参数
- message:  
    打印到异常日志中可方便区分或者检索的关键词

##### 返回值
无，但是会直接输出至异常日志中

##### 示例
```php
trace();
```









### 获取变量的值，如果变量是一个闭包，会执行它并返回闭包中的返回值
----
```php
mix value($value)
```
##### 参数
- value:  
    可传某个值，也可以传一个闭包

##### 返回值
传入的值或者闭包的执行结果

##### 示例
```php
value($config['display_name']);
```











### 获取某个闭包的唯一标识，建议不要硬编码判断闭包的标识，因为唯一标识中也含有闭包定义所在的文件及行范围，相关变化也会改变闭包的标识，需注意
----
```php
string closure_id($closure)
```
##### 参数
- closure:  
    闭包

##### 返回值
闭包的唯一标识

##### 示例
```php
$id = closure_id($closure)
```











### 判断字符串是否以某个字符串开始
----
```php
boolean starts_with($haystack, $needles)
```
##### 参数
- haystack:  
    判断该变量字符串是否以指定字符串开头

- needles:  
    作为判断依据的开头字符串，也可以传入数组，传入为数组时匹配任意一个返回值即为 true

##### 返回值
是否以指定字符串开头的 boolean 值

##### 示例
```php
if (starts_with($post, '亲，')) {
    echo '淘宝体';
}
```











### 判断字符串是否以某个字符串结尾
----
```php
boolean ends_with($haystack, $needles)
```
##### 参数
- haystack:  
    判断该变量字符串是否以指定字符串结尾

- needles:  
    作为判断依据的结尾字符串，也可以传入数组，传入为数组时匹配任意一个返回值即为 true

##### 返回值
是否以指定字符串结尾的 boolean 值

##### 示例
```php
if (ends_with($post, '?')) {
    echo '疑问句';
}
```











### 确保字符串以指定字符串结尾，如果已经是以指定字符串结尾则不会被改变
----
```php
string str_finish($value, $cap)
```
##### 参数
- value:  
    被操作的字符串

- cap:  
    指定的结尾字符串

##### 返回值
处理后的字符串

##### 示例
```php
echo str_finish('真棒', '!');   // 真棒!
echo str_finish('真棒!', '!');  // 真棒!
```











### 确保字符串以指定字符串开头，如果已经是以指定字符串开头则不会被改变
----
```php
string str_begin($value, $cap)
```
##### 参数
- value:  
    被操作的字符串

- cap:  
    指定的开头字符串

##### 返回值
处理后的字符串

##### 示例
```php
echo str_begin('亲，您好', '亲，');   // 亲，您好
echo str_begin('您好', '亲，');  // 亲，您好
```











### 判断某个字符串是否是 URL
----
```php
boolean is_url($path)
```
##### 参数
- path:  
    被判断的字符串

##### 返回值
判断结果

##### 示例
```php
if (is_url($path)) {
     echo '是 URL';
}
```











### 指定配置文件根目录
----
```php
string config_dir($dir = null)
```
##### 参数
- dir:  
    配置文件根目录

##### 返回值
当前生效的配置文件根目录

##### 示例
```php
config_dir(FRAME_DIR.'/config');
```











### 获取指定的配置
----
```php
array config($key)
```
##### 参数
- key:  
    配置名

##### 返回值
符合当前环境的配置

##### 示例
```php
$config = config('mysql');
```











### 获取当前环境名
----
```php
string env()
```
##### 参数
##### 返回值
当前环境名

##### 示例
```php
$env = env();
```











### 判断当前环境是否是传入的环境
----
```php
boolean is_env($env)
```
##### 参数
- env:  
    环境名

##### 返回值
判断结果

##### 示例
```php
if (is_env('production')) {
    echo '线上环境';
}
```











### 不为空
----
```php
boolean not_empty($mixed)
```
##### 参数
- mixed:  
    被判断的变量

##### 返回值
判断结果

##### 示例
```php
if (not_empty($mixed)) {
    echo '不为空';
}
```











### 不为 null
----
```php
boolean not_null($mixed)
```
##### 参数
- mixed:  
    被判断的变量

##### 返回值
判断结果

##### 示例
```php
if (not_null($mixed)) {
    echo '不为 null';
}
```











### 传入的所有变量都为空
----
```php
boolean all_empty(...$args)
```
##### 参数
- ...args:  
    要被判断的变量，可以传多个参数

##### 返回值
判断结果

##### 示例
```php
if (all_empty($a, $b, $c)) {
    echo '都为空';
}
```











### 传入的所有变量都为 null
----
    ```php
boolean all_null(...$args)
    ```
##### 参数
- ...args:  
    要被判断的变量，可以传多个参数

##### 返回值
判断结果

##### 示例
```php
if (all_null($a, $b, $c)) {
    echo '都为 null';
}
```











### 传入的所有变量都不为空
----
```php
boolean all_not_empty(...$args)
```
##### 参数
- ...args:  
    要被判断的变量，可以传多个参数

##### 返回值
判断结果

##### 示例
```php
if (all_not_empty($a, $b, $c)) {
    echo '都不为空';
}
```











### 传入的所有变量都不为 null
----
    ```php
boolean all_not_null(...$args)
    ```
##### 参数
- ...args:  
    要被判断的变量，可以传多个参数

##### 返回值
判断结果

##### 示例
```php
if (all_not_null($a, $b, $c)) {
    echo '都不为 null';
}
```











### 有为空的值
----
```php
boolean has_empty(...$args)
```
##### 参数
- ...args:  
    要被判断的变量，可以传多个参数

##### 返回值
判断结果

##### 示例
```php
if (has_empty($a, $b, $c)) {
    echo '有空值';
}
```











### 有为 null 的值
----
    ```php
boolean has_null(...$args)
    ```
##### 参数
- ...args:  
    要被判断的变量，可以传多个参数

##### 返回值
判断结果

##### 示例
```php
if (has_null($a, $b, $c)) {
    echo '有空值';
}
```











### 获取一个时间  
----
```php
string datetime($expression = null, $format = 'Y-m-d H:i:s')
```
##### 参数
- expression:  
    关于所需要时间的描述，可以为 null，也可以是时间戳，也可以是一个相对时间的描述语句

- format:  
    返回的时间的格式

##### 返回值
时间字符串

##### 示例
```php
$now = datetime();
$the_time = datetime(1514736000);  // 2015-01-01 00:00:00
$tomorrow_this_time = datetime('+1 days'); // 明天此刻
$last_friday = datetime('last friday'); // 不含今天的上一个周五 0 点
$friday = datetime('friday'); // 含今天的下一个周五，即如果今天为周五返回为今天 0 点
$next_friday = datetime('next friday'); // 不含今天的下一个周五，即如今天为周五，则为下周五 0 点
$next_friday_noon = datetime('next friday 12:00:00'); // 不含今天的下一个周五，即如今天为周五，则为下周五 12 点
```











### 计算并生成时间差异字符串
----
```php
mix datetime_diff($datetime1, $datetime2, $format = '%ts')
```
##### 参数
- datetime1:  
    时间1

- datetime2:  
    时间2

- format:  
格式字符串是对返回值格式的描述，其中的变量[参考这里](http://php.net/manual/en/dateinterval.format.php#refsect1-dateinterval.format-parameters)，在官方基础上又添加了`ts`总差异描述，`tm`总差异分钟数（秒差异舍去），`th`总差异小时数（分、秒差异舍去）`td`总差异天数（时、分、秒差异舍去）

##### 返回值
按照`format`的格式计算出来的差异字符串

##### 示例
```php
$description = datetime_diff($datetime1, $datetime2, '共差 %ts 秒');
$interval_second = datetime_diff($datetime1, $datetime2);
```











### 远程 POST 请求
----
```php
mix remote_post($url, $data = [], $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    请求的目标地址

- data:  
    要传的值，支持字符串和数组两个类型，为字符串时会直接通过 http body 传过去，为数组时会按照 form 格式传过去

- timeout:  
    多久放弃等待结果，单次重试的时间

- retry:  
    [curl 错误码](https://curl.haxx.se/libcurl/c/libcurl-errors.html)不为 0 时的请求重试次数

- headers:  
    header 数组，如
    ```php
    ['Content-type: text/plain', 'Content-length: 100']
    ```

- cookies:  
    键值对数组

##### 返回值
远程请求后的结果，通讯失败为 false

##### 示例
```php
$html = remote_post($url);
```











### 远程 POST 请求，返回结果为 json
----
```php
mix remote_post_json($url, $data = [], $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    请求的目标地址

- data:  
    要传的值，支持字符串和数组两个类型，为字符串时会直接通过 http body 传过去，为数组时会按照 form 格式传过去

- timeout:  
    多久放弃等待结果，单次重试的时间

- retry:  
    [curl 错误码](https://curl.haxx.se/libcurl/c/libcurl-errors.html)不为 0 时的请求重试次数

- headers:  
    header 数组，如
    ```php
    ['Content-type: text/plain', 'Content-length: 100']
    ```

- cookies:  
    键值对数组

##### 返回值
远程请求后的结果数组，通讯失败为 false

##### 示例
```php
$res = remote_post_json($url)
```











### 远程 POST 请求，返回结果为 xml
----
```php
mix remote_post_xml($url, $data = [], $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    请求的目标地址

- data:  
    要传的值，支持字符串和数组两个类型，为字符串时会直接通过 http body 传过去，为数组时会按照 form 格式传过去

- timeout:  
    多久放弃等待结果，单次重试的时间

- retry:  
    [curl 错误码](https://curl.haxx.se/libcurl/c/libcurl-errors.html)不为 0 时的请求重试次数

- headers:  
    header 数组，如
    ```php
    ['Content-type: text/plain', 'Content-length: 100']
    ```

- cookies:  
    键值对数组

##### 返回值
远程请求后的结果数组，通讯失败为 false

##### 示例
```php
$res = remote_post_xml($url)
```











### 远程 GET 请求
----
```php
mix remote_get($url, $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    请求的目标地址

- timeout:  
    多久放弃等待结果，单次重试的时间

- retry:  
    [curl 错误码](https://curl.haxx.se/libcurl/c/libcurl-errors.html)不为 0 时的请求重试次数

- headers:  
    header 数组，如
    ```php
    ['Content-type: text/plain', 'Content-length: 100']
    ```

- cookies:  
    键值对数组

##### 返回值
远程请求后的结果数组，通讯失败为 false

##### 示例
```php
$html = remote_get($url);
```











### 远程 GET 请求，返回结果为 json
----
```php
mix remote_get_json($url, $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    请求的目标地址

- timeout:  
    多久放弃等待结果，单次重试的时间

- retry:  
    [curl 错误码](https://curl.haxx.se/libcurl/c/libcurl-errors.html)不为 0 时的请求重试次数

- headers:  
    header 数组，如
    ```php
    ['Content-type: text/plain', 'Content-length: 100']
    ```

- cookies:  
    键值对数组

##### 返回值
远程请求后的结果数组，通讯失败为 false

##### 示例
```php
$res = remote_get_json($url);
```











### 远程 GET 请求，返回结果为 xml
----
```php
mix remote_get_xml($url, $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    请求的目标地址

- timeout:  
    多久放弃等待结果，单次重试的时间

- retry:  
    [curl 错误码](https://curl.haxx.se/libcurl/c/libcurl-errors.html)不为 0 时的请求重试次数

- headers:  
    header 数组，如
    ```php
    ['Content-type: text/plain', 'Content-length: 100']
    ```

- cookies:  
    键值对数组

##### 返回值
远程请求后的结果数组，通讯失败为 false

##### 示例
```php
$res = remote_get_xml($url);
```











### 获取单例
----
```php
object instance($class_name)
```
##### 参数
- class_name:  
    要获取单例的类名

##### 返回值
单例对象

##### 示例
```php
$obj = instance('stdClass');
```











### json 构造方法
----
```php
string json($data = [])
```
##### 参数
- data:  
    要被转换为 json 的数据

##### 返回值
json 字符串

##### 示例
```php
$res = json($data);
```
