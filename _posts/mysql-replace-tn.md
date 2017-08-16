---
title: MYSQL替换换行和回车符
date: 2017-08-14 12:47:02
tags:
- MySQL
categories:
- MySQL
---

由于活动业务场景需求，需要 DBA 将 Oracel 库表 a 中满足条件的 60 万用户 uid 数据导入到 MySQL 表 b 中 uid 字段中。但我拿到数据表后，用表中一条 uid 数据执行 uid 条件查询发现并未命中结果，到底发生了什么？<!---more-->

## 问题描述

使用 Vavicat 查看新导出的表 b 数据如下：

{% assset_img f78a979c-f979-4a39-b117-72989a05c658.png %}

从表象上看并没有发现问题，执行查询：

```SQL
SELECT * FROM table_a WHERE uid = "340ae30a-724e-12c5-6b92-************";

0 rows retrieved in 18ms (execution: 11ms, fetching: 7ms)
```

此时意外地并没有命中任何结果。

## 分析

经过确认，查询 uid 确实存在表 b 中，查询条件没问题。正眉头紧锁时，我使用 PhpStrom 集成的 Database 插件发现，数据格式奇怪地有些不一致，如下图：

{% asset_img 78e7f070-e9ac-45f6-958d-f5d282afec0e.png %}

仔细观察不难发现，第 1 行 uid 数据比第 2 行数据前多了“←┘”符号，所以确定是 Oracel 表导入 MySQL 表后导致某些列（uid ）值前多了 [换行符]()，查询条件与真实数据不一致 ，因此无法查询到结果。

## 解决

由于换行符导致数据异常，所以只需提工单给 DBA 替换掉异常数据的特殊换行符即可。

```SQL
UPDATE table_a SET uid = REPLACE(REPLACE(uid, CHAR(10), ''), CHAR(13), '');
```

在 MySQL 中，CHAR(10) 和 CHAR(13) 分别代 [换行符]() 和 [回车符]()，这里都替换掉。再次查询：

```SQL
SELECT * FROM table_a WHERE uid = "340ae30a-724e-12c5-6b92-************";

1 row retrieved starting from 1 in 10ms (execution: 5ms, fetching: 5ms)
```

