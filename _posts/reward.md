---
title: PHP生成随机红包算法
date: 2017-02-13 00:07:06
tags:
- PHP
- 算法
categories:
- 语言
- PHP
---

>原文：http://www.lcode.cc/2016/12/24/rand_ward.html

前一阵公司业务有一个生成红包的需求，分为固定红包和随机红包两种，固定红包没什么好说的了，随机红包要求指定最小值，和最大值，必须至少有一个最大值，可以没有最小值，但任何红包不能小于最小值。

![](https://img.fanhaobai.com/2017/02/reward/p4GlWAFMrXts5zPMnA88Zsm_.png)<!--more-->

以前从来没做过这方面，有点懵B，于是去百度了一番，结果发现能找到的红包算法都有各种各样的 bug，要么会算出负值，要么超过最大值，所以决定自己撸一套出来。

# 基本思路

在随机数生成方面，我借鉴了这位博主 [＠悲惨的大爷](http://www.cnblogs.com/hanyouchun/p/5074923.html) 的思路：

>**原文**：比如要把 1 个红包分给 N 个人，实际上就是相当于要得到 N 个百分比数据 条件是这 N 个百分比之和 = 100/100。这 N 个百分比的平均值是 1/N。 并且这 N 个百分比数据符合一种正态分布（多数值比较靠近平均值）。   
>**解读**：比如我有 1000 块钱，发 50 个红包，就先随机出 50 个数，然后算出这 50 个数的均值 avg，用 avg/(1/N)，就得到了一个基数 mixrand ，然后用随机出的那 50 个数分别去除以 mixrand ，得到每个数相对基数的百分比 randVal ，然后用 randVal 乘以 1000 块钱，就可以得到每个红包的具体金额了。

还是不太清楚咋回事？没关系，我们一起撸代码！

# 算法实现

Talk is cheap, show me your code!

## 核心生成算法

```PHP
<?php
/*
 * Author:xx_lufei
 * Time:2016年9月14日09:55:36
 * Note:红包生成随机算法
 */
class Reward
{
    public $rewardMoney;        #红包金额、单位元
    public $rewardNum;          #红包数量

    #执行红包生成算法
    public function splitReward($rewardMoney, $rewardNum, $max, $min)
    {
        #传入红包金额和数量，因为小数在计算过程中会出现很大误差，所以我们直接把金额放大100倍，后面的计算全部用整数进行
        $min = $min * 100;
        $max = $max * 100;
        #预留出一部分钱作为误差补偿，保证每个红包至少有一个最小值
        $this->rewardMoney = $rewardMoney * 100 - $rewardNum * $min;
        $this->rewardNum = $rewardNum;
        #计算出发出红包的平均概率值、精确到小数4位。
        $avgRand = 1 / $this->rewardNum;
        $randArr = array();
        #定义生成的数据总合sum
        $sum = 0;
        $t_count = 0;
        while ($t_count < $rewardNum) {
            #随机产出四个区间的额度
            $c = rand(1, 100);
            if ($c < 15) {
                $t = round(sqrt(mt_rand(1, 1500)));
            } else if ($c < 65) {
                $t = round(sqrt(mt_rand(1500, 6500)));
            } else if ($c < 95) {
                $t = round(sqrt(mt_rand(6500, 9500)));
            } else {
                $t = round(sqrt(mt_rand(9500, 10000)));
            }
            ++$t_count;
            $sum += $t;
            $randArr[] = $t;
        }

        #计算当前生成的随机数的平均值，保留4位小数
        $randAll = round($sum / $rewardNum, 4);

        #为将生成的随机数的平均值变成我们要的1/N，计算一下每个随机数要除以的总基数mixrand。此处可以约等处理，产生的误差后边会找齐
        #总基数 = 均值/平均概率
        $mixrand = round($randAll / $avgRand, 4);

        #对每一个随机数进行处理，并乘以总金额数来得出这个红包的金额。
        $rewardArr = array();
        foreach ($randArr as $key => $randVal) {
            #单个红包所占比例randVal
            $randVal = round($randVal / $mixrand, 4);
            #算出单个红包金额
            $single = floor($this->rewardMoney * $randVal);
            #小于最小值直接给最小值
            if ($single < $min) {
                $single += $min;
            }
            #大于最大值直接给最大值
            if ($single > $max) {
                $single = $max;
            }
            #将红包放入结果数组
            $rewardArr[] = $single;
        }

        #对比红包总数的差异、将差值放在第一个红包上
        $rewardAll = array_sum($rewardArr);
        #此处应使用真正的总金额rewardMoney，$rewardArr[0]可能小于0
        $rewardArr[0] = $rewardMoney * 100 - ($rewardAll - $rewardArr[0]);
        #第一个红包小于0时,做修正
        if ($rewardArr[0] < 0) {
            rsort($rewardArr);
            $this->add($rewardArr, $min);
        }

        rsort($rewardArr);
        #随机生成的最大值大于指定最大值
        if ($rewardArr[0] > $max) {
            #差额
            $diff = 0;
            foreach ($rewardArr as $k => &$v) {
                if ($v > $max) {
                    $diff += $v - $max;
                    $v = $max;
                } else {
                    break;
                }
            }
            $transfer = round($diff / ($this->rewardNum - $k + 1));
            $this->diff($diff, $rewardArr, $max, $min, $transfer, $k);
        }
        return $rewardArr;
    }

    #处理所有超过最大值的红包
    public function diff($diff, &$rewardArr, $max, $min, $transfer, $k)
    {
        #将多余的钱均摊给小于最大值的红包
        for ($i = $k; $i < $this->rewardNum; $i++) {
            #造随机值
            if ($transfer > $min * 20) {
                $aa = rand($min, $min * 20);
                if ($i % 2) {
                    $transfer += $aa;
                } else {
                    $transfer -= $aa;
                }
            }
            if ($rewardArr[$i] + $transfer > $max) continue;
            if ($diff - $transfer < 0) {
                $rewardArr[$i] += $diff;
                $diff = 0;
                break;
            }
            $rewardArr[$i] += $transfer;
            $diff -= $transfer;
        }
        if ($diff > 0) {
            $i++;
            $this->diff($diff, $rewardArr, $max, $min, $transfer, $k);
        }
    }

    #第一个红包小于0,从大红包上往下减
    public function add(&$rewardArr, $min)
    {
        foreach ($rewardArr as &$re) {
            $dev = floor($re / $min);
            if ($dev > 2) {
                $transfer = $min * floor($dev / 2);
                $re -= $transfer;
                $rewardArr[$this->rewardNum - 1] += $transfer;
            } elseif ($dev == 2) {
                $re -= $min;
                $rewardArr[$this->rewardNum - 1] += $min;
            } else {
                break;
            }
        }
        if ($rewardArr[$this->rewardNum - 1] > $min || $rewardArr[$this->rewardNum - 1] == $min) {
            return;
        } else {
            $this->add($rewardArr, $min);
        }
    }
}
```

## 细节考虑

下边这段代码用来控制具体的业务逻辑，按照具体的需求，留出固定的最大值、最小值红包的金额等；在代码中调用生成红包的方法时 splitReward($total, $num,$max - 0.01, $min)，我传入的最大值减了 0.01，这样就保证了里面生成的红包最大值绝对不会超过我们设置的最大值。 

```PHP
<?php 
class CreateReward{
    /*
     * 生成红包
     * author    xx     2016年9月23日13:53:38
     * @param   int          $total               红包总金额
     * @param   int          $num                 红包总数量
     * @param   int          $max                 红包最大值
     * 
     */
    public function random_red($total, $num, $max, $min)
    {
        #总共要发的红包金额，留出一个最大值;
        $total = $total - $max;
        $reward = new Reward();
        $result_merge = $reward->splitReward($total, $num, $max - 0.01, $min);
        sort($result_merge);
        $result_merge[1] = $result_merge[1] + $result_merge[0];
        $result_merge[0] = $max * 100;
        foreach ($result_merge as &$v) {
            $v = floor($v) / 100;
        }
        return $result_merge;
    }
}
```

# 实例测试

## 基础代码

先设置好各种初始值。

```PHP
<?php
/**
 * Created by PhpStorm.
 * User: lufei
 * Date: 2017/1/4
 * Time: 22:49
 */
header('content-type:text/html;charset=utf-8');
ini_set('memory_limit', '128M');

require_once('CreateReward.php');
require_once('Reward.php');

$total = 50000;
$num = 300000;
$max = 50;
$min = 0.01;

$create_reward = new CreateReward();
```

## 性能测试

因为 memory_limit 的限制，所以只测了 5 次的均值，结果都在 1.6s 左右。

```PHP
for($i=0; $i<5; $i++) {
    $time_start = microtime_float();
    $reward_arr = $create_reward->random_red($total, $num, $max, $min);
    $time_end = microtime_float();
    $time[] = $time_end - $time_start;
}
echo array_sum($time)/5;
function microtime_float()
{
    list($usec, $sec) = explode(" ", microtime());
    return ((float)$usec + (float)$sec);
}
```

运行结果：

![](https://img.fanhaobai.com/2017/02/reward/Dd5AQhhljSVuOdmUAngQ0Zka.png)

## 数据检查

**1） 数值是否有误**

检测有没有负值，有没有最大值，最大值有多少个，有没有小于最小值的值。

```PHP
$reward_arr = $create_reward->random_red($total, $num, $max, $min);
sort($reward_arr);//正序，最小的在前面
$sum = 0;
$min_count = 0;
$max_count = 0;
foreach($reward_arr as $i => $val) {
    if ($i<3) {
        echo "<br />第".($i+1)."个红包，金额为：".$val."<br />";  
    } 
    if ($val == $max) {
          $max_count++;
    }
    if ($val < $min) {
        $min_count++;
    }
    $val = $val*100;
    $sum += $val;
}
//检测钱是否全部发完
echo '<hr>已生成红包总金额为：'.($sum/100).';总个数为：'.count($reward_arr).'<hr>';
//检测有没有小于0的值
echo "<br />最大值:".($val/100).',共有'.$max_count.'个最大值，共有'.$min_count.'个值比最小值小';
```

运行结果：

![](https://img.fanhaobai.com/2017/02/reward/JXPHry2Rdd_PuvEwsaZrFJTq.png)

**2） 正态分布情况**

注意，出图的时候，红包的数量不要给的太大，不然页面渲染不出来，会崩 。

```PHP
$reward_arr = $create_reward->random_red($total, $num, $max, $min);
$show = array();
rsort($reward_arr);
//为了更直观的显示正态分布效果,需要将数组重新排序
foreach($reward_arr as $k=>$value)
{
    $t=$k%2;
    if(!$t) $show[]=$value;;
    else array_unshift($show,$value);
}
echo "设定最大值为:".$max.',最小值为:'.$min.'<hr />';
echo "<table style='font-size:12px;width:600px;border:1px solid #ccc;text-align:left;'><tr><td>红包金额</td><td>图示</td></tr>";
foreach($show as $val)
{
    #线条长度计算
    $width=intval($num*$val*300/$total);
    echo "<tr><td> {$val} </td><td width='500px;text-align:left;'><hr style='width:{$width}px;height:3px;border:none;border-top:3px double red;margin:0 auto 0 0px;'></td></tr>";
}
echo "</table>";
```

运行结果：

![](https://img.fanhaobai.com/2017/02/reward/p4GlWAFMrXts5zPMnA88Zsm_.png)

>**PS**：有朋友问我生成的数据有没有通过数学方法来验证其是否符合标准正态分布，因为我的数学不好，这个还真没算过，只是看着觉得像，就当他是了。既然遇到了这个问题，就一定要解决嘛，所以我就用 php 内置函数算了一下，算出来的结果在数据量小的时候还是比较接近正态分布的，但是数据量大起来的时候就不能看了，我整不太明白这个，大家感兴趣的可以找一下原因哟。 php 的四个函数：stats_standard_deviation（标准差），stats_variance（方差）， stats_kurtosis（(峰度），stats_skew（偏度）。使用上面的函数需要安装 [stats]((http://pecl.php.net/package/stats) 扩展。

# 总结

到这里，红包就算是写完啦，不知道能不能涨 50 块工资，但应该能解决燃眉之急了。 
哦对，还落下了这个源码，[打包下载](https://github.com/xxlufei/reward) 。
