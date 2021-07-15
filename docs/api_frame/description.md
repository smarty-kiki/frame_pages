# 快速原型

快速原型功能，是提供给开发者将自己惯常的实现方式封装在框架中，通过后续快速配置即可生成对应的代码的能力，要实现这样的效果，总共有几个步骤：

1. 封装自己惯常的实现方式在 `command/description_extension`
2. 使用时，在 `domain/description` 中写对应实体的描述文件 `xxx.yml` 和 `.relationship.yml`
3. 执行相关的命令来生成对应的代码文件：
```bash
php public/cli.php entity:make-from-description                      // 从实体描述文件初始化 entity、dao、migration
php public/cli.php entity:make-docs-from-description                 // 从实体描述文件初始化 entity、dao、migration
php public/cli.php crud:make-from-description                        // 通过描述文件生成 CRUD 控制器
php public/cli.php crud:make-error-code-from-description             // 通过描述文件生成 error-code
php public/cli.php crud:make-docs-from-description                   // 通过描述文件生成 CRUD 相关接口文档
php public/cli.php crud:make-error-code-docs-from-description        // 通过描述文件生成 error-code 相关文档
```

### 如何将逻辑封装在 `command/description_extension` 中

各目录所放置的逻辑：
```bash
.
├── controller                   // controller 相关
│   ├── add                      // 添加方法
│   ├── delete                   // 删除方法
│   ├── detail                   // 明细方法
│   ├── list                     // 列表方法
│   └── update                   // 更新方法
├── dao                          // dao 方法
├── docs                         // 文档相关
│   ├── api                      // api 文档相关
│   │   ├── add                  // 添加方法文档相关
│   │   ├── delete               // 删除方法文档相关
│   │   ├── detail               // 明细方法文档相关
│   │   ├── list                 // 列表方法文档相关
│   │   └── update               // 更新方法文档相关
│   ├── entity                   // 实体文档相关
│   │   ├── entity               // 实体文档相关
│   │   └── relationship         // 关联关系文档相关
│   └── error_code               // 错误码文档相关
├── entity                       // 实体相关
├── error_code                   // 错误码相关
├── migration                    // 表结构相关
├── struct_group                 // 字段组相关
└── struct_type                  // 字段类型相关
    └── data_type                // 数据库字段类型相关
```

其中 `struct_type` `data_type` `struct_group` 比较特殊，`struct_type` 代表了业务字段的类型，如名称、状态、性别这样的类型；`data_type` 代表数据库类型，比如时间、枚举等；`struct_group` 代表了字段组合，比如开始时间和结束时间组合。除这三个目录使用 `yaml` 填写之外，其余文件夹中的文件都是用 `blade` 模版语法来填写。比如：

`struct_type/data_type/string.yml`
```yaml
database_field:
  type: varchar
  length: $(length)
  allow_null: true
  default: null
option:
  length: 255
```

表示 `data_type` 指定为 `string` 的实体属性最终创建建表语句时，会按照 `database_field` 中的配置来创建，并且这里说明了这个 `data_type` 在 `struct_type` 引用或者直接在实体描述文件中使用时可以覆盖定义的 `option` 有 `length` 值。

`struct_type/name.yml`
```yaml
data_type: string
validator:
  - function: 'mb_strlen($value) <= $(length)'
    failed_message: 不能超过 $(length) 字
display_name: 名称
option:
  length: 30
```

表示 `struct_type` 指定为 `name` 的实体属性是按照 `data_type` 为 `string` 来定义的，但是覆盖定义了 `length`，同时这里注意在 `struct_type` 定义时可以定义 `validator`，`validator` 是个数组，其中数组中的每一个值又有两个字段，两个字段有两种用法，一种是 `function` + `failed_message`，即当该最终生成的实体属性被赋值时，会执行这个方法，变量 `$value` 为赋值的值，如果方法返回 `false`，抛出异常 `failed_message`，另一种是 `reg` + `failed_message`，即当被赋值时，会按照正则来去匹配，如果不匹配，则返回 `false`，抛出异常 `failed_message`

### 使用时的实体描述文件和关联关系描述文件格式是怎么样的

实体的描述文件结合着如下例子来说明：  
`domain/description/environment.yml`
```yaml
display_name: 环境             // 实体的中文名字
description: 环境              // 实体的中文描述
structs:                      // 属性配置
  name:                       // 叫 name 的属性
    type: name                // 指定 struct_type 为 name
    data_type: string         // 覆盖 data_type 为 string
    database_field:           // 覆盖 database_field 定义
      type: varchar
      length: 15
      allow_null: true
      default: null
    validator:                // 覆盖 validator
      - function: 'mb_strlen($value) <= $(length)'
        failed_message: 不能超过 $(length) 字
    display_name: 名称         // 覆盖 display_name
    require: true             // 配置该属性在实体创建时为必传
repeat_check_structs:         // 配置这个实体在添加新记录或者修改属性时的排重按照哪些属性来排重
  - name
```

如上述例子，当 `name` 指定了 `type` 为 `name` 时，从 `data_type` 到 `display_name` 行其实已经被定义，可以不写，如果需要覆盖来自 `struct_type` 的定义，才需要写明细出来，如果上述例子中不需要覆盖配置，最简可以写为这样：
```yaml
display_name: 环境
# description: 环境            // description 未配置时默认与 display_name 一致
structs:                      // 属性配置
  name:                       // 叫 name 的属性
    type: name                // 指定 struct_type 为 name
    # require: true             // require 未配置时默认为 true
repeat_check_structs:         // 配置这个实体在添加新记录或者修改属性时的排重按照哪些属性来排重
  - name
```

关联关系描述文件例子如下：  
`domain/description/.relationship.yml`
```yaml
- from:                                  // 数组中的一项为一个关联关系，一个关联关系会形成双向的关系，这里只需要描述 has_many、has_one 的方向，belongs_to 会自动生成
    entity: category                     // 实体类型
    to_attribute_name: category          // 在 to 的实体上，关联关系的属性名称
    to_display: "$this->id"
    to_snaps: []
  to:
    entity: environment                  // 实体类型
    from_attribute_name: environments    // 在 from 的实体上，关联关系的属性名称
    from_display: "$this->id"
    from_snaps: []
  relationship_type: has_many            // category has_many environment
  associate_delete: true                 // 当删除 category 时是否会自动删除 environment
  require: true                          // 当创建 environment 时是否必须要传 category
```

### 执行相关命令有没有其他的方式及注意点