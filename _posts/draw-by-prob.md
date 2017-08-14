---
title: 按照奖品概率分布抽奖的实现
date: 2017-05-18 12:20:23
tags:
- PHP
- 算法
categories:
- 语言
- PHP
---

需求：首先用户通过以一定方式（好友点赞等）开启抽奖资格，然后按照用户 100% 中奖概率进行抽奖，且系统的发放奖品需要按照各个奖品整体的期望中奖比例来进行分布，最后用户抽中奖品调用第三方发放接口发放奖品并记录保存，另有些奖品存在发放数量限制。<!--more-->

## 问题分析

整个抽奖过程是同步进行，由于前置了开启抽奖资格保护，会避免用户集中进行抽奖，故系统并发量并不会太高。突出的问题主要有以下几个：

1）由于同步调用第三方接口发放奖品，奖品可能发放失败；
2）有一些奖品存在数量限制，可能已经发放完；
3）系统要求用户 100% 抽中奖品；
4）系统要求各个奖品总的发放情况符合预期的比例分布；

## 解决方案

针对以上突出问题，给出针对的解决办法。

* 问题1：采用带有次数限制的重试机制，降低奖品发放接口发放失败情况，同时捕获异常来应对接口返回异常信息。重试机制失败则自动重新进行一轮按概率抽奖，依次类推并做重发次数限制；
* 问题2：奖品数量在奖品发放端进行限制。因为系统存在数量限制的奖品期望发放比例较低，每轮抽中这些奖品概率也较低，所以可以采用若奖品已发放完，则自动重新进行一轮按概率抽奖，依次类推并做重发次数限制；
* 问题3：尽管有发放接口的重试机制和自动多轮按概率抽奖机制，也可能存在抽取奖品失败的情况，这里采用一种特定奖品作为兜底的办法，当然兜底奖品也有重试机制，使用户抽中概率接近 100%；
* 问题4：因为重试机制失败或者抽取到已经发送完毕的奖品时，会自动重新进行下一轮抽奖，由于规则也是按照概率抽奖，所以不影响各个奖品总的比例分布情况；

## 编码

### 按概率抽奖

核心思想是采用随机函数 mt_rand() 来模拟用户抽奖。

奖品信息如下：
```PHP
//所有奖品信息
$allPrizes = [
  'jd'    => ['name' => '京东券', 'probability' => 30],
  'film'  => ['name' => '电影票', 'probability' => 10],
  'tb'    => ['name' => '淘宝券', 'probability' => 60],
]
```

**方式一** 

这是一个比较中规中矩的方式，*主要思想* 是：将所有奖品按照期望比例分布，一段一段小区间分布到 1~100 这个区间，然后随机一个 1~100 的随机数，如果这个随机数落在某段区间，则表示抽取对应区间的奖品。

```
1            30     10                    60
1|-----------|------|----------------------|100
     京东券    电影票          淘宝券       
```

代码如下：
```PHP
/**
 * 按照概率抽取一个奖品, 返回奖品
 * @param   array      $prizes     所有奖品的probability概率总和应该为100
 * @return  mixed
 */
private function randPrize(array $prizes)
{
    //总概率基数
    $totalProbability = array_sum(array_column(array_values($prizes), 'probability'));
    if (100 !== $totalProbability) {
        throw new Exception('invalid probability config');
    }
    $rand = mt_rand(1, 100);
    $cursor = 0;
    $id = '';
    while(list($key, $item) = each($prizes)) {
        if ($rand > $cursor && $rand <= $cursor + $item['probability']) {
            $id = $key;
            break;
        }
        $cursor += $item['probability'];
    }
    unset($prizes[$id]['probability']);

    return $prizes[$id] + ['id' => $id];
}
```

*方式二*

该方式如果直接看代码比较难理解。主要思想：按照给定顺序（按照奖品配置顺序），先后一个一个抽取奖品，直到抽中一个奖品为止， 抽中后续奖品的概率的前提是没有抽中当前奖品，多次抽取概率应该相乘。

例如：

```
次数       奖品       概率    基数        中奖概率                     未中奖概率
 1        京东券      30     100         30/100                      70/100
 2        电影票      10      70      (70/100)*(10/70)           (70/100)*(60/70)
 3        淘宝券      60      60     (70/100)*(60/70)*(1)       1-(70/100)*(60/70)*(1)
```

```PHP
/**
 * 按照概率抽取一个奖品, 返回奖品, 
 * @param   array    $prizes    参与抽奖的奖品信息, 所有奖品的probability概率总和应该为100
 * @return  array
 */
private function randPrize(array $prizes)
{
    //总概率基数
    $totalProbability = array_sum(array_column(array_values($prizes), 'probability'));
    if (100 !== $totalProbability) {
        throw new Exception('invalid probability config');
    }
    //可以考虑按照概率倒序排序
    /*uasort($prizes, function(array $a, array $b) {
        if ($a['probability'] == $b['probability']) return 0;
        return $a['probability'] > $b['probability'] ? -1 : 1;
    });*/
    //按照奖品顺序依次模拟抽中奖品
    $id = '';
    foreach ($prizes as $key => $item) {
        $rand = mt_rand(1, $totalProbability);    //本次抽奖的基数
        if ($rand <= $item['probability']) {      //表示抽中
            $id = $key;
            break;
        } else {
            $totalProbability -= $item['probability'];  //后续奖品基数减去抽过的概率, 因为抽中后一个奖品的前提是抽不中前一些奖品
        }
    }
    unset($prizes[$id]['probability']);
    return $prizes[$id] + ['id' => $id];
}
```

### 抽中奖品

主要包含重试机制、自动重新一轮按照概率抽奖机制、兜底机制的实现。

 ```PHP
/**
 * 抽奖
 * @param   array   $allPrizes
 * @return  mixed
 */
public function draw($allPrizes)
{
    $tryTimes = 0;
    $outPrize = [];
    $prize = [];

    //如果抽到有数量限制奖品且奖品也已经抽完或者抽取失败, 最多抽奖次数
    while ($tryTimes < 4) {
        $tryTimes++;
        //按照概率抽取
        $prize =  $this->randPrize($allPrizes);
        //模拟发放奖品方法
        $outPrize = $this->getOnePrize($prize['id']);
        //抽中退出
        if (!empty($outPrize)) {
            break;
        }
    }

    echo '尝试按照概率抽取次数:' , $tryTimes, PHP_EOL;

    //多次抽奖都抽中已经抽完的奖品, 则用兜底奖品兜底
    $tryTimes = 0;
    while (!$outPrize && $tryTimes < 2) {
        $tryTimes++;
	$prize = $allPrizes['default'] + ['id' => 'default'];
        $outPrize = $this->getOnePrize('default');
    }

    echo '兜底抽取次数:' , $tryTimes, PHP_EOL;

    if (!$outPrize) {
        //兜底失败, 可能是券达到上限, 或者接口down了
        return false;
    } else {
        //合并奖品信息
        $outPrize = $outPrize + $prize;
    }

    return $outPrize;
}
 ```

## 验证

### 概率分布

*抽样方法*
```PHP
public function sample($all, $times)
{
    $out = [];
    $count = $times;
    if ($times > 1000000) return;
    while ($times) {
        $times--;
        $prize = $this->draw($all);
        if (!isset($out[$prize['id']])) {
            $out[$prize['id']] = 0;
        }
        $out[$prize['id']]++;
    }
    array_walk($out, function(&$value, $key) use ($count) {
        $value = ($value / $count * 100);
    });
 
    ksort($out);
    return $out;
}
```
*抽样结果*
```PHP
//期望概率
array(3) {
  ["film"] => int(10)
  ["jd"] => int(30)
  ["tb"] => int(60)
}
//抽样2000次
array(3) {
  ["film"] => string(4) "9.8"
  ["jd"] => string(6) "31.35"
  ["tb"] => string(6) "58.85"
}
```

### 异常处理机制

```PHP
尝试按照概率抽取次数: 3
兜底抽取次数: 0
抽中奖品为：array(3) {
  ["name"] => string(20) "淘宝50元消费券"
  ["content"] => string(12) "WD84-3233-21"
  ["id"] => string(2) "tb"
}
```

