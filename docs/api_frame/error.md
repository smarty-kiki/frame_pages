# 错误

`api_frame` 中，在 `index.php` 处注册了全局的错误捕获 `handle`，如：
```php
set_error_handler('http_err_action', E_ALL);
set_exception_handler('http_ex_action');
register_shutdown_function('http_fatel_err_action');

if_has_exception(function ($ex) {

    log_exception($ex);

    return json([
        'succ' => false,
        'msg' => $ex->getMessage(),
    ]);
});
```

示例中将异常记录日志并返回了统一的响应 `json`
