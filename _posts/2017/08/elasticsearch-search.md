---
title: Elasticsearch检索实战
date: 2017-08-09 23:38:30
tags:
- Elasticsearch
categories:
- Lucene
---

随着公司房源数据的急剧增多，现搜索引擎 Solr 的搜索效率和建立索引效率显著降低，而 [Elasticsearch](https://github.com/elastic/elasticsearch) 是一个实时的分布式搜索和分析引擎，它是基于全文搜索引擎 [Apache Lucene](https://lucene.apache.org/) 之上，接入 Elasticsearch 是必然之选。本文是我学习使用 Elasticsearch 检索的笔记。

![](https://img.fanhaobai.com/2017/08/elasticsearch-search/9a3accb9-0da1-47e4-ad58-428370464af6.jpg)<!--more-->

Elasticsearch 支持 RESTful API 方式检索，查询结果以 JSON 格式响应，文中示例数据见 [这里](http://es.fanhaobai.com)。有关 Elasticsearch 详细使用说明，见  [官方文档](https://elasticsearch.cn/book/elasticsearch_definitive_guide_2.x/)。

## Url

检索 url 中需包含 **索引名**，`_search`为查询关键字。例如 [http://es.fanhaobai.com/rooms/_search](http://es.fanhaobai.com/rooms/_search) 的 rooms 为索引名，此时表示无任何条件检索，检索结果为：

```JS
GET /rooms/_search

{
   "took": 6,
   "timed_out": false,
   "_shards": { ... },
   "hits": {
      "total": 3,
      "max_score": 1,
      "hits": [
         {
            "_index": "rooms",
            "_type": "room_info",
            "_id": "3",
            "_score": 1,
            "_source": {
               "resblockId": "1111027377528",
               "resblockName": "金隅丽港城",
               "houseId": 1087599828743,
               "cityCode": 110000,
               "size": 10.5,
               "bizcircleCode": [ "18335711" ],
               "bizcircleName": [ "望京" ],
	       "price": 2300
            }
         },
         {
            ... ...
            "_source": {
               "resblockId": "1111047349969",
               "resblockName": "融泽嘉园",
               "houseId": 1087817932553,
               "cityCode": 110000,
               "size": 10.35,
               "bizcircleCode": [ "611100314" ],
               "bizcircleName": [ "西二旗" ],
               "price": 2500
            }
         },
	 ... ...
      ]
   }
}
```

> 注：Elasticsearch 官方偏向于使用 GET 方式（能更好描述信息检索的行为），GET 方式可以携带请求体，但是由于不被广泛支持，所以 Elasticsearch 也支持 POST 请求。后续查询语言使用 POST 方式。

当我们确定了需要检索文档的 url 后，就可以使用查询语法进行检索，Elasticsearch 支持以下 Query string（查询字符串）和 DSL（结构化）2 种检索语句。

## 检索语句

### Query string

我们可以直接在 get 请求时的 url 后追加`q=`查询参数，这种方法常被称作 query string 搜索，因为我们像传递 url 参数一样去传递查询语句。例如查询小区 id 为 1111027374551 的房源信息：

```JS
GET /rooms/_search?q=resblockId:1111027374551

//查询结果,无关信息已省略
{
   "hits": [
      {
         "_source": {
            "resblockId": "1111027374551",
            "resblockName": "国风北京二期",
            ... ...
         }
      }
   ]
}
```

虽然查询字符串便于查询特定的搜索，但是它也有局限性。

### DSL

DSL 查询以 JSON 请求体的形式出现，它允许构建更加复杂、强大的查询。DSL 方式查询上述 query string 查询条件则为：

```JS
POST /rooms/_search

{
   "query": {
      "term": {
         "resblockId": "1111027374551"
      }
   }
}
```

term 语句为过滤类型之一，后面再进行说明。使用 DSL 语句查询支持 **filter**（过滤器）、**match**（全文检索）等复杂检索场景。

## 基本检索

Elasticsearch 支持为 2 种检索行为，它们都是使用 DSL 语句来表达检索条件，分别为 **query** （结构化查询）和 **filter**（结构化搜索）。

说明：后续将使用 SQL 对比 DSL 语法进行搜索条件示例。

### 结构化查询

结构化查询支持全文检索，会对检索结果进行相关性计算。使用结构化查询，需要传递 query 参数：

```Js
{ "query": your_query }
//your_query为{}表示空查询
```

> 注：后续查询中不再列出 query 参数，只列出 your_query（查询内容）。

#### match_all查询

match_all 查询简单的匹配所有文档。在没有指定查询方式时，它是默认的查询。查询所有房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms
```

match_all 查询为：

```Js
{ "match_all": {}}
```

#### match查询

match 查询为全文搜索，类似于 SQL 的 LIKE 查询。查询小区名中包含“嘉”的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE resblockName LIKE '%嘉%'
```

match 查询为：

```Js
{ "match": { "resblockName": "嘉" }}
//结果
"hits": [
    {
        "_source": {
            "resblockId": "1111047349969",
            "resblockName": "融泽嘉园",
            ... ...
        }
    }
]
```

#### multi_match查询

multi_match 查询可以在多个字段上执行相同的 match 查询：

```Js
{
    "multi_match": {
        "query":  "京",
        "fields": [ "resblockName", "bizcircleName" ]
    }
}
```

#### range查询

range 查询能检索出那些落在指定区间内的文档，类似于 SQL 的 BETWEEN 操作。range 查询被允许的操作符有：

| 操作符  | 操作关系 |
| ---- | ---- |
| gt   | 大于   |
| gte  | 大于等于 |
| lt   | 小于   |
| lte  | 小于等于 |

查询价格在 (2000, 2500] 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE price BETWEEN 2000 AND 2500 AND price != 2000
```

range 查询为：

```Js
{
    "range": {
        "price": {
            "gt": 2000,
            "lte": 2500
        }
    }
}
```

#### term查询

term 查询用于精确值匹配，可能是数字、时间、布尔。例如查询房屋 id 为 1087599828743 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE houseId = 1087599828743
```

term 查询为：

```Js
{ "term": { "houseId": 1087599828743 }}
```

#### terms查询

terms 查询同 term 查询，但它允许指定多值进行匹配，类似于 SQL 的 IN 操作。例如查询房屋 id 为 1087599828743 或者 1087817932342 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE houseId IN (1087599828743, 1087817932342)
```

terms 查询为：

```Js
{ "terms": { "houseId": [ 1087599828743, 1087817932342 ] }}
```

> term 查询和 terms 查询都不分析输入的文本， 不会进行相关性计算。

#### exists查询和missing查询

exists 查询和 missing 查询被用于查找那些指定字段中有值和无值的文档，类似于 SQL 中的 IS NOT NULL 和 IS NULL 查询。查询价格有效的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE price IS NOT NULL
```
exists 查询为：

```Js
{ "exists": { "field": "price" }}
```

#### bool查询

我们时常需要将多个条件的结构进行逻辑与和或操作，等同于 SQL 的 AND 和 OR，这时就应该使用 bool 子句合并多子句结果。 共有 3 种 bool 查询，分别为 must（AND）、must_not（NOT）、should（OR）。

| 操作符      | 描述                          |
| -------- | --------------------------- |
| must     | AND 关系，**必须** 匹配这些条件才能检索出来  |
| must_not | NOT 关系，**必须不** 匹配这些条件才能检索出来 |
| should   | OR 关系，**至少匹配一条** 条件才能检索出来   |
| filter   | **必须** 匹配，不参与评分             |

查询小区中包含“嘉”字或者房屋 id 为 1087599828743 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE (resblockName LIKE '%嘉%' OR houseId = 1087599828743) AND (cityCode = 110000)
```

bool 查询为：

```Js
{
  "bool": {
     "must": {
        "term": {"cityCode": 110000 }
     },
     "should": [
        { "term": { "houseId": 1087599828743 }},
        { "match": { "resblockName": "嘉" }}
     ]
  }
}
```

使用 filter 语句来使得其子句不参与评分过程，减少评分可以有效地优化性能。重写前面的例子：

```Js
{
  "bool": {
     "should": [
        { "match": { "resblockName": "嘉" }}
     ],
     "filter" : {
        "bool": {
           "must": { "term": { "cityCode": 110000 }},
           "should": [
              { "term": { "houseId": 1087599828743 }}
           ]
        }
     }
  }
}
```

bool 查询可以相互的进行嵌套，已完成非常复杂的查询条件。

#### constant_score查询

constant_score 查询将一个不变的常量评分应用于所有匹配的文档。它被经常用于你只需要执行一个 **filter**（过滤器）而没有其它查询（评分查询）的情况下。

```Js
{
    "constant_score": {
        "filter": {
            "term": { "houseId": 1087599828743 } 
        }
    }
}
```

### 结构化搜索

结构化搜索的查询适合确定值数据（数字、日期、时间），这些类型数据都有明确的格式。结构化搜索结果始终是是或非，结构化搜索不关心文档的相关性或分数，它只是简单的包含或排除文档，由于结构化搜索使用到过滤器，在查询时需要传递 filter 参数，由于 DSL 语法查询必须以 query 开始，所以 filter 需要放置在 query 里，因此结构化查询的结构为：

```Js
{
    "query": {
        "constant_score": { 
            "filter": {
                //your_filters
            }
        }
    }
}
```
> 注：后续搜索中不再列出 query 参数，只列出 your_filters（过滤内容）。

结构化搜索一样存在很多过滤器 term、terms、range、exists、missing、bool，我们在结构化查询中都已经接触过了。

#### term搜索

最为常用的 term 搜索用于查询精确值，可以用它处理数字（number）、布尔值（boolean）、日期（date）以及文本（text）。查询小区 id 为 1111027377528 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE resblockId = "1111027377528"
```

term 搜索为：

```Js
{ "term": { "resblockId": "1111027377528" }}
```

类似`XHDK-A-1293-#fJ3`这样的文本直接使用 term 查询时，可能无法获取到期望的结果。是因为 Elasticsearch 在建立索引时，会将该数据分析成 xhdk、a、1293、#fj3 字样，这并不是我们期望的，可以通过指定 not_analyzed 告诉 Elasticsearch 在建立索引时无需分析该字段值。

#### terms搜索

terms 搜索使用方式和 term 基本一致，而 terms 是搜索字段多值的情况。查询商圈 code 为 18335711 或者 611100314 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE bizcircleCode IN (18335711, 611100314)
```

terms搜索为：

```Js
{ "terms": { "bizcircleCode": [ "18335711", "611100314" ] }}
```

#### range搜索

在进行范围过滤查询时使用 range 搜索，支持数字、字母、日期的范围查询。查询面积在 [15, 25] 平米之间的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE size BETWEEN 10 AND 25
```

range 搜索为：

```Js
{
    "range": {
        "size": {
            "gte": 10,
            "lte": 25
        }
    }
}
```

range 搜索使用在日期上：

```Js
{
    "range": {
        "date": {
            "gt": "2017-01-01 00:00:00",
            "lt": "2017-01-07 00:00:00"
        }
    }
}
```

#### exists和missing搜索

exists 和 missing 搜索是针对某些字段值存在和缺失的查询。查询房屋面积存在的房源列表：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE size IS NOT NULL
```

exists 搜索为：

```Js
{"exists": { "field": "size" }}
```

missing 搜索刚好和 exists 搜索相反，但语法一致。

#### bool组合搜索

bool 过滤器是为了解决过滤多个值或字段的问题，它可以接受多个其他过滤器作为子过滤器，并将这些过滤器结合成各式各样的逻辑组合。

bool 过滤器的组成部分，同 bool 查询一致：

```Js
{
   "bool": {
      "must":     [],
      "should":   [],
      "must_not": [],
   }
}
```

类似于如下 SQL 查询条件：

```SQL
SELECT * FROM rooms WHERE (bizcircleCode = 18335711 AND price BETWEEN 2000 AND 2500) OR (bizcircleCode = 611100314 AND price >= 2500)
```

使用 bool 过滤器实现为：

```Js
{
   "bool": {
       "should": [
           { 
              "term": { "bizcircleCode": "18335711" },
              "range": { "price": { "gte": 2000, "lte": 25000 }}
           }, 
           { 
              "term": { "bizcircleCode": "611100314" },
              "range": { "price": { "gte": 2500 }}
           } 
       ]
   }
}
```

> **区别**：结构化查询会进行相关性计算，因此不会缓存检索结果；而结构化搜索会缓存搜索结果，因此具有较高的检索效率，在不需要全文搜索或者其它任何需要影响相关性得分的查询中建议只使用结构化搜索。当然，结构化查询和结构化搜索可以配合使用。

### 聚合

 该部分较复杂，已单独使用文章进行说明，见 [Elasticsearch检索 — 聚合和LBS](https://www.fanhaobai.com/2017/08/elasticsearch-advanced-search.html#聚合) 部分。

### _source子句

某些时候可能不需要返回文档的全部字段，这时就可以使用 _source 子句指定返回需要的字段。只返回需要的房源信息字段：

```Js
{
   "_source": [ "cityCode", "houseId", "price", "resblockName" ]
}
```

### sort子句

#### 简单排序

排序是使用比较多的推荐方式，在 Elasticsearch 中，默认会按照相关性进行排序，相关性得分由一个浮点数进行表示，并在搜索结果中通过`_score`参数返回（未参与相关性评分时分数为 1）， 默认是按`_score`降序排序。

sort 方式有 desc、asc 两种。将房源查询结果按照价格升序排列：

```Js
{
   "sort": {
      "price": { "order": "asc" }}
   }
}
```

#### 多级排序

当存在多级排序的场景时，结果首先按第一个条件排序，仅当结果集的第一个 sort 值完全相同时才会按照第二个条件进行排序，以此类推。

```Js
{
   "sort": [
      { "price": { "order": "asc" }},
      { "_score": { "order": "desc" }}  //price一直时，按照相关性降序
   ]
}
```

#### 字段多指排序

当字段值为 **多值** 及 [字段多指排序]()，Elasticsearch 会对于数字或日期类型将多值字段转为单值。转化有 min 、max 、avg、 sum 这 4 种模式。 

例如，将房源查询结果按照商圈 code 升序排列：

```Js
{
   "sort": {
      "bizcircleCode": {
         "order": "asc",
         "mode":  "min"
      }
   }
}
```

### 分页子句

和 SQL 使用 LIMIT 关键字返回单 page 结果的方法相同，Elasticsearch 接受 from（初始结果数量）和 size（应该返回结果数量） 参数：

```Js
{
   "size": 8,
   "from": 1
}
```

## 验证查询合法性

在实际应用中，查询可能变得非常的复杂，理解起来就有点困难了。不过可以使用`validate-query`API来验证查询合法性。

```Js
GET /room/_validate/query
{
   "query": { "resblockName": { "match": "嘉" }}
}
```

合法的 query 返回信息：

```Js
{
   "valid":         false,
   "_shards": {
      "total":       1,
      "successful":  1,
      "failed":      0
   }
}
```

## 最后

别的业务线已经投入 Elasticsearch 使用有段时间了，找房业务线正由 Solr 切换为 Elasticsearch，各个系统有一个探索和磨合的过程。当然，Elasticsearch 我们已经服务化了，对 DSL 语法也进行了一些简化，同时支持了定制化业务。另外，使用 [elasticsearch-sql](https://github.com/NLPchina/elasticsearch-sql) 插件可以让 Elasticsearch 也支持 SQL 操作。  

<strong>相关文章 [»]()</strong>

* [Elasticsearch检索 — 聚合和LBS](https://www.fanhaobai.com/2017/08/elasticsearch-advanced-search.html) <span>（2017-08-21）</span>