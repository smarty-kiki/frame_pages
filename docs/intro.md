# 定位
一个追求易用、组合灵活、高效的 `php` 组合式框架

### frame 是什么
`frame` 是一套用于构建 `http` 服务端的组合式框架核心库，与其他大型框架不同的是，`frame` 被设计为松散独立的文件，按服务端的应用需要来灵活组合。不仅易于理解，还获得了很高的执行效率。

如果你已经是有经验的服务端开发者，想知道 `frame` 与其他库/框架有哪些区别，请查看[对比其他框架](diff_other.md)。

### 设计原则

为了更好的理解 `frame`，需要充分理解它的设计原则，`php` 方面几个主流开源框架，都或多或少的在做企业应用或者快速开发时缺乏点什么，对一个现代框架来说：

- 不能有太差的执行性能
- 具有做分布式服务的能力
- 可以提高交付效率
- 开发者可以轻松的遵循优秀实践

基于这几个理想，`frame` 遵循了以下原则：

- 框架层面的逻辑因为会趋于稳定且维护频率不高，减少逻辑层次，使用函数封装，领域层为了提高交付效率、简化开发继续使用 `oop`
- 提供了有效分离 “逻辑” 与 “持久化” 的执行时间的 “工作单元”，配套的 “ID 生成器”，用以提高数据库的使用效率，也拥有了数据库分布式的基础
- 用闭包来实现成对逻辑以约束研发在同一个作用域层面写成对的逻辑，如事务开始及提交的函数 `db_transaction`、工作单元开始及提交的函数 `unit_of_work`
- 阅读效率的强迫症优化，要求本项目内的变量类名，全部使用小写与下划线的方式来保持英文词语拥有稳定间隔（空格或者下划线）
