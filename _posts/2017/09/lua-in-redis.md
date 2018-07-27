---
title: Lua在Redis的应用
date: 2017-09-04 21:50:19
tags:
- Lua
- Redis
categories:
- 语言
- Lua
---

Redis 从 2.6 版本起，也已开始支持 [Lua 脚本](https://redis.io/commands/eval)，我们可以更加得心应手地使用或扩展 Redis，特别是在高并发场景下 Lua 脚本提供了更高效、可靠的解决方案。

![](https://img1.fanhaobai.com/2017/09/lua-in-redis/3916d13312c22d84d29d3860b59544a9.png)<!--more-->

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

这段脚本代码虽然是 Lua 语言编写（ [进入Lua的世界](https://www.fanhaobai.com/2017/09/lua.html)），但是其实就是 PHP 版本的翻译版。那为什么这样，Lua 脚本就能解决库存问题了呢？

Redis 中嵌入 Lua 脚本，所具有的几个特性为：

* [原子操作]()：Redis 将整个 Lua 脚本作为一个原子执行，无需考虑并发，无需使用事务来保证数据一致性；
* [高性能]()：嵌入 Lua 脚本后，可以减少多个命令执行的网络开销，进而间接提高 Redis 性能；
* [可复用]()：Lua 脚本会保存于 Redis 中，客户端都可以使用这些脚本；

## 在Redis中嵌入Lua

![](https://img2.fanhaobai.com/2017/09/lua-in-redis/3916d13312c22d84d29d3860b59544a9.png)

### 使用Lua解析器

Redis 提供了 EVAL（直接执行脚本） 和 EVALSHA（执行 SHA1 值的脚本） 这两个命令，可以使用内置的 Lua 解析器执行 Lua 脚本。语法格式为：

* [EVAL]()  script  numkeys  key [key ...]  arg [arg ...] 
* [EVALSHA]()  sha1  numkeys  key [key ...]  arg [arg ...] 

参数说明：

* script / sha1：EVAL 命令的第一个参数为需要执行的 Lua 脚本字符，EVALSHA 命令的一个参数为 Lua 脚本的 [SHA1 值](https://redis.io/commands/eval#bandwidth-and-evalsha)
* numkeys：表示 key 的个数
* key [key ...]：从第三个参数开始算起，表示在脚本中所用到的那些 Redis 键（key），这些键名参数可以在 Lua 中通过全局数组 KYES[i] 访问
* arg [arg ...]：附加参数，在 Lua 中通过全局数组 ARGV[i] 访问

EVAL 命令的使用示例：

```Lua
> EVAL "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}" 2 key1 key2 first second
1) "key1"
2) "key2"
3) "first"
4) "second"
```

每次使用 EVAL 命令都会传递需执行的 Lua 脚本内容，这样增加了宽带的浪费。Redis 内部会永久保存被运行在脚本缓存中，所以使用 EVALSHA（建议使用） 命令就可以根据脚本 SHA1 值执行对应的 Lua 脚本。

```Lua
> SCRIPT LOAD "return 'hello'"
"1b936e3fe509bcbc9cd0664897bbe8fd0cac101b"
> EVALSHA 1b936e3fe509bcbc9cd0664897bbe8fd0cac101b 0
"hello"
```

> Redis 中执行 Lua 脚本都是以原子方式执行，所以是原子操作。另外，redis-cli 命令行客户端支持直接使用`--eval lua_file`参数执行 Lua 脚本。

Redis 中有关脚本的命令除了 EVAL 和 EVALSHA 外，[其他常用命令]() 如下：

| 命令                                | 描述                           |
| --------------------------------- | ---------------------------- |
| SCRIPT EXISTS script [script ...] | 查看脚本是是否保存在缓存中                |
| SCRIPT FLUSH                      | 从缓存中移除所有脚本                   |
| SCRIPT KILL                       | 杀死当前运行的脚本                    |
| SCRIPT LOAD script                | 将脚本添加到缓存中,不立即执行<br>返回脚本SHA1值 |

### 数据类型的转换

由于 Redis 和 Lua 都有各自定义的数据类型，所以在使用执行完 Lua 脚本后，会存在一个数据类型转换的过程。

Lua 到 Redis 类型转换与 Redis 到 Lua 类型转换相同部分关系：

| [Lua 类型](https://www.fanhaobai.com/2017/09/lua.html#数据类型) | [Redis 返回类型](http://www.redis.cn/topics/protocol.html) | 说明  |
| --------------------- | ---------------- | ---------------------------- |
| number                | integer          | 浮点数会转换为整数<br>3.333-->3 |
| string                | bulk             |                        |
| table（array）        | multi bulk       |                        |
| boolean false         | nil              |                        |

```Lua
> EVAL "return 3.333" 0
(integer) 3
> EVAL "return 'fhb'" 0
"fhb"
> EVAL "return {'fhb', 'lw', 'lbf'}" 0
1) "fhb"
2) "lw"
3) "lbf"
> EVAL "return false" 0
(nil)
```

需要注意的是，从 Lua 转化为 Redis 类型比 Redis 转化为 Lua 类型多了一条 [额外]() 规则：

| Lua 类型       | Redis 返回类型 | 说明     |
| ------------ | ---------- | ------ |
| boolean true | integer    | 返回整型 1 |

```Lua
> EVAL "return true" 0
(integer) 1
```

总而言之，[类型转换的原则]() 是将一个 Redis 值转换成 Lua 值，之后再将转换所得的 Lua 值转换回 Redis 值，那么这个转换所得的 Redis 值应该和最初时的 Redis 值一样。

### 全局变量保护

为了防止不必要的数据泄漏进 Lua 环境， Redis 脚本不允许创建全局变量。

```Lua
-- 定义全局函数
function f(n)
    return n * 2
end
return f(4);
```

执行`redis-cli --eval function.lua`命令，会抛出尝试定义全局变量的错误：

```Dos
(error) ERR Error running script (call to f_0a602c93c4a2064f8dc648c402aa27d68b69514f): @enable_strict_lua:8: user_script:1: Script attempted to create global variable 'f'
```

## Lua脚本调用Redis命令

Redis 创建了用于与 Lua 环境协作的组件—— 伪客户端，它负责执行 Lua 脚本中的 Redis 命令。

![](https://img3.fanhaobai.com/2017/09/lua-in-redis/ae7223b50754e37b7cd89cfe24fc13dd.png)

### 调用Redis命令

在 Redis 内置的 Lua 解析器中，调用 redis.call() 和 redis.pcall() 函数执行 Redis 的命令。它们除了处理错误的行为不一样外，其他行为都保持一致。调用 格式：

* redis.call(command, [key ...], arg [arg ...] )
* redis.pcall(command, [key ...], arg [arg ...] )

```Lua
> EVAL "return redis.call('SET', 'name', 'fhb')" 0
> EVAL "return redis.pcall('GET', 'name')" 0
"fhb"
```

### Redis日志

在 Lua 脚本中，可以通过调用 redis.log()  函数来写 Redis 日志。格式为：

redis.log(loglevel, message)

loglevel 参数可以是 redis.LOG_DEBUG、redis.LOG_VERBOSE、redis.LOG_NOTICE、redis.LOG_WARNING 的任意值。

查看`redis.conf`日志配置信息：

```Bash
# logleval必须一致才会记录
loglevel notice
logfile "/home/logs/redis.log"
```

Lua 写 Redis 日志示例：

```Lua
> EVAL "redis.log(redis.LOG_NOTICE, 'I am fhb')" 0
113:M 04 Sep 13:12:36.229 * I am fhb
```

## 案例

### API 访问速率控制

通过 Lua 实现一个针对用户的 API 访问速率控制，Lua 代码如下：

```Lua
local key = "rate.limit:string:" .. KEYS[1]
local limit = tonumber(ARGV[1])
local expire_time = tonumber(ARGV[2])
local times = redis.call("INCR", key)
if times == 1 then
    redis.call("EXPIRE", key, expire_time)
end
if times > limit then
    return 0
end
return 1
```

KEYS[1] 可以用 API 的 URI + 用户 uid 组成，ARGV[1] 为单位时间限制访问的次数，ARGV[2] 为限制的单位时间。

### 批量HGETTALL

这个例子演示通过 Lua 实现批量 HGETALL，当然也可以使用 [管道](https://www.fanhaobai.com/2017/08/redis-pipelining.html) 实现。

```Lua
-- KEYS为uid数组
local users = {}
for i,uid in ipairs(KEYS) do
    local user = redis.call('hgetall', uid)
    if user ~= nil then
        table.insert(users, i, user)
    end
end
return users
```

<strong>相关文章 [»]()</strong>

* [进入Lua的世界](https://www.fanhaobai.com/2017/09/lua.html) <span>（2017-09-03）</span>
* [Lua在Nginx的应用](https://www.fanhaobai.com/2017/09/lua-in-nginx.html) <span>（2017-09-09）</span>
