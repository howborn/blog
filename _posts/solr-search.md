---
title: Solr的使用 — 检索
date: 2017-08-13 16:22:24
tags:
- Solr
categories:
- Lucene
---

本文是延续 [Solr的使用](https://www.fanhaobai.com/2017/08/solr-insatll-push.html) 系列，前一篇文章已经讲了 Solr 的部署和数据推送，这里主要以示例方式讲述 Solr 的常见查询语法，同时介绍如何使用 PHP 语言的客户端 [solarium](https://github.com/fan-haobai/solarium)  同 Solr 集群进行数据交互。
{% asset_img c4665602-82dc-4cc3-9eaf-c0ed12935d08.png %}<!--more-->

想要详细地了解 Solr 查询语法，可参考 [官方wiki](https://cwiki.apache.org/confluence/display/solr/Query+Syntax+and+Parsing)。

## 数据格式

用于示例的数据，我已经推送到了 Solr ，[见这里](http://solr.fanhaobai.com/solr/rooms/select?q=*:*&wt=json&indent=true)。数据 Core 为 rooms，数据格式形如：

```Js
[{
    "resblockId": 1111027377528,
    "resblockName": "金隅丽港城",
    "houseId": 1087599828743,
    "cityCode": 110000,
    "size": 10.5,
    "bizcircleCode": [ 18335711 ],
    "bizcircleName": [ "望京" ],
    "price": 2300,
    "location": "39.997106,116.469306",
    "id": "0119df79-68d9-4cd9-ba07-4d6395a4841c"
},
{
    "resblockId": 1111047349969,
    "resblockName": "融泽嘉园",
    ... ...
}]
```

## 查询语句的组成

通过向 Solr 集群 GET 请求`/solr/core-name/select?query`形式的查询 API 完成查询，其中 core-name 为查询的 Core 名称。查询语句 query 由以下基本元素项组成，按使用频率先后排序：

| 名称          | 描述                | 示例                           |
| ----------- | ----------------- | ---------------------------- |
| wt          | 响应结果的格式           | json                         |
| fl          | 指定结果集的字段          | *（所有字段）                      |
| fq          | 过滤查询              | id : 0119df79-68d9-4cd9-ba07 |
| start       | 指定结果集起始返回的行数，默认 0 | 0                            |
| rows        | 指定结果集返回的行数，默认 10  | 15                           |
| sort        | 结果集的排序规则          | price+asc                    |
| defType     | 设置查询解析器名称         | dismax                       |
| timeAllowed | 查询超时时间            |                              |

### wt

wt 设置结果集格式，支持 json、xml、csv、php、ruby、pthyon，序列化的结果集，常使用 json 格式。

### fl

fl 指定返回的字段，多指使用“空格”和“,”号分割，但只支持设置了`stored=true`的字段。`*`表示返回全部字段，一般情况不需要返回文档的全部字段。

**字段别名**：使用`displayName:fieldName`形式指定字段的别名，例如：

```Js
fl=id,sales_price:price,name
```

**函数**：fl 还支持使用 Solr [内置函数](#函数)，例如根据单价算总价：

```Js
fl=id,total:product(size,price)
```

### fq

fq 过滤查询条件，可充分利用 cache，所以可以利用 fq 提高检索性能。

### sort

sort 指定结果集的排序规则，格式为`<fieldName>+<sort>`，支持 asc 和 desc 两种排序规则。例如按照价格倒序排列：

```Js
sort=price+desc
```

也可以多字段排序，价格和面积排序：

```Js
sort=price+asc,size+desc
```

## 条件查询

查询字符串 q 由以下元素项组成，字段条件形如`fieldName:value`格式：

| 名称   | 描述          | 示例                         |
| ---- | ----------- | -------------------------- |
| q    | 查询字符串       | \*:\*                      |
| q.op | 表达式之间的关系操作符 | AND/OR                     |
| df   | 查询被索引的字段    | id:0119df79-68d9-4cd9-ba07 |

以上元素项的默认值由`solrconfig.xml`配置文件定义。通常查询时设置`q=*:*`，然后通过 fq 过滤条件来完成查询，通过缓存提高查询性能。

### 模糊查询

Solr 的模糊查询使用占位符来描述查询规则，如下：

| 符号   | 描述        | 示例                    |
| ---- | --------- | --------------------- |
| ?    | 匹配单个字符    | te?t 会检索到 test 和 text |
| *    | 匹配零个或多个字符 | tes* 会检索到 tes、test 等  |

查询小区名称中包含“嘉”的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE resblockName LIKE "%嘉%"
```

Solr 的模糊查询为：

```Js
fq=resblockName:*丽*
```

### 单精确值查询

单精确值查询是最简单的查询，类似于 SQL 中 = 操作符。查询小区 id 为 1111027377528 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE resblockId = 1111027377528
```

Solr 中查询为：

```Js
fq=resblockId:1111027377528
```

### 多精确值查询

多精确值查询是单精确值查询的扩展，格式为`(value1 value2 ...)`，功能类似于 SQL 的 IN 操作符。查询小区 id 为 1111027377528 或者 1111047349969 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE resblockId IN (1111027377528, 1111047349969)
```

Solr 中查询为：

```Js
fq=resblockId:(1111027377528 1111047349969)
```

### 范围查询

范围查询是查询指定范围的值（数字和时间），格式为`[value1 TO value2]`，类似于 SQL 的 BETWEEN 操作符。查询价格在 [2000, 3000] 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE price BETWEEN 2000 AND 3000
```

Solr 中范围查询为：

```
fq=price:[2000 TO 3000]
```

几个特殊的范围查询：

| 条件   | 表达式          | 示例                          |
| ---- | ------------ | --------------------------- |
| >=   | [value TO *] | price:[2000 TO *] 价格 >=2000 |
| <=   | [* TO value] | price:[* TO 2000] 价格 <=2000 |

### 布尔查询

将基本查询结合布尔查询，就可以实现大部分复杂的检索场景。布尔查询支持以下几种布尔操作：

| 操作逻辑 | 操作符     | 描述     |
| ---- | ------- | ------ |
| AND  | &&<br>+ | 逻辑与关系  |
| OR   |         | 逻辑或关系  |
| NOT  | ！<br>-  | 逻辑取反关系 |

查询北京市价格区间在 [2000, 3000] 或者上海市价格区间在 [1500, 2000] 的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE (cityCode=110000 AND price BETWEEN 2000 AND 3000) OR (cityCode=310000 AND price BETWEEN 1500 AND 2000)
```

转换为逻辑与布尔查询：

```Js
fq=(cityCode:110000 && price:[2000 TO 3000])||(cityCode:310000 && price:[1500 TO 2000])
```

## Group查询

在实际中分组查询比较常见，当然 Solr 也支持分组查询。分组查询语句由以下基本元素项组成（常用部分）：

| 名称           | 类型      | 描述                  |
| ------------ | ------- | ------------------- |
| group        | boolean | 是否进行分组查询            |
| group.field  | string  | 按该字段值进行分组           |
| group.limit  | integer | 每组元素集大小，默认为 1       |
| group.offset | integer | 每组元素起始行数            |
| group.sort   | string  | 组内元素排序规则，asc 和 desc |

查询西二旗内价格最便宜小区的房源信息：

```SQL
-- SQL表述
SELECT * FROM rooms WHERE bizcircleCode=611100314 GROUP BY resblockId ORDER BY price ASC LIMIT 1
```

Group 分组查询为：

```Js
q=*:*&fq=bizcircleCode:611100314&group=true&group.field=resblockId&group.limit=1&group.sort=size+desc
```

结果为：

```Js
"groups": [
{
    "groupValue": 1111047349969,
    "doclist": {
    "numFound": 1,                 //每组房源数
    "start": 0,
    "docs": [
    {
        "resblockId": 1111047349969,
        "resblockName": "融泽嘉园",
        "bizcircleCode": [ 611100314 ],
        "price": 2500
        ... ...
    }]
    ... ...
}]
```

## Facet查询

在大多数情况下，Group 分组已经能满足我们的需求，但是如果待分组字段为多值，Group 分组已经无能为力了，这时使用 Facet 就能轻松解决。

Solr 的 Facet 语句由以下基本元素构成（常用）：

| 名称             | 类型      | 描述                 |
| -------------- | ------- | ------------------ |
| facet          | boolean | 是否进行 facet 查询      |
| facet.field    | string  | 按该字段值进行 facet      |
| facet.limit    | integer | 每组元素集大小，默认为 1      |
| facet.offset   | integer | 每组元素起始行数           |
| facet.sort     | string  | 结果集排序规则，asc 和 desc |
| facet.mincount | integer | 每组元素最小数量           |

例如，统计每个商圈的房源分布情况并倒序排列，由于 bizcircleCode 字段为多值，Facet 查询为：

```Js
//此时不需要文档信息，故rows=0
q=*:*&fq=cityCode:110000&facet=true&facet.field=bizcircleCode&facet.sort=desc&rows=0
```

结果如下：

```Js
"facet_fields": {
    "bizcircleCode": [
        "18335711",
        1,
        "18335745",
        1,
        "611100314",
        3
    ]
}
```

## 空间检索

Solr 的 geofilt 过滤器可以实现 LBS 检索，但要在`schema.xml`配置中将需检索字段的字段类型设置为`solr.LatLonType`类型。geofilt 过滤器参数列表如下：

| 名称     | 描述                 | 示例                   |
| ------ | ------------------ | -------------------- |
| d      | 检索距离，单位 km         | 2                    |
| pt     | 检索中心点坐标，格式：lat,lon | 40.074203,116.315445 |
| sfield | 检索的索引字段            | location             |

示例中的 location 字段，值为  "40.074203,116.315445"，类型配置为：

```Xml
<fieldType name="location" class="solr.LatLonType" subFieldSuffix="_coordinate"/>
<field name="location" type="location"/>
```

则检索坐标点`40.074203,116.315445`附近 2 公里的房源信息：

```Js
q=*:*&fq={!geofilt}&spatial=true&pt=40.074203,116.315445&sfield=location&d=2
```

## 函数

Solr 提供一些函数以实现逻辑或数学运算。其中常用 **数学运算** 函数列表如下：

| 函数名     | 描述        | 示例               |
| ------- | --------- | ---------------- |
| abs     | 求绝对值      | abs(-5)          |
| max     | 返回最大值     | max(1, 2, 3)     |
| min     | 返回最小值     | min(1, 2, 3)     |
| pow     | 返回指数运算的结果 | pow(2, 2)        |
| sqrt    | 开方运算的结果   | sqrt(100)        |
| product | 乘积        | product(1, 2, 3) |
| sub     | 差         | sub(3, 2)        |
| sum     | 和         | sum(1, 2, 3)     |
| div     | 商         | div(4, 2)        |
| log     | 10 的对数    | log(10)          |

常用的 **逻辑运算** 函数：

| 函数名    | 描述                                       | 示例            |
| ------ | ---------------------------------------- | ------------- |
| def    | 定义字段默认值                                  | def(price, 0) |
| if     | if(test,value1,value2)<br>test?value1:value2 |               |
| exists | 字段是否存在                                   |               |

这些函数可以使用在返回值或者查询条件上。例如返回每个房源的每平方米价格信息：

```Js
q=*:*&fl=*,avgPrice:div(price, size)
```

## solarium客户端

PHP 可以使用 [solarium](https://github.com/solariumphp/solarium) 客户端，实现 Solr 数据源的检索，详细使用说明 [见这里](http://solarium.readthedocs.io/en/stable/)。

### 配置基本

solarium 客户端需要配置 Solr 的基本信息。如下：

```PHP
//config.php
<?php
$solr = [
    'endpoint' => [
        'localhost' => [
            'host' => 'solr.fanhaobai.com',
            'port' => 80,
            'path' => '/solr/rooms/',
        ]
    ]
];
```

### 基本查询

solarium 提供的查询方法较丰富，整理后如下表所示：

| 方法                | 所属对象   | 描述                 |
| ----------------- | ------ | ------------------ |
| createSelect      | client | 创建查询 query 对象      |
| select            | client | 执行查询，返回 result 对象  |
| setQuery          | query  | 添加 query 条件        |
| setStart          | query  | 设置结果集起始行           |
| setRows           | query  | 设置结果集行数            |
| setFields         | query  | 设置返回的字段            |
| addSort           | query  | 结果集排序规则            |
| createFilterQuery | query  | 创建 filter query 对象 |

查询北京市的所有房源信息，如下：

```PHP
$client = new Solarium\Client($solr);
$query = $client->createSelect()->setStart(0)->setRows(20);
$query->createFilterQuery('rooms')->setQuery('cityCode:110000');
$result = $client->select($query);
```

### Group查询

solarium 提供的分组查询方法如下表所示（常用）：

| 方法          | 所属对象   | 描述            |
| ----------- | ------ | ------------- |
| getGrouping | query  | 创建分组 group 对象 |
| addQuery    | group  | 添加分组 query    |
| setSort     | group  | 设置分组排序规则      |
| setLimit    | group  | 设置分组数量        |
| getGrouping | result | 获取分组信息        |

获取西二旗每个小区的房源分布信息，如下：

```PHP
$client = new Solarium\Client($solr);
$query = $client->createSelect()->setStart(0)->setRows(20)->setQuery('bizcircleCode:611100314');
$group = $query->getGrouping();
$group->addField('resblockId')->setLimit(10)->setSort('price desc')->setNumberOfGroups(true);
$result = $client->select($query);
$groups = $result->getGrouping();
```

### Facet查询

solarium 提供的 Facet 查询方法，如下表（常用）：

| 方法               | 所属对象  | 描述            |
| ---------------- | ----- | ------------- |
| getFacetSet      | query | 创建分组 facet 对象 |
| createFacetField | facet | 创建 facet 字段   |
| setField         | facet | facet 分组字段    |
| setLimit         | facet | 设置 facet 分组大小 |

获取北京市每个商圈的房源分布信息，如下：

```PHP
$client = new Solarium\Client($solr);
$query = $client->createSelect()->setStart(0)->setRows(20)->setQuery('bizcircleCode:611100314');
$facet = $query->getFacetSet();
$facet->createFacetField('bizcircle')->setField('bizcircleCode')->setLimit(10);
$result = $client->select($query);
```

## 总结

到这里，Solr 系列就整理完毕了，未涉及的部分后续接触时再补充。这两天利用休息时间充电，自己在 Solr 方面的技能也算是上了一个台阶了。

<strong>相关文章 [»]()</strong>

* [Solr的使用 — 部署和数据推送](https://www.fanhaobai.com/2017/08/solr-install-push.html) <span>（2017-08-12）</span>