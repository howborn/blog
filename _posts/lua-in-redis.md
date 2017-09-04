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

[Lua](http://www.lua.org/) 是一个扩展式程序设计语言，作为一个强大、轻量的脚本语言，可以嵌入任何需要的程序中使用。Redis 从 2.6 版本起，也已开始支持 [Lua 脚本](https://redis.io/commands/eval)，我们可以更加得心应手地使用或扩展 Redis，特别是在高并发场景下 Lua 脚本提供了更高效、可靠的解决方式。

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

Lua 是一种动态类型语言，且语法相对较简单，这里只介绍其基本语法和使用方法，更多信息见 [Lua 5.1 参考手册](https://www.codingnow.com/2000/download/lua_manual.html)。

### 数据类型

Lua 作为通用型脚本语言，有 8 种基本数据类型：

| 类型       | 说明                       | 示例                                 |
| -------- | ------------------------ | ---------------------------------- |
| nil      | 只有一种值 nil<br>标识和别的任何值的差异 | nil                                |
| boolean  | 两种值 false 和 true         | false                              |
| number   | 实数（双精度浮点数）               | 520                                |
| string   | 字符串，不区分单双引号              | “fhb”<br>'fhb'                     |
| function | 函数                       | function haha() {<br>return 1<br>} |
| userdata | 将任意 C 数据保存在 Lua 变量       |                                    |
| thread   | 区别独立的执行线程<br>用来实现协程      |                                    |
| table    | 表，实现了一个关联数组<br>唯一一种数据结构  | {1, 2, 3}                          |

使用库函数 [type()](https://www.codingnow.com/2000/download/lua_manual.html#pdf-type) 可以返回一个变量或标量的类型。有关数据类型需要说明的是：

* **nil** 和 **false** 都能导致条件为假，而另外所有的值都被当作真
* 在 number 和 string 类型参与比较或者运算时，会存在隐式类型转化，当然也可以显示转化（tonumber()）
* 由于 table、 function、thread、userdata 的值是所谓的对象，变量本身只是一个对对象的引用，所以赋值、参数传递、函数返回，都是对这些对象的引用传递

### 变量

Lua 中有三类变量：全局变量、局部变量、还有 table 的域。[任何变量除非显式的以 local 修饰词定义为局部变量，否则都被定义为全局变量]()，局部变量作用范围为函数或者代码块内。说明，在变量的首次赋值之前，变量的值均为 nil。

```Lua
--使用--符号注释
globalVar = 'is global'
--if代码块
if 1 > 0 then
   local localVar = 'is local'  --
   print(localVar)    --可以访问局部变量
   print(globalVar)   --可以访问全局变量
end
print(localVar)       --不能访问局部变量
print(globalVar)      --可以访问全局变量
```

### 语法约定


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