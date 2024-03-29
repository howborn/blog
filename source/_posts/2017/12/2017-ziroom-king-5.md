---
title: 王者编程大赛之五 — 最短路径
date: 2017-12-06 23:14:00
tags:
- 算法
- 数据结构
categories:
- 算法
---

自如年底就会拥有 50W 间房子，大家知道每间房房子都是需要配置完才能出租给自如客的，整个房租的配置过程是很复杂的，每天都需要大量的物流师傅将家电、家具等物品从仓库送到需要配置的每个房间。

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-5/40beff35-47fc-4427-8805-e183233b598b.png)<!--more-->

为了能在更多的时间配置更多的房子，我要不断的优化物流从仓库 A 到房间 G 的路径或者仓库 B 到房间 E 的距离，请写出一种算法给你任意图中两点，计算出两点之间的最短距离。
注：A B C D E F G H 都可能是仓库或者房间，点与点之间是距离。

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-5/40beff35-47fc-4427-8805-e183233b598b.png)

## 解题思路

该题是求解无向图单源点的最短路径，经常采用 [Dijkstra](https://zh.wikipedia.org/wiki/%E6%88%B4%E5%85%8B%E6%96%AF%E7%89%B9%E6%8B%89%E7%AE%97%E6%B3%95) 算法求解，是按路径长度递增的次序产生最短路径。

### 算法理论

Dijkstra 算法是运用了最短路径的最优子结构性质，最优子结构性质描述为：P(i,j) = {$v_i$,...,$v_k$,...,$v_s$,$v_j$} 是从顶点 i 到 j 的最短路径，顶点 k 和 s 是这条路径上的一个中间顶点，那么 P(k,s) 必定也是从 k 到 s 的最短路径。

由于 P(i,j) = {$v_i$,...,$v_k$,...,$v_s$,$v_j$} 是从顶点 i 到 j 的最短路径，则有 P(i,j) = P(i,k) + P(k,s) + P(k,j)。若 P(k,s) 不是从顶点 k 到 s 的最短路径，那么必定存在另一条从顶点 k 到 s 的最短路径 P'(k,s)，故 P'(i,j) = P(i,k) + P'(k,s) + P(k,j) < P(i,j)，与题目相矛盾，因此 P(k,s) 是从顶点 k 到 s 的最短路径。

### 算法流程

根据最短路径的最优子结构性质，Dijkstra 提出了以最短路径长度递增，逐次生成最短路径的算法。譬如对于源顶点 $v_0$，首先选择其直接相邻的顶点中最短路径的顶点$v_i$，那么可得从 $v_0$ 到达 $v_j$ 顶点的最短距离 $D[j]=min(D[j], D[j] + matrix[i][j])$（$matrix[i][j]$ 为从顶点 $v_i$ 到 $v_j$ 的直接距离）。

假设存在图 G={V,E}，V 为所有顶点集合，源顶点为 $v_0$，U={$v_0$} 表示求得终点路径的集合，D[i] 为顶点 $v_0$ 到 $v_i$ 的最短距离，P[i] 为顶点 $v_0$ 到 $v_i$ 最短路径上的顶点。

算法描述为：

1）从 V-U 中选择使 D[i] 值最小的顶点 $v_i$，将 $v_i$ 加入到 U 中；
2）更新 $v_i$ 与任一顶点 $v_j$ 的最短距离，即 $D[j]=min(D[j], D[i]+matrix[i][j])$；
3）直到 U=V，便求得从顶点  $v_0$ 到图中任一一点的最短路径；

例如，求 CG 最短路径，算法过程可图示为：

源顶点 $v_0$ = C，顶点与索引关系为 A→H = 0→7，初始时：

* U = {false, false, false, false, false, false, false, false}
* D = {INF ,INF, **0**, INF, INF, INF, INF, INF}
* P = { {}, {}, {C}, {}, {}, {}, {}, {} }

将顶点 C 包含至 U 中：

* U = {false, false, **true**, false, false, false, false, false}

更新顶点 C 至任一节点的距离：

* D = {**6**, **9**, **0**, **11**, INF, INF, INF, INF}
* P = { {C,A}, {C,B}, {C}, {C,D}, {}, {}, {}, {} }

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-5/b7724f85-3855-410c-9cc7-1cfcee5d29e4.png)

再选择不在 U 中的最短路径顶点 A，则将 A 包含至 U 中：

* U = {**true**, false, **true**, false, false, false, false, false}

更新顶点 A 至任一节点的距离：

* D = {**6**, **9**, **0**, **11**, INF, **25**, INF, INF}
* P = { {C,A}, {C,B}, {C}, {C,D}, {}, {C,A,F}, {}, {} }

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-5/c5f725fc-f801-4e93-9f32-5adb8a76e1a0.png)

继续选择不在 U 中的最短路径顶点 B，则将 B 包含至 U 中：

* U = {**true**, **true**, **true**, false, false, false, false, false}

更新顶点 B 至任一节点的距离：

* D = {**6**, **9**, **0**, **11**, **16**, **25**, INF, INF}
* P = { {C,A}, {C,B}, {C}, {C,D}, {C,B,E}, {C,A,F}, {}, {} }

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-5/45552677-bcd6-4d45-b627-a398f0cfe04d.png)

以此类推，直到遍历结束：

* U =  {**true**, **true**, **true**, **true**, **true**, **true**, **true**, **true**}
* D = {**6**, **9**, **0**, **11**, **16**, **21**, **33**, **16**}
* P = { {C,A}, {C,B}, {C}, {C,D}, {C,B,E}, {C,B,E,F}, {C,B,E,F,G}, {C,D,H} }

![](//www.fanhaobai.com/2017/12/2017-ziroom-king-5/7eeefcb6-6b96-4719-9819-c96b31309449.png)

因此，CG 的最短距离为 33，最短路径为 C-B-E-F-G。

## [编码实现](https://github.com/fan-haobai/2017-ziroom-king/blob/master/src/7.php)

实现的代码如下，并将一一详细说明。

```PHP
define('MAX', 9999999999);

class Path
{
    //图对应索引数组
    public $indexMatrix = array();
    //顶点与索引映射关系
    public $indexMap = array();
    public $startPoint;
    public $endPoint;
    public $len = 0;
    //最短距离
    public $D = array();
    //已寻找集合
    public $U = array();
    //最短路径
    public $P = array();

    public function __construct(array $matrix, $startPoint, $endPoint)
    {
        $this->indexMap = array_keys($matrix);
        $this->len = count($matrix);

        array_walk($matrix, function(&$value) {
            $value = array_values($value);
        });
        $this->indexMatrix = array_values($matrix);
        $this->startPoint = array_search($startPoint, $this->indexMap);
        $this->endPoint = array_search($endPoint, $this->indexMap);
        
        $this->init();
    }

    public function init()
    {
        for ($i = 0; $i < $this->len; $i++) {
            //初始化距离
            $this->D[$i] = $this->indexMatrix[$this->startPoint][$i] > 0 ? $this->indexMatrix[$this->startPoint][$i] : MAX;
            $this->P[$i] = array();
            //初始化已寻找集合
            if ($i != $this->startPoint) {
                array_push($this->P[$i], $i);
                $this->U[$i] = false;
            } else {
                $this->U[$i] = true;
            }
        }
    }
    
    public function getDistance()
    {
        return $this->D[$this->endPoint];
    }

    public function getPath()
    {
        $path = $this->P[$this->endPoint];
        array_unshift($path, $this->startPoint);

        foreach ($path as &$value) {
            $value = $this->indexMap[$value];
        }

        return $path;
    }
}
```

Dijkstra 算法求解：

```PHP
public function dijkstra()
{
    for ($l = 1; $l < $this->len; $l++) {
        $min = MAX;
        //查找距离源点最近的节点{v}
        $v = $this->startPoint;
        for ($i = 0; $i < $this->len; $i++) {
            if (!$this->U[$i] && $this->D[$i] < $min) {
                $min = $this->D[$i];
                $v = $i;
            }
        }
        $this->U[$v] = true;

        //更新最短路径
        for ($i = 0; $i < $this->len; $i++) {
            if (!$this->U[$i] && ($min + $this->indexMatrix[$v][$i] < $this->D[$i])) {
                $this->D[$i] = $min + $this->indexMatrix[$v][$i];
                $this->P[$i] = array_merge($this->P[$v], array($i));
            }
        }
    }
}
```

接收标准输入处理并输出结果：

```PHP
//图
$matrix = array(
    'A' => array('A' => MAX, 'B' => 15, 'C' => 6, 'D' => MAX, 'E' => MAX, 'F' => 25, 'G' => MAX, 'H' => MAX),
    'B' => array('A' => 15, 'B' => MAX, 'C' => 9, 'D' => MAX, 'E' => 7, 'F' => MAX, 'G' => MAX, 'H' => MAX),
    'C' => array('A' => MAX, 'B' => 9, 'C' => MAX, 'D' => 11, 'E' => MAX, 'F' => MAX, 'G' => MAX, 'H' => MAX),
    'D' => array('A' => MAX, 'B' => MAX, 'C' => 11, 'D' => MAX, 'E' => 12, 'F' => MAX, 'G' => MAX, 'H' => 5),
    'E' => array('A' => MAX, 'B' => 7, 'C' => 6, 'D' => 12, 'E' => MAX, 'F' => 5, 'G' => MAX, 'H' => 7),
    'F' => array('A' => 25, 'B' => MAX, 'C' => 6, 'D' => MAX, 'E' => 5, 'F' => MAX, 'G' => 12, 'H' => MAX),
    'G' => array('A' => MAX, 'B' => MAX, 'C' => MAX, 'D' => MAX, 'E' => MAX, 'F' => 12, 'G' => MAX, 'H' => 17),
    'H' => array('A' => MAX, 'B' => MAX, 'C' => MAX, 'D' => 5, 'E' => 7, 'F' => 25, 'G' => 17, 'H' => MAX),
);

//CG
while(!$input = trim(fgets(STDIN), " \t\n\r\0\x0B[]"));
$path = new Path($matrix, $input{0}, $input{1});
$path->dijkstra();
echo $path->getDistance(), ' ', implode('-', $path->getPath()), PHP_EOL;
```

## 总结

本问题是求无向图源点的最短路径，时间复杂度为 $O(n^2)$，若求解有向图源点的最短路径，只需将相邻顶点的逆向路径置为 ∞，即修改初始图的矩阵。不得不说的是，比求单源点最短路径更加复杂的求某一对顶点的最短路径问题，也可以以每一个顶点为源点使用 Dijkstra 算法求解，但是有更加简洁的 [Floyd](https://zh.wikipedia.org/wiki/Floyd-Warshall%E7%AE%97%E6%B3%95) 算法。

<strong>相关文章 [»](#)</strong>

* [王者编程大赛之一](https://www.fanhaobai.com/2017/12/2017-ziroom-king-1.html) <span>（2017-12-05）</span>
* [王者编程大赛之二 — 蓄水池](https://www.fanhaobai.com/2017/12/2017-ziroom-king-2.html) <span>（2017-12-05）</span>
* [王者编程大赛之三 — 01背包](https://www.fanhaobai.com/2017/12/2017-ziroom-king-3.html) <span>（2017-12-05）</span>
* [王者编程大赛之四 — 约瑟夫环](https://www.fanhaobai.com/2017/12/2017-ziroom-king-4.html) <span>（2017-12-06）</span>
