# 控制器

我们需要声明控制器来响应指定请求，在 `frame` 框架中，控制器与路由是同时出现的。控制器文件可以统一放在 `controller` 文件夹下，在 `public/index.php` 中指定位置引入：
```php
// controller/index.php

if_get('/', function ()
{
    return 'hello world';
});

// public/index.php

include CONTROLLER_DIR.'/index.php';
```

### 自动 json 化
在 `api_frame` 中，已经定义了 `if_verify`、`if_has_exception` 逻辑，整个项目都会以如下格式返回 `json` 内容：
```json
{
  "code": 0,  // 异常码
  "msg" : "", // 异常消息
  "data": "", // controller 返回内容的 json 结构
}
```
所以上述示例在 `api_frame` 会返回如下内容：
```json
{
  "code": 0,
  "msg" : "",
  "data": "hello world"
}
```
`controller` 的闭包中如果需要返回 `json` 格式，无需转换，框架会自动将内容 `json` 化，如：
```php
if_get('/', function ()
{
    return [
        'id' => 1,
    ];
});
```
返回值为：
```json
{
  "code": 0,
  "msg" : "",
  "data": {
    "id": 1
  }
}
```

### 框架已经提供的接口

#### /health_check
框架默认提供的健康检查接口，该接口会返回：
```json
{
  "code": 0,
  "msg": "",
  "data": "ok"
}
```

#### /error_code_maps
框架默认提供的获取错误码字典的接口，该接口会返回：
```json
{
  "code": 0,
  "msg": "",
  "data": [
      "ERROR_CODE_SAMPLE": "样例错误码说明文字"
  ]
}
```