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

**每张表都必须包含五个系统字段**：`id`（bigint unsigned 主键）、`version`（int）、`create_time` / `update_time` / `delete_time`（`datetime(3)`，毫秒精度，与 `datetime()` 的默认格式 `Y-m-d H:i:s.v` 对齐）。这五个字段与[实体](entity.md)的五个系统字段一一对应。

## 命令

所有迁移命令通过 `public/cli.php` 调用：

### migrate:install

```bash
php public/cli.php migrate:install
```

安装迁移系统：**仅创建**迁移记录表 `migrations`（记录已执行的文件名与批次 `batch`），不执行任何迁移文件。

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

**对比数据库自动生成迁移**，用于「先在数据库里手工改结构、再固化为迁移」的流程：

1. 执行全部迁移文件后快照当前库结构（包含手工改动的部分）
2. 回滚全部迁移、重建出「仅迁移文件」的结构并再次快照
3. 两次快照对比，差异（即手工改动）写成 `command/migration/sql/` 下带时间戳的新文件：`# up` 应用改动、`# down` 反向回滚
4. 自动重跑一遍，把新迁移应用并记录

两次快照无差异时输出 `no different!`，不生成文件。`--name` 为迁移描述。

### migrate:make-merge

```bash
php public/cli.php migrate:make-merge
```

归档已执行的迁移文件：移入 `command/migration/sql/merged/<时间戳><签名>/` 目录，并生成一份 `<时间戳>_merge_generated.sql` 基线（归档后等价的结构快照），用于控制迁移文件数量增长。后续执行迁移时会自动识别归档与基线文件。

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

迁移记录表 `migrations`（由 `migrate:install` 创建）只有三个字段：

| 字段 | 说明 |
|------|------|
| `id` | int unsigned 自增主键 |
| `migration` | 迁移文件名（varchar(255)，utf8_unicode_ci） |
| `batch` | 批次号，`migrate` 每次执行记为一批 |

`migrate` 写入记录；`migrate:rollback` 回滚最近一批并删除对应记录；`migrate:reset` 清空全部记录。`migrate:make` 对比结构时会跳过这张表。

## ClickHouse 迁移

ClickHouse 的结构变更走独立的一套：`command/migration/migrate_clickhouse.php` + `command/migration/clickhouse_sql/`，命令形态与 MySQL 迁移一致（`migrate:install` / `migrate` / `migrate:make` 等），生产部署由 `project/tool/clickhouse_migrate.sh` 执行。详见 [ClickHouse](clickhouse.md)。

## 生产部署

生产部署的 `after_push.sh` 会自动执行迁移（见[环境](environment.md)）。手动执行：

```bash
cd /var/www/php-vibe-coding-frame
php public/cli.php migrate
```
