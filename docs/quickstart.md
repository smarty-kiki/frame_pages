# 快速上手

以一个简单的用户模块为例，走完「新建路由 → 新建 Entity/DAO → 创建数据表 → 渲染页面」的完整流程。

## 1. 新建一个路由

在 `controller/` 下创建文件，例如 `controller/user.php`：

```php
<?php

if_get('/user/*', function ($user_id) {
    return dao('user')->find_by_id($user_id); // 返回实体 → JSON
});

if_post('/user', function () {
    $name = input('name');
    return user::create($name); // Entity 实现了 JsonSerializable → JSON
});

if_get('/user/list', function () {
    $users = dao('user')->find_all();
    return render('user/list', ['users' => $users]);  // render() 返回 HTML 字符串
});
```

然后在 `public/index.php` 中加入一行 `include`：

```php
include CONTROLLER_DIR.'/base.php';
include CONTROLLER_DIR.'/user.php';  // 新增
```

> 页面路由放在 `controller/` 下由 `public/index.php` 加载，只返回 HTML 字符串。
> 接口路由放在 `controller_api/` 下由 `public/api.php` 加载，路由以 `/api/` 开头，任意返回值统一包装成 `{code, msg, data}` JSON。详见[控制器](controller.md)。

## 2. 新建一个 Entity + DAO

**Entity**（`domain/entity/user.php`）：

```php
<?php

class user extends entity
{
    public $structs = [
        'name'   => '',
    ];

    public static function create(string $name): user
    {
        $user = parent::init();
        $user->name = $name;
        return $user;
    }
}
```

**DAO**（`domain/dao/user.php`）：

```php
<?php

class user_dao extends dao
{
    protected $table_name = 'user';
    protected $db_config_key = 'default';
}
```

**注册类映射**——运行一条命令即可：

```bash
sh project/tool/classmap.sh domain
```

该命令会扫描 `domain/` 目录下的类，重新生成 `domain/autoload.php`。

## 3. 创建数据库表

```bash
php public/cli.php migrate:make --name=create_user_table
```

自动生成的 SQL 文件为 `command/migration/sql/` 下带时间戳前缀的文件（如 `2026_08_19_10_30_00_create_user_table.sql`），内容：

```sql
# up
create table `user` (
    `id` bigint(20) not null,
    `version` int(11) not null default 0,
    `create_time` datetime not null,
    `update_time` datetime not null,
    `delete_time` datetime default null,
    `name` varchar(255) not null default '',
    primary key (`id`)
) engine=InnoDB default charset=utf8mb4;

# down
drop table `user`;
```

执行迁移：

```bash
php public/cli.php migrate
```

## 4. 渲染页面

创建模板 `view/user/list.php`：

```html
@include('layout/header')

<h1>用户列表</h1>

@foreach ($users as $user)
    <div>
        <span>{{ $user->name }}</span>
    </div>
@endforeach

@include('layout/footer')
```

在浏览器访问对应的页面路由即可看到渲染结果。
