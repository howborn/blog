---
title: ELK集中式日志平台之一 — 平台架构
date: 2017-12-16 13:14:00
tags:
- 系统设计
- 日志
categories:
- 系统设计
---

随着微服务化的推广，我们的应用都会采取分布式方式部署，这就会导致应用日志比较分散，应用监控和排查问题都比较困难，同时效率还低下，集中式日志平台就是为了解决这个问题。

![](https://img.fanhaobai.com/2017/12/elk/c0625948-b690-48ad-a178-63fc08b0cefb.png)<!--more-->

## 背景

很早前，我们的应用都已经接入了 [CAT](https://github.com/dianping/cat)，能够在线实时查看应用访问量、异常的调用情况等应用性能指标，同时也打通了各平台的调用链路，基本满足应用的性能监控要求。

![](https://img.fanhaobai.com/2017/12/elk/b488220c-e24a-4eaf-8ee9-81cc6ae9484c.png)

由于我们应用业务日志并没有推送到 CAT，所以当线上出现问题时，传统方式查看业务日志，排查问题比较困难，搭建业务日志集中平台迫在眉睫。经过调研，我们选择了 [Elastic](https://www.elastic.co) 提供的 ELK 日志解决方案，查看 [在线演示](http://demo.elastic.co/app/kibana#/dashboard/b7be4700-6837-11e7-bd1c-eb5e5ad48f8b)。

原因主要有两点：

* ELK 提供的功能满足我们的使用要求，并有较高的扩展性；
* ELK 为一套开源项目，较低的维护成本；

## 相关概念

ELK 指的是一套解决方案，是 [Elasticsearch](https://www.elastic.co/cn/products/elasticsearch)、[Logstash](https://www.elastic.co/cn/products/logstash) 和 [Kibana](https://www.elastic.co/cn/products/kibana) 三种软件产品的首字母缩写，[Beats](https://www.elastic.co/cn/products/beats) 是 ELK 协议栈的新成员。

* E：代表 Elasticsearch，负责日志的存储和检索； 
* L：代表 Logstash，负责日志的收集、过滤和格式化； 
* K：代表 Kibana，负责日志数据的可视化；
* Beats：是一类轻量级数据采集器；

其中，目前 Beats 家族根据功能划分，主要包括 4 种：

* Filebeat：负责收集文件数据； 
* Packetbeat：负责收集网络流量数据；
* Metricbeat：负责收集系统级的 CPU 使用率、内存、文件系统、磁盘 IO 和网络 IO 统计数据；
* Winlogbeat：负责收集 Windows 事件日志数据;

![](https://img.fanhaobai.com/2017/12/elk/de986f14-1b7a-46f0-bf81-e477dda1e157.png)

在该日志平台系统中，就使用了 Filebeat 作为日志文件收集工具，Filebeat 可以很方便地收集 Nginx、Mysql、Redis、Syslog 等应用的日志文件。

## 日志平台架构

ELK 集中式日志平台，总体上来说，部署在应用服务器上的数据采集器，近实时收集日志数据推送到日志过滤节点的 Logstash，然后 Logstash 再推送格式化的日志数据到 Elasticsearch 存储，Kibana 通过 Elasticsearch 集中检索日志并可视化。

当然，ELK 集中日志平台也是经过一次次演变，才变成最终的样子。

### ES + Logstash + Kibana

![](https://img.fanhaobai.com/2017/12/elk/b19f74ae-2be3-4aef-b390-246acbf3050f.png)

最开始的架构中，由 Logstash 承担数据采集器和过滤功能，并部署在应用服务器。由于 Logstash 对大量日志进行过滤操作，会消耗应用系统的部分性能，带来不合理的资源分配问题；另一方面，过滤日志的配置，分布在每台应用服务器，不便于集中式配置管理。

### 引入Logstash-forwarder

![](https://img.fanhaobai.com/2017/12/elk/c2f50522-4a60-47b5-80b3-69f194745e19.png)

使用该架构，引入 Logstash-forwarder 作为数据采集，Logstash 和应用服务器分离，应用服务器只做数据采集，数据过滤统一在日志平台服务器，解决了之前存在的问题。但是 Logstash-forwarder 和 Logstash 间通信必须由 SSL 加密传输，部署麻烦且系统性能并没有显著提升；另一方面，Logstash-forwarder 的定位并不是数据采集插件，系统不易扩展。

### 引入Beats

![](https://img.fanhaobai.com/2017/12/elk/c0625948-b690-48ad-a178-63fc08b0cefb.png)

该架构，基于 Logstash-forwarder 架构，将 Logstash-forwarder 替换为 Beats。由于 Beats 的系统性能开销更小，所以应用服务器性能开销可以忽略不计；另一方面，Beats 可以作为数据采集插件形式工作，可以按需启用 Beats 下不同功能的插件，更灵活，扩展性更强。例如，应用服务器只启用 Filebeat，则只收集日志文件数据，如果某天需要收集系统性能数据时，再启用 Metricbeat 即可，并不需要太多的修改和配置。

这种 ELK+Beats 的架构，已经满足大部分应用场景了，但当业务系统庞大，日志数据量较大、较实时时，业务系统就和日志系统耦合在一起了。

### 引入队列

![](https://img.fanhaobai.com/2017/12/elk/17b1a5c7-2897-46f2-becd-3f03f926bc0f.png)

该架构，引入消息队列，均衡了网络传输，从而降低了网络闭塞，尤其是丢失数据的可能性；另一方面，这样可以系统解耦，具有更好的灵活性和扩展性。

## 总结

比较成熟的 ELK+Beats 架构，因其扩展性很强，是集中式日志平台的首选方案。在实际部署时，是否引入消息队列，根据业务系统量来确定，早期也可以不引入消息队列，简单部署，后续需要扩展再接入消息队列。

<strong>相关文章 [»]()</strong>

* [ELK集中式日志平台之二 — 部署](https://www.fanhaobai.com/2017/12/elk-install.html) <span>（2017-12-21）</span>
* [ELK集中式日志平台之三 — 进阶](https://www.fanhaobai.com/2017/12/elk-advanced.html) <span>（2017-12-22）</span>
