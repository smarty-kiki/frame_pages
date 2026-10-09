# 视图

本框架内置一个**轻量 Blade 模板引擎**：模板文件放在 `view/` 目录，以 `.php` 结尾，支持 `{{ }}` 输出、`@if` / `@foreach` 等指令与 `@include` 布局复用。渲染入口是 `render()`，模板编译由 `view_blade.php` 提供。

## 渲染入口

### render

```php
render(string $view, array $args = [])
```

渲染模板并返回 HTML 字符串。`$view` 为相对视图根目录的路径（不含 `.php`），`$args` 为注入模板的变量。页面入口直接 `return render(...)` 输出。

```php
if_get('/user/list', function () {
    return render('user/list', ['users' => dao('user')->find_all()]);
});
```

### include_view

```php
include_view(string $view, array $args = [])
```

直接 `include` 视图文件（**不做 Blade 编译**），`$args` 经 `extract` 注入变量。适用于片段本身是原生 PHP 的场景；模板内复用需要编译的片段请用 `@include`（见下文）。

```php
<!-- view/index.php -->
<?php include_view('layout/header'); ?>
```

### blade

```php
blade($template)
```

把一段模板字符串编译成 PHP 代码（**不执行**）。返回编译后的 PHP 字符串，可自行 `eval` 或检查。

```php
$code = blade('Hello, {{ $name }}!');
```

### blade_eval

```php
blade_eval($template, $args = [])
```

编译并执行模板字符串，返回渲染结果。适合动态模板（如短信/邮件正文模板）。

```php
$html = blade_eval('你好，{{ $name }}', ['name' => '张三']);
```

### blade_view_compiler

```php
blade_view_compiler($view)
```

编译指定模板文件（相对视图根目录），返回**可 `include` 的路径**：编译缓存开启时把编译结果写入缓存文件（`config/blade.php` 的 `compiled_path`）并返回该路径；关闭时写入 `blade://` stream 包装器并返回流路径。`render()` 内部调用。

### blade_view_compiler_generate

```php
blade_view_compiler_generate()
```

返回一个「模板编译闭包」，供 `view_compiler()` 注册。框架在 `public/index.php` 中已注册：

```php
view_compiler(blade_view_compiler_generate());
```

## view_path / view_compiler

```php
view_path(?string $path = null): string
view_compiler(?closure $closure = null): ?closure
```

- `view_path()` 读取 / 设置视图根目录（见[响应](response.md)）
- `view_compiler()` 读取 / 设置渲染时使用的编译器；未注册时默认按 `view_path().$view.'.php'` 直接 `include`（纯 PHP 文件也能当模板渲染）

## Blade 语法

### 输出

原样输出（**不转义**——直接输出用户输入有 XSS 风险）：

```blade
{{ $name }}
```

转义输出（`htmlentities` + `ENT_QUOTES`，防 XSS，输出用户内容用它）：

```blade
{{{ $user_input }}}
```

带默认值输出（变量未设置时输出右侧值）：

```blade
{{ $name or '游客' }}
```

原样输出 Blade 代码（不编译，如文档示例）：

```blade
@{{ $name }}
```

### 控制流

条件判断：

```blade
@if ($age >= 18)
    成年
@elseif ($age >= 6)
    未成年
@else
    儿童
@endif
```

取反判断：

```blade
@unless ($is_vip)
    不是会员
@endunless
```

循环：

```blade
@foreach ($users as $user)
    {{ $user->name }}
@endforeach
```

```blade
@for ($i = 0; $i < 10; $i++)
    第 {{ $i }} 次
@endfor
```

```blade
@while ($page < 10)
    {{ $page }}
@endwhile
```

### 包含

```blade
@include('layout/header')
@include('layout/footer')
```

`@include` 只接模板路径（括号 + 引号，相对 `view/`、不带 `.php`），**不支持传数据数组**；被引入模板自动继承当前作用域的全部变量（含 `render()` 传入的与父模板已赋值的）。需要专属变量时在 `@include` 前用 `@php` 赋值：

```blade
@php $title = '首页'; @endphp
@include('layout/footer')
```

### 原生 PHP

```blade
@php
    $total = array_sum(array_column($orders, 'amount'));
@endphp
```

### 注释

```blade
{{-- 这行注释不会输出到 HTML --}}
```

## 模板目录约定

```
view/
├── index/        # 页面模板
├── error/        # 404.php / 500.php
├── layout/       # 公共布局（header/footer/pagination 约定）
└── blade/        # 编译缓存（自动生成，勿手动编辑）
```

- 开发环境 `config/development/blade.php` 设置 `compiled_cache => false`，模板每次实时编译（改模板即生效）
- 生产 / 测试环境 `compiled_cache => true`（默认），编译结果写入 `compiled_path`（`view/blade/`），文件名 = 模板路径把 `/` 换成 `-`（如 `index-index.blade.php`）；缓存**只判断文件是否存在**、不比对模板更新时间，模板改动后必须清掉缓存才生效（`after_push.sh` 会自动清理）
