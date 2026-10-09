# ClickHouse

ClickHouse 是面向分析的列式数据库，本框架通过 HTTP 接口（默认 8123 端口）访问它：`ch_*` 全局函数与 [db_*](database.md) 风格一致，每次请求按配置拼 URL 直接发（HTTP 无长连接状态）。查询与写入分离：查询走 `{name:Type}` 占位符绑定，批量写入按行 JSON 提交。

## 配置

连接参数在 `config/clickhouse.php` 中配置（见[配置](config.md)）：

```php
'resources' => [
    'local' => [
        'host' => '127.0.0.1',
        'port' => 8123,
        'database' => 'default',
        'username' => 'default',
        'password' => '',
        'timeout' => 10,          // 单次 HTTP 请求超时秒数（分析型查询偏慢，比 Redis 宽松）
        'settings' => [],         // 随每次请求下发的 ClickHouse 设置
    ],
],
```

- `settings` 是随每次请求下发的 ClickHouse 设置项（如 `max_execution_time`）
- 框架默认补上 `output_format_json_quote_64bit_integers` / `output_format_json_quote_decimals` 两项，让 64 位整数与 Decimal 以**字符串**返回——JSON 里它们会退化成 double，超过 2^53 的值静默丢精度；需要数字类型时在这两项上显式设 `0` 覆盖
- 所有函数末尾的 `$config_key` 指定使用哪个 midwares 键（默认 `'default'`；`clickhouse:*` 迁移命令用 `'migrate'`）
- 配置缺少 `host` / `port` 时抛 `CLICKHOUSE_CONFIG`

## 查询

绑定值走 `param_*` 查询串 + SQL 里的 `{name:Type}` 占位符，由 ClickHouse 服务端做转义，避免拼接 SQL：

```php
$rows = ch_query(
    'select * from `log` where `user_id` = {user_id:UInt64} and `level` in {levels:Array(String)}',
    ['user_id' => 1001, 'levels' => ['error', 'fatal']]
);
```

- 绑定值的键**不带冒号**（`'user_id'` 而非 `':user_id'`），SQL 里用 `{user_id:UInt64}` 接收
- 标量直接传；数组 / 映射会拼成 ClickHouse 字面量 `['a','b']` / `{'k':'v'}`（不能交给 `http_build_query` 展开成 `param_x[0]=a`，服务端认不出）
- 输出格式统一走 `default_format=JSONEachRow`，响应体按行解析 JSON——不要在 SQL 末尾自己拼 `format`（会被 SQL 末尾的行注释吃掉、分号结尾还会变成多语句报错）；SQL 里显式写了非 JSONEachRow 的 format 会直接报错

### ch_query

```php
ch_query($sql, array $binds = [], $config_key = 'default')
```

查询返回关联数组列表（每行一个关联数组）。

### ch_query_first

```php
ch_query_first($sql, array $binds = [], $config_key = 'default')
```

查询第一行；SQL 未带 `limit` 时自动追加 `limit 1`；未找到返回 `null`。

```php
$row = ch_query_first('select * from `log` order by `create_time` desc', []);
```

### ch_query_column

```php
ch_query_column($column, $sql, array $binds = [], $config_key = 'default')
```

提取每行的 `$column` 列，返回一维数组。

### ch_query_value

```php
ch_query_value($value, $sql, array $binds = [], $config_key = 'default')
```

取第一行的 `$value` 列；未找到返回 `null`。

## 写入

### ch_write

```php
ch_write($sql, array $binds = [], $config_key = 'default')
```

执行建表、insert、改写（`ALTER TABLE ... UPDATE` / `DELETE`）等语句，返回值取自响应头 `X-ClickHouse-Summary` 的 `written_rows`。

> **不能用返回值判断写入是否生效**：DDL 与 mutation 的 `written_rows` 恒为 0，开启异步插入时也可能为 0。

### ch_insert_rows

```php
ch_insert_rows($table, array $rows, $config_key = 'default')
```

批量写入：`$rows` 为字段一致的关联数组列表，按行 JSON 编码（JSONEachRow）后作为请求体传输，无需拼占位符。返回写入行数。

- 每行的键必须一致：**缺键的列** ClickHouse 会静默填默认值（DateTime 变 1970-01-01），**多余的键**会静默丢弃
- 单个值超过 2^53 时 PHP 里已经是 float、`json_encode` 会输出科学计数法导致写入失败——框架直接抛出 `CLICKHOUSE_INT_OVERFLOW`，请以字符串形式传入

```php
ch_insert_rows('log', [
    ['user_id' => '1001', 'level' => 'error', 'create_time' => datetime()],
    ['user_id' => '1002', 'level' => 'info',  'create_time' => datetime()],
]);
```

### ch_ping

```php
ch_ping($config_key = 'default')
```

健康检查：连接或认证失败返回 `false`。部署脚本用它判断 ClickHouse 可达性（见下文）。

## 错误处理与重试

- 非 200 响应抛异常，消息带基础地址、状态码与响应体（`clickhouse {地址} [{code}] {响应体}`）——查询串里有 `param_*` 绑定值，不出现在异常消息里
- **不做重试**：写请求重试可能重复写入，所有 `ch_*` 请求都只发一次

## 迁移

ClickHouse 的表结构迁移与 MySQL 版并列（`command/migration/migrate_clickhouse.php`），迁移文件放 `command/migration/clickhouse_sql/`，格式沿用同一套 `# up` / `# down` 约定。

命令：

```bash
php public/cli.php clickhouse:install            # 建迁移记录表
php public/cli.php clickhouse:make --name=xxx    # 生成迁移模板
php public/cli.php clickhouse:migrate            # 执行未应用的迁移
php public/cli.php clickhouse:dry-run            # 打印将执行的 SQL，不实际执行
php public/cli.php clickhouse:rollback           # 回滚最近一批
php public/cli.php clickhouse:reset              # 回滚全部
php public/cli.php clickhouse:status             # 查看已应用 / 待应用
php public/cli.php clickhouse:uninstall          # 删除迁移记录表
```

- 迁移记录表为 ClickHouse 中的 `migrations`（`migration` / `batch` / `create_time`），`clickhouse:rollback` 会反序执行 down 并同步删除记录
- ClickHouse **没有事务**：迁移 SQL 应自带 `if not exists` / `if exists` 保证重跑安全
- 改 `ORDER BY` / 分区键 / 引擎无法 `ALTER`，只能重建表，down 会丢数据
- HTTP 接口不接受一次提交多条语句：迁移文件按 `;` 拆开逐条执行（整行的 `--` 注释会先剥掉；字符串字面量里的 `;` 会被误拆，注意规避）

测试 / 生产部署由 `project/tool/clickhouse_migrate.sh` 执行：ClickHouse 可达时建库（库名取自配置）后依次跑 `clickhouse:install` / `clickhouse:migrate`，不可达则跳过（见[环境](environment.md)）。
