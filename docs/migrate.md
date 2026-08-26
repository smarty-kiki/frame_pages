# 迁移

迁移（Migration）把数据库结构变更纳入版本管理：每个变更是一个带时间戳的 SQL 文件，由 CLI 命令按顺序执行、可回滚。本框架的迁移基于「`# up` / `# down` 双段 SQL 文件」。

## 迁移文件

### 命名规则

迁移文件保存在 `command/migration/sql/` 目录，命名格式：

```
YYYY_mm_dd_HH_MM_SS_描述.sql
```

例如 `2026_08_19_10_30_00_create_user_table.sql`。文件名自带顺序，执行时按文件名排序逐个执行。

### 文件格式

每个文件包含 `# up` 与 `# down` 两段，分别对应正向执行与回滚：

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

**每张表都必须包含五个系统字段**：`id`（bigint 主键）、`version`、`create_time`、`update_time`、`delete_time`。这五个字段与[实体](entity.md)的五个系统字段一一对应。

## 命令

所有迁移命令通过 `public/cli.php` 调用：

### migrate:install

```bash
php public/cli.php migrate:install
```

安装迁移系统：创建迁移记录表（记录已执行的迁移文件名），并执行全部已有迁移。

### migrate

```bash
php public/cli.php migrate
```

执行未执行过的迁移文件。迁移记录表会记录每个已执行文件，已执行的跳过。

### migrate:uninstall

```bash
php public/cli.php migrate:uninstall
```

卸载迁移系统：删除迁移记录表。

### migrate:dry-run

```bash
php public/cli.php migrate:dry-run
```

预演执行：打印将要执行的迁移 SQL，**不实际执行**。用于上线前检查。

### migrate:make

```bash
php public/cli.php migrate:make --name=create_user_table
```

生成一个新迁移文件：在 `command/migration/sql/` 下创建带当前时间戳前缀的 `xxx.sql`，内容为 `# up` / `# down` 空骨架，并提示需包含五个系统字段。`--name` 为迁移描述。

### migrate:make-merge

```bash
php public/cli.php migrate:make-merge
```

把已执行过的迁移文件合并归档到 `command/migration/sql/merged/`，并生成一个精简的基线迁移。用于控制迁移文件数量增长。

### migrate:rollback

```bash
php public/cli.php migrate:rollback
```

回滚最近一次执行的一组迁移：执行对应文件的 `# down` 段，并更新迁移记录。

### migrate:reset

```bash
php public/cli.php migrate:reset
```

重置迁移状态：回滚全部已执行的迁移（执行全部 `# down`），清空迁移记录。

## 迁移表结构

迁移记录表记录已执行的迁移文件名与执行时间。`migrate:install` 创建，`migrate` 写入，`migrate:rollback` / `migrate:reset` 删除记录。

## 生产部署

生产部署的 `after_push.sh` 会自动执行迁移（见[开发环境](environment.md)）。手动执行：

```bash
cd /var/www/php-vibe-coding-frame
php public/cli.php migrate
```
