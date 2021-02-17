# 断言

断言能力提供了简单实现防御式编程的能力，使用时按需要载入，示例：
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
    断言逻辑，注意，这里描述的是应该怎样，即，为 `true` 时断言通过，否则拦截

- description:
    当断言逻辑为 `false` 时，抛出的异常 `message`

- exception_class_name:
    抛出的异常的类型

- exception_code:
    抛出的异常的 `code` 值

##### 返回值
无

##### 示例
```php
otherwise($customer->is_not_null());
```














### 断言结合错误码
----
如果使用结合错误码的断言时，会按照配置机制加载 `error_code` 配置，配置的格式可以参考：

```php
return [
    '10001' => '这是一个示例错误，:replace',
];
```

方法说明：
```php
otherwise_error_code($error_code, $assertion, array $replace_contents = [])
```
##### 参数
- error_code:
    当断言逻辑为 `false` 时，抛出的异常的 `code` 值，通过读取配置来生成异常的 `message`

- assertion:
    断言逻辑，注意，这里描述的是应该怎样，即，为 `true` 时断言通过，否则拦截

- replace_contents:
    当配置中的异常 `message` 内容中有可动态改变部分时，通过传入对应的替换数组来让 `message` 可以动态化

##### 返回值
无

##### 示例
```php
otherwise_error_code(10001, $customer->is_not_null(), [
  ':replace' => '这里可被替换',
]);
```
