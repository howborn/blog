---
title: ELK+Beats集中式日志平台
date: 2017-12-10 13:14:00
tags:
- 分布式
- 平台架构
categories:
- 分布式
---

## 日志平台架构

## ELK+Filebeat安装

由于 ELK 需要 JAVA 8 以上的环境，安装 ELK 前请确保 JAVA 环境已经存在。

```Bash
$ java -version
openjdk version "1.8.0_151"
```

### Elasticsearch

通过 [官方地址](https://www.elastic.co/downloads/past-releases) 下载选择合适的版本（这里为 5.2.0），下载并解压：

```Bash
$ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.2.0.tar.gz
$ mkdir -p /usr/local/elasticsearch
$ tar zxvf elasticsearch-5.2.0.tar.gz -C /usr/local/elasticsearch
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
$ chown -R elk:elk /usr/local/elasticsearch
$ su elk
# 守护进程
$ nohup /usr/local/elasticsearch/bin/elasticsearch &
# 端口
$ netstat -tunpl | grep "9200"
tcp   0   0 127.0.0.1:9200   0.0.0.0:*    LISTEN    27029/java
# 获取信息
$ curl 127.0.0.1:9200
```

## kibana

有关 Kibana 详细的安装方法见 [官方手册](https://www.elastic.co/guide/en/kibana/current/install.html)。首先，下载 [Kibana](https://www.elastic.co/downloads/past-releases) 软件包，注意同 Elasticsearch 版本对应，然后解压：

```Bash
$ wget https://artifacts.elastic.co/downloads/kibana/kibana-5.2.0-linux-x86_64.tar.gz
$ tar zxvf kibana-5.2.0-linux-x86_64.tar.gz -C /usr/local/elk
$ mv /usr/local/elk/kibana-5.2.0-linux-x86_64 /usr/local/elk/kibana
$ cd /usr/local/elk/kibana
```

修改配置文件`kibana.yml`以下配置项：

```Bash
$ vim vim config/kibana.yml
# 基本配置
server.port: 5601                           # 监听端口
server.host: "0.0.0.0"                      # 绑定地址
server.name: "elk.fanhaobai.com"            # 域名
elasticsearch.url: "http://127.0.0.1:9200"  # es地址
kibana.index: ".kibana"                     # 索引名
```

最后，启动 Kibana 后（可配置为 [Service 服务](https://github.com/cjcotton/init-kibana)），直接访问 [elk.fanhaobai.com](http://elk.fanhaobai.com/) 即可。

```Bash
$ ./bin/kibana

$ netstat -tunpl | grep 5601
tcp   0    0 0.0.0.0:5601    0.0.0.0:*      LISTEN     8390/node
```

## Logstash

Logstash 的详细安装过程见 [官方手册](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html#_yum)。这里采用 yum 来完成安装，先下载并安装 GPG-KEY：

```Bash
$ rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

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
$ yum install logstash
# 默认安装在/usr/share
$ ln -s /usr/share/logstash /usr/local/elk/logstash
# 执行测试
$ /usr/local/elk/logstash/bin/logstash logstash -e 'input { stdin { } } output { stdout {} }'

The stdin plugin is now waiting for input:
elk
2017-11-26T14:25:07.264Z fhb elk
```