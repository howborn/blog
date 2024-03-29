---
title: 王者编程大赛之三 — 01背包
date: 2017-12-05 23:12:00
tags:
- 算法
- 数据结构
categories:
- 算法
---

服务目前每月会对搬家师傅进行评级，根据师傅的评级排名结果，我们将优先保证最优师傅的全天订单。

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-3/9f4a2cb2-ab32-4b28-b054-b479c04270e5.png)<!--more-->

假设师傅每天工作 8 个小时，给定一天 n 个订单，每个订单其占用时间长为 $T_i$，挣取价值为 $V_i$，现请您为师傅安排订单，并保证师傅挣取价值最大。

输入格式
输入 n 组数据，每组以逗号分隔，并且每一个订单的编号、时长、挣取价值以空格分隔
输出格式
输出争取价值和订单编号，订单编号按照价值由大到小排序，争取价值相同，则按照每小时平均争取价值由大到小排序

示例：
输入：[MV10001 2 100,MV10008 2 30,MV10003 1 200,MV10009 6 500,MV10010 3 400]
输出：730 MV10010 MV10003 MV10001 MV10008
输入：[M10001 2 100,M10002 3 210,M10003 3 300,M10004 2 150,M10005 1 70,M10006 2 220,M10007 1 10,M10008 3 30,M10009 3 200,M10010 2 400]
输出：990 M10010 M10003 M10006 M10005

## 解题思路

由于本题每个订单每天只被安排一次，是典型地采用 [动态规划](https://zh.wikipedia.org/wiki/%E5%8A%A8%E6%80%81%E8%A7%84%E5%88%92) 求解的 01 背包问题。

### 动态规划概念

[动态规划过程](#)：每次决策依赖于当前状态，又随即引起状态的转移。一个决策序列就是在变化的状态中产生出来的，所以，这种多阶段最优化决策解决问题的过程就称为动态规划。

[动态规划原理](#)：动态规划与分治法类似，都是把原问题拆分成不同规模相同特征的小问题，通过寻找特定的递推关系，先解决一个个小问题，最终达到解决原问题的效果。

### 建立动态方程

假设，师傅挣取价值最大时的订单为 $x_1$,$x_2$,$x_3$,...,$x_i$（其中 $x_i$ 取 1 或 0，表示第 i 个订单被安排或者不安排），$v_i$ 表示第 i 个订单的价值，$w_i$ 表示第 i 个订单的耗时时长，$wv(i,j)$ 表示安排了第 i 个订单，师傅总耗时为 j 时的最大价值。

可得订单价值和耗时的关系图：

| i    | 1    | 2    | 3    | 4    | 5    |
| ---- | ---- | ---- | ---- | ---- | ---- |
| w(i) | 2    | 2    | 1    | 6    | 3    |
| v(i) | 100  | 30   | 200  | 500  | 400  |

因此，可得 [动态方程](#)：

$$wv(i,j) = \begin{cases}
wv(i-1,j)(j < w(i)) \\
max(wx(i-1,j),wv(i-1,j-w(i))+v(i))(j \geq w(i))
\end{cases}$$

说明：$j<w(i)$ 表示订单不被安排，$j \geq w(i)$ 表示订单被安排。

### 确定边界

可以确定边界条件 $wx(0,j) = wx(i, 0) = 0$，$wx(0,j)$ 表示一个订单都没安排，再怎么耗时价值都为 0，$wx(i,0)$ 表示没有耗时，安排多少订单价值都为 0。

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-3/18359c82-3ff9-48c7-825e-77fe17419621.png)

### 求解

求解过程，可以填表来进行模拟：

1) 如 i=1,j=1 时，有 $j<w(i)$，故 $wx(1,1) = wx(1-1,1) = 0$；
2) 又如 i=1,j=2 时，有 $j=w(i)$，故 $wx(1,2) = max(wx(1-1,1), wx(1-1,2-w(1)) + v(1) = 100$；
3) 如此下去，直至填到最后一个，i=5,j=8 时，有 $j<w(i)$，故 $wx(5,8) = max(wx(5-1,8), wx(5-1,8-w(5)) + v(5) = 730$；
4) 在耗时没有超过 8 小时的前提下，当前 5 个订单都被安排过时，$wx(5,8) = 730$ 即为所求的最大价值；

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-3/366c6f00-35a1-46c6-ba98-76e3c7b3bae4.png)

### 解的组成

尽管 [求解](#求解) 过程已经求出了最大价值，但是并没有得出哪些订单被安排了，也就是没有得出解的组成部分。

但是在求解的过程中不难发现，寻解方程满足如下定义：

$$x(i) = \begin{cases}
wv(i,j) = wv(i-1,j) \\
wv(i,j) \neq wv(i-1,j)
\end{cases}$$

从表格右下到左上为寻解方向，寻解过程如下：

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-3/9f4a2cb2-ab32-4b28-b054-b479c04270e5.png)

1) i=5,j=8 时，有 $wv(5,8) != wv(4,8)$，故 $x(5) = 1$，此时 $j -= w(5)$，$j = 5$；
2) i=4 时，无论 j 取何值，都有 $wv(4,j) == wv(3,j)$，故 $x(5) = 0$，此时 $j = 5$；
3) i=3,j=5 时，有 $wv(3,5) != wv(2,5)$，故 $x(3) = 1$，此时 $j -= w(3)$，$j = 4$；
4) i=2,j=4时，有 $wv(2,4) != wv(1,4)$，故 $x(2) = 1$，此时 $j -= w(2)$，$j = 2$；
5) i=1,j=2时，有 $wv(1,2) != wv(1,2)$，故 $x(1) = 1$，此时 $j -= w(1)$，$j = 0$，寻解结束；

## [编码实现](https://github.com/fan-haobai/2017-ziroom-king/blob/master/src/5.php)

实现的代码如下，并将一一详细说明。

```PHP
class Knapsack
{
    //物品重量,index从1开始表示第1个物品
    public $w = array();
    //物品价值,index从1开始表示第1个物品
    public $v = array();
    //最大价值,$wv[$i][$w]表示前i个物品重量为w时的最大价值
    public $wv = array();
    //物品总数
    public $n = 0;
    //物品总重量
    public $W = 0;
    //背包中的物品
    public $goods = array();

    /**
     * Knapsack constructor.
     * @param array $goods 物品信息,格式如下:
     * [
     *   [index, w, v]   //good1
     *   ...
     * ]
     * @param $c
     */
    public function __construct(array $goods, $c)
    {
        $this->goods = $goods;

        $this->W = $c;
        $this->n = count($goods);
        //初始化物品价值
        $v = array_column($goods, 2);
        array_unshift($v, 0);
        $this->v = $v;
        //初始化物品重量
        $w = array_column($goods, 1);
        array_unshift($w, 0);
        $this->w = $w;
        //初始化最大价值
        $this->wv = array_fill(0, $this->n + 1, array_fill(0, $this->W + 1, 0));

        $this->pd();
        $this->canPut();
    }

    public function getMaxPrice()
    {
        return $this->wv[$this->n][$this->W];
    }
}
```

动态求解过程：

```PHP
public function pd()
{
    for ($i = 0; $i <= $this->W; $i++) {
        for ($j = 0; $j <= $this->n; $j++) {
            //未放入物品和重量为空时,价值为0
            if ($i == 0 || $j == 0) {
                continue;
            }

            //决策
            if ($i < $this->w[$j]) {
                $this->wv[$j][$i] = $this->wv[$j - 1][$i];
            } else {
                $this->wv[$j][$i] = max($this->wv[$j - 1][$i], $this->wv[$j - 1][$i - $this->w[$j]] + $this->v[$j]);
            }
        }
    }
}
```

寻解过程：

```PHP
public function canPut()
{
    $c = $this->W;
    for ($i = $this->n; $i > 0; $i--) {

        //背包质量为c时,前i-1个和前i-1个物品价值不变,表示第1个物品未放入
        if ($this->wv[$i][$c] == $this->wv[$i - 1][$c]) {
            $this->goods[$i - 1][3] = 0;
        } else {
            $this->goods[$i - 1][3] = 1;
            $c = $c - $this->w[$i];
        }
    }
}
```

按照订单价值降序获取订单信息（若订单价值相同则按单位时间平均价值降序排列）：

```PHP
public function getGoods()
{
    $filter = function($value) {
        return $value[3];
    };
    $goods = array_filter($this->goods, $filter);
    usort($goods, function($a, $b) {
        if ($a[2] == $b[2]) {
            if ($a[2] / $a[1] < $b[2] / $b[1]) {
                return 1;
            }
            return 0;
        }
        return $a[2] < $b[2];
    });

    return $goods;
}
```

接收标准输入处理并输出结果：

```PHP
$arr = explode(',', $input);
$filter = function ($value) {
    return explode(' ', $value);
};

$knapsack = new Knapsack(array_map($filter, $arr), 8);
$goods = $knapsack->getGoods();

echo $knapsack->getMaxPrice(), ' ', implode(' ', array_column($goods, 0)), PHP_EOL;
```

## 总结

该题使用动态规划求解，算法的时间复杂度为 $O(nc)$，当然也可以采用其他方式求解。例如先将订单按照价值排序，然后依次尝试进行安排订单，直至剩余耗时不能再被安排订单。

有关动态规划的其他典型应用，请参考 [常见的动态规划问题分析与求解](https://www.cnblogs.com/wuyuegb2312/p/3281264.html) 一文。

<strong>相关文章 [»](#)</strong>

* [王者编程大赛之一](https://www.fanhaobai.com/2017/12/2017-ziroom-king-1.html) <span>（2017-12-05）</span>
* [王者编程大赛之二 — 蓄水池](https://www.fanhaobai.com/2017/12/2017-ziroom-king-2.html) <span>（2017-12-05）</span>
* [王者编程大赛之四 — 约瑟夫环](https://www.fanhaobai.com/2017/12/2017-ziroom-king-4.html) <span>（2017-12-06）</span>
* [王者编程大赛之五 — 最短路径](https://www.fanhaobai.com/2017/12/2017-ziroom-king-5.html) <span>（2017-12-06）</span>
