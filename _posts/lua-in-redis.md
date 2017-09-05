---
title: Lua在Redis的应用
date: 2017-09-03 21:50:19
tags:
- Lua
- Redis
categories:
- 语言
- Lua
---

Redis 从 2.6 版本起，也已开始支持 [Lua 脚本](https://redis.io/commands/eval)，我们可以更加得心应手地使用或扩展 Redis，特别是在高并发场景下 Lua 脚本提供了更高效、可靠的解决方式。

![](http://www.fanhaobai.com/2017/09/lua-in-redis/3916d13312c22d84d29d3860b59544a9.png)<!--more-->

## 为什么要使用Lua

我们先看一个抢购场景下 [商品库存]() 的问题，用 PHP 可简单实现为：

```PHP
$key = 'number:string';
$redis = new Redis();
$number = $redis->get($key);
if ($number <= 0) {
    return 0;
}
$redis->decr($key);
return $number--;
```

这段代码其实存在问题，高并发时会出现库存超卖的情况，因为上述操作在 Redis 中不是原子操作，会导致库存逻辑的判断失效。尽管可以通过优化代码来解决问题，比如使用 [Decr]() 原子操作命令、或者使用 [锁]() 的方式，但这里使用 Lua 脚本来解决。

```Lua
local key = 'number:string'
local number = tonumber(redis.call("GET", key))
if number <= 0 then
   return 0
end
redis.call("DECR", key)
return number--
```

这段脚本代码虽然是 Lua 语言编写（见 [Lua 语法](#Lua基本语法)），但是其实就是 PHP 版本的翻译版。那为什么这样，Lua 脚本就能解决库存问题了呢？

Redis 中嵌入 Lua 脚本，所具有的几个特性为：

* [原子操作]()：Redis 将整个 Lua 脚本作为一个原子执行，无需考虑并发，无需使用事务来保证数据一致性；
* [高性能]()：嵌入 Lua 脚本后，可以减少多个命令执行的网络开销，进而间接提高 Redis 性能；
* [可复用]()：Lua 脚本会保存于 Redis 中，客户端都可以使用这些脚本；

## Lua基本语法



## Redis与Lua转换

[手册](http://www.redis.cn/commands/eval.html)

### 数据类型转换

### 相互调用

### 全局变量保护

为了防止不必要的数据泄漏进 Lua 环境， Redis 脚本不允许创建全局变量。

```Redis
redis 127.0.0.1:6379> eval 'a=10' 0
(error) ERR Error running script (call to f_933044db579a2f8fd45d8065f04a8d0249383e57): user_script:1: Script attempted to create global variable 'a'
```

## 案例

### API 访问速率控制

### 批量HGETTALL