# 对话

提供会话的能力，框架中 `dialogue` 目录下的文件为基于具体组件的实现，如 `beanstalk.php`，使用时按需要载入，示例：
```php
include FRAME_DIR.'/dialogue/beanstalk.php';
```
组件使用时会按照配置机制加载对应的组件配置，示例：
```php
// config/beanstalk.php
return [
    'midwares' => [
        'default' => 'local',
        'dialogue' => 'local',
    ],

    'resources' => [
        'local' => [
            'host' => '127.0.0.1',
            'port' => 11300,
            'timeout' => 1,
        ],
    ],
];
```











## 委托注册

### 注册需要发消息时会执行的逻辑
----
```php
closure dialogue_send_action(closure $action = null)
```
##### 参数
- action:
    发消息时被执行的逻辑闭包，调用时会接受到 user_id、content

##### 返回值
当前生效的逻辑闭包

##### 示例
```php
dialogue_send_action(function ($user_id, $content) {
    echo "@$user_id $content";
});
```











### 注册话题未匹配时会执行的逻辑
----
```php
closure dialogue_topic_miss_action(closure $action = null)
```
##### 参数
- action:
    发消息时被执行的逻辑闭包，调用时会接受到 user_id、content、time

##### 返回值
当前生效的逻辑闭包

##### 示例
```php
dialogue_topic_miss_action(function ($user_id, $content, $time) {
    echo "@$user_id 不懂'$content'";
});
```











### 话题处理结束后会执行的逻辑
----
```php
closure dialogue_topic_finish_action(closure $action = null)
```
##### 参数
- action:
    话题处理结束后被执行的逻辑闭包，调用时会接受到 user_id、content、time

##### 返回值
当前生效的逻辑闭包

##### 示例
```php
dialogue_topic_finish_action(function ($user_id, $content, $time) {
    echo "处理完成用户的会话";
});
```











### TODO
----
```php
TODO dialogue_topic_match_extension_action(closure $action = null)
```
##### 参数
- action:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_topic_match_extension_action(closure $action = null)
```











### TODO
----
```php
TODO dialogue_topics($topics = null)
```
##### 参数
- topics:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_topics($topics = null)
```











### TODO
----
```php
TODO dialogue_topic_match($content, $topic)
```
##### 参数
- content:
    TODO

- topic:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_topic_match($content, $topic)
```











### TODO
----
```php
TODO dialogue_push($user_id, $content, $is_sync = false, $delay = 0, $priority = 10, $config_key = 'default')
```
##### 参数
- user_id:
    TODO

- content:
    TODO

- is_sync:
    TODO

- delay:
    TODO

- priority:
    TODO

- config_key:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_push($user_id, $content, $is_sync = false, $delay = 0, $priority = 10, $config_key = 'default')
```











### TODO
----
```php
TODO dialogue_push_to_other_operator($message, $delay = 0, $priority = 10, $config_key = 'default')
```
##### 参数
- message:
    TODO

- delay:
    TODO

- priority:
    TODO

- config_key:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_push_to_other_operator($message, $delay = 0, $priority = 10, $config_key = 'default')
```











### TODO
----
```php
TODO dialogue_watch($config_key = 'default', $memory_limit = 1048576)
```
##### 参数
- config_key:
    TODO

- memory_limit:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_watch($config_key = 'default', $memory_limit = 1048576)
```











### TODO
----
```php
TODO dialogue_ask_and_wait($user_id, $ask, $pattern = null, $timeout = 60, $config_key = 'default')
```
##### 参数
- user_id:
    TODO

- ask:
    TODO

- pattern:
    TODO

- timeout:
    TODO

- config_key:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_ask_and_wait($user_id, $ask, $pattern = null, $timeout = 60, $config_key = 'default')
```











### TODO
----
```php
TODO dialogue_choice_and_wait($user_id, $ask, array $choice, $timeout, closure $action)
```
##### 参数
- user_id:
    TODO

- ask:
    TODO

- choice:
    TODO

- timeout:
    TODO

- action:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_choice_and_wait($user_id, $ask, array $choice, $timeout, closure $action)
```











### TODO
----
```php
TODO dialogue_form_and_wait($user_id, $ask, array $form, $timeout, closure $action)
```
##### 参数
- user_id:
    TODO

- ask:
    TODO

- form:
    TODO

- timeout:
    TODO

- action:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_form_and_wait($user_id, $ask, array $form, $timeout, closure $action)
```











### TODO
----
```php
TODO dialogue_topic($topic, closure $closure)
```
##### 参数
- topic:
    TODO

- closure:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_topic($topic, closure $closure)
```











### TODO
----
```php
TODO dialogue_say($user_id, $content)
```
##### 参数
- user_id:
    TODO

- content:
    TODO

##### 返回值
TODO

##### 示例
```php
TODO dialogue_say($user_id, $content)
```
