# 工作单元

工作单元是一个很好的封装持久化动作，简化业务代码，提高数据库使用效率、树立服务的数据管理边界的模式，当开启工作单元后，与工作单元同样系统编码的实体的增删改动作会被记录下来，在工作单元完成时会将这些数据变更持久化。






### 注册工作单元的系统编码
----
```php
string unit_of_work_db_config_key($config_key = null)
```
##### 参数
- config_key:  
    工作单元所属的数据库配置，可以不传

##### 返回值
工作单元所属的数据库配置 key

##### 示例
```php
unit_of_work_db_config_key('customer');
```











### 工作单元
----
```php
mix unit_of_work(Closure $action)
```
##### 参数
- action:  
    在工作单元中执行的逻辑闭包

##### 返回值
逻辑闭包的返回值

##### 示例
```php
$customer = unit_of_work(function () {
    return customer::create();
});
```










### 注册工作单元执行成功时的逻辑
----
```php
closure if_unit_of_work_executed($action = null)
```
##### 参数
- action:  
    在工作单元成功执行完毕后执行的逻辑闭包，不传时直接返回当前生效的逻辑闭包


##### 返回值
当前生效的闭包

##### 示例
```php
if_unit_of_work_executed(function () {
    queue_push('after_save');
});
```











### 注册工作单元执行被打断时的逻辑
----
```php
closure if_unit_of_work_disturbed($action = null)
```
##### 参数
- action:  
    在工作单元执行被打断时执行的逻辑闭包，不传时直接返回当前生效的逻辑闭包

##### 返回值
当前生效的闭包

##### 示例
```php
if_unit_of_work_disturbed(function () {
    queue_push('save_failed');
});
```
