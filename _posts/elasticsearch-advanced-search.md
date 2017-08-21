---
title: Elasticsearch检索 — 聚合和LBS
date: 2017-08-05 17:42:43
tags:
- cors
categories:
- 语言
- PHP
---

上一篇文章 [Elasticsearch检索实战](https://www.fanhaobai.com/2017/08/elasticsearch-search.html) 已经讲述了 Elasticsearch 基本检索使用，已满足大部分检索场景，但是某些特定项目中会使用到 [聚合]() 和 [LBS]() 这类高级检索，以满足检索需求。这里将讲述 Elasticsearch 的聚合和 LBS 检索使用方法。

{% asset_img  %}<!--more-->

本文示例的房源数据，[见这里](http://es.fanhaobai.com/rooms/_search)，检索同样使用 Elasticsearch 的 DSL 对比 SQL 来说明。

## 聚合

### aggs聚合

aggs 子句聚合是 Elasticsearch 默认的聚合实现方式。

#### 桶和指标

先理解这两个基本概念：

| 名称          | 描述           |
| ----------- | ------------ |
| 桶（Buckets）  | 满足特定条件的文档的集合 |
| 指标（Metrics） | 对桶内的文档进行统计计算 |

每个聚合都是 [一个或者多个桶和零个或者多个指标]() 的组合，聚合可能只有一个桶，可能只有一个指标，或者可能两个都有。例如这个 SQL：

```SQL
SELECT COUNT(field_name) FROM table GROUP BY field_name
```

其中`COUNT(field_name)`相当于指标，`GROUP BY field_name`相当于桶。桶在概念上类似于 SQL 的分组（GROUP BY），而指标则类似于 COUNT() 、 SUM() 、 MAX() 等统计方法。

桶和指标的可用取值列表：

| 分类   | 操作符              | 描述                          |
| ---- | ---------------- | --------------------------- |
| 桶    | terms            | 按精确值划分桶                     |
| 指标   | sum              | 桶内对该字段值求总数                  |
| 指标   | min              | 桶内对该字段值求最小值                 |
| 指标   | max              | 桶内对该字段值求最大值                 |
| 指标   | avg              | 桶内对该字段值求平均数                 |
| 指标   | cardinality（ 基数） | 桶内对该字段不同值的数量（ *distinct* 值） |

#### 简单聚合

Elasticsearch 聚合 DSL 描述如下：

```Js
"aggs" : { 
    "aggs_name" : {
        "operate" : { 
            "field" : "field_name"
        }
    }
}
```
其中，aggs_name 表示聚合结果返回的字段名，operate 表示桶或指标的操作符名，field_name 为需要进行聚合的字段。

* 例1，统计西二旗每个小区的房源数量：

```SQL
-- SQL描述
SELECT resblockId, COUNT(resblockId) FROM rooms WHERE bizcircleCode = 611100314 GROUP BY resblockId
```

Elasticsearch 聚合为：

```Js
{
  "query": {
    "constant_score": {
      "filter": {
        "bool": {
          "must": [{ "term": { "bizcircleCode": 611100314 }}]
        }
      }
    }
  },
  "aggs": {
    "resblock_list": {
      "terms": { "field": "resblockId" }
    }
  }
}
```

聚合结果如下：

```Js
{
"hits": {
    "total": 6,
    "max_score": 1,
    "hits": [... ...]
},
"aggregations": {
    "resblock_list": {
        "doc_count_error_upper_bound": 0,
        "sum_other_doc_count": 0,
        "buckets": [
          {
            "key": 1321052240532,    //小区id为1321052240532有4间房
            "doc_count": 4
          },
          {
            "key": 1111047349969,    //小区id为1111047349969有1间房
            "doc_count": 1
          },
          {
            "key": 1111050770108,    //小区id为1111050770108有1间房
            "doc_count": 1
          }
        ]
    }
}}
```
可见，此时聚合的结果有且只有分组后文档的  [数量]()，只适合做一些分组后文档数的统计。

* 例2，去重统计西二旗小区的数量：

```SQL
-- SQL描述
SELECT COUNT(DISTINCT resblockId) FROM rooms WHERE bizcircleCode = 611100314
```

使用 cardinality 指标统计：

```Js
{
  "aggs": {
    "resblock_count": {
      "cardinality": {
        "field": "resblockId"
      }
    }
  }
}
```

#### 添加度量指标

上述的简单聚合，虽然可以统计桶内的文档数量，但是没法实现组内的其他指标统计，比如小区内的最低房源价格，这时就可以给桶添加一个 min 指标。

```SQL
-- SQL描述
SELECT resblockId, MIN(price) FROM rooms WHERE bizcircleCode = 611100314
```

添加 min 指标后为：

```Js

```


####  嵌套桶



#### 文档信息

当需要获取聚合后每组的文档信息（小区的名字和坐标等）时，就需要嵌套且使用 top_hits 子句来实现。


## LBS