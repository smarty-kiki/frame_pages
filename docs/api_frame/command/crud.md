# `crud`
通过描述文件来快速生成与 `crud` 相关的代码

### `crud:make-from-description`
通过描述文件生成 `crud` 的 `controller`，参数 `--entity_name=xxx` 来指定通过哪个描述文件来生成，可选参数 `--output_file=xxx` 指定输出的 `controller` 文件路径，默认路径是 `controller/xxx.php`

### `crud:make-error-code-from-description`
通过描述文件生成 `crud` 中所需要的 `error_code`，参数 `--entity_name=xxx` 来指定通过哪个描述文件来生成，会保存在 `config/error_code.php` 中

### `crud:make-docs-from-description`
通过描述文件生成 `crud` 接口相关的文档，参数 `--entity_name=xxx` 来指定通过哪个描述文件来生成，生成的文件在 `docs/api` 中

### `crud:make-error-code-docs-from-description`
通过描述文件生成 `crud` 中所需要的 `error_code` 相关的文档，参数 `--entity_name=xxx` 来指定通过哪个描述文件来生成，生成的文件为 `docs/error_code.md`