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

在模板内部包含另一个模板（等价 `@include`），复用布局与片段。

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

编译指定模板文件（相对视图根目录），返回编译后的 PHP 代码。`render()` 内部调用。

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
- `view_compiler()` 读取 / 设置渲染时使用的编译器

## Blade 语法

### 输出

输出变量（已自动转义 HTML，防 XSS）：

```blade
{{ $name }}
```

带默认值输出（变量为空时输出默认值）：

```blade
{{ $name or '游客' }}
```

原样输出（不转义，慎用——输出用户输入会 XSS）：

```blade
{{{ $html }}}
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
@include('layout/footer', ['title' => '首页'])
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
- 生产环境 `compiled_cache => true`，编译结果写入 `view/blade/` 缓存文件，`after_push.sh` 会清理编译缓存
