---
title: 求非负元素数组所有元素能组合的最大字符串
date: 2017-04-03 13:43:56
tags:
- PHP
- 算法
categories:
- 语言
- PHP
---

问题叙述：将一个非负元素数组中的所有元素排列组合在一起，找出值最大的那个排列情况。例如 [0, 9, 523, 94, 10, 4]，排列组合后值最大数为：9945234100。

![预览图](https://img.fanhaobai.com/2017/04/array-form-max-string/57f35c24-2eeb-4c68-bf28-0771b11cad34.png)<!--more-->

本文废话较多，可以直接跳转到 [编码实现](/2017/04/array-form-max-string.html#编码实现) 部分。

## 背景描述 ##

这是我遇到的一道笔试题。首次遇见我也是很懵，当时我的第一感觉就是排序，但是没有及时理清里面的规律，导致后面并没有解答出此题。

## 问题分析 ##

### 确定输入值 ###

该问题描述很简单，也给出了测试用例，需求很明白。但是还需要注意问题背后隐藏的一些问题。

可确定输入的情况大致为：

*  数组元素都为非负数，但可能为 0；
*  数组长度并没有确定，长度可能很大。这里假设操作不溢出；
*  数组元素的位数不确定，用例只涉及到 2 位数，需要考虑多位数的情况。这里假设操作不溢出；

### 寻找规律 ###

面试时请教了一下面试官，面试官的思路：

> 最简单办法就是枚举所有可能的排列组合情况，然后求排列组合后的最大值；再就是寻找组合的规律，满足什么条件的元素排列在前。

当然这只是面试官提供的一些解决思路，付诸于实践还需要探索。在复试前的一天晚上我再次翻出这个问题，并找到了一些思路。

就拿问题中的用例 [0, 9, 523, 94, 10, 4] 来说，需要找出的结果为：9,94,523,4,10,0（为了方便说明，用”,“分割了数组元素）。

先将复杂问题简单化处理，首先尝试使用 **排序算法** 来分析过程。分析 9 和 94 的排列，为什么 9 排列在 94 前？[那是因为这 2 个数存在 2 种排列情况，既_ 9_94_ 和_ 9_49_，很明显 _9_94_ 排列大于 _9_49_ 排列，所以需要将 9 排列在 94 前，反之则需要交换元素位置]()。如果采用这样规则处理，是在 2 个元素之间进行枚举排列情况，且单次枚举情况限定在了 2 种，降低了问题的复杂程度并易于编码实现，后续可以直接使用排序方法来多次重复这种 2 个元素之间的单次枚举动作。

说明：符号“_”为占位符，表示该位置可能还存在其他元素，但不影响当前两个元素的前后排列顺序。后续出现该符号将不再说明。

总之，我认为该问题是排序问题的一个变种情况，同排序问题不同的是 **比较规则**。这里不是直接比较 2 个元素值大小，而是比较 2 个元素排列组合后值的大小。

## 实现思路 ##

经过上述分析，问题规律已经掌握清楚，这里整理出实现的思路。

### 整体思路 ###

*  确定使用排序算法实现；
*  与传统排序不同之处为元素之间的比较规则；

### 排序过程 ###

使用冒泡排序来说明上述用例的排序过程。

![](https://img.fanhaobai.com/2017/04/array-form-max-string/65FD0FD202413415D266AC754A75AAF3.png)

### 比较规则 ###

本问题的排序比较规则可以描述为：假设参与比较的两个元素为 A、B（初始时 A 在 B 前，排序结果从左至右为由大到小），比较时如果排列 _A_B_ 小于排列 _B_A_，A 和 B 则交换位置，反之不交换。

## 编码实现 ##

### 比较规则 ###

```PHP
/**
 * 比较规则
 * @param   string    $a
 * @param   string    $b
 * @return  int
 */
function cmp($a, $b) {
    if ($a == $b) {
        return 0;
    }
    return $a . $b > $b . $a ? -1 : 1;
}
```

### 冒泡排序 ###

```PHP
/**
 * 冒泡排序
 * @param   array    $Arr   待排序数组
 * @return  array
 */
function bubble_sort(array $Arr) {
    $length = count($Arr);
	if ($length < 2) {
        return $Arr;
    }

    for ($i = 1, $change = true; $i <= $length && $change; $i++) {
        $change = false;
        for ($j = $length - 1; $j > $i - 1; $j--) {
            if (cmp($Arr[$j - 1], $Arr[$j]) > 0) {
                $temp = $Arr[$j - 1];
                $Arr[$j - 1] = $Arr[$j];
                $Arr[$j] = $temp;
                $change = true;
            }
        }
    }
    return $Arr;
}

/**
 * 寻找非零元素数组中所有元素排列组合后的最大值
 * @param   array     $Arr        待排序数组
 * @param   string    $method     排序方法
 * @return  mixed
 */
function array_form_max_str(array $Arr, $method = 'bubble') {
    //参数校验
    if (!is_array($Arr)) return false;
    foreach ($Arr as $value) {
        if ($value < 0) return false;
    }
    //排序算法
    switch ($method) {
        case 'quick' :
            usort($Arr, "cmp");           //快速排序
            break;
        case 'bubble' :
            $Arr = bubble_sort($Arr);     //冒泡排序
            break;
        default : break;
    }
    //拼接
    return implode('', $Arr);
}
```

### 快速排序 ###

由于 PHP 中 sort 排序函数采用快速排序算法，这里直接使用之。

```PHP
/**
 * 寻找非零元素数组中所有元素排列组合后的最大值
 * @param   array     $Arr        待排序数组
 * @param   string    $method     排序方法
 * @return  mixed
 */
function array_form_max_str(array $Arr, $method = 'quick') {
    //参数校验
    if (!is_array($Arr)) return false;
    foreach ($Arr as $value) {
        if ($value < 0) return false;
    }
    //排序算法
    switch ($method) {
        case 'quick' :                   //快速排序
            usort($Arr, "cmp");
            break;
        case 'bubble' :
            $Arr = bubble_sort($Arr);    //冒泡排序
            break;
        default : break;
    }
    //拼接
    return implode('', $Arr);
}
```

## 用例测试 ##

这里只对快速排序方法使用 2  组测试用例并列举如下。

### 测试代码 ###

```PHP
$Arr = [20,913,223,91,20,3];
echo '数组为[', implode(',', $Arr), ']', PHP_EOL;
echo '最大排列组合为：', array_form_max_str($Arr), PHP_EOL;
```

### 测试结果 ###

```PHP
//第1组用例
数组为[0,9,523,94,10,4]
最大排列组合为：9945234100

//第2组用例
数组为[20,913,223,91,20,3]
最大排列组合为：9191332232020
```

## 写在最后 ##

经过深入分析问题的本质，也使得我对与排序算法有了更深入的认识，更算是一个巩固。同时，正是由于我尝试着去解决这个问题，才使得我在后面的复试环节中面试官再次提出相同问题时，给出了一个满意的解决方案。

<strong>相关文章 [»]()</strong>

* [王者编程大赛之一](https://www.fanhaobai.com/2017/12/2017-ziroom-king-1.html#题3) <span>（2017-12-05）</span>