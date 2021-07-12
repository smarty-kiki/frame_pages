# 命令行工具

`frame` 框架自带了命令行接口能力，可以通过执行以下命令来查看已有的命令列表：
```php
php public/cli.php
```
可以看到：
```bash
未匹配到命令，支持以下命令:
migrate:install                                   初始化 migrate 所需的表结构
migrate:uninstall                                 删除 migrate 所需的表结构
migrate                                           执行 migrate
migrate:dry-run                                   展示将要跑的 sql
migrate:rollback                                  回滚最后一次 migrate
migrate:make                                      新建 migration
migrate:reset                                     回滚所有 migrate
migrate:generate-diff                             生成 tmp migration 与正式 migration 的差别变更
description:demo-description                      创建 demo description 文件
description:make-entity-description               通过交互式输入创建领域实体描述文件
description:make-relationship-description         通过交互式输入创建领域实体关系描述文件
entity:make-from-description                      从实体描述文件初始化 entity、dao、migration
entity:make-docs-from-description                 从实体描述文件初始化 entity、dao、migration
entity:restep-last-id                             刷新 ID 生成器的最新 id
crud:make-from-description                        通过描述文件生成 CRUD 控制器
crud:make-error-code-from-description             通过描述文件生成 error-code
crud:make-docs-from-description                   通过描述文件生成 CRUD 相关接口文档
crud:make-error-code-docs-from-description        通过描述文件生成 error-code 相关文档
queue:worker                                      启动队列 worker
queue:status                                      队列状态
queue:pause                                       暂停队列任务派发
queue:peek-buried                                 处理 buried 状态的任务
queue:ready-to-buried                             将 ready 状态的任务快速改变为 buried 状态
queue:buried-dump                                 将 buried 状态的任务快速导出文件并清理
queue:dump-import                                 将导出的 dump 文件快速导入到队列并进入 ready 状态
console                                           终端模式
```

### `migrate`
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
#### `migrate:install`
在还未安装 `migrate` 的数据库上，首先需要执行 `migrate:install`，此操作会在数据库中创建 `migrations` 表

#### `migrate:uninstall`
在已安装 `migrate` 的数据库上，执行 `migrate:uninstall` 可以删除 `migrations` 表，注意，此操作会丢失之前的 `migrate` 执行情况

#### `migrate`
执行时，会将项目中 `command/migration` 目录下的 `.sql` 文件中未在该库执行过的文件中的 `#up` 部分在数据库中执行，如果带上参数 `--tmp_files=true` 则只检查 `command/migration/tmp` 下的 `.sql` 文件

#### `migrate:dry-run`
执行时，会将执行 `migrate` 时会执行的 `sql` 打印出来，并不在数据库中执行

#### `migrate:rollback`
执行时，会执行最后一次 `migrate` 命令执行的 `.sql` 文件中的 `#down` 部分，用以实现回滚最后一次操作的效果

#### `migrate:make`
执行时，会基于数据库中当前的情况和 `migrate` 的情况作出对比，将差异生成新的 `.sql` 文件，参数 `--name=xxx` 可指定生成的文件名，如 `2021_07_12_16_25_00_xxx.sql`

#### `migrate:reset`
执行时，会执行数据库中已记录的 `.sql` 文件的 `#down` 部分，用以重置掉所有变更

#### `migrate:generate-diff`
执行时，会比对 `command/migration/tmp` 下 `.sql` 文件的执行结果和 `command/migration` 下 `.sql` 的执行结果，将差异生成新的 `command/migration` 下的文件

### `description`
### `entity`
### `crud`
### `queue`
### `console`