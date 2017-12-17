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

## 清理过期日志文档

随着时间的推移，日志平台会产生大量的索引文件，这样不但会占用磁盘空间，而且还会导致检索性能降低。对于那些已经失效的日志文档，长期存在并没有任何价值，所以应该定期对其清理。

### [设置索引过期时间](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/mapping-ttl-field.html)

最简单的办法就是给每个索引设定 TTLs（过期时间），在索引模板中定义失效时间为 7 天：

```Json
PUT /_template/logstash
{
    "template": "*",  
    "mappings": {
        "_default_": { "_ttl": { "enabled": true, "default": "7d" } }
    }
}
```

> 索引的 TTLs 特性已经从 Elasticsearch 5+ 版本移除，故不推荐使用该方式。

### [通过查询条件删除文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html)

例如，日志中时间格式形如`"2016-12-24T17:36:14.000Z`，则清理 7 天前日志的查询条件为：

```Json
{
    "query": {
        "range": { "@timestamp": { "lt": "now-7d", "format": "date_time" } }
    }
}
```

上述查询中，`@timestamp`指定查询字段，`format`指定时间的 [格式](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/mapping-date-format.html) 为`date_time`，`now-7d`表示当前时间往前推移 7 天的时间。



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
$ 0 0 * * * /usr/bin/curl -u user:password  -H'Content-Type:application/json' -d'query' -XPOST "host/*/_delete_by_query?pretty" > path.log
```

其中，`user`和`password`为 Elasticsearch 的用户名和密码，`query`为待清理日志的查询条件，`path.log`为日志文件路径。

> 该方式只是删除了过期的日志文档，并不会删除过期的索引信息，适用于对特定索引下的日志文档进行定期清理的场景。

### [自定义脚本](https://github.com/fan-haobai/tools-shell/blob/master/elk/delete-index.sh)

我们部署日志收集时，通常会以日、月的形式归档建立索引，所以清理过期日志，只需清理过期的索引。

这里通过`GET /_cat/indices`和`DELETE /index?pretty`这 2 个 API 完成过期索引的清理，清理脚本如下：

```Bash
#!/bin/bash
# 待删除索引的正则表达式
SEARCH_PREG="nginx-www-access-20[0-9][0-9](\.[0-9]{2})+"
# 保留索引的天数
KEEP_DAYS=7
URL=http://es.fanhaobai.com
PORT=
USER=user
PASSWORD=password

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
0 0 * * * /usr/local/elk/elasticsearch/bin/delete-index.sh >> /usr/local/elk/elasticsearch/logs/delete-index.log 2>&1
```

> 该方式通过自定义脚本方式，可以较灵活的配置所需清理的过期索引，使用起来简洁轻便，但若 Elasticsearch 采用集群方式部署，那么该方式就不是很灵活了。

### [Curator工具](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/about.html)

当遇到清理过期索引比较复杂的场景时，就可以使用官方提供的管理工具 Curator。其不仅可以进行复杂场景的索引管理，还可以进行快照管理，而实现这一切，只需要配置 YAML 格式的配置文件。

#### 安装

这里使用 yum 安装，先配置 yum 源。在`/etc/yum.repos.d/`目录下创建名为`curator.repo`的文件，内容如下：

```Ini
[curator-5]
name=CentOS/RHEL 6 repository for Elasticsearch Curator 5.x packages
baseurl=https://packages.elastic.co/curator/5/centos/6
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
```

使用 yum 命令安装：

```Bash
$ rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
$ yum install -y elasticsearch-curator

# 获取所有索引
$ curator_cli --http_auth user:password --host es.fanhaobai.com --port 80 show_indices --verbose

.kibana     open   15.7KB       3   1   0 2017-12-15T06:15:07Z
```

#### 配置

* [主配置文件](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/configfile.html)

创建名为`/etc/curator/curator.yml`的配置文件，主要用来配置 Elasticsearch 服务的相关信息：

```Yaml
client:
  hosts:
    - es.fanhaobai.com         #集群配置形如[ "10.0.0.1", "10.0.0.2" ]
  port: 80
  http_auth: user:password     #授权信息
  url_prefix:
  use_ssl: false
  certificate:
  client_cert:
  client_key:
  ssl_no_validate: false
  timeout: 30
  master_only: false
logging:
  loglevel: INFO
  logfile: /usr/local/elk/elasticsearch/logs/elasticsearch-curator.log
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
```

其中，需要配置 hosts、port、http_auth 这 3 个配置项。

* [任务配置文件](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/actionfile.html)

例如，待清理索引的格式形如`test-2017.11.16`，需清理 7 天过期的索引。创建名为`delete-index.yml`的 [配置](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/ex_delete_indices.html) 文件，内容如下：

```Yaml
actions:
  1:                                  #任务1
   action: delete_indices             #任务动作
   description: "Delete nginx index"  #日志描述
   options:
     ignore_empty_list: false
     disable_action: false
   filters:                           #管道
   - filtertype: pattern              #模式过滤
     kind: prefix                     #匹配索引前缀
     value: test-                     #匹配值，索引前缀为test-
   - filtertype: age                  #时间过滤
     source: name                     #过滤形式
     direction: older                 #往后推算
     timestring: '%Y.%m.%d'           #时间格式，同索引时间格式
     unit: days                       #时间单位
     unit_count: 7                    #时间间隔，7天内
```

Curator 支持配置多个任务，其中 [action](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/actions.html) 为任务动作，[filters](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filters.html) 为管道过滤器，[filtertype](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/filtertype.html) 为过滤器的过滤类型，支持多种过滤类型。

测试删除过期索引：

```Bash
#删除前
$ curator_cli --config /etc/curator/curator.yml show_indices --verbose | grep test-
test-2017.11.16      open   162.0B       0   3   0 2017-12-17T06:10:04Z
test-2017.12.16      open   486.0B       0   3   0 2017-12-17T05:58:07Z

$ curator --config /etc/curator/curator.yml /etc/curator/delete-index.yml

#删除过期索引后
$ curator_cli --config /etc/curator/curator.yml show_indices --verbose | grep test-
test-2017.12.16      open   486.0B       0   3   0 2017-12-17T05:58:07Z
```

配置每天执行任务：

```Bash
0 0 * * * /usr/bin/curator --config /etc/curator/curator.yml /etc/curator/delete-index.yml
```

> 该方式不但直接通过配置即可方便实现过期索引的清理，而且可以在复杂场景轻松地管理索引、快照等，故推荐该方式。