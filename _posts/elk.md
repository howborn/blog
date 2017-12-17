---
title: ELK+Beats集中式日志平台之一 —  平台架构
date: 2017-12-10 13:14:00
tags:
- 分布式
- 日志
categories:
- 分布式
---

![]()<!--more-->

## 概念

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

## 日志平台架构