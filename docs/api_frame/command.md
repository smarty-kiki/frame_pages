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


### `description`
### `entity`
### `crud`
### `console`

