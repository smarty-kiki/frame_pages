# 路由

frame 提供了一个与常规框架不同的路由机制，通常一个 URL 的路由，需要有 url、controller、action 三个命名起来非常啰嗦的东西，如订单的创建接口，通常会设计为：
```
URL:        /orders
Method:     PUT or POST
Controller: Order
Action:     create
```
以某框架为例：
```php
// router.php

Route::post('/orders', 'OrderController@create');

// controllers/OrderController.php

class OrderController extends BaseController
{
    public function create()
    {
        // do sth for order create
    }
}
```

使用 frame 这么实现
```php
// controller/order.php

if_post('/orders', function ()
{
    // do sth for order create
});
```

从 URL 中提取参数的时候，某框架示例：
```php
// router.php

Route::get('/posts/{postId}/comments/{commentId}', 'PostController@showComment');

// controllers/PostController.php

class PostController extends BaseController
{
    public function showComment($postId, $commentId)
    {
        // do sth for showing post comment
    }
}
```

使用 frame 这么实现
```php
// controller/post.php

if_get('/posts/*/comments/*', function ($post_id, $comment_id)
{
    // do sth for showing post comment
});
```
