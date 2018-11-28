---
title: 负载均衡算法 — 轮询
date: 2018-11-28 12:14:10
tags:
- 算法
categories:
- 算法
- PHP
---

在分布式系统中，为了实现负载均衡，就会涉及到负载调度算法。负载调度典型的应用场景如 Nginx 的 upstream 和 RPC 服务发现，常见的负载均衡算法有  [轮询]()、[源地址 Hash]()、[最少连接]()，而 **轮询** 是最简单且应用最广的算法。

![预览图](https://img1.fanhaobai.com/2018/11/load-balance-round-robin/)<!--more-->

