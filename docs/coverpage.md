# php-vibe-coding-frame

> 一个专为 PHP-FPM 快速开发设计、对 Vibe Coding 友好的单层 MVC PHP 框架

- 路由即闭包，控制器即函数，写完即跑
- 无 DI 容器、无注解、无 Composer autoload
- 所有控制器闭包自动包裹 `unit_of_work()`，实体变更自动提交
- 入口决定响应格式：页面出 HTML、API 出 JSON、SSE 出流式

[GitHub](https://github.com/smarty-kiki/php-vibe-coding-frame)
[开始上手](intro.md)
