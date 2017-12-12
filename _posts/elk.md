---
title: ELK+Beats集中式日志平台
date: 2017-12-10 13:14:00
tags:
- 分布式
- 日志
categories:
- 分布式
---

![]()<!--more-->

## 日志平台架构

ELK 指的是一套解决方案，是 Elasticsearch、Logstash 和 Kibana 三种软件产品的首字母缩写。 

* E：代表 Elasticsearch，负责日志的存储和检索； 
* L：代表 Logstash，负责日志的收集，过滤和格式化； 
* K：代表 Kibana，负责日志的展示统计和数据可视化；
* Filebeat：ELK 协议栈的新成员，是一个轻量级开源日志文件数据搜集器；

![]()<!--more-->

这种架构引入 Beats 作为日志搜集器。目前 Beats 包括四种：

* Packetbeat（搜集网络流量数据）；
* Metricbeat（搜集系统、进程和文件系统级别的 CPU 和内存使用情况等数据）；
* Filebeat（搜集文件数据）； 
* Winlogbeat（搜集 Windows 事件日志数据）;

## 安装

由于 ELK 需要 JAVA 8 以上的环境，安装 ELK 前请确保 JAVA 环境已经存在。

```Bash
$ java -version
openjdk version "1.8.0_151"
```

### Elasticsearch

通过 [官方地址](https://www.elastic.co/downloads/past-releases) 下载选择合适的版本（这里为 5.6.5），下载并解压：

```Bash
$ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.5.tar.gz
$ mkdir -p /usr/local/elasticsearch
$ tar zxvf elasticsearch-5.6.5.tar.gz -C /usr/local/elk/elasticsearch
```

一般启动前，需要修改配置文件`jvm.options`中 JVM 大小，否则可能启动失败。

```Bash
$ vim config/jvm.options
# 根据实际情况修改，默认为2g
-Xms256m
-Xmx256m
```

Elasticsearch 新版本不允许以 root 身份启动，因此先创建 elk 用户。切换用户后启动 ，Elasticsearch 默认监听 9200 端口。

```Bash
$ useradd elk
$ chown -R elk:elk /usr/local/elk/elasticsearch
# 守护进程
$ sudo -u elk nohup /usr/local/elk/elasticsearch/bin/elasticsearch &
# 端口
$ netstat -tunpl | grep "9200"
tcp   0   0 127.0.0.1:9200   0.0.0.0:*    LISTEN    27029/java
# 获取信息
$ curl 127.0.0.1:9200
```

## Kibana

有关 Kibana 详细的安装方法见 [官方手册](https://www.elastic.co/guide/en/kibana/current/install.html)。这里采用 yum 来完成安装，先下载并安装 GPG-KEY：

```Bash
$ rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```
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

使用 yum 安装：

```Bash
$ yum install -y kibana
$ ln -s /usr/share/kibana /usr/local/elk/kibana
$ cd /usr/local/elk/kibana
```

修改配置文件`kibana.yml`以下配置项：

```Bash
$ vim kibana.yml
# 基本配置
server.port: 5601                           # 监听端口
server.host: "0.0.0.0"                      # 绑定地址
server.name: "elk.fanhaobai.com"            # 域名
elasticsearch.url: "http://127.0.0.1:9200"  # es地址
kibana.index: ".kibana"                     # 索引名
```

启动 Kibana：

```Bash
$ service kibana start

$ netstat -tunpl | grep 5601
tcp   0    0 0.0.0.0:5601    0.0.0.0:*      LISTEN     8390/node
```

访问 [elk.fanhaobai.com](http://elk.fanhaobai.com/) 就可以看到 Kibana 强大的界面了。

## Logstash

Logstash 的详细安装过程见 [官方手册](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html#_yum)。

在`/etc/yum.repos.d`目录下新建`logstash.repo`文件，并添加如下内容：

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
# 默认安装在/usr/share
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

```

### Beats

#### Filebeat

Filebeat 安装详细安装过程见 [官方手册](https://www.elastic.co/downloads/beats/filebeat)，这里直接使用 yum 安装即可。

```Bash
$ yum install -y filebeat
$ ln -s /usr/share/filebeat /usr/local/elk/filebeat
```

修改配置文件：

```Bash
#nginx模块需要安装ingest-geoip和ingest-user-agent插件
$ sudo bin/elasticsearch-plugin install ingest-geoip
$ sudo bin/elasticsearch-plugin install ingest-user-agent
```

```Yaml

```

启动 Filebeat，默认监听端口 xxx:

```Bash
$ 
```