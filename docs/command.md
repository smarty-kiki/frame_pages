# 命令行

本框架通过 `public/cli.php` 提供 CLI 命令支持，命令定义在 `command/` 目录，与 HTTP 路由类似——**命令即闭包**。配合命令行补全脚本，交互体验友好。

## 声明一个命令

命令文件放在 `command/` 下，在 `public/cli.php` 中 `include` 引入：

```php
<?php
// command/hello.php

command('hello', '打招呼', function () {
    return 'hello world' . PHP_EOL;
});
```

`command()` 的三个参数：规则（`命令名`）、描述（`--help` 时展示）、执行闭包。

```php
// public/cli.php
include COMMAND_DIR.'/hello.php';
```

执行：

```bash
php public/cli.php hello
# hello world
```

## command

```php
command($rule, $description, closure $action)
```

注册一个命令。`$rule` 为命令名（可含空格分段，如 `queue:worker`）；`$description` 为命令描述；`$action` 为执行闭包，其返回值会被输出。

```php
command('migrate', '执行迁移', function () {
    // ...
});
```

## 参数约定

CLI 参数遵循两种格式：

- `-x`：布尔开关，出现即为 `true`
- `--key=value`：字符串参数，通过 `command_paramater('key')` 读取

```bash
php public/cli.php queue:worker --tube=mail --config_key=queue --memory_limit=10485760
php public/cli.php migrate:dry-run -v
```

## command_paramater

```php
command_paramater($key, $default = null)
```

读取命令行参数。`--key=value` → `value`；`-key` → `true`；未传返回 `$default`。

```php
command('queue:pause', '暂停队列', function () {
    $tube  = command_paramater('tube');
    $delay = command_paramater('delay', 3600);
    queue_pause($tube, $delay);
});
```

## 命令不存在兜底

`command()` 注册命令时，如果当前输入的命令与规则不匹配，会把该命令的规则与描述**收集起来**；全部命令注册完毕后调用 `command_not_found()`（无参）触发兜底。

### if_command_not_found

```php
if_command_not_found(?closure $action = null)
```

注册「命令未匹配」时的兜底闭包（getter / setter）。触发时闭包收到两个数组参数：`$rules`（全部已注册命令名）与 `$descriptions`（对应描述）。`public/cli.php` 用它打印可用的命令列表：

```php
if_command_not_found(function ($rules, $descriptions) {
    echo "未匹配到命令，支持以下命令:\n";
    foreach ($rules as $num => $rule) {
        echo str_pad($rule, 50, ' ').$descriptions[$num]."\n";
    }
});
```

### command_not_found

```php
command_not_found(?string $rule = null, ?string $description = null)
```

- 传入 `$rule` / `$description`：**收集**一个命令的规则与描述（`command()` 内部对每个不匹配的命令调用）
- 无参调用：**触发**已注册的 `if_command_not_found` 闭包并退出，用于全部命令注册完毕后兜底

```php
// public/cli.php 末尾
command_not_found();   // 未匹配的命令 → 打印命令列表后退出
```

## 交互输入

以下函数用于在命令执行过程中向用户询问输入：

### command_read

```php
command_read($prompt, $default = true, array $options = [])
```

读取一行用户输入。`$prompt` 为提示文本，`$default` 为回车时的默认值。

- 传入 `$options` 时显示**编号菜单**并要求选择，直到输入合法选项为止，返回所选选项对应的值（`$options[$result]`）
- 不传 `$options` 时返回用户输入的字符串（回车返回 `$default`）

```php
$name = command_read('请输入用户名: ', '匿名用户');

$action = command_read('选择操作', 0, ['kick', 'delete']);   // 返回 'kick' 或 'delete'
```

### command_read_bool

```php
command_read_bool($prompt, $default = 'n')
```

读取 `y` / `n` 并转为布尔值。回车返回 `$default`（默认 `'n'`），循环直到输入合法。

```php
$confirm = command_read_bool('确定执行？', 'y');
if ($confirm) {
    // 执行
}
```

### command_read_completions

```php
command_read_completions(?closure $closure = null)
```

注册 **Tab 补全回调**的 getter / setter。回调接收 `$buffer_info`（`readline_info()` 返回的数组），返回补全候选项字符串数组。注册后 `_command_readline` 输入时按下 Tab 会调用它并过滤候选项。

```php
command_read_completions(function ($buffer_info) {
    return ['mail', 'sms', 'push'];
});
```

### _command_readline

```php
_command_readline($prompt)
```

带 Tab 补全的 readline 交互输入内部函数（`command_read` 底层使用）。

## CLI 补全

`after_env_start.sh` 会把 cli 补全脚本追加到 `~/.bashrc`，支持 Tab 补全命令名与 `--key` 参数（基于已注册的命令与参数定义生成）。

## 返回值约定

`command()` 匹配到命令后执行 `exit($action())`：

- 闭包返回**字符串** → 输出到 stdout 并以退出码 0 结束
- 闭包返回**数字** → 作为进程退出码
- 闭包内**抛异常**（含 `business_exception`）→ 作为未捕获异常向上抛，PHP 输出错误信息并以非零退出码结束

因此命令闭包内多用 `echo` 直接输出，需要中途退出时返回数字或直接 `exit(...)`。
