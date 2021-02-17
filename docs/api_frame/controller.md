# 控制器

我们需要声明控制器来响应指定请求，在 `frame` 框架中，控制器与路由是同时出现的。控制器文件可以统一放在 `controller` 下，在 `public/index.php` 中指定位置引入：
```php
// controller/index.php

if_get('/', function ()
{
    return 'hello world';
});

// public/index.php

include CONTROLLER_DIR.'/index.php';
```
