---
title: Vim快捷键整理
date: 2016-06-21 00:00:00
tags:
- Linux
categories:
- Linux
---

> 原文：http://www.libenfu.com/vim-快捷键整理

作为一名后端码农，常用的 vim 快捷键，你了解多少呢？

![](//www.fanhaobai.com/2016/06/vim-shortcut/SYZgz3rtMAjJutBWOVw9Wxtj.png)<!--more-->

## 移动光标

1、左移`h`、右移`l`、下移`j`、上移`k`
2、向下翻页`ctrl + f`，向上翻页`ctrl + b`
3、向下翻半页`ctrl + d`，向上翻半页`ctrl + u`
4、移动到行尾`$`，移动到行首`0`（数字），移动到行首第一个字符处`^`
5、移动光标到下一个句子`）`，移动光标到上一个句子`（`
6、移动到段首`{`，移动到段尾`}`
7、移动到下一个词`w`，移动到上一个词`b`
8、移动到文档开始`gg`，移动到文档结束`G`
9、移动到匹配的`{}.().[]`处`%`
10、跳到第`n`行`ngg`或`nG`或 `:n`
11、移动光标到屏幕顶端`H`，移动到屏幕中间`M`，移动到底部`L`
12、读取当前字符，并移动到本屏幕内下一次出现的地方`*`
13、读取当前字符，并移动到本屏幕内上一次出现的地方`#`

## 查找替换

1、光标向后查找关键字`#`或者`g#`
2、光标向前查找关键字`*`或者`g*`
3、当前行查找字符`fx/Fx/tx/Tx`
4、基本替换`:s/s1/s2`（将下一个`s1`替换为`s2`）
5、全部替换`:%s/s1/s2`
6、只替换当前行`:s/s1/s2/g`
7、替换某些行`:n1,n2 s/s1/s2/g`
8、搜索模式为`/string`，搜索下一处为`n`，搜索上一处为`N`
9、制定书签`mx`，但是看不到书签标记，而且只能用小写字母
10、移动到某标签处``x`
11、移动到上次编辑文件的位置` `.`

```
. 代表一个任意字符
* 代表一个或多个字符的重复
```

## 编辑操作

1、光标后插入`a`, 行尾插入`A`
2、后插一行插入`o`，前插一行插入`O`
3、删除字符插入`s`， 删除正行插入`S`
4、光标前插入`i`，行首插入`I`
5、删除一行`dd`，删除后进入插入模式`cc`或者`S`
6、删除一个单词`dw`，删除一个单词进入插入模式`cw`
7、删除一个字符`x`或者`dl`，删除一个字符进入插入模式`s`或者`cl`
8、粘贴`p`，交换两个字符`xp`，交换两行`ddp`
9、复制`y`，复制一行`yy`
10、撤销`u`，重做`ctrl + r`，重复`.`
11、智能提示`ctrl + n`或者`ctrl + p`
12、删除`motion`跨过的字符，删除并进入插入模式`c{motion}`
13、删除到下一个字符跨过的字符，删除并进入插入模式，不包括`x`字符`ctx`
14、删除当前字符到下一个字符处的所有字符，并进入插入模式，包括`x`字符，`cfx`
15、删除`motion`跨过的字符，删除但不进入插入模式`d{motion}`
16、删除`motion`跨过的字符，删除但不进入插入模式，不包括`x`字符`dtx`
17、删除当前字符到下一个字符处的所有字符，包括`x`字符`dfx`
18、如果只是复制的情况时，将`12-17`条中的`c`或`d`改为`y`
19、删除到行尾可以使用`D`或`C`
20、拷贝当前行`yy`或者`Y`
21、删除当前字符`x`
22、粘贴`p`
23、可以使用多重剪切板，查看状态使用`:reg`，使用剪切板使用`”`，例如复制到`w`寄存器，`”wyy`或者使用可视模式`v”wy`
24、重复执行上一个作用使用`.`
25、使用数字可以跨过`n`个区域，如`y3x`，会拷贝光标到第三个`x`之间的区域，`3j`向下移动`3`行
26、在编写代码的时候可以使用`]p`粘贴，这样可以自动进行代码缩进
27、`>>`缩进所有选择的代码
28、`<<`反缩进所有选择的代码
29、`gd`移动到光标所处的函数或变量的定义处
30、`K`在`man`里搜索光标所在的词
31、合并两行`J`
32、若不想保存文件，而重新打开`:e!`
33、若想打开新文件`:e filename`，然后使用`ctrl + ^`进行文件切换

## 窗口操作

1、分隔一个窗口`:split`或者`:vsplit`
2、创建一个窗口`:new`或者`:vnew`
3、在新窗口打开文件`:sf {filename}`
4、关闭当前窗口`:close`
5、仅保留当前窗口`:only`
6、到左边窗口`ctrl + w,h`
7、到右边窗口`ctrl + w,l`
8、到上边窗口`ctrl + w,k`
9、到下边窗口`ctrl + w,j`
10、到顶部窗口`ctrl + w,t`
11、到底部窗口`ctrl + w,b`

## 宏操作

1、开始记录宏操作`q[a-z]`，按`q`结束，保存操作到寄存器`[a-z]`中
2、`@[a-z]`执行寄存器`[a-z]`中的操作
3、`@@`执行最近一次记录的宏操作

## 可视操作

1、进入块可视模式`ctrl + v`
2、进入字符可视模式`v`
3、进入行可视模式`V`
4、删除选定的块`d`
5、删除选定的块然后进入插入模式`c`
6、在选中的块同是插入相同的字符`I<String>ESC`

## 跳到声明

1、`[[`向前跳到顶格第一个`{`
2、`[]`向前跳到顶格第一个`}`
3、`]]`向后跳到顶格的第一个`{`
4、`]]`向后跳到顶格的第一个`}`
5、`[{`跳到本代码块的开头
6、`]}`跳到本代码块的结尾

## 挂起操作

1、挂起`Vim ctrl + z`或者`:suspend`
2、查看任务，在`shell`中输入`jobs`
3、恢复任务`fg [job number]`（将后台程序放到前台）或者`bg [job number]`（将前台程序放到后台）
4、执行`shell`命令`:!command`
5、开启`shell`命令`:shell`，退出该`shell exit`
6、保存`vim`状态`:mksession name.vim`
7、恢复`vim`状态`:source name.vim`
8、启动`vim`时恢复状态`vim -S name.vim`

来一张键位图，好好学习。

![](//www.fanhaobai.com/2016/06/vim-shortcut/qPGPXPzaHzq32G7rIZ3SX8Qd.png)
