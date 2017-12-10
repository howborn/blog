---
title: 王者编程大赛之四 — 约瑟夫环
date: 2017-12-06 13:12:00
tags:
- 算法
- 数据结构
categories:
- 算法
---

每年夏季自如都会组织夏季夏令营活动，给来京参加夏令营的小崩友准备好多礼物，今年也是如此。

![](https://www.fanhaobai.com/2017/12/2017-ziroom-king-4/3d9cf2e7-dfe6-4b6e-8526-991296c3ea51.png)<!--more-->

组委会准备了一些小游戏来获得这些礼物，其中有一个游戏是这样的：组委会让小崩友围成一个圈。然后随机制定一个数 e，让编号为 0 的小朋友开始报数。每次喊道 e-1 的小朋友直接出列，淘达出局。从本次喊道 e-1 的下一个小朋友开始，继续从 0 报数...e-1 淘汰出局...一直这样进行...最后进行到最后一个小朋友，这位可以拿到"熊帅"亲笔签名的"木木"毛绒玩具。（注：小朋友的编号是从 0 到 n-1 )

示例：
输入：n=1314 e=520
输出：796
输入：n=88888 e=1018
输出：69148

## 解题思路

该题是一个 [约瑟夫环](https://zh.wikipedia.org/wiki/%E7%BA%A6%E7%91%9F%E5%A4%AB%E6%96%AF%E9%97%AE%E9%A2%98) 问题（猴子选大王），这里运用数学知识找出递推关系式。

假设，总共有 n 个人，数到 k（n >= k）的人被杀掉，幸存者的位置为 $p_n$（为了便于理解，编号从 1 开始）。

易知，初始位置为 k 的人会被第一个杀掉。此时，经过重新排序之后，问题变成了 n-1 个人的情形。幸存者的位置为 $p_{n-1}$。如果能够找到从 $p_{n-1}$ 到 $p_{n-1}$ 的递推关系，那么问题就解决了。

![](https://www.fanhaobai.com/2017/12/2017-ziroom-king-4/3d9cf2e7-dfe6-4b6e-8526-991296c3ea51.png)

重新编号后，上一轮相对这一轮每个人位置关系映射为：

1 -> n-k+1
2 -> n-k+2
...
k-1 -> n-1
k+1 -> 1
...
$p_n$ -> $p_{n-1}$
...
n-1 -> n-k+1
n -> n-k

这样，我们就得到一个递推关系式：[$p_n = (p_{n-1} + k) % n$]()，初始条件 $p_1 = 1$（1 个人时幸存者为自己），当然该提递推公式同样适用于 n < k 的情况。

## [编码实现](https://github.com/fan-haobai/2017-ziroom-king/blob/master/src/6.php)

约瑟夫环递推实现：

```PHP
function josephus($n, $e)
{
    $idx = 0;
    for ($i = 2; $i <= $n; $i ++) {
        $idx = ($idx + $e) % $i;
    }
    return $idx;
}
```

接收标准输入处理并输出结果：

```PHP
$input = str_replace(' ', '&', $input);
parse_str($input, $arr);
echo josephus($arr['n'], $arr['e']), PHP_EOL;
```

## 总结

由于本题只是需要求出最终的幸存者编号，所以可以直接使用递推公式求解，算法时间复杂度为 $O(n)$。若需要模拟整个游戏过程，则需要使用 [链表](http://blog.csdn.net/sxhelijian/article/details/9052891) 模拟实现。

<strong>相关文章 [»]()</strong>

* [王者编程大赛之一](https://www.fanhaobai.com/2017/12/2017-ziroom-king-1.html) <span>（2017-12-05）</span>
* [王者编程大赛之二 — 蓄水池](https://www.fanhaobai.com/2017/12/2017-ziroom-king-2.html) <span>（2017-12-05）</span>
* [王者编程大赛之三 — 01背包](https://www.fanhaobai.com/2017/12/2017-ziroom-king-3.html) <span>（2017-12-05）</span>
* [王者编程大赛之五 — 最短路径](https://www.fanhaobai.com/2017/12/2017-ziroom-king-5.html) <span>（2017-12-06）</span>