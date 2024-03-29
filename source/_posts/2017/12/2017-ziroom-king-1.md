---
title: 王者编程大赛之一
date: 2017-12-05 05:12:06
tags:
- 算法
- 数据结构
categories:
- 算法
---

本次王者编程大赛分为 3 个组别，分别为研发、测试、移动战场。这里只讨论研发战场所考的 [题目](https://github.com/fan-haobai/2017-ziroom-king)，本次大赛共有 7 道题，主要考查点为基础算法，解题所用语言不做限制，但是需要在 [在线验证平台](http://www.anycodes.cn/zh/) 使用标准输入并验证通过，最后成绩以正确性和答题时间为评定依据。
![](//www.fanhaobai.com/2017/12/2017-ziroom-king-1/f9829b13-af2e-4c7b-b214-40bc78223c18.png)<!--more-->

所有题目中第 4 题蓄水池问题，是困惑我时间比较长的，其他题目比较容易看出考察点，这里我给出了 7 道题目自己的 [实现方式](https://github.com/fan-haobai/2017-ziroom-king/tree/master/src)，仅作为解题参考，若你有更好的思路欢迎讨论交流。

本章只叙述前 3 道相对简单的题目，后续题目及解题思路将在 [王者编程大赛系列](https://www.fanhaobai.com/2017/12/2017-ziroom-king-2.html) 中列出。

## 标准输入过滤

由于采用标准输入进行输入，为了防止输入多余的字符，影响程序执行结果，所以有必要对输入进行过滤处理。

```PHP
//等待输入并过滤
while(!$input = trim(fgets(STDIN), " \t\n\r\0\x0B[]"));
```

## 题1

## 题目

活动“司庆大放送，一元即租房”，司庆当日，对于签约入住的客户，住满 30 天，返还（首月租金 -1 元）额度的租金卡。租金卡的面额遵循了类似人民币的固定面额（1000 元、500 元、100 元、50 元、20 元、10 元、5 元、1 元），请实现一个算法，给客户返还的租金卡张数是最少的。

示例：
输入（租金卡金额）：54
输出：5
输入（租金卡金额）：9879
输出：20

## 解题思路

该问题其实就是，对租金卡的金额对题目中所列出的租金卡面额按照从大到小的顺序做商，一直到余数为 0。

## 编码实现

```PHP
function getCards($rent) {
    $cardMoney = array(1000, 500, 100, 50, 20, 10, 5, 1);
    $cardNumber = array_fill(0, count($cardMoney), 0);

    $i = 0;
    do {
        $cardNumber[$i] = intval($rent / $cardMoney[$i]);
        $rent = $rent % $cardMoney[$i];
        if ($rent < $cardMoney[$i]) {
            //移动到下一个面额
            $i++;
        }
    } while ($rent);

    return $cardNumber;
}

//输入:54
$card = getCards((int)$input);
echo array_sum($card), PHP_EOL;
```

## 题2

### 题目（排列组合）

2016 年自如将品质管理中心升级为安全与品质管理中心，并开通了自如举报邮箱。请看下边的算式

1 2 3 4 5 6 7 8 9 = 110（举报邮箱前缀数字）;

为了使等式成立，需要在数字间填入加号或者减号（可以不填，但不能填入其它符号）。之间没有填入符号的数字组合成一个数，例如：12 + 34 + 56 + 7 - 8 + 9 就是一种合格的填法。

请大家帮忙计算出多少个可能组合吧，至少 3 个以上算有效。

示例：
输入：[1 2 3 4 5 6 7 8 9]
输出：12 + 34 + 56 + 7 - 8 + 9

## 解题思路

该题考查点是排列组合问题，待连接的数字已经有序，所以只需要确定相邻两个数字的连接符即可。假设待连接数字的长度为 n，那么问题可以描述为，将空格、+、- 这 3 种连接符插入到 n-1 个相邻待连接数字之间的位置，所以共有 3^n-1 种情况，然后判断每种情况的计算结果是否为等式右边的数字。

为了获取 3 种连接符组成的 3^n-1 种组合情况，这里巧妙地运用 [3 进制运算](#) 来实现。

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-1/25fc16ed-ebdd-4094-84a4-150ad9a31b1f.png)

算法执行流程：

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-1/d4724b85-8491-451a-8b3c-d6c06842ec69.png)

## 编码实现

实现代码如下，并将一一详细说明。

```PHP
<?php
class Rank
{
    public $data = array();
    public $operate = array('', '-', '+');
    public $originLen = 0;
    public $sum = 0;

    public function __construct(array $data, $sum)
    {
        $this->originLen = count($data);
        $this->sum = $sum;

        foreach ($data as $k => $value) {
            $this->data[$k*2] = $value;
        }
    }
}
```

3 进制运算的实现，注意需要对高位进行补 0 的操作，其中 number 为 3^n-1（组合情况）。

```PHP
public function ternary($number)
{
    $pos = 2 * $this->originLen - 3;

    do {
        $mod = $number % 3;
        $number = (int)($number / 3);
        $this->data[$pos] = $this->operate[$mod];
        $pos -= 2;
    } while($number);
    //高位补0
    while ($pos > 0) {
        $this->data[$pos] = $this->operate[0];
        $pos -= 2;
    }

    ksort($this->data);
}
```

对 3 种连接符组成 3^n-1 种组合，根据等式成立情况进行取舍：

```PHP
public function run()
{
    $result = array();
    $times = pow(3, $this->originLen - 1);
    for ($i = 0; $i < $times; $i++) {
        //模拟3进制的运算
        $this->ternary($i);
        //决策
        $str = implode('', $this->data);
        if (eval("return $str;") == $this->sum) {
            $result[] = $str;
        }
    }

    return $result;
}
```

接收标准输入并输出结果：

```PHP
//输入:[1 2 3 4 5 6 7 8 9]
$rank = new Rank(explode(' ', $input), 110);
array_walk($rank->run(), function($value) {
    echo $value, PHP_EOL;
});
```

## 题3

### 题目（排序）

给定一个所有元素为非负的数组，将数组中的所有数字连接起来，求最大的那个数。

示例：
输入：4,94,9,14,1
输出：9944141
输入：121,89,98,15,4,3451
输出：98894345115121

### 解题思路

这道题是我司的笔试题目之一，我之前写的[《求非负数组元素组成的最大字符串》](https://www.fanhaobai.com/2017/04/array-form-max-string.html)文章，已经有过实现过程的描述。当然这道题可能有很多种实现方式，但是我认为最合适的实现还是采用排序的方式，容易理解，实现也简洁。

* 比较规则：分析 a 和 b 的排列，因为这 2 个数存在 2 种排列情况，既 [*a_b*](#) 和 [*b_a*](#)，若 [*a_b*](#) 组合值大于 [*b_a*](#) 组合，那么认为 a "大于" b，则 a 需要排列在 b 前面，反之则需要交换 a 和 b 的位置。同我们熟悉的排序算法唯一不同的是，这里不是直接通过比较 2 个元素值大小，而是需要通过排列后的 2 个新值进行大小比较。
* 排序算法：由于只是比较规则的不同，所以常用的排序算法（冒泡、快速、堆）一样适用。

这里使用冒泡排序来进行说明，每一趟找出待排序元素的最小值，算法执行流程如下：

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-1/a1cb7d2c-7fb6-4dbd-a363-3cd9e300743d.png)

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-1/d0955aea-2787-4e6b-adea-8fe1f61236de.png)

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-1/03a07a80-8bc3-46d1-bcab-17e2a057d951.png)

### 编码实现

定义比较规则，ab 和 ba 组合后的数字进行值大小的比较：

```PHP
function cmp($a, $b) {
    if ($a == $b) {
        return 0;
    }
    return $a . $b > $b . $a ? -1 : 1;
}
```

接收输入并输出结果：

```PHP
function array_form_max_str(array $Arr) {
    foreach ($Arr as $value) {
        if ($value < 0) {
            return '';
        }
    }

    usort($Arr, "cmp");
    //拼接
    return implode('', $Arr);
}

//输入:4,94,9,14,1
echo array_form_max_str(explode(',', $input)), PHP_EOL;
```

## 总结

这 3 道题算是热身吧，第 2 题巧妙运用 3 进制运算来模拟排列情况，都相对较容易，只是实现方式你是否会在意优雅而已。虽然简单，但是也不建议一上来就开始编码，首先要想清楚解题思路，然后编码实现即可。

<strong>相关文章 [»](#)</strong>

* [王者编程大赛之二 — 蓄水池](https://www.fanhaobai.com/2017/12/2017-ziroom-king-2.html) <span>（2017-12-05）</span>
* [王者编程大赛之三 — 01背包](https://www.fanhaobai.com/2017/12/2017-ziroom-king-3.html) <span>（2017-12-05）</span>
* [王者编程大赛之四 — 约瑟夫环](https://www.fanhaobai.com/2017/12/2017-ziroom-king-4.html) <span>（2017-12-06）</span>
* [王者编程大赛之五 — 最短路径](https://www.fanhaobai.com/2017/12/2017-ziroom-king-5.html) <span>（2017-12-06）</span>
