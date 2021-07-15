# `entity`
通过描述文件来快速生成与 `entity` `dao` `migration` 相关的代码，以及与实体相关的操作

### `entity:make-from-description`
通过描述文件生成 `entity` `dao` `migration`，参数 `--entity_name=xxx` 来指定通过哪个描述文件来生成，输出路径是 `domain/dao` `domain/entity` `command/migration`

### `entity:make-docs-from-description`
通过描述文件生成 `entity` 相关的文档，参数 `--entity_name=xxx` 来指定通过哪个描述文件来生成，输出路径是 `docs/entity/xxx.md`，同时也会在 `docs/entity/relationship.md` 中维护该实体的关联关系文档

### `entity:restep-last-id`
可以重新刷新 `id` 生成器中的各实体 `id` 为最新 `id`，适用于 `redis` 数据丢失恢复、数据有未通过 `id` 生成器生成 `id` 插入了数据库等情况的修复