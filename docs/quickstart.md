# 快速上手

以一个简单的用户模块为例，走完「新建路由 → 新建 Entity/DAO → 创建数据表 → 渲染页面」的完整流程。

## 1. 新建一个路由

接口路由放在 `controller_api/` 下，例如 `controller_api/user.php`：

```php
<?php

if_get('/api/user/*', function ($user_id) {
    return dao('user')->find_by_id($user_id); // 返回实体 → JSON
});

if_post('/api/user', function () {
    $name = input('name');
    return user::create($name); // Entity 实现了 JsonSerializable → JSON
});
```

页面路由放在 `controller/` 下，例如 `controller/user.php`：

```php
<?php

if_get('/user/list', function () {
    $users = dao('user')->find_all();
    return render('user/list', ['users' => $users]);  // render() 返回 HTML 字符串
});
```

然后在对应入口文件中各加一行 `include`：

```php
// public/index.php
include CONTROLLER_DIR.'/base.php';
include CONTROLLER_DIR.'/user.php';  // 新增

// public/api.php
include API_DIR.'/base.php';
include API_DIR.'/user.php';  // 新增
```

> 页面路由放在 `controller/` 下由 `public/index.php` 加载，只返回 HTML 字符串；接口路由放在 `controller_api/` 下由 `public/api.php` 加载，路由以 `/api/` 开头，任意返回值统一包装成 `{code, msg, data}` JSON。详见[控制器](controller.md)。
> 规则**命中即执行**：本例中 `/api/user/*` 只匹配单段路径（`/api/user/123`），不会挡住 `/api/user`；同类资源有通配与精确规则时，精确规则要写在通配规则之前（详见[路由](router.md)）。

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
    protected $db_config_key = 'entity';
}
```

> `$db_config_key` 是 DAO 连接的库位，默认 `entity`：`entity` 实体读写（与工作单元同一连接）、`migrate` 迁移、`default` 自由用途，对应 `config/mysql.php` 的 `midwares` 映射。

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
    `id` bigint unsigned not null,
    `version` int not null default 0,
    `create_time` datetime(3) not null,
    `update_time` datetime(3) not null,
    `delete_time` datetime(3) default null,
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
