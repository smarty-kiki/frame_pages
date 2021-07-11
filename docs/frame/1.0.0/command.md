# 命令行

命令行能力提供了开发者开发命令行交互功能的简单函数，使用时直接加载 `command.php`，示例：
```php
include FRAME_DIR.'/command.php';
```










### 声明命令行能力
----
```php
void command($rule, $description, closure $action)
```
##### 参数
- rule:  
    命令行中带什么参数来执行这个命令，建议做一定的分组设计如 `test:hello-world`

- description:  
    对于该命令行逻辑的文字说明，可以在这里说明所需要的参数

- action:  
    该命令的逻辑

##### 返回值
无

##### 示例
```php
command('test:hello-world', '这是一个测试命令', function ()
{
    echo "hello world\n";
});
```











### 在 `command` 逻辑中获取命令行所带的参数
----
```php
mix command_paramater($key, $default = null)
```
##### 参数
- key:  
    在命令行中传的参数名，命令行传参时可以传 `boolean` 值，如 -echo_disabled 也可以传具体的字符、数字值，如 `--name=xxx`

- default:  
    如果没获取到的默认值

##### 返回值
获取到的参数值

##### 示例
```php
$echo_disabled = command_paramater('echo_disabled', false);
// 或
$name = command_paramater('name', 'demo');
```











### 注册如果没有对应参数的命令逻辑时执行的逻辑
----
```php
closure if_command_not_found(closure $action = null)
```
##### 参数
- action:  
    未命中对应命令的逻辑时执行的逻辑闭包, 该闭包在执行时会被传入所有已注册的命令参数、命令说明

##### 返回值
当前生效的逻辑闭包

##### 示例
```php
if_command_not_found(function ($rules, $descriptions) {
    echo "未匹配到命令，支持以下命令:\n";
    foreach ($rules as $num => $rule) {
        echo str_pad($rule, 50, ' ').$descriptions[$num]."\n";
    }
});
```











### 声明未命中命令
----
```php
void command_not_found($rule = null, $description = null)
```
##### 参数
- rule:  
    用户声明时不需要传参，在框架调用时会传入未命中的命令参数

- description:  
    用户声明时不需要传参，在框架调用时会传入未命中的命令说明

##### 返回值
无

##### 示例
```php
command_not_found();
```











### 在命令逻辑中与用户交互等待用户输入
----
```php
$mix = command_read($prompt, $default = true, array $options = [])
```
##### 参数
- prompt:  
    与用户交互时显示给用户的文字

- default:  
    用户直接键入回车时的默认值

- options:  
    如果传入该值，会约束用户输入的选择范围，用户只能输入 `options` 数组中的 `key`

##### 返回值
用户的输入，如果传入了 `options`，返回值为用户选择的值

##### 示例
```php
$name = command_read('你叫啥', '你猜');
// 或
$sex = command_read('性别', 0, ['男', '女', '其他']);
```








### 注册补全闭包，当在命令逻辑中用 `command_read` 获取用户输入，用户按 `tab` 补全时执行
----
```php
closure command_read_completions(closure $closure = null)
```
##### 参数
- closure:  
    当用户按 `tab` 补全时执行的闭包

##### 返回值
当前生效的逻辑闭包

##### 示例
```php
command_read_completions(function () {
    return ['hello', 'world'];
});
```








### 在命令逻辑中与用户交互等待用户输入 `boolean` 值
----
```php
boolean command_read_bool($prompt, $default = 'n')
```
##### 参数
- prompt:  
    与用户交互时显示给用户的文字

- default:  
    用户直接按回车时的默认值，可传 `y` 或者 `n`

##### 返回值
`boolean` 值

##### 示例
```php
$is_ok = command_read_bool('are you ok', $default = 'n');
```
