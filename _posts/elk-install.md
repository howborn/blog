---
title: ELK集中式日志平台之二 — 部署
date: 2017-12-17 16:14:00
tags:
- 分布式
- 日志
categories:
- 分布式
---

![]()<!--more-->

## 安装前准备

### JAVA运行环境

ELK 需要 JAVA 8 以上的运行环境，若未安装则按如下步骤进行安装：

```Bash
# 查看已安装
$ rpm -qa | grep java
# 批量卸载
$ rpm -qa | grep java | xargs rpm -e --nodeps
$ yum install -y java-1.8.0-openjdk*
$ java -version
openjdk version "1.8.0_151"
```

### 安装GPG-KEY

由于采用 yum 安装，所以需要下载并安装 GPG-KEY：

```Bash
$ rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

## Elasticsearch

### 安装

通过 [官方地址](https://www.elastic.co/downloads/past-releases) 下载选择合适的版本（例如 5.6.5），下载并解压：

```Bash
$ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.5.tar.gz
$ mkdir -p /usr/local/elasticsearch
$ tar zxvf elasticsearch-5.6.5.tar.gz -C /usr/local/elk/elasticsearch
```

一般启动前，需要修改配置文件`jvm.options`中 JVM 大小，否则可能启动失败。

```Bash
$ vim config/jvm.options
# 根据实际情况修改
-Xms256m
-Xmx256m
```

Elasticsearch 新版本不允许以 root 身份启动，因此先创建 elk 用户。这里使用 [service](https://github.com/fan-haobai/init-script/blob/master/elasticsearch/elasticsearch) 服务方式管理 Elasticsearch，修改启动用户和安装目录。

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
CONF_DIR="$ES_HOME/config"
```

最后，安装后续使用到的插件：

```Bash
$ sudo bin/elasticsearch-plugin install ingest-geoip
$ sudo bin/elasticsearch-plugin install ingest-user-agent
$ sudo bin/elasticsearch-plugin install x-pack
```

设置开机启动服务并启动 Elasticsearch，其默认监听 9200 端口。

```Bash
# 开启服务
$ chkconfig --add elasticsearch
$ chkconfig elasticsearch on

$ service elasticsearch start

$ netstat -tunpl | grep "9200"
tcp   0   0 127.0.0.1:9200   0.0.0.0:*    LISTEN    27029/java
# 获取信息
$ curl 127.0.0.1:9200
```

> 安装 x-pack 插件后，对 Elasticsearch 的操作都需要授权，默认用户名为 elastic，默认密码为 changeme。

### 配置

* [创建索引模板](https://www.elastic.co/guide/cn/elasticsearch/guide/current/index-templates.html)

建立一个名为`logstash`的索引模板，这个模板将应用于所有以`logstash`为起始的索引，作为 Logstash 推送日志时索引的模板。

```Josn
PUT _template/logstash
{
    "template": "*",           //应用于所有索引
    "settings": {
        "index": {
            "number_of_shards": "3",   //主分片数
            "number_of_replicas": "0"  //副分片数
        }
    },
    "mappings": {
        "_default_": {
            "_all": {
                "enabled": true
            },
            "dynamic_templates": [
                {
                    "string_fields": {
                        "match": "*",
                        "match_mapping_type": "string",
                        "mapping": {
                            "type": "string",
                            "index": "not_analyzed",
                            "omit_norms": true,
                            "doc_values": true,
                            "fields": {
                                "raw": {
                                    "index": "not_analyzed",
                                    "ignore_above": 256,
                                    "type": "string"
                                }
                            }
                        }
                    }
                }
            ],
            "properties": {
                "geoip": {
                    "type": "object",
                    "dynamic": true,
                    "properties": {
                        "location": {
                            "type": "geo_point"    //地理坐标
                        }
                    }
                }
            }
        }
    }
}
```

## [Kibana](https://www.elastic.co/guide/en/kibana/current/install.html)

在`/etc/yum.repos.d`目录下新建`kibana.repo`文件，并添加如下内容：

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
$ ln -s /usr/share/kibana /usr/local/elk/kibana
$ cd /usr/local/elk/kibana
```

修改配置文件`kibana.yml`以下配置项：

```Bash
$ vim kibana.yml
server.port: 5601                           # 监听端口
server.host: "0.0.0.0"                      # 绑定地址
server.name: "elk.fanhaobai.com"            # 域名
elasticsearch.url: "http://127.0.0.1:9200"  # es地址
kibana.index: ".kibana"                     # 索引名
elasticsearch.username: "elastic"           # 用户名
elasticsearch.password: "changeme"          # 密码
```

安装常用插件，例如 x-pack：

```Bash
$ sudo bin/kibana-plugin install x-pack
```

修改 init 启动脚本，并启动 Kibana：

```Bash
vim /etc/init.d/kibana

program=/usr/share/kibana/bin/kibana
args=-c\\\ /usr/share/kibana/kibana.yml

$ service kibana start

$ netstat -tunpl | grep 5601
tcp   0    0 0.0.0.0:5601    0.0.0.0:*      LISTEN     8390/node
```

配置 web 服务后，访问 [elk.fanhaobai.com](http://elk.fanhaobai.com/) 就可以看到 Kibana 强大并绚丽的面目了。

> 安装 x-pack 插件后，访问 Kibana 同样需要授权，且任何 Elasticsearch 的用户名和密码组合都可被认证通过。

## Logstash

### 安装

Logstash 的详细安装过程见 [官方手册](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html#_yum)。

在`/etc/yum.repos.d`目录下创建`logstash.repo`文件，并添加如下内容：

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

使用 yum 安装 Logstash，并执行测试：

```Bash
$ yum install -y logstash
# 默认安装路径/usr/share
$ ln -s /usr/share/logstash /usr/local/elk/logstash
$ cd /usr/local/elk/logstash
# 命令行测试
$ bin/logstash -e 'input { stdin { } } output { stdout {} }'

The stdin plugin is now waiting for input:
elk
2017-11-26T14:25:07.264Z fhb elk
```

生成并修改 init 启动脚本：

```Bash
$ bin/system-install /etc/logstash/startup.options sysv

$ vim /etc/init.d/logstash

home=/usr/share/logstash
name=logstash
program=$home/bin/logstash
args=--path.settings\ $home/config
```

安装 x-pack 插件，进行基本状态信息的监控:

```Bash
$ sudo bin/logstash-plugin install x-pack
```

### 配置

#### 主配置文件

Logstash 主配置文件为`config/logstash.yml`，配置如下：

```Yaml
path.data: /var/lib/logstash
path.logs: /usr/share/logstash/logs
# 处理器配置
path.config: /usr/share/logstash/config/conf.d
# elasticsearch 用户名和密码
xpack.monitoring.elasticsearch.username: elastic
xpack.monitoring.elasticsearch.password: changeme
```

#### 配置处理器

创建一个简单的 inputs → filters → outputs 处理器，例如`conf.d/filebeat.conf`。日志过滤处理后，直接推送到 Elasticsearch，在 output 处理器中配置其用户名和密码，同时指定以索引模板形式建立索引。

```Conf
input {
    beats {
        port => 5044
    }
}

filter {
	if [fileset][name] =~ "access" {
		mutate { replace => { type => "nginx_access" } }
		grok {
			match => {"message" => "%{COMBINEDAPACHELOG}"}
		}
		date {
		    match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
		}
	} else if [fileset][name] =~ "error" {
		mutate { replace => { type => "nginx_error" } }
	} else {
		drop {}
	}
}

output {
    elasticsearch {
        hosts => "localhost:9200"
        manage_template => false
        index => "%{[@metadata][type]}-%{+YYYY.MM}"
        document_type => "%{[@metadata][env]}"
		user => "elastic"            #用户名     
		password => "changeme"       #密码
		template_name => "logstash"  #索引模板名
    }
}
```

更详细的配置，见 [Logstash Configuration Examples])(https://www.elastic.co/guide/en/logstash/current/config-examples.html)。

## Beats

### Filebeat

#### 安装

Filebeat 安装详细安装过程见 [官方手册](https://www.elastic.co/downloads/beats/filebeat)，这里直接使用 yum 安装即可。

```Bash
$ yum install -y filebeat
$ ln -s /usr/share/filebeat /usr/local/elk/filebeat
```

修改 init 启动脚本：

```Bash
$ vim /etc/init.d/filebeat

home=/usr/share/filebeat
pidfile=${PIDFILE-/var/run/filebeat.pid}
agent=${BEATS_AGENT-$home/bin/filebeat}
args="-c $home/filebeat.yml -path.home $home -path.config $home -path.data $home/bin/data -path.logs $home/bin/logs"
```

配置启动服务，然后启动 Filebeat：

```Bash
$ chkconfig --add filebeat
$ chkconfig filebeat on
$ service filebeat start
```

##### 配置

修改 Filebeat 配置文件`filebeat.yml`，开启 nginx 日志采集模块，如下：

```Yaml
filebeat.modules:
- module: nginx
  access:
    enabled: true
    var.paths: ["/data/logs/fanhaobai.com.access.log"]
    prospector:
      fields:
        type: nginx-hexo-access
  error:
    enabled: true
    var.paths: ["/usr/local/nginx/logs/error.log"]
    prospector:
      fields:
        type: nginx-all-error
        
fields:
  env: prod
queue_size: 1000
bulk_queue_size: 0

output.logstash:
  enabled: true
  hosts: ["localhost:5044"]  
  worker: 1  
  loadbalance: true
  index: 'filebeat'
```
