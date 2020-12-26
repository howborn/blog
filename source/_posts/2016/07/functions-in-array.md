---
title: in_array()函数的坑
date: 2016-07-06 08:00:00
tags:
- PHP
categories:
- 语言
- PHP
---

在 PHP 项目开发过程中，in_array 函数你一定使用不少吧，那么你知道**`in_array(0, array('s'))`**返回什么吗？<!--more-->

对于上面这个问题，我想一般人都会觉得结果是 false，而实际结果应该是 [true](#)，不信可以运行代码就知道结果了。

那么，为什么 PHP 会认为整型`0`会存在于数组`array('s')`中呢，很明显数组中只存在字符串`s`，而不存在整型`0`的呀？

# 查阅手册

在 [PHP官方手册](http://php.net/manual/zh) 中查阅到`in_array`函数的说明，如下：

> **bool in_array ( mixed $needle , array $haystack [, bool $strict = FALSE ] )**     
> 说明：在 haystack 中搜索 needle，如果没有设置 strict 则使用 **宽松** 的比较。如果第三个参数 strict 的值为 true，则 in_array 函数还会检查 needle 的 **类型** 是否和 haystack 中的相同。

in_array 函数存在第三个参数 strict，它用来标记函数在对两元素进行比较时是否采用 **严格比较**，类似 == 和 === 区别，in_array 函数默认采用 **宽松** 比较，即不比较类型，只比较值是否相等。

# 分析原因

现在看来，之所以结果出现 true，是因为 in_array 函数没有使用第三个参数，而默认进行了 **宽松** 比较，即等同于 `0 == 's' ?` 的问题。

由于 PHP 是弱类型语言，在对两个不同类型的值进行操作（比较运算）时，会存在数据类型的 **隐式转化**。

**比较运算** 时 **不同类型转化规则** 如下表：

![](//img2.fanhaobai.com/2016/07/functions-in-array/ftmDbIAmvincNjudJwK3N82_.png)

可知，当两不同类型数值中含有数字类型，都会转化为数字类型进行比较。那么`s`转化为数字类型为`0`，所以`0 == 0 ？`判断为 true，这就是为什么`in_array(0, array('s'))`结果为   true 的原因。

# 思考

那么想要达到我们预期的效果，上述问题必须进行 **严格** 比较，可以使用`in_array(0, array('s'), true)`，这也告诫 **[我们在使用 in_array 函数时，若不能预知待搜索值和数组元素的类型，建议将第三个参数设为 true，保证比较时进行严格比较，进而不会产生意外的结果。](#)**



 

