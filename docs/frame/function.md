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
    如果没有对应的值返回的默认值

##### 返回值
目标值

##### 示例
```php
$name = array_get($data, 'base_info.name', '无名');
```











### 在数组指定位置设置值
----
```php
void array_set(&$array, $key, $value)
```
##### 参数
- array:  
    被设置的数组

- key:  
    要设置的 array key，因 array 是多层、多维的，key 可以用点符号来表达多层、多维逻辑、如 data.name

- value:  
    要设置的值

##### 返回值
无

##### 示例
```php
array_set($data, 'data.name', 'kiki');
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











### 从数组中遍历获取某个值
----
```php
array array_fetch($array, $key)
```
##### 参数
- array:  
    目标数组

- key:  
    要获取的 array key，因 array 是多层、多维的，key 可以用点符号来表达多层、多维逻辑、如 data.name

##### 返回值
要获取的值的数组

##### 示例
```php
$array = [
    [
        'data' => ['name' => 'kiki'],
    ],
    [
        'data' => ['name' => 'kiki'],
    ],
];
$names = array_fetch($array, 'data.name');
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











### TODO
----
```php
TODO aksort(&$array, $valrev = false, $keyrev = false)
```
##### 参数
- array:  
    TODO

- valrev:  
    TODO

- keyrev:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO aksort(&$array, $valrev = false, $keyrev = false)
```











### TODO
----
```php
TODO str_cut($string, $len, $suffix = '...')
```
##### 参数
- string:  
    TODO

- len:  
    TODO

- suffix:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO str_cut($string, $len, $suffix = '...')
```











### TODO
----
```php
TODO dd(...$args)
```
##### 参数
- args:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dd(...$args)
```











### TODO
----
```php
TODO value($value)
```
##### 参数
- value:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO value($value)
```











### TODO
----
```php
TODO closure_name($closure)
```
##### 参数
- closure:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO closure_name($closure)
```











### TODO
----
```php
TODO starts_with($haystack, $needles)
```
##### 参数
- haystack:  
    TODO

- needles:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO starts_with($haystack, $needles)
```











### TODO
----
```php
TODO ends_with($haystack, $needles)
```
##### 参数
- haystack:  
    TODO

- needles:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO ends_with($haystack, $needles)
```











### TODO
----
```php
TODO str_finish($value, $cap)
```
##### 参数
- value:  
    TODO

- cap:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO str_finish($value, $cap)
```











### TODO
----
```php
TODO is_url($path)
```
##### 参数
- path:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO is_url($path)
```











### TODO
----
```php
TODO config_dir($dir = null)
```
##### 参数
- dir:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO config_dir($dir = null)
```











### TODO
----
```php
TODO config($key)
```
##### 参数
- key:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO config($key)
```











### TODO
----
```php
TODO env()
```
##### 参数
##### 返回值
TODO

##### 示例
```php
TODO env()
```











### TODO
----
```php
TODO is_env($env)
```
##### 参数
- env:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO is_env($env)
```











### TODO
----
```php
TODO not_empty($mixed)
```
##### 参数
- mixed:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO not_empty($mixed)
```











### TODO
----
```php
TODO not_null($mixed)
```
##### 参数
- mixed:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO not_null($mixed)
```











### TODO
----
```php
TODO all_empty(...$args)
```
##### 参数
- args:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO all_empty(...$args)
```











### TODO
----
```php
TODO all_not_empty(...$args)
```
##### 参数
- args:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO all_not_empty(...$args)
```











### TODO
----
```php
TODO has_empty(...$args)
```
##### 参数
- args:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO has_empty(...$args)
```











### TODO
----
```php
TODO datetime($expression = null, $format = 'Y-m-d H:i:s')
```
##### 参数
- expression:  
    TODO

- format:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO datetime($expression = null, $format = 'Y-m-d H:i:s')
```











### TODO
----
```php
TODO datetime_diff($datetime1, $datetime2, $format = '%ts')
```
##### 参数
- datetime1:  
    TODO

- datetime2:  
    TODO

- format:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO datetime_diff($datetime1, $datetime2, $format = '%ts')
```











### TODO
----
```php
TODO remote_post($url, $data = [], $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    TODO

- data:  
    TODO

- timeout:  
    TODO

- retry:  
    TODO

- headers:  
    TODO

- cookies:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO remote_post($url, $data = [], $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```











### TODO
----
```php
TODO remote_post_json($url, $data = [], $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    TODO

- data:  
    TODO

- timeout:  
    TODO

- retry:  
    TODO

- headers:  
    TODO

- cookies:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO remote_post_json($url, $data = [], $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```











### TODO
----
```php
TODO remote_get($url, $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    TODO

- timeout:  
    TODO

- retry:  
    TODO

- headers:  
    TODO

- cookies:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO remote_get($url, $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```











### TODO
----
```php
TODO remote_get_json($url, $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```
##### 参数
- url:  
    TODO

- timeout:  
    TODO

- retry:  
    TODO

- headers:  
    TODO

- cookies:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO remote_get_json($url, $timeout = 3, $retry = 3, array $headers = [], array $cookies = [])
```











### TODO
----
```php
TODO instance($class_name)
```
##### 参数
- class_name:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO instance($class_name)
```











### TODO
----
```php
TODO json($data = [])
```
##### 参数
- data:  
    TODO

##### 返回值
TODO

##### 示例
```php
TODO json($data = [])
```
