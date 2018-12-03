---
title: 负载均衡算法 — 轮询
date: 2018-11-30 19:14:10
tags:
- 算法
categories:
- 算法
- PHP
---

在分布式系统中，为了实现负载均衡，就会涉及到负载调度算法。负载调度典型的应用场景如 Nginx 的 upstream 和 RPC 服务发现，常见的负载均衡算法有  [轮询]()、[源地址 Hash]()、[最少连接数]()，而 **轮询** 是最简单且应用最广的算法。

![预览图](https://img1.fanhaobai.com/2018/11/load-balance-round-robin/1e858872-6235-4131-98ba-433690eb32c1.jpg)<!--more-->

3 种常见的轮询调度算法，分别为 [简单轮询](#简单轮询)、[加权轮询](#加权轮询)、[平滑加权轮询]()。如下 4 个服务，本文将用其来说明轮询调度过程。

|    服务实例   | 	权重值 |
| ------------ | --------------|
|  192.168.10.1:2202 |	1 |
|  192.168.10.2:2202 | 2 |
|  192.168.10.3:2202 | 	3 |
|  192.168.10.4:2202 | 	4 |

## 简单轮询

简单轮询是轮询算法中最简单的一种，由于它不支持配置负载比例，所以应用较少。

### 算法描述

假设有 N 台实例 S = {S1, S2, …, Sn}，指示变量 currentPos 表示当前选择的实例 ID，初始化为 -1。算法可以描述为：
1、请求到来时，自加变量 currentPos，使其指向下一个实例；
2、重复步骤 1，若所有实例已被 **调度** 过一次（上一次调度时 currentPos 指向了最后一个实例），则重置为 0；

调度过程，如下：

|  请求     | currentPos |       选中的实例     |
| -------- | ---------| -----------------------------|
|    1  |   0 |    192.168.10.1:2202  |
|    2  |   1 |    192.168.10.2:2202  |
|    3  |   2 |    192.168.10.3:2202  |
|    4  |   3 |    192.168.10.4:2202  |
|    5  |   0 |    192.168.10.1:2202  |

### [代码实现](https://github.com/fan-haobai/load-balance/blob/master/Robin/Robin.php)

这里使用 PHP 来实现，源码见 [load-balance](https://github.com/fan-haobai/load-balance) 部分。

首先，定义一个统一的操作接口，主要有`init()`和`next()`这 2 个方法。

```PHP
interface RobinInterface
{
    /**
     * 初始化服务权重
     *
     * @param array $services
     *
     * @return mixed
     */
    public function init(array $services);

    /**
     * 获取一个服务
     *
     * @return mixed
     */
    public function next();

}
```

然后，根据简单轮询算法思路，实现上述接口：

```PHP
class Robin implements RobinInterface
{
    private $services = array();

    private $total;

    private $currentPos = -1;

    public function init(array $services)
    {
        $this->services = $services;
        $this->total = count($services);
    }

    public function next()
    {
        // 已调度完一圈,重置currentPos值为第一个实例位置
        $this->currentPos = ($this->currentPos + 1) % $this->total;

        return $this->services[$this->currentPos];
    }

}
```

其中，`total`为总实例数量，`services`为服务实例列表。由于简单轮询调度不需要配置权重，因此可简单配置为：

```PHP
$services = [
    '192.168.10.1:2202',
    '192.168.10.2:2202',
    '192.168.10.3:2202',
    '192.168.10.4:2202',
];
```

### 优缺点分析

在实际应用中，同一个服务部署到不同的硬件环境，会出现性能不同的情况。若直接使用简单轮询调度算法，给每个服务实例相同的负载，那么，必然会出现资源浪费的情况。因此为了避免这种情况，就出现了下面的 [加权轮询](#加权轮询) 算法。

## 加权轮询

加权轮询算法引入了“权”，改进了简单轮询算法，可以根据硬件性能配置实例的权重，从而合理利用资源。

### 算法描述

假设有 N 台实例 S = {S1, S2, …, Sn}，权重 W = {W1, W2, ..., Wn}，指示变量 currentPos 表示当前选择的实例 ID，初始化为 -1；变量 currentWeight 表示当前权重，初始值为 max(S)；max(S) 表示 N 台实例的最大权重值，gcd(S) 表示 N 台实例权重的最大公约数。算法可以描述为：
1、请求到来时，赋值变量 i 为 currentPos，自加 i **直到** i 指向的实例的权重大于或等于 currentWeight；
2、若所有实例已被遍历过一次（上一次遍历时 i 指向了最后一个实例），则重置 i 为 0；并且 currentWeight 减小为 currentWeight - gcd(S)，若 currentWeight 小于或等于 0，则重置为 max(S)；
3、赋值 currentPos 为 i；

例如，上述 4 个服务，最大权重 max(S) 为 4，最大公约数 gcd(S) 为 1。其调度过程如下：

|  请求      | currentPos |   currentWeight  |      选中的实例     |
| ----------- | ---------- | ---------------- | ------------------- |
|   1        |   3        |   4           |   192.168.10.4:2202  |
|   2        |   2        |   3           |   192.168.10.3:2202  |
|   3        |   3        |   3           |   192.168.10.4:2202  |
|   4        |   1        |   2           |   192.168.10.2:2202  |
|   ...      |   ...      |  ...          |   ....               |
|   6        |   3        |   2           |   192.168.10.4:2202  |
|   7        |   0        |   1           |   192.168.10.1:2202  |
|   ...      |   ...      |  ...          |   ....               |
|   9        |   2        |  1            |   192.168.10.3:2202  |
|   10       |   3        |  4            |   192.168.10.4:2202  |

### [代码实现](https://github.com/fan-haobai/load-balance/blob/master/Robin/WeightRobin.php)

这里使用 PHP 来实现，源码见 [load-balance](https://github.com/fan-haobai/load-balance) 部分。

```PHP
class WeightRobin implements RobinInterface
{
    private $services = array();

    private $total;

    private $currentPos = -1;

    private $currentWeight;

    public function init(array $services)
    {
        foreach ($services as $ip => $weight) {
            $this->services[] = [
                'ip'     => $ip,
                'weight' => $weight,
            ];
        }

        $this->total = count($this->services);
    }

    public function next()
    {
        $i = $this->currentPos;
        while (true) {
            $i = ($i + 1) % $this->total;

            // 已全部被遍历完一次
            if (0 === $i) {
                // 减currentWeight
                $this->currentWeight -= $this->getGcd();

                // 赋值currentWeight为0,回归到初始状态
                if ($this->currentWeight <= 0) {
                    $this->currentWeight = $this->getMaxWeight();
                }
            }

            // 直到当前遍历实例的weight大于或等于currentWeight
            if ($this->services[$i]['weight'] >= $this->currentWeight) {
                $this->currentPos = $i;

                return $this->services[$this->currentPos]['ip'];
            }
        }
    }
```

其中，`getMaxWeight()`为所有实例的最大权重值；`getGcd()`为所有实例权重的最大公约数，主要是通过`gcd()`方法（可以使用`gmp_gcd()`函数）求得 2 个数的最大公约数，然后求每一个实例的权重与当前最大公约数的最大公约数。实现如下：

```PHP
private function getGcd()
{
    $gcd = $this->services[0]['weight'];

    for ($i = 0; $i < $this->total; $i++) {
        $gcd = $this->gcd($gcd, $this->services[$i]['weight']);
    }

    return $gcd;
}
```

需要注意的是，在配置`services`服务列表时，需要指定其权重：

```PHP
$services = [
    '192.168.10.1:2202' => 1,
    '192.168.10.2:2202' => 2,
    '192.168.10.3:2202' => 3,
    '192.168.10.4:2202' => 4,
];
```

### 优缺点分析

[加权轮询](#加权轮询) 算法虽然通过配置实例权重，解决了 [简单轮询](#简单轮询) 的资源利用问题，但是它还是存在一个比较明显的 **缺陷**。例如：

服务实例 S =  {a, b, c}，权重 W = {5, 1, 1}，使用加权轮询调度生成的实例序列为 {a, a, a, a, a, b, c}，那么就会存在连续 5 个请求都被调度到实例 a。而实际中，这种不均匀的负载是不被允许的，因为连续请求会突然加重实例 a 的负载，可能会导致严重的事故。

为了解决加权轮询调度不均匀的缺陷，一些人提出了 [平滑加权轮询]() 调度算法，它会生成的更均匀的调度序列 {a, a, b, a, c, a, a}。对于神秘的平滑加权轮询算法，我将在后续文章中详细介绍它的原理和实现。

## 总结

轮询算法是最简单的调度算法，因为它无需记录当前所有连接的状态，所以它是一种  [无状态]() 的调度算法，这些特性使得它应用较广。

需要注意的是，轮询调度算法并不能动态感知每个实例的负载，依赖于我们的历史经验，人为配置权重来实现基本的负载均衡，并不能保证服务的高可用性。若服务的某些实例因其他原因负载突然加重，轮询调度还是会一如既往地分配请求给这个实例，因此可能会形成小面积的宕机，导致服务的不可用。