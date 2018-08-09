---
title: 进入Lua的世界
date: 2017-09-03 22:49:22
tags:
- Lua
categories:
- 语言
- Lua
---

Lua 是一个扩展式程序设计语言，作为一个强大、轻量的脚本语言，可以嵌入任何需要的程序中使用。Lua 被设计成一种动态类型语言，且它的语法相对较简单，这里只介绍其基本语法和使用方法，更多信息见 [Lua 5.3 参考手册](http://cloudwu.github.io/lua53doc/manual.html)。

![](https://img4.fanhaobai.com/2017/09/lua/c391629e-be21-4038-ab25-b47fe368daeb.jpg)<!---more-->

## 数据类型

Lua 作为通用型脚本语言，有 8 种基本数据类型：

| 类型       | 说明                       | 示例                                 |
| -------- | ------------------------ | ---------------------------------- |
| nil      | 只有一种值 nil<br>标识和别的任何值的差异 | nil                                |
| boolean  | 两种值 false 和 true         | false                              |
| number   | 实数（双精度浮点数）               | 520                                |
| string   | 字符串，不区分单双引号              | “fhb”<br>'fhb'                     |
| function | 函数                       | function haha() <br>   return 1<br>end |
| userdata | 将任意 C 数据保存在 Lua 变量       |                                    |
| thread   | 区别独立的执行线程<br>用来实现协程      |                                    |
| table    | 表，实现了一个关联数组<br>唯一一种数据结构  | {1, 2, 3}                          |

使用库函数 [type()](https://www.codingnow.com/2000/download/lua_manual.html#pdf-type) 可以返回一个变量或标量的类型。有关数据类型需要说明的是：

* **nil** 和 **false** 都能导致条件为假，而另外所有的值都被当作真
* 在 number 和 string 类型参与比较或者运算时，会存在隐式类型转化，当然也可以显示转化（tonumber()）
* 由于 table、 function、thread、userdata 的值是所谓的对象，变量本身只是一个对对象的引用，所以赋值、参数传递、函数返回，都是对这些对象的引用传递

## 变量

Lua 中有三类变量：全局变量、局部变量、还有 table 的域。[任何变量除非显式的以 local 修饰词定义为局部变量，否则都被定义为全局变量]()，局部变量作用范围为函数或者代码块内。说明，在变量的首次赋值之前，变量的值均为 nil。

```Lua
-- 行注释
--[[
块注释
--]]
globalVar = 'is global'
-- if代码块
if 1 > 0 then
   local localVar = 'is local'
   print(localVar)    -- 可以访问局部变量
   print(globalVar)   -- 可以访问全局变量
end
print(localVar)       -- 不能访问局部变量
print(globalVar)      -- 可以访问全局变量
```

## 标识符约定

Lua 中用到的名字（标识符）可以是任何非数字开头的字母、数字、下划线组成的字符串，同大多数语言保持一致。

### 关键字

下面这些是保留的关键字，不能用作名字：

![](https://img5.fanhaobai.com/2017/09/lua/fe33e61ca081f36909b9f2d16b5c9d4b.png)

大部分的流程控制关键字将在 [流程控制](#流程控制) 部分说明。

### 操作符

![](https://img0.fanhaobai.com/2017/09/lua/84414e900ee77fc8fd1baf9fc9c7a7d7.png)

大部分运算操作符将在 [表达式](#表达式)  部分进行说明。

## 语句

Lua 的一个执行单元叫做 chunk（语句组），一个语句组就是一串语句段，而 block（语句块）是一列语句段。

```Lua
do block end
```

下面将介绍 Lua 的主要流程控制语句。

### 条件语句

Lua 中同样是用 if 语句作为条件流程控制语句，else if 或者 else 子句可以省略。

```Lua
-- exp为条件表达式，block为条件语句
if exp then
   block
elseif exp then
   block
else
   block
end
```

控制结构中的条件表达式可以返回任何值。 false 和 nil 都被认为是假，所有其它值都被认为是真。另外 Lua 中并没有提供 switch 子句，我们除了使用冗长的 if 子句外，怎么实现其他语言中的 [switch]() 功能呢？

```Lua
-- 利用表实现
local switch = {
   [1] = function()    -- 索引对应的域为匿名函数
      return "Case 1."
   end,
   [2] = function()
      return "Case 2."
   end,
   [3] = function()
      return "Case 3."
   end
}
local exp = 4         -- exp为条件表达式
local func = switch[exp]
-- 实现switch-default功能
if (func) then
   return func()
else
   return "Case default."
end
```

### 循环语句

Lua 支持 for、while、repeat 这三种循环子句。

[while]() 子句结构定义为：

```Lua
-- 结束条件为：循环条件==false
while 循环条件 do
    代码块
end

-- 1+...+10的和
local sum = 0
local i = 1
while i <= 10 do
   i = i + 1
   sum = sum + i
end
return sum
```

[for]() 子句结构定义为：

```Lua
 -- 结束条件为：变量<=循环结束值  
for 变量=初值, 循环结束值, 步长 do
   代码块
end

-- 1+...+10的和
local sum = 0
for i=1, 10, 1 do
   sum = sum + i
end
return sum
```

另外，for 结合 in 关键字可以遍历 table 类型的数据，如下：

```Lua
local names = {'fhb', 'lw', 'lbf'}
local name;
for i,value in ipairs(names) do
   if i == 1 then
      name = value
   end
end
return name
```

[repeat]() 子句只有循环条件为 true 时，才退出循环。跟通常使用习惯相反，因此使用较少。其结构定义为：

```Lua
-- 结束条件为：循环条件==true
repeat
   代码块
until 循环条件
-- 1+...+10的和
local sum = 0
local i = 1
repeat
   i = i + 1
   sum = sum + i
until i > 10
return sum
```

### 语句的退出

return 和 break 关键字都可以用来退出语句组，但 return 关键字可以用来退出函数和代码块，包括循环语句，而 break 关键字只能退出循环语句。

## 表达式

在 Lua 中由多个操作符和操作数组成一个表达式。

### 赋值

Lua 允许多重赋值。 因此，赋值的语法定义是等号左边是一系列变量， 而等号右边是一系列的表达式。 两边的元素都用逗号间。如果右值比需要的更多，多余的值就被忽略，如果右值的数量不够， 将会被扩展若干个 nil。

```Lua
-- 变量简单赋值
x = 10
y = 20
-- 交换x和y的值
x, y = y, x
```

### 数学运算

Lua 支持常见的数学运算操作符，见下表：

| 操作符    | 含义   | 示例       |
| ------ | ---- | -------- |
| +<br>- | 加减运算 | 10 - 5   |
| *<br>/ | 乘除运算 | 10 * 5   |
| %      | 取模运算 | 10 % 5   |
| ^      | 求幂运算 | 4^(-0.5) |
| -      | 取负运算 | -0.5     |

需要指出的是，string 类型进行数学运算操作时，会隐式转化为 number 类型。

```Lua
return '12' / 6    -- 返回2
```

### 比较运算

Lua 中的比较操作符有见下表：

| 操作符     | 含义                | 示例                 |
| ------- | ----------------- | ------------------ |
| ==      | 等于，为严格判断          | "1" == 1 结果为 false |
| ~=      | 不等于<br>等价于==操作的反值 | "1"~=1 结果为 true    |
| <<br><= | 小于或小于等于           | 1<=2               |
| ><br>>= | 大于或大于等于           | 2>=1               |

比较运算的结果一定是 boolean 类型。[如果操作数都是数字，那么就直接做数字比较，如果操作数都是字符串，就用字符串比较的方式进行，否则，无法进行比较运算]()。

### 逻辑运算

Lua 中的逻辑操作符有 and、or 以及 not，一样把 false 和 nil 都作为假， 而其它值都当作真。

| 操作符  | 含义   | 示例        |
| ---- | ---- | --------- |
| and  | 与    | 10 and 20 |
| or   | 或    | 10 or 20  |
| not  | 取非   | not false |

取反操作 not 总是返回 false 或 true 中的一个。 and 和 or 都遵循短路规则，也就是说 and 操作符在第一个操作数为 false 或 nil 时，返回这第一个操作数， 否则，and 返回第二个参数； or 操作符在第一个操作数不为 nil 和 false 时，返回这第一个操作数，否则返回第二个操作数。 

```Lua
10 and 20           --> 20
nil and 10          --> nil
10 or 20            --> 10
nil or "a"          --> "a"
not false           --> true
```

### 其他运算

Lua 中还有两种特别的操作符，分别为字符串连接操作符（..）和取长度操作符（#）。

特别说明： 

* 如果字符串连接操作符的操作数存在 number 类型，则会隐式转化为 string 类型
* 取长度操作符获取字符串的长度是它的字节数，table 的长度被定义成一个整数下标 n

```Lua
'1' .. 2           --> '12'
#'123'             --> 3
#{1, 2}            --> 2
```

### 操作符优先级

Lua 中操作符的优先级见下表，从低到高优先级顺序： 

![](https://img1.fanhaobai.com/2017/09/lua/fc34646b-5eaf-45ba-b89a-0d8fc3f1b71d.png)

运算符优先级通常是这样，但是可以用括号来改变运算次序。

## 函数

在 Lua 中，函数是和字符串、数值和表并列的基本数据结构， 属于第一类对象( first-class-object)，可以和数值等其他类型一样赋给变量以及作为参数传递，同样可以作为返回值接收（闭包）。

### 定义函数

函数在 Lua 中定义也很简单，基本结构为：

```Lua
-- arg为参数列表
function function_name(arg)
　　body
end

-- 阶乘函数
function fact(n)
    if n == 1 then
        return 1
    else
        return n * fact(n - 1)
    end
end
-- 调用函数
return fact(4)
```

可以用 local 关键字来修饰函数，表示局部函数。

```Lua
local function foo(n)
    return n * 2
end
```

在 Lua 中有一个概念，函数与所有类型值一样都是匿名的，即它们都没有名称。当讨论一个函数名时，实际上是在讨论一个持有某函数的变量：

```Lua
function f(x) return -x end
-- 上述写法只是一种语法糖，是下述代码的简写形式
f = function(x) return -x end
```

### 函数参数

Lua 中函数实参有两种传递方式，但大部分情况会进行值传递。

#### 值传递

当实参值为非 table 类型时，会采用值传递。几个传参规则如下：

* 若实参个数大于形参个数，从左向右，多余的实参被忽略
* 若实参个数小于形参个数，从左向右，没有被初始化的形参被初始化为 nil
* 支持边长参数，用`...`表示

```Lua
-- 定义两个函数
function f(a, b) end
function g(a, ...) end
-- 调用参数情况
f(3)             a=3, b=nil
f(3, 4, 5)       a=3, b=4
g(3, 4, 5)       a=3, ...  --> 4 5
```

当函数为变长参数时，函数内使用`...`来获取变长参数，Lua 5.0 后`...`替换为名 arg 的隐含局部变量。

```Lua
function f(...)
   for k,v in ipairs({...}) do
      print(k, v)
   end
end

f(2,3,3) 
```

#### 引用传递

当实参为 table 类型时，传递的只是实参的引用而已。

```Lua
local function f(arg)
   arg[3] = 'new'
end
local a = {1, 2}
f(a)
return a[3]        --> "new"
```

### 函数返回值

Lua 函数允许返回多个值，中间用逗号隔开。函数返回值接收规则：

* 若返回值个数大于接收变量的个数，多余的返回值会被忽略
* 若返回值个数小于参数个数，从左向右，没有被返回值初始化的变量会被初始化为 nil

```Lua
function f1() return "a" end
function f2() return "a", "b" end

x, y = f1()         --> x="a", y=nil
x = f2()            --> x="a", "b"被丢弃
-- table构造式可以接受函数所有返回值
local tab = {f2()}  --> t={"a", "b"}
-- ()会迫使函数返回一个结果
printf((f2()))      --> "a"
```

Lua 中除了我们自定义函数外，已经实现了部分功能函数，见 [标准函数库](http://cloudwu.github.io/lua53doc/manual.html#6)。

## 表

### 定义和使用

Lua 中最特别的数据类型就是表（table），可以用来实现数组、Hash、对象，全局变量也使用表来管理。

```Lua
-- array
local array = { 1, 2, 3 }
print(array[1], #array)          --> 1, 3
-- hash
local hash = { a=1, b=2, c=3 }
print(hash.a, hash['b'], #hash)  --> 1, 2, 0
-- array和hash
local tab = {1, 2, 3}
tab['x'] = function() return 'hash' end
return {tab.x, #tab}             --> 2, 3
```

说明：当表表示数组时，索引从 1 开始。

### 元表

元表（metatable）中的键名称为事件，值称为元方法，它用来定义原始值在特定操作下的行为。可通过 [getmetatable()]() 来获取任一事件的元方法，同样可以通过 [setmetatable()]() 覆盖任一事件的元方法。Lua 支持的表事件：

| 元方法                                      | 事件              |
| ---------------------------------------- | --------------- |
| \_\_add(table, value)<br>\_\_sub(table, value) | + 和 - 操作        |
| \_\_mul(table, value)<br>\_\_div(table, value) | * 和 / 操作        |
| \_\_mod(table, value)<br>\_\_pow(table, value) | % 和 ^ 操作        |
| \_\_concat(table, value)                   | .. 操作           |
| \_\_len(table)                             | # 操作            |
| \_\_eq(table, value)<br>\_\_lt(table, value)<br>\_\_le(table, value) | == 、<、<= 操作     |
| \_\_index(table, index)<br>\_\_newindex(table, index) | 取和赋值下标操作        |
| \_\_call(table, ...)                       | 调用一个值           |
| \_\_tostring(table)                        | 调用 tostring() 时 |

覆盖这些元方法，即可实现重载运算符操作。例如重载 tostring 事件：

```Lua
local hash = { x = 2, y = 3 }
local operator = {
    __tostring = function(self)
        return "{ " .. self.x .. ", " .. self.y .. " }"
    end
}
setmetatable(hash, operator)
print(tostring(hash))             --> "{ 2, 3 }"
```

## 总结

Lua 是面向过程语言，使得可以简单易学。轻量级的特性，使得以脚本方式轻易地嵌入别的程序中，例如 [PHP](https://pecl.php.net/package/lua)、JAVA、[Redis](https://redis.io/commands/eval)、Nginx 等语言或应用。当然，Lua 也可以通过表实现面向对象编程。

<strong>相关文章 [»]()</strong>

* [Lua在Redis的应用](https://www.fanhaobai.com/2017/09/lua-in-redis.html) <span>（2017-09-04）</span>
* [Lua在Nginx的应用](https://www.fanhaobai.com/2017/09/lua-in-nginx.html) <span>（2017-09-09）</span>
