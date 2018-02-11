---
title: ELK集中式日志平台之二 — 部署
date: 2017-12-21 23:14:00
tags:
- 系统设计
- 日志
categories:
- 系统设计
---

由于系统日志量还在可控范围，所以选择了 ELK+Beats 的方案，并未引入消息队列，当然后续需要可以对系统升级。鉴于此，只需要在日志平台部署 Elasticsearch 和 Logstash 集群，同时在应用服务器部署 Filebeat。

![](https://img.fanhaobai.com/2017/12/elk-install/0da3b439-5174-4aff-b9dc-f275ebbd9e1f.png)<!--more-->

## 安装前准备

### JAVA环境

ELK 需要 JAVA 8 以上的运行环境，若未安装则按如下步骤安装：

```Bash
# 查看是否安装
$ rpm -qa | grep java
# 批量卸载
$ rpm -qa | grep java | xargs rpm -e --nodeps
$ yum install -y java-1.8.0-openjdk*
$ java -version
openjdk version "1.8.0_151"
```

在文件`/etc/profile`配置环境变量：

```Bash
# 指向安装目录
JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.151-1.b12.el6_9.x86_64
PATH=$JAVA_HOME/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
JAVACMD=/usr/bin/java
export JAVA_HOME JAVACMD CLASSPATH PATH
```

执行`source /etc/profile`命令，使配置环境生效。

### 安装GPG-KEY

由于后续采用 yum 安装，所以需要下载并安装 GPG-KEY：

```Bash
$ rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

## Elasticsearch

### 安装

通过 [官方地址](https://www.elastic.co/downloads/past-releases) 下载选择最新版本，然后解压：

```Bash
$ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.1.1.tar.gz
$ mkdir -p /usr/local/elk
$ tar zxvf elasticsearch-6.1.1.tar.gz -C /usr/local/elk
$ mv /usr/local/elk/elasticsearch-6.1.1 /usr/local/elk/elasticsearch
```

启动前，需要修改配置文件`jvm.options`中 JVM 大小，否则可能会内存溢出，导致启动失败。

```Bash
$ vim config/jvm.options
# 根据实际情况修改
-Xms128m
-Xmx256m
```

由于 Elasticsearch 新版本不允许以 [root]() 身份启动，因此先创建 elk 用户。这里使用 [service](https://github.com/fan-haobai/init-script/blob/master/elasticsearch/elasticsearch) 服务方式管理 Elasticsearch，修改启动用户和安装目录。

```Bash
$ useradd elk
$ chown -R elk:elk /usr/local/elk/elasticsearch

$ vim /etc/init.d/elasticsearch
ES_USER="elk"
ES_GROUP="elk"
ES_HOME="/usr/local/elk/elasticsearch"
MAX_OPEN_FILES=65536
MAX_MAP_COUNT=262144
LOG_DIR="$ES_HOME/logs"
DATA_DIR="$ES_HOME/data"
```

设置开机启动服务，启动 Elasticsearch，其默认监听 9200 端口。

```Bash
# 开启服务
$ chkconfig --add elasticsearch
$ chkconfig elasticsearch on

$ service elasticsearch start

$ netstat -tunpl | grep "9200"
tcp   0   0 127.0.0.1:9200   0.0.0.0:*    LISTEN    27029/java
# 获取信息
$ curl http://127.0.0.1:9200
```

最后，安装使用到的插件：

```Bash
$ cd /usr/local/elk/elasticsearch
# ingest-geoip和ingest-user-agent分别为ip解析插件和agent解析插件
$ bin/elasticsearch-plugin install ingest-geoip
$ bin/elasticsearch-plugin install ingest-user-agent
# 用户管理和monitor管理
$ bin/elasticsearch-plugin install x-pack
# 修改用户密码
$ bin/x-pack/setup-passwords interactive
```

> 安装 x-pack 插件后，对 Elasticsearch 的操作都需要授权，默认用户名为 elastic，默认密码为 changeme。

## [Kibana](https://www.elastic.co/guide/en/kibana/current/install.html)

首先，在`/etc/yum.repos.d`目录下创建名为`kibana.repo`的 yum 源文件：

```Bash
[kibana-5.x]
name=Kibana repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

使用 yum 命令安装：

```Bash
$ yum install -y kibana
$ mkdir -p /usr/local/elk
$ ln -s /usr/share/kibana /usr/local/elk/kibana
$ cd /usr/local/elk/kibana
```

修改配置文件`kibana.yml`以下配置项：

```Bash
$ mkdir -p /usr/local/elk/kibana/config
$ mv /etc/kibana/kibana.yml /usr/local/elk/kibana/config
$ vim config/kibana.yml

server.port: 5601                           # 监听端口
server.host: "0.0.0.0"                      # 绑定地址
server.name: "elk.fanhaobai.com"            # 域名
elasticsearch.url: "http://127.0.0.1:9200"  # es
kibana.index: ".kibana"                     # 索引名
elasticsearch.username: "elastic"           # 用户名
elasticsearch.password: "changeme"          # 密码
```

安装常用插件，例如 x-pack：

```Bash
$ bin/kibana-plugin install x-pack
```

修改 [init]() 启动脚本，并启动 Kibana：

```Bash
vim /etc/init.d/kibana

home=/usr/share/kibana
program=$home/bin/kibana
args=-c\\\ $home/config/kibana.yml
# 默认以kibana运行
$ chown -R kibana:kibana /usr/local/elk/kibana/*
$ chkconfig --add kibana
$ chkconfig kibana on
$ service kibana start
```

配置 Web 服务后，访问 [elk.fanhaobai.com](http://elk.fanhaobai.com/) 就可以看到 Kibana 强大又绚丽的界面。

> 安装 x-pack 插件后，访问 Kibana 同样需要授权，且任何 Elasticsearch 的用户名和密码对都可被认证通过。

## Logstash

### [安装](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html#_yum)

首先，在`/etc/yum.repos.d`目录下创建`logstash.repo`文件：

```Bash
[logstash-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

使用 yum 安装 Logstash，并测试：

```Bash
# 安装logstash 5.x
$ yum install -y logstash
# 默认安装路径/usr/share
$ mkdir -p /usr/local/elk
$ ln -s /usr/share/logstash /usr/local/elk/logstash
$ cd /usr/local/elk/logstash
# 命令行测试
$ bin/logstash -e 'input { stdin { } } output { stdout {} }'

The stdin plugin is now waiting for input:
elk
2017-11-21T22:25:07.264Z fhb elk
```

生成并修改 [init]() 启动脚本：

```Bash
$ bin/system-install /etc/logstash/startup.options sysv
$ vim /etc/init.d/logstash
home=/usr/share/logstash
name=logstash
program=$home/bin/logstash
args=--path.settings\ $home/config
# 添加启动
$ chkconfig --add logstash
$ chkconfig logstash on
```

安装 x-pack 插件，基本状态信息的监控:

```Bash
$ bin/logstash-plugin install x-pack
```

### 配置

#### 主配置文件

Logstash 主配置文件为`config/logstash.yml`，配置如下：

```Yaml
path.data: /var/lib/logstash
path.logs: /usr/share/logstash/logs
# 配置
path.config: /usr/share/logstash/config/conf.d
# elasticsearch用户名和密码
xpack.monitoring.elasticsearch.username: elastic
xpack.monitoring.elasticsearch.password: changeme
```

#### [配置管道](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)

创建一个简单的管道（inputs → filters → outputs），配置文件为`conf.d/filebeat.conf`。日志过滤处理后，直接推送到 Elasticsearch，在 output 部分需配置 Elasticsearch 的用户名和密码。

```Conf
input {
    beats {
        port => 5044
    }
}

filter {
    if [fileset][name] =~ "access" {
        grok {
            match => {"message" => "%{COMBINEDAPACHELOG}"}
        }
        date {
            match => ["timestamp", "dd/MMM/YYYY:H:m:s Z"]
        }
    } else if [fileset][name] =~ "error" {
    
    } else {
        drop {}
    }
}

output {
    elasticsearch {
        hosts => "localhost:9200"
        manage_template => false
        index => "%{[@metadata][type]}-%{+YYYY.MM}"  #索引名称
        document_type => "%{[fields][env]}"          #文档类型
        user => "elastic"                            #用户名     
        password => "changeme"                       #密码
    }
}
```

更多配置示例，见 [Logstash Configuration Examples](https://www.elastic.co/guide/en/logstash/current/config-examples.html)。

### 启动

```Bash
$ service logstash start
# 完成监听
$ netstat -tnpl | grep 5044
tcp   0      0 0.0.0.0:5044     0.0.0.0:*    LISTEN      10132/java
```

## Beats

### Filebeat

#### [安装](https://www.elastic.co/downloads/beats/filebeat)

由于同 Elasticsearch 使用一个源，所以直接使用 yum 安装：

```Bash
# 安装filebeat 5.6.6
$ yum install -y filebeat
$ mkdir -p /usr/local/elk/beats
$ ln -s /usr/share/filebeat /usr/local/elk/beats/filebeat
$ cd /usr/local/elk/beats/filebeat
```

修改 init 启动脚本：

```Bash
$ vim /etc/init.d/filebeat

home=/usr/share/filebeat
pidfile=${PIDFILE-/var/run/filebeat.pid}
agent=${BEATS_AGENT-$home/bin/filebeat}
args="-c $home/filebeat.yml -path.home $home -path.config $home -path.data $home/bin/data -path.logs $home/bin/logs"
```

配置启动服务：

```Bash
$ chkconfig --add filebeat
$ chkconfig filebeat on
```

#### 配置

创建 Filebeat 配置文件`filebeat.yml`，开启 nginx 日志模块采集 access 日志信息：

```Yaml
filebeat.modules:
- module: nginx
  access:
    enabled: true
    var.paths: ["/data/logs/fanhaobai.com.access.log"] #日志路径
    prospector:
      fields:
        type: nginx-www-access               #Logstash的type字段
  error:
    enabled: true
    var.paths: ["/data/logs/error.log"]
    prospector:
      fields:
        type: nginx-all-error
fields:                                      #自定义字段，Logstash的fields字段
  env: prod                                  #添加环境标识
queue_size: 1000
bulk_queue_size: 0

output.logstash:                             #输出到Logstash
  enabled: true
  hosts: ["localhost:5044"]  
  worker: 1  
  loadbalance: true
  index: 'filebeat'
```

#### 启动

```Bash
$ service filebeat start
# 查看推送日志
$ tailf /usr/local/elk/beats/filebeat/bin/logs/filebeat
2017-12-22T02:00:53+08:00 INFO Non-zero metrics in the last 30s: filebeat.harvester.open_files=1 filebeat.harvester.running=1
libbeat.logstash.publish.read_bytes=6 libbeat.logstash.publish.write_bytes=460
```

Filebeat 启动后，会侦测待采集文件内容是否有增加或更新，并实时推送数据到 Logstash。

> 因为 Filebeat、Logstash 有些配置并不向后兼容，更新升级后可能导致服务不可用，所以这里在`/etc/yum.conf`增加`exclude=filebeat logstash`配置项，禁用`yum update`的自动更新。

## 数据呈现

Filebeat 推送到 Logstash 过滤后，Elasticsearch 存储的数据格式为：

```Json
{
    "_index": "nginx-www-access-2017.12",
    "_type": "prod",
    "_source": {
        "response_code": "200",
        "ip": "106.11.152.143",
        "offset": 81989257,
        "method": "GET",
        "user_name": "-",
        "input_type": "log",
        "http_version": "1.1",
        "read_timestamp": "2017-12-21T18:12:53.604Z",
        "source": "/data/logs/fanhaobai.com.access.log",
        "fileset": {
            "name": "access",
            "module": "nginx"
        },
        "type": "nginx-www-access",
        "url": "/2017/11/qconf-deploy.html",
        "referrer": "-",
        "@timestamp": "2017-12-21T18:12:53.000Z",
        "@version": "1",
        "beat": {
            "name": "fhb",
            "hostname": "fhb",
            "version": "5.6.5"
        },
        "host": "fhb",
        "body_sent": { "bytes": "44067" },
        "fields": { "env": "prod" }
    }
}
```

在 Kibana 中呈现效果为：

![](https://img.fanhaobai.com/2017/12/elk-install/a1ff2131-8dd8-4ad1-8ba3-c2d2ebeffc91.png)

<strong>相关文章 [»]()</strong>

* [ELK集中式日志平台之一 — 平台架构](https://www.fanhaobai.com/2017/12/elk.html) <span>（2017-12-16）</span>
* [ELK集中式日志平台之三 — 进阶](https://www.fanhaobai.com/2017/12/elk-advanced.html) <span>（2017-12-22）</span>
