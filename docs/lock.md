# 锁

基于 Redis 的互斥执行工具（`frame/lock_cache.php`），用于防止并发重复执行：`singly_run` 抢不到锁就放弃，`serially_run` 抢不到锁就排队串行。两者都走 `config/redis.php` 的 `lock` 中间件（见[配置](config.md)），底层依赖 [cache_add / cache_compare_set / cache_compare_delete](cache.md) 等原子操作。

## singly_run

```php
singly_run($key, $expire_second, closure $closure, ?closure $fail_closure = null)
```

**互斥执行**：并发调用只有一个能进入闭包执行，其余调用方**不等待**、直接返回 `$fail_closure` 的结果（未传则返回 `null`）。适合「同一时刻只允许一个在跑，跑不了也不等」的场景（如定时任务防重）。

```php
singly_run('daily_report', 60, function () {
    // 生成日报……
}, function () {
    return '已有任务在执行';
});
```

- `$expire_second` 为锁的过期秒数，必须大于 0（否则抛 `LOCK_CACHE_EXPIRE`）——锁不带过期时间时，持有方崩溃会永久死锁
- 锁键为 `singly_run_{$key}`，值为随机持有令牌
- 闭包执行完（含抛异常）在 `finally` 中释放：**值仍是自己的令牌才删**（`cache_compare_delete`）——跑超 `$expire_second` 时锁可能已被下一个调用方拿到，不能误删

## serially_run

```php
serially_run($key, $expire_second, $wait_second, closure $closure, ?closure $fail_closure = null)
```

**排队串行执行**：并发调用按到达顺序排队（先到先执行），前一个闭包执行完把锁**交接**给阻塞最久的下一个，认领到交接的才执行。`$wait_second` 秒内等不到交接则返回 `$fail_closure` 的结果（未传则 `null`），不执行闭包。适合「必须依次执行、宁可排队等一会」的场景（如顺序处理同一个用户的订单）。

```php
serially_run('order:1001:pay', 10, 5, function () {
    // 排队执行支付处理……
}, function () {
    return '当前排队较多，请稍后再试';
});
```

- `$expire_second` 必须大于 0（同上，抛 `LOCK_CACHE_EXPIRE`）；`$wait_second` 必须大于 0（`0` 在 `cache_blpop` 里表示永久阻塞，会一直占住调用方，抛 `LOCK_CACHE_WAIT`）
- 等待队列用 Redis List 实现：锁键为 `serially_run_lock_{$key}`，唤醒信号键为 `serially_run_wake_{$key}`
- 排队超时**不写任何键、不做清理**，退出不影响后面排队的调用方

## 运行机制

锁键共有**三种取值**：键不存在（空闲）、持有方令牌（持有中）、交接标记 `serially_run_handoff`（交接中——持有方已释放、等待方尚未认领）。

- 交接时锁键**全程存在**：持有方把值从自己的令牌原子替换为交接标记（`cache_compare_set`），随后向唤醒队列推一条信号、唤醒一个等待方；新来的调用方抢不到锁，只能排队——保证排队顺序不被插队
- 等待方被唤醒后原子认领交接标记（换回自己的令牌）；交接标记已过期而锁空着时，直接抢也算轮到
- **不续期**：锁只在创建时带 `$expire_second` 的 TTL，抢锁失败的调用方不会给它续期——持有方被 kill 时靠到期自动解锁，不会永久卡住后续调用方
- 唤醒信号与交接标记都是短 TTL 的自愈窗口（信号 5 秒、交接标记 3 秒，常量 `LOCK_CACHE_WAKE_EXPIRE` / `LOCK_CACHE_HANDOFF_EXPIRE`）：交接中断（信号没发出去、认领方崩溃）时，到期后锁自然空出，新调用方即可接手
- 持有方抛异常时由 `finally` 正常释放，异常继续向上抛——锁只负责互斥，业务失败的处理由闭包自行决定
