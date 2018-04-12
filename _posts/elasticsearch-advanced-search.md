---
title: Elasticsearch检索 — 聚合和LBS
date: 2017-08-21 22:42:43
tags:
- Elasticsearch
categories:
- Lucene
---

文章 [Elasticsearch检索实战](https://www.fanhaobai.com/2017/08/elasticsearch-search.html) 已经讲述了 Elasticsearch 基本检索使用，已满足大部分检索场景，但是某些特定项目中会使用到 [聚合]() 和 [LBS]() 这类高级检索，以满足检索需求。这里将讲述 Elasticsearch 的聚合和 LBS 检索使用方法。

![](https://img.fanhaobai.com/2017/08/elasticsearch-advanced-search/d758139c-86ce-4472-89e8-7eb385cf7991.jpg)<!--more-->

本文示例的房源数据，[见这里](http://es.fanhaobai.com/rooms/_search)，检索同样使用 Elasticsearch 的 DSL 对比 SQL 来说明。

## 聚合

### 常规聚合

aggs 子句聚合是 Elasticsearch 常规的聚合实现方式。

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

| 分类   | 操作符              | 描述                         |
| ---- | ---------------- | -------------------------- |
| 桶    | terms            | 按精确值划分桶                    |
| 指标   | sum              | 桶内对该字段值求总数                 |
| 指标   | min              | 桶内对该字段值求最小值                |
| 指标   | max              | 桶内对该字段值求最大值                |
| 指标   | avg              | 桶内对该字段值求平均数                |
| 指标   | cardinality（基数） | 桶内对该字段不同值的数量（*distinct* 值） |

#### 简单聚合

Elasticsearch 聚合 DSL 描述如下：

```Js
"aggs" : { 
    "aggs_name" : {
        "operate" : { "field" : "field_name" }
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
          "key": 1321052240532, //小区id为1321052240532有4间房
          "doc_count": 4
        },
        {
          "key": 1111047349969,//小区id为1111047349969有1间房
          "doc_count": 1
        },
        {
          "key": 1111050770108,//小区id为1111050770108有1间房
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
{
  "aggs": {
    "resblock_list": {
      "terms": { "field": "resblockId" },
      "aggs": {
        "min_price": {
          "min": { "field": "price" }
        }
      }
    }
  }
}
```

结果为：

```Js
"buckets": [
  {
    "key": 1321052240532,
    "doc_count": 4,
    "min_price": {
      "value": 3320
    }
  }
]
```

####  嵌套桶

当然桶与桶之间也可以进行嵌套，这样就能满足复杂的聚合场景了。

例如，统计每个商圈的房源价格分布情况：

```SQL
-- SQL描述
SELECT bizcircleCode, GROUP_CONCAT(price) FROM rooms WHERE cityCode = 110000 GROUP BY bizcircleCode
```

桶聚合实现如下：

```Js
{
  "aggs": {
    "bizcircle_price": {
      "terms": { "field": "bizcircleCode" },
      "aggs": {
        "price_list": {
          "terms": { "field": "price" }
        }
      }
    }
  }
}
```

聚合结果如下：

```Js
{
  "bizcircle_price": {
  "doc_count_error_upper_bound": 0,
  "sum_other_doc_count": 0,
  "buckets": [
    {
      "key": 18335745,
      "doc_count": 1,
      "price_list": {
      "buckets": [
        {
          "key": 3500,
          "doc_count": 1
        }
      ]
    },
    ... ...
  ]
}
```

#### 增加文档信息

通常情况下，聚合只返回了统计的一些指标，当需要获取聚合后每组的文档信息（小区的名字和坐标等）时，该怎么处理呢？这时，使用 top_hits 子句就可以实现。

例如，获取西二旗每个小区最便宜的房源信息：

```Js
{
  "aggs": {
    "rooms": {
      "top_hits": {
        "size": 1,
        "sort": { "price": "asc" },
        "_source": []
      }
    }
  }
}
```

其中，size 为组内返回的文档个数，sort 表示组内文档的排序规则，_source 指定组内文档返回的字段。

聚合后的房源信息：

```Js
{
  "bizcircle_price": {
    "buckets": [
    {
      "key": 1111050770108,
      "doc_count": 1,
      "rooms": {
        "hits": {
          "total": 1,
          "hits": [
            {
              "_index": "rooms",
              "_source": {
                "resblockId": 1111050770108,
                "resblockName": "领秀慧谷C区",
                "size": 15.3,
                "bizcircleName": [ "西二旗", "回龙观" ],
                "location": "40.106349,116.31051"
              },
              "sort": [ 3500 ]
           }
         ]
       }
     }
    }]
  }
}
```

### 字段折叠

从 Elasticsearch 5.0 之后，增加了一个新特性 field collapsing（字段折叠），字段折叠就是特定字段进行合并并去重，然后返回结果集，该功也能实现 agg top_hits 的聚合效果。

例如， [增加文档信息](#增加文档信息) 部分的获取西二旗每个小区最便宜的房源信息，可以实现为：

```Js
{
  "collapse": {
    "field": "resblockId",  //按resblockId字段进行折叠
    "inner_hits": {
      "name": "top_price", //房源信息结果键名
      "size": 1,           //每个折合集文档数
      "sort": [            //每个折合集文档排序规则
        { "price": "desc" }
      ],
      "_source": []        //文档的字段
    }
  }
}
```

检索结果如下：

```Js
{
  "hits": {
    "total": 7,
    "hits": [
    {
      "_index": "rooms",
      "_score": 1,
      "_source": {
        "resblockId": 1111050770108,
        "resblockName": "领秀慧谷C区",
        ... ...
      },
      "fields": {
        "resblockId": [ 1111050770108 ]
      },
      "inner_hits": {
        "top_price": {
          "hits": {
            "total": 1,
            "hits": [ 
            { 
              "_index": "rooms",
              "_source": {
                "resblockId": 1111050770108,
                "resblockName": "领秀慧谷C区",
                "price": 3500,
                ... ...
                "location": "40.106349,116.31051"
              },
              "sort": [ 3500 ]
            }]
          }
        }
      }
    ]
  }
}
```

> Field collapsing 和 agg top_hits 区别：field collapsing 的结果是够精确，同时速度较快，更支持分页功能。

## LBS

Elasticsearch 同样也支持了空间位置检索，即可以通过地理坐标点进行过滤检索。

### 索引格式

由于地理坐标点不能被动态映射自动检测，需要显式声明对应字段类型为 geo-point，如下：

```Js
PUT /rooms   //索引名

{
  "mappings": {
    "room": {
      "properties": {
        ... ...
        "location": {          //空间位置检索字段
          "type": "geo_point"  //字段类型
        }
      }
    }
  }
}
```

### 数据格式

当需检索字段类型设置成 geo_point 后，推送的经纬度信息的形式可以是字符串、数组或者对象，如下：

| 形式   | 符号         | 示例                                    |
| ---- | ---------- | ------------------------------------- |
| 字符串  | "lat,lon"  | "40.060937,116.315943"                |
| 对象   | lat 和 lon  | { "lat":40.060937, "lon":116.315943 } |
| 数组   | [lon, lat] | [116.315943, 40.060937]               |

特别需要注意数组形式时 lon 与 lat 的前后位置，不然就果断踩坑了。

然后，推送含有经纬度的数据：

```Js
POST /rooms/room/

{
  "resblockId": 1321052240532,
  "resblockName": "领秀新硅谷1号院",
  "houseId": 1112046338679,
  "cityCode": 110000,
  "size": 14,
  "bizcircleCode": [ 611100314 ],
  "bizcircleName": [ "西二旗" ],
  "price": 3330,
  "location": "40.060937,116.315943"
}
```

### 检索过滤方式

Elasticsearch 中支持 4 种地理坐标点过滤器，如下表：

| 名称                 | 描述                     |
| ------------------ | ---------------------- |
| geo_distance       | 找出与指定位置在给定距离内的点        |
| geo_distance_range | 找出与指定点距离在最小距离和最大距离之间的点 |
| geo_bounding_box   | 找出落在指定矩形框中的点           |
| geo_polygon        | 找出落在多边形中的点，将不说明        |

例如，查找西二旗地铁站 4km 的房源信息：

```Js
{
  "filter": {              //过滤搜索子句
    "geo_distance": {
      "distance": "4km",
      "location": {
        "lat": 40.106349,
        "lon": 116.31051
      }
    }
  }
}
```

LBS 检索的结果为：

```Js
{
  "hits": [
    {
      "_index": "rooms",
      "_source": {
        "resblockId": 1111050770108,
        "resblockName": "领秀慧谷C区",
        ... ...
        "location": "40.106349,116.31051"
      }
    },
    {
      "_index": "rooms",
      "_source": {
        "resblockId": 1111047349969,
        "resblockName": "融泽嘉园",
        ... ...
        "location": "40.074203,116.315445"
      }
    }
  ]
}
```

## 总结

本文讲述了使用 Elasticsearch 进行 [聚合]() 和 [LBS]() 检索，尽管文中只是以示例形式进行说明，会存在很多不全面的地方，还是希望对你我学习 Elasticsearch 能有所帮助。

<strong>相关文章 [»]()</strong>

* [Elasticsearch检索实战](https://www.fanhaobai.com/2017/08/elasticsearch-search.html) <span>（2017-08-09）</span>