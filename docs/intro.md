# 定位

一个专为 PHP-FPM 快速开发设计的单层 MVC PHP 框架。无 DI 容器、无注解、无 YAML 路由配置、无 Composer autoload——**路由即闭包，控制器即函数，写完即跑**。

### php-vibe-coding-frame 是什么

`php-vibe-coding-frame` 是一套用于构建 `php` 服务端的单层 MVC 框架，与其他大型框架不同的是，它被设计为扁平直接的代码：依赖通过 `include` 显式加载，配置是 `php` 数组，路由是闭包。不仅易于理解，还获得了很高的执行效率。

如果你已经是有经验的服务端开发者，想知道本框架与 `Laravel` 有哪些区别，请查看[与 Laravel 的差异](diff_other.md)。

## 为什么这个框架对 Vibe Coding 友好

Vibe Coding 的核心是**从想法到代码的路径最短**——没有仪式感，没有概念包袱，所见即所得。这个框架在每个关键路径上都为此设计：

- **零启动成本**：一行 `include` 注册路由，一条命令生成 Entity/DAO/迁移文件，Docker 一键启动开发环境。不需要理解 ServiceProvider、Facade、Container binding。
- **意图即结果**：闭包返回数组就是 JSON，返回字符串就是 HTML。不需要 `response()->json()`、不需要 `view()` 包装。AI 或人——看一眼代码就知道输出是什么。
- **没有魔法**：没有 `__call` 代理、没有 Facade 静态代理、没有注解解析。Ctrl+Click 能追到源码，grep 能找到所有引用。AI 工具的静态分析不会被框架的元编程绕晕。
- **一个文件就是一个功能**：路由、参数校验、业务调用全在一个闭包内，不需要在 Controller → Service → Repository 的调用链中跳转。修改一个功能，改一个文件就够。
- **自动持久化**：`unit_of_work()` 自动包裹所有路由闭包，创建 Entity、赋属性即可，闭包结束自动写入数据库。不用记 `save()`、`flush()` 调用时机。心智负担趋近于零。

简单说：**框架退后一步，让意图站到前面。**

## 设计原则

- **显式优于隐式**：依赖靠 `include`，配置靠 PHP 数组，路由靠闭包。没有"魔法"，所有行为可见。
- **约定优于配置**：Entity 类名即表名、DAO 命名即 `{entity}_dao`、返回数组即 JSON。默认行为覆盖 90% 场景。
- **简单优于灵活**：单一 MVC 层，无中间件栈、无服务容器、无 Provider。够用就好，不设可扩展点。
- **纯函数 + 静态方法**：无类实例化的 DI，无反射，无注解扫描。所有能力通过函数和静态方法暴露。

## 架构概览

本框架通过 `public/` 下的四个入口承接不同场景，**入口决定响应格式**：

```
页面 → nginx / → PHP-FPM → public/index.php → bootstrap.php（加载 frame/） → 注册错误处理
  → 注册 if_verify（unit_of_work 包裹） → 加载 controller/ → 路由匹配 → HTML 响应

api  → nginx /api/* → PHP-FPM → public/api.php → bootstrap.php（加载 frame/）+ frame/php_fpm.php
  → 注册 if_verify（unit_of_work 包裹） → 加载 controller_api/ → 路由匹配 → JSON 响应

cli  → public/cli.php → bootstrap.php（加载 frame/） → 加载 command/ → 命令匹配

sse  → nginx /sse/* → PHP-FPM → public/sse.php → bootstrap.php（加载 frame/）+ frame/sse.php
  → 加载 controller_sse/ → 每请求处理一个流
```

核心行为：

- **页面入口**（`controller/`）只出 HTML：闭包返回字符串 → HTML 响应；返回非字符串会被判为编程错误抛 500，提示迁移到 `controller_api/`
- **API 入口**（`controller_api/`）只出 JSON：任意返回值（数组/Entity/标量）统一包装成 `{code, msg, data}` JSON 响应
- **SSE 入口**（`controller_sse/`）流式输出：每个 `yield` 发一个 `data:` 事件，`yield true` 结束流
- **所有控制器闭包默认包裹在 `unit_of_work()` 中**，实体变更自动提交并处理事务
- **`$_SERVER['ENV']`** 控制环境（development/production），配置自动按环境合并覆盖

## 10 秒看到 Hello World

```bash
git clone git@github.com:smarty-kiki/php-vibe-coding-frame.git my-project && cd my-project
sh project/tool/start_development_server.sh   # 需要 Docker + 输入 sudo 密码
```

打开浏览器访问 `http://localhost`，看到 "hello world" 页面。

> 映射了 80 和 3306 端口，若端口冲突可修改 `project/tool/start_development_server.sh`。

## 目录结构

```
.
├── bootstrap.php            # 框架通用加载
├── public/                  # Web 根目录（nginx root）
│   ├── index.php            # 页面入口（HTML）
│   ├── api.php              # API 入口（JSON）
│   ├── cli.php              # CLI 入口
│   └── sse.php              # SSE 入口
├── frame/                   # 框架核心库（ORM、DB、Cache、Queue、Blade、SSE、日志）
├── controller/              # 页面路由定义（闭包，只返回 HTML）
├── controller_api/          # API 路由定义（闭包，路由以 /api/ 开头，只返回 JSON）
├── controller_sse/          # SSE 流式业务逻辑
├── domain/                  # 领域层（Entity + DAO + Knowledge）
├── config/                  # PHP 配置数组 + ENV 环境覆盖
├── command/                 # CLI 命令（migrate、queue、entity）
├── view/                    # Blade 模板
├── interceptor/             # 拦截器（请求前置/后置逻辑）
├── util/                    # 工具类（外部能力封装：支付、短信、OSS）
└── project/                 # 部署配置与工具脚本
```

完整说明见[目录结构](directory.md)。
