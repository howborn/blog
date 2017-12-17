---
title: ELK+Beats集中式日志平台之三 —  监控运维
date: 2017-12-10 13:14:00
tags:
- 分布式
- 日志
categories:
- 分布式
---

![]()<!--more-->

## 删除过期索引

随着时间的推移，日志平台会产生大量的索引，如果不进行索引管理，不但会占用磁盘空间，而且还会导致检索性能降低。对于那些已经失效的日志，长期存在并没有太大的价值，所以我们应该定期对其进行清理。

### [设置索引过期时间](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/mapping-ttl-field.html)

最简单的办法就是给每个索引设定 TTLs（过期时间），在索引模板中定义失效时间为 15 天：

```Json
PUT /_template/logstash
{
    "template": "*",  
    "mappings": {
        "_default_": {
            "_ttl": {
                "enabled": true,
                "default": "30d"
            }
        }
    }
}
```

> 索引的 TTLs 特性已经从 Elasticsearch 5+ 版本移除，故不推荐使用该方式。

### [通过查询条件删除文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)

例如，日志中时间格式形如`"2016-12-24T17:36:14.000Z`，则删除 7 天前日志的查询条件为：

```Json
{
    "query": {
        "range": {
            "@timestamp": {
                "lt": "now-7d",
                "format": "date_time"
            }
        }
    }
}
```

上述查询中，`@timestamp`指定查询字段，lt 表示小于操作（lte 表示小于等于， gt 表示大于，gte 表示大于等于），`format`指定时间的 [格式](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/mapping-date-format.html) 为`date_time`，`now-7d`表示当前时间往前移 7 天的时间，时间操作支持的单位也很多，如下：

* y，代表一年
* M，代表一个月
* w，代表一周
* d，代表一天
* h，代表一个小时
* m，代表一分钟
* s，代表一秒钟
* ms，代表毫秒

配置定期清理过期日志的任务：

```Bash
$ * 0 * * * /usr/bin/curl -u username:password  -H'Content-Type:application/json' -d'query' -XPOST "host/*/_delete_by_query?pretty" > path.log
```

其中，`username`和`password`为 Elasticsearch 的用户名和密码，`query`为待清理日志的查询条件，`path.log`为日志文件路径。

> 该方式只是清理了过期的日志文档，并不会删除过期的索引信息，适用于对特定索引下的日志文档进行定期清理的场景。

### 自定义脚本

我们部署 ELK 时，日志通常会以日、月的形式归档建立索引，所以清理过期日志，只需删除过期的索引。



### [Curator]()
## 删除过期索引

随着时间的推移，日志平台会产生大量的索引，如果不进行索引管理，不但会占用磁盘空间，而且还会导致检索性能降低。对于那些已经失效的日志，长期存在并没有太大的价值，所以我们应该定期对其进行清理。

### [设置索引过期时间](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/mapping-ttl-field.html)

最简单的办法就是给每个索引设定 TTLs（过期时间），在索引模板中定义失效时间为 15 天：

```Json
PUT /_template/logstash
{
    "template": "*",  
    "mappings": {
        "_default_": {
            "_ttl": {
                "enabled": true,
                "default": "30d"
            }
        }
    }
}
```

> 索引的 TTLs 特性已经从 Elasticsearch 5+ 版本移除，故不推荐使用该方式。

### [通过查询条件删除文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)

例如，日志中时间格式形如`"2016-12-24T17:36:14.000Z`，则删除 7 天前日志的查询条件为：

```Json
{
    "query": {
        "range": {
            "@timestamp": {
                "lt": "now-7d",
                "format": "date_time"
            }
        }
    }
}
```

上述查询中，`@timestamp`指定查询字段，lt 表示小于操作（lte 表示小于等于， gt 表示大于，gte 表示大于等于），`format`指定时间的 [格式](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/mapping-date-format.html) 为`date_time`，`now-7d`表示当前时间往前移 7 天的时间，时间操作支持的单位也很多，如下：

* y，代表一年
* M，代表一个月
* w，代表一周
* d，代表一天
* h，代表一个小时
* m，代表一分钟
* s，代表一秒钟
* ms，代表毫秒

配置定期清理过期日志的任务：

```Bash
$ * 0 * * * /usr/bin/curl -u username:password  -H'Content-Type:application/json' -d'query' -XPOST "host/*/_delete_by_query?pretty" > path.log
```

其中，`username`和`password`为 Elasticsearch 的用户名和密码，`query`为待清理日志的查询条件，`path.log`为日志文件路径。

> 该方式只是清理了过期的日志文档，并不会删除过期的索引信息，适用于对特定索引下的日志文档进行定期清理的场景。

### [自定义脚本]()

我们部署日志收集时，通常会以日、月的形式归档建立索引，所以清理过期日志，只需删除过期的索引。

我们可以通过`GET /_cat/indices`和`DELETE /index?pretty`这 2 个 API 完成过期索引的清理，执行脚本如下：

```Bash
#!/bin/bash
# 待删除索引的正则表达式
SEARCH_PREG="nginx-www-access-20[0-9][0-9](\.[0-9]{2})+"
# 保留索引的天数
KEEP_DAYS=60
URL=http://es.fanhaobai.com
PORT=
USER=elastic
PASSWORD=changeme

date2stamp () {
    date --utc --date "$1" +%s
}

if [ $PORT ]; then elastic_url="$URL:${PORT}"; fi

indices=`curl -u "$USER:$PASSWORD" -s "$URL/_cat/indices?v" | grep -E "$SEARCH_PREG" | awk '{ print $3 }'`
endDate=`date2stamp "$KEEP_DAYS day ago"`

for index in ${indices}; do
  date=`echo $index | sed "s/.*\([0-9]\{4\}\([.\-][0-9]\{2\}\)*\).*/\1/g" | sed 's/[.\-]/-/g'`
  if [ `echo $date | grep -o \- | wc -l` = 1 ]; then date="$date-01"; fi

  currentDate=`date -u "+%Y-%m-%d %T"`
  logDate=`date2stamp $date`

  if [ $(($endDate-$logDate)) -ge 0 ]; then
      echo "[${currentDate}] - ${index} | DELETE";
      curl -u "$USER:$PASSWORD" -XDELETE "$URL/${index}?pretty"
  else
      echo "[${currentDate}] - ${index} | NO";
  fi
done
```

配置定时任务：

```
0 0* * * * /usr/local/elk/elasticsearch/bin/delete-index.sh >> /usr/local/elk/elasticsearch/logs/delete-index.log 2>&1
```

### [Curator]()
