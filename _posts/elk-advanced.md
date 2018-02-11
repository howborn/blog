---
title: ELK集中式日志平台之三 —  进阶
date: 2017-12-22 23:12:00
tags:
- 系统设计
- 日志
categories:
- 系统设计
---

部署 [ELK](https://www.fanhaobai.com/2017/12/elk-install.html) 后，日志平台就搭建完成了，基本上可以投入使用，但是其配置并不完善，也并未提供实时监控和流量分析功能，本文将对 ELK 部署后的一些常见使用问题给出解决办法。
![](https://img.fanhaobai.com/2017/12/elk-advanced/993155ac-718b-4e4b-9d36-d9d73357b162.png)<!--more-->![](https://www.fanhaobai.com/2017/12/elk-advanced/993155ac-718b-4e4b-9d36-d9d73357b162.png)

## Logstash管道进阶

### [Input](https://www.elastic.co/guide/en/logstash/current/input-plugins.html)

Input 插件指定了 Logstash 事件的输入源，已经支持 [beats](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-beats.html)、[kafka](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html)、[redis](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-redis.html) 等源的输入。

例如，配置 Beats 源为输入，且端口为 5044：

```Yaml
input {
    beats { port => 5044 }
}
```

### Filter

Filter 插件主要功能是数据过滤和格式化，通过简洁的表达式就可以完成数据的处理。

以下这些配置信息，为插件共有配置：

| 配置项          | 类型    | 描述   |
| ------------ | ----- | ---- |
| add_field    | hash  | 添加字段 |
| add_tag      | array | 添加标签 |
| remove_field | array | 删除字段 |
| remove_tag   | array | 删除标签 |

#### Drop

[Drop](https://www.elastic.co/guide/en/logstash/current/plugins-filters-drop.html) 插件用来过滤掉无价值的数据，例如过滤掉静态文件日志信息：

```Yaml
if [url] =~ "\.(jpg|jpeg|gif|png|bmp|swf|fla|flv|mp3|ico|js|css|woff)" {
    drop {}
}
```

#### Date

我们可以用 [Date](https://www.elastic.co/guide/en/logstash/current/plugins-filters-date.html) 插件来格式化时间字段。

例如，将 time 字段值格式化为`dd/MMM/YYYY:H:m:s Z`形式：

```Yaml
date { match => [ "[time]", "dd/MMM/YYYY:H:m:s Z" ] }
```

#### Mutate

[Mutate](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html) 插件用来对字段进行 [rename](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html#plugins-filters-mutate-rename)、[replace](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html#plugins-filters-mutate-replace) 、[merge](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html#plugins-filters-mutate-merge) 以及字段值 [convert](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html#plugins-filters-mutate-convert)、[split](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html#plugins-filters-mutate-split)、[join](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html#plugins-filters-mutate-join) 操作。

例如，将字段`@timestamp`重命名（rename 或 replace）为 read_timestamp：

```Yaml
mutate { rename => { "@timestamp" => "read_timestamp" } }
```

以下是对字段值的操作，使用频率较高。

* 字段值类型转换（convert）

例如，将 response_code 字段值转换为整型：

```Yaml
mutate { convert => { "fieldname" => "integer" } }
```

* 字符串分割为数组（split）

例如，将经纬度坐标用数组表示：

```Yaml
mutate { split => { "location" => "," } }
```

* 数组合并为字符串（join）

例如，将经纬度坐标合并：

```Yaml
mutate { join => { "location" => "," } }
```

#### Kv

[Kv](https://www.elastic.co/guide/en/logstash/current/plugins-filters-kv.html) 插件能够对 key=value 格式的字符进行格式化或过滤处理，这里只对 field_split 项配置进行说明，更多配置见 [Kv Filter Configuration Options](https://www.elastic.co/guide/en/logstash/current/plugins-filters-kv.html#plugins-filters-kv-options)。

例如，获取形如`?name=cat&type=2`GET 请求的参数：

```Yaml
kv { field_split => "&?" }
```

处理后，将会获取到以下 2 个参数：

* `name: cat`
* `type: 2`

#### Json

[Json](https://www.elastic.co/guide/en/logstash/current/plugins-filters-json.html) 插件当然是用来解析 Json 字符串，而 [Json_encode](https://www.elastic.co/guide/en/logstash/current/plugins-filters-json_encode.html) 插件是对字段编码为 Json 字符串。例如，Nginx 日志为 Json 格式，则：

```Yaml
json { source => "message" }
```

#### Grok

[Grok](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html) 插件可以根据指定的表达式 [结构化]() 文本数据，表达式需形如`%{SYNTAX:SEMANTIC}`格式，SYNTAX 指定字段值类型，可以为 IP、WORD、DATA、NUMBER 等。

例如，形如`55.3.244.1 GET /index.html 15824 0.043`的请求日志，则对应的表达式应为`%{IP:client} %{WORD:method} %{WORD:request} %{NUMBER:bytes} %{NUMBER:duration}`，配置如下：

```Yaml
grok {
    match => { "message" => "%{IP:client} %{WORD:method} %{WORD:request} %{NUMBER:bytes} %{NUMBER:duration}" }
}
```

经过 Grok 过滤后，输出为：

* `client: 55.3.244.1`
* `method: GET`
* `request: /index.html`
* `bytes: 15824`
* `duration: 0.043`

我们可以使用 [Grok Debug](http://grokdebug.herokuapp.com/) 在线调试 Grok 表达式，常用 Nginx、MySQL、Redis 日志的 Grok 表达式见 [Configuration Examples](https://www.elastic.co/guide/en/logstash/current/logstash-config-for-filebeat-modules.html) 部分。

> [useragent](https://www.elastic.co/guide/en/logstash/current/plugins-filters-useragent.html) 插件用来解析用户客户端信息，[geoip](https://www.elastic.co/guide/en/logstash/current/plugins-filters-geoip.html) 插件可以根据 IP 地址解析出用户所在的地址位置，配置较简单，这里不做说明。

### Output

Output 插件配置 Logstash 输出对象，可以为 [elasticsearch](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)、[email](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-email.html)、[file](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-file.html) 等介质。

例如，配置过滤后存储在 Elasticsearch 中：

```Yaml
output {
    elasticsearch {
        hosts => "localhost:9200"
        manage_template => false
        index => "%{[@metadata][type]}-%{+YYYY.MM}"
        document_type => "%{[fields][env]}"
        template_name => "logstash"
        user => "elastic"
        password => "changeme"
    }
}
```

当然，Output 插件不只是可以将过滤数据输出到一种介质，还可以同时指定多种介质。 

### 配置示例

实现基于 Nginx 日志进行过滤处理，并且通过 useragent 和 geoip 插件获取用户客户端和地理位置信息。详细配置如下：

```Yaml
input {
    beats { port => 5044 }
}
filter {
    if [fileset][module] == "nginx" {
        if [fileset][name] == "access" {
            grok {
                match => { "message" => ["%{IPORHOST:[@metadata][remote_ip]} - %{DATA:[user_name]} \[%{HTTPDATE:[time]}\] \"%{WORD:[method]} %{DATA:[url]} HTTP/%{NUMBER:[http_version]}\" %{NUMBER:[response_code]} %{NUMBER:[body_sent][bytes]} \"%{DATA:[referrer]}\" \"%{DATA:[@metadata][agent]}\""] }
                remove_field => "message"
            }
            if [url] =~ "\.(jpg|jpeg|gif|png|bmp|swf|fla|flv|mp3|ico|js|css|woff)" {
                drop {}
            }
            mutate { add_field => { "read_timestamp" => "%{@timestamp}" } }
            date { match => [ "[time]", "dd/MMM/YYYY:H:m:s Z" ] }
            useragent {
                source => "[@metadata][agent]"
                target => "useragent"
            }
            geoip {
                source => "[@metadata][remote_ip]"
                target => "geoip"
            }
        } else if [fileset][name] == "error" {
            grok {
                match => { "message" => ["%{DATA:[time]} \[%{LOGLEVEL:[level]}\] %{POSINT:[pid]}#%{NUMBER:[tid]}: %{GREEDYDATA:[error_message]}(?:, client: %{IPORHOST:[ip]})(?:, server: %{IPORHOST:[server]}?)(?:, request: \"%{WORD:[method]} %{DATA:[url]} HTTP/%{NUMBER:[http_version]}\")?(?:, upstream: %{WORD:[upstream]})?(?:, host: %{QS:[request_host]})?(?:, referrer: \"%{URI:[referrer]}\")?"] }
                remove_field => "message"
            }
            date { match => [ "[time]", "YYYY/MM/dd H:m:s" ] }
        }
    }
}
output {
    elasticsearch {
        hosts => "localhost:9200"
        manage_template => false
        index => "%{[@metadata][type]}-%{+YYYY.MM}"
        document_type => "%{[fields][env]}"
        template_name => "logstash"
        user => "elastic"
        password => "changeme"
    }
}
```

## [索引模板](https://www.elastic.co/guide/cn/elasticsearch/guide/current/index-templates.html)

Logstash 在推送数据至 Elasticsearch 时，默认会自动创建索引，但有时候我们需要定制化索引信息，Logstash 创建的索引就不符合我们的要求，此时就可以使用索引模板来解决。

创建一个名为`logstash`的索引模板，并指定该索引模板的匹配模式，作为 Logstash 推送日志时索引的模板。

```Json
PUT _template/logstash
{
    "index_patterns": ["*access*", "*error*"],
    "settings": {
        "index": {
            "number_of_shards": "3",       
            "number_of_replicas": "0"
        }
    },
    "mappings": {
        "_default_": {
            "properties": {
                "@timestamp": {
                  "type": "date"
                },
                "@version": {
                    "type": "text",
                    "fields": {
                        "keyword": {
                            "type": "keyword",
                            "ignore_above": 256
                        }
                    }
                }
            }
        }
    }
}
```

其中 [index_patterns]() 为匹配模式，表示含有 access 和 error 的索引才会使用该模板。[mappings]()  为字段映射规则，可以配置更多的字段映射规则，已配置字段根据索引模板规则映射，未配置字段则动态映射。

## 指定数据存储类型

Logstash 推送数据到 Elasticsearch 时，可以通过以下几种方式指定字段存储类型。

### grok

```Yaml
grok {
    match => { "message" => "%{IP:client} %{WORD:method} %{WORD:request} %{NUMBER:bytes} %{NUMBER:duration}" }
}
```

其中 IP、WORD、NUMBER 分别会映射为 Elasticsearch 的 IP、String、Number 类型。

### mutate

通过 Mutate 过滤插件的 convert 配置项，可以转换字段值类型。

```Yaml
mutate { convert => { "fieldname" => "integer" } }
```

### 索引模板

若想要根据用户 IP 地址解析后的地理位置信息，得出访问用户的地理分布情况，就需要在 Elasticsearch 中将用户地理坐标存储为 [geo_point]() 类型，而 Logstash 并不能自动完成这个步骤，我们可以在索引模板中指定 location 字段的类型为 geo_point。

Elasticsearch 待存储的地理位置数据，格式如下：

```Json
{"geoip": {
  "location": { 
    "lat": 40.722,
    "lon": -73.989
  }
}}
```

索引模板的 [Mappings](#索引模板) 部分，应设置为：

```Json
{"mappings": {
    "_default_": {
        "properties": {
            "geoip": {
                "type": "object",
                "dynamic": true,
                "properties": {
                    "location": {
                        "type": "geo_point"
                    }
                }
            }
        }
    }
}}
```

## 清理过期数据

日志平台会产生大量的索引文件，这样不但会占用磁盘空间，而且还会导致检索性能降低，对于那些已经失效的日志文档，应该定期对其清理。

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

配置定期清理过期日志的任务：

```Bash
0 0 * * * /usr/bin/curl -u elastic:changeme  -H'Content-Type:application/json' -d'query' -XPOST "host/*/_delete_by_query?pretty" > path.log
```

其中，`elastic`和`changeme`分别为 Elasticsearch 的用户名和密码，`query`为待清理日志的查询条件，`path.log`为日志文件路径。

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
$ curator_cli --http_auth elastic:changeme --host es.fanhaobai.com --port 80 show_indices --verbose

.kibana     open   15.7KB       3   1   0 2017-12-15T06:15:07Z
```

#### 配置

* [主配置文件](https://www.elastic.co/guide/en/elasticsearch/client/curator/current/configfile.html)

创建名为`/etc/curator/curator.yml`的配置文件，主要用来配置 Elasticsearch 服务的相关信息：

```Yaml
client:
  hosts:
    - es.fanhaobai.com         #集群配置形如["10.0.0.1", "10.0.0.2"]
  port: 80
  http_auth: elastic:changeme  #授权信息
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

## 数据报表

上述一切准备步骤做好后，我们就可以利用 Kibana 对大量的日志数据进行报表分析，进而实现应用监控和流量分析。

### 创建索引模式

选择 Kibana 的 ”Managemant  >> Kibana >> Index Patterns" 项 ，创建一个名为`nginx-www-access*`的索引模式，并设为默认索引，如图：

![](https://img.fanhaobai.com/2017/12/elk-advanced/d82824ed-15eb-47c5-9ec6-925f2d3f7758.png)

### 创建数据图表

选择 Kibana 的 ”Visualize" 项，创建一个数据图表，Kibana 已经支持了丰富的图标类型，这里选择 Line 类型图表制作一个用户访问量的图表。

图表的 Metrics（指标） 和 Buckets（桶）属性，Metrics 用来表示 PV 和 UV，而 Buckets 则是时间维度，UV 需要根据 location 去重后统计。

图表的 Metrics 部分，如下图：

![](https://img.fanhaobai.com/2017/12/elk-advanced/f2c9321a-e7e4-11e7-80c1-9a214cf093ae.png)

图表的 Buckets 部分，如下图：

![](https://img.fanhaobai.com/2017/12/elk-advanced/3f97da38-e7e5-11e7-80c1-9a214cf093ae.png)

最后，生成的用户访问量图表如文章起始所示。

### 创建实时监控面板

当我们创建了各种指标的数据图表后，就可以将这些数据图表组合成一个实时监控面板。选择 Kibana 的 ”Dashboard" 项，创建一个监控面板，并添加所需监控指标的数据图表，拖拽调整各图表到合适位置并保存，一个实时监控面板就呈现在眼前了。

下面是我针对主站 [Blog](https://www.fanhaobai.com) 健康监控和流量分析做出的实时 [数据报表](http://elk.fanhaobai.com) 展示，基本上满足了实时监控要求。

![](https://img.fanhaobai.com/2017/12/elk-advanced/b27378ac-e7e8-11e7-80c1-9a214cf093ae.png)

<strong>相关文章 [»]()</strong>

* [ELK集中式日志平台之一 — 平台架构](https://www.fanhaobai.com/2017/12/elk.html) <span>（2017-12-16）</span>
* [ELK集中式日志平台之二 — 部署](https://www.fanhaobai.com/2017/12/elk-install.html) <span>（2017-12-22）</span>
