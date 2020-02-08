# 断言

断言能力提供了简单实现防御式编程的能力，引用示例：
```php
include FRAME_DIR.'/otherwise.php';
```










### 断言
----
```php
otherwise($assertion, $description = 'assertion is not true', $exception_class_name = 'Exception', $exception_code = 0)
```
##### 参数
- assertion:  
    断言逻辑

- description:  
    当断言逻辑为 false 时，抛出的异常 message

- exception_class_name:  
    抛出的异常的类型

- exception_code:  
    抛出的异常的 code 值

##### 返回值
无

##### 示例
```php
otherwise($customer->is_not_null());
```
