# 日志

提供日志记录能力，统一管理不同类型日志对应的存储方案，框架中 `log` 目录下为基于不同组件的日志能力实现，使用时按需加载，示例：
```php
include FRAME_DIR.'/log/file.php';
```
组件使用时需要有对应的配置，示例：
```php
// config/log.php
return [
    'exception_path' => '/tmp/php_exception.log',
    'notice_path' => '/tmp/php_notice.log',
];
```


### 记录异常
----
```php
void log_exception(throwable $ex)
```
##### 参数
- ex:  
    具体要记录的异常对象

##### 返回值
无

##### 示例
```php
log_exception($ex);
```











### 记录提醒
----
```php
void log_notice($message)
```
##### 参数
- message:  
    需要记录的日志文字

##### 返回值
无

##### 示例
```php
log_notice($message);
```



















### 为模块记录日志
----
```php
void log_module($module, $message)
```
##### 参数
- module:  
    模块名

- message:  
    需要记录的日志文字

##### 返回值
无

##### 示例
```php
log_module('order', $message);
```
