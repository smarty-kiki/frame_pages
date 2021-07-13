# `migrate`
`migrate` 是管理表结构的命令集合，包含：
```bash
php public/cli.php migrate:install
php public/cli.php migrate:uninstall
php public/cli.php migrate
php public/cli.php migrate:dry-run
php public/cli.php migrate:rollback
php public/cli.php migrate:make
php public/cli.php migrate:reset
php public/cli.php migrate:generate-diff
```
### `migrate:install`
在还未安装 `migrate` 的数据库上，首先需要执行 `migrate:install`，此操作会在数据库中创建 `migrations` 表

### `migrate:uninstall`
在已安装 `migrate` 的数据库上，执行 `migrate:uninstall` 可以删除 `migrations` 表，注意，此操作会丢失之前的 `migrate` 执行情况

### `migrate`
执行时，会将项目中 `command/migration` 目录下的 `.sql` 文件中未在该库执行过的文件中的 `#up` 部分在数据库中执行，如果带上参数 `--tmp_files=true` 则只检查 `command/migration/tmp` 下的 `.sql` 文件

### `migrate:dry-run`
执行时，会将执行 `migrate` 时会执行的 `sql` 打印出来，并不在数据库中执行

### `migrate:rollback`
执行时，会执行最后一次 `migrate` 命令执行的 `.sql` 文件中的 `#down` 部分，用以实现回滚最后一次操作的效果

### `migrate:make`
执行时，会基于数据库中当前的情况和 `migrate` 的情况作出对比，将差异生成新的 `.sql` 文件，参数 `--name=xxx` 可指定生成的文件名，如 `2021_07_12_16_25_00_xxx.sql`

### `migrate:reset`
执行时，会执行数据库中已记录的 `.sql` 文件的 `#down` 部分，用以重置掉所有变更

### `migrate:generate-diff`
执行时，会比对 `command/migration/tmp` 下 `.sql` 文件的执行结果和 `command/migration` 下 `.sql` 的执行结果，将差异生成新的 `command/migration` 下的文件
