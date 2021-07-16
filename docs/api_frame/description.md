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
description: 环境              // 实体的中文描述，非必填，默认与 display_name 一致
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
    require: true             // 配置该属性在实体创建时为必传，非必填，默认为 true
repeat_check_structs:         // 配置这个实体在添加新记录或者修改属性时的排重按照哪些属性来排重
  - name
```

如上述例子，当 `name` 指定了 `type` 为 `name` 时，从 `data_type` 到 `display_name` 行其实已经被定义，可以不写，如果需要覆盖来自 `struct_type` 的定义，才需要写明细出来，如果上述例子中不需要覆盖配置，最简可以写为这样：
```yaml
display_name: 环境
structs:
  name:
    type: name
repeat_check_structs:
  - name
```

关联关系描述文件例子如下：  
`domain/description/.relationship.yml`
```yaml
- from:                                  // 数组中的一项为一个关联关系，一个关联关系会形成双向的关系，这里只需要描述 has_many、has_one 的方向，belongs_to 会自动生成
    entity: category                     // 实体类型
    to_attribute_name: category          // 在 to 的实体上，关联关系的属性名称，非必填，默认与实体类型一致
    to_display: "$this->id"              // 当构造页面或者接口时给关联关系的另一面实体提供一个查询文本描述的方法，非必填，默认为 "$this->id"
    to_snaps: []                         // 配置在建立两个实体关联时，自动维护的冗余字段，非必填
  to:
    entity: environment                  // 实体类型
    from_attribute_name: environments    // 在 from 的实体上，关联关系的属性名称，非必填，当 relationship_type 为 has_many 时，默认为实体类型的复数，has_one 时为单数
    from_display: "$this->id"            // 当构造页面或者接口时给关联关系的另一面实体提供一个查询文本描述的方法，非必填，默认为 "$this->id"
    from_snaps: []                       // 配置在建立两个实体关联时，自动维护的冗余字段，非必填
  relationship_type: has_many            // category has_many environment
  associate_delete: true                 // 当删除 category 时是否会自动删除 environment
  require: true                          // 当创建 environment 时是否必须要传 category
```
最简可以写为这样：
```yaml
- from:
    entity: category
  to:
    entity: environment
  relationship_type: has_many
  associate_delete: true
  require: true
```

这个文件可以配置多条实体关系，这里需要注意的几个点：

1. 只从 `has_many` `has_one` 来配置，当 `A has_many B` 时，自动就会 `B belongs_to A`
2. 如果两个实体有多个关系，需要注意定义 `xx_attribute_name` 来做区分
3. `has_many` 关系时，`from_attribute_name` 注意要用复数，用以方便其他开发者理解

上边两个例子的两个文件：  
`domain/description/environment.yml`  
`domain/description/.relationship.yml`  
配置的内容，在执行快速原型生成的命令时，会以 `$entity_name` `$entity_info` `$relationship_infos` 三个变量提供给 `command/description_extension` 中的模版进行代码的生成，`$entity_name` 是 `domain/description/environment.yml` 的文件名字 `environment`，`$entity_info` 是 `domain/description/environment.yml` 文件中的内容的 `php` 数组形式，`$relationship_infos` 是 `domain/description/.relationship.yml` 中，与 `environment` 相关的关系的信息，内容如下：
```php
[
    'relationships' => [
        'xxxx' => [
            'entity' => ‘’,
            'entity_display_name' => ‘’,
            'attribute_name' => ‘’,
            'self_attribute_name' => ‘’,
            'self_display' => ‘’,
            'snaps' => ‘’,
            'relationship_type' => ‘’,
            'reverse_relationship_type' => ‘’,
            'associate_delete' => true,
            'require' => true,
        ]
    ],
    'display_for_relationships' => [
        'display_for_xxxx_oooxxxx' => '',
        'display_for_xxxx_xxxoooo' => '',
    ],
]
```
这样在框架扩展者在封装自己惯常实现方式时，可以结合这些变量来配置生成代码的模版。

### 执行相关命令有没有其他的方式及注意点
当配置好 `domain/description` 下的文件后，可以通过手工执行篇首提到的命令来生成代码，也可以启动监控配置文件改动的脚本来自动监听并且批量执行生成命令：
```bash
sh project/tool/development/fast_demo_watch.sh                  // inotify 监控文件变更事件，在有些环境中获取不到变化事件，如 macbook pro m1 的 docker 环境中
sh project/tool/development/fast_demo_watch_by_md5.sh           // md5 变化监控文件变更事件，当文件内容在监控过程中没变化时不会触发
sh project/tool/development/fast_demo_watch_by_mtime.sh         // mtime 变化监控文件变更事件
```
启动后脚本会处于监控文件变更状态，配置文件变更后会有回显类似这样：
```bash
watch environment.yml generate
delete     /var/www/api_frame/command/migration/tmp/*_environment.sql                    success!
generate   /var/www/api_frame/domain/entity/environment.php                              success!
generate   /var/www/api_frame/domain/dao/environment.php                                 success!
generate   /var/www/api_frame/command/migration/tmp/2021_07_16_13_22_08_environment.sql  success!
delete     /var/www/api_frame/docs/entity/environment.md                                 success!
generate   /var/www/api_frame/docs/entity/relationship.md                                success!
generate   /var/www/api_frame/docs/entity/environment.md                                 success!
include    /var/www/api_frame/docs/entity/environment.md                                 success!
uninclude  /var/www/api_frame/controller/environment.php                                 success!
generate   /var/www/api_frame/controller/environment.php                                 success!
include    /var/www/api_frame/controller/environment.php                                 success!
generate   /var/www/api_frame/config/error_code.php                                      success!
generate   /var/www/api_frame/docs/error_code.md                                         success!
delete     /var/www/api_frame/docs/api/environment.md                                    success!
generate   /var/www/api_frame/docs/api/environment.md                                    success!
include    /var/www/api_frame/docs/api/environment.md                                    success!
generate  /var/www/api_frame/domain/autoload.php  success!
migrate  /var/www/api_frame/command/migration/tmp/2021_07_16_13_22_08_environment.sql  success  up!
```

其中有一些关键词及其含义如下：  
```bash
delete               删除文件
generate             生成文件
include              将目标文件添加进了框架加载文件中
uninclude            将目标文件从框架加载文件中移除
```
监听变化生成对应的代码后，会重新生成 `domain/autoload.php`，也会将 `migration` 重新执行，所以在改动过程中会将开发环境的数据库中已存在的数据丢弃。  
监听的状态变化包括新增、修改、删除，删除时会将相关生成的文件删除，如：
```bash
watch environment.yml delete
delete  /var/www/api_frame/command/migration/tmp/*_environment.sql  success!
delete  /var/www/api_frame/domain/dao/environment.php               success!
delete  /var/www/api_frame/domain/entity/environment.php            success!
delete  /var/www/api_frame/docs/entity/environment.md               success!
delete  /var/www/api_frame/controller/environment.php               success!
clean   /var/www/api_frame/config/error_code.php                    success!
clean   /var/www/api_frame/docs/error_code.md                       success!
delete  /var/www/api_frame/docs/api/environment.md                  success!
generate  /var/www/api_frame/domain/autoload.php  success!
```

在生成过程中，可能有些文件已经编辑并加入了一些非生成的代码，生成时会按照一定规则避开避免覆盖代码，在 `dao` `entity` 文件中，会标记注释：
```php
class environment_dao extends dao
{
    protected $table_name = 'environment';
    protected $db_config_key = 'default';

    /* generated code start */                       // 这个注释对中间的区域，就是给生成代码留的，自己实现的方法要注意放在这个注释对的外面
    /* generated code end */
}
```
在 `controller` 文件覆盖时，会判断被覆盖的文件是否有被人为修改过，如果没有，会直接覆盖为新生成的文件，如果有，则不会覆盖，并在同目录下生成 `xxxxx.diff.php` 文件，文件中会展示出新生成的文件和当前文件的区别，供手工去合并两个文件的代码
在 `config/error_code.php` 文件生成时，也会有标记注释来区分生成的和手写的代码部分，如：
```php
return [
    /* generated environment start */               // 同样，自己实现的方法要注意放在这个注释对的外面
    'ENVIRONMENT_NOT_FOUND' => '无效的 environment',
    'ENVIRONMENT_REQUIRE_NAME' => '未传入 name',
    /* generated environment end */
    //more
];
```
