# [后端搬运工]()

[![](https://img.shields.io/github/issues/fan-haobai/blog.svg)](https://github.com/fan-haobai/blog/issues)  [![](https://img.shields.io/github/forks/fan-haobai/blog.svg)](https://github.com/fan-haobai/blog/network) [![](https://img.shields.io/github/stars/fan-haobai/blog.svg)](https://github.com/fan-haobai/blog/stargazers)

## 关注公众号获取文章推送

![公众号](https://github.com/howborn/blog/blob/master/source/wechat.jpeg)

## 项目代码

本项目采用 git submodule 方式管理源代码。

* clone 命令

```bash
git clone --recursive https://github.com/howborn/blog.git
```

* pull 命令

```bash
git pull && git submodule foreach git pull origin master
```

* 安装 hexo

```bash
npm install -g hexo-cli
npm install hexo
npm install hexo-deployer-git --save
```

* 发布文章

```bash
# 本地预览
hexo s
# 发布到git仓库托管, 配置见_config.yml的deploy项
hexo deploy -g
```

## 部署环境

支持 docker 部署，请先安装 [docker-compose](https://docs.docker.com/compose/)。

* 配置环境变量

```bash
cp docker.example.env docker.env
```

> 其中，各环境变量意义见`docker.example.env`文件中的注释说明，可以根据实际情况修改各环境变量参数的值。

* 支持HTTPS协议

```bash
/bin/bash dockerfiles/nginx/ssl/init_ssl.sh
```

> 注意：如果无需支持HTTPS协议，则跳过此步骤，需要将环境变量`ENABLE_SSL`修改为`true`。

* 启动容器

```bash
docker-compose up --force-recreate --build -d
```

## 文章内容

本站所有的文章 Markdown 文件，请移步 [这里](https://github.com/fan-haobai/blog/tree/master/source/_posts)。

### 杂谈

* [2021年终总结]()（2022-01-12）
* [从北京回到成都的这3个月](https://mp.weixin.qq.com/s/mTiNQg57SgFneAC46aaQig)（2018-06-27）

### 架构

* [如何实现一个自定义规则引擎](https://mp.weixin.qq.com/s/MZSLrfdXFR_iiZWmNk2Mgg)（2024-04-23）
* [基于准实时规则引擎的业务风控方案](https://mp.weixin.qq.com/s/ZW7bkd9JZudvK0YS5WmS9A)（2022-06-28）
* [自如2018新年活动系统 — 抢红包](https://mp.weixin.qq.com/s/VG_Wcxte8avnXzn4bPXiGA)（2018-01-30）
* [千人千面个性化推荐系统](https://mp.weixin.qq.com/s/FVs4Kfi_stQ9Yp_qgOv78g)（2023-01-02）
* [Flink在用户画像上的应用](https://mp.weixin.qq.com/s/VYjwbQ3vrepLkOJoH0xoIA)（2022-12-23）
* [使用Docker轻松部署Hexo博客系统](https://mp.weixin.qq.com/s/seUlg_CicwaEZE-BuJPaAQ)（2020-12-27）
* [自建一个简易的OpenAPI网关](https://mp.weixin.qq.com/s/QF585V8k0xqmwNGx3uggfw)（2020-07-15）
* [在分布式系统使用Kafka](https://mp.weixin.qq.com/s/2jiVvgCsBH4_AT1bj_6dUQ)（2020-05-12）
* [商品价格的多币种方案](https://mp.weixin.qq.com/s/-4-ZhWhGUr9jGCyZwQVrkw)（2019-02-28）
* [我的博客发布上线方案 — Hexo]()（2018-03-03）
* [ELK集中式日志平台之三 — 进阶](https://mp.weixin.qq.com/s/hMLjVx9JF7EPAYd5B94O3Q)（2017-12-22）
* [ELK集中式日志平台之二 — 部署](https://mp.weixin.qq.com/s/E3W48eVpRahLtFjsdb_xwA)（2017-12-21）
* [ELK集中式日志平台之一 — 平台架构](https://mp.weixin.qq.com/s/A-QZm2JTGP2BMCnh6kpjBg)（2017-12-16）

### 算法

* [负载均衡算法 — 平滑加权轮询](https://mp.weixin.qq.com/s/LmBra6oPihlqKXGtWv6yIQ)（2018-12-30）
* [负载均衡算法 — 轮询](https://mp.weixin.qq.com/s/tAeI27-IA5CnbKwavUUkLQ)（2018-12-29）
* [王者编程大赛之五 — 最短路径](https://mp.weixin.qq.com/s/BhyTTm3x2NnrFCpoyYA5Pw)（2017-12-06）
* [王者编程大赛之四 — 约瑟夫环](https://mp.weixin.qq.com/s/yOhZ_kzxBTDr0uKAH5_g5g)（2017-12-06）
* [王者编程大赛之三 — 01背包](https://mp.weixin.qq.com/s/xq2SRtXNls7Bii5OMiAapA)（2017-12-05）
* [王者编程大赛之二 — 蓄水池](https://mp.weixin.qq.com/s/VYrStSwxMOer5Ivq3t9PFA)（2017-12-05）
* [王者编程大赛之一](https://mp.weixin.qq.com/s/tuE_rEsWVwRh8bD9zPUFeg)（2017-12-05）
* [什么是Bitmap算法？]()（2017-08-16）
* [按照奖品概率分布抽奖的实现](https://mp.weixin.qq.com/s/W5ON6gJRiNFl1WHCPw-XMg)（2017-05-18）
* [求非负元素数组所有元素能组合的最大字符串](https://mp.weixin.qq.com/s/Es0OVVga9GpuABHOSTCyCA)（2017-04-03）
* [PHP生成随机红包算法]()（2017-02-13）
* [什么是B-树？]()（2017-07-08）

### 语言

* [用PHP玩转进程之二 — 多进程PHPServer](https://mp.weixin.qq.com/s/XrAV2BRUkx8o4tIaYWYdDA)（2018-09-02）
* [用PHP玩转进程之一 — 基础](https://mp.weixin.qq.com/s/_WPrbGRG7Fuk1RYNSoK7Eg)（2018-08-28）
* [使用Supervisor管理进程]()（2017-09-23）
* [APP接口多版本处理]()（2017-08-19）
* [Lua在Nginx的应用](https://mp.weixin.qq.com/s/dt_4FVcgRpMkwTSp7qy32w)（2017-09-09）
* [Lua在Redis的应用](https://mp.weixin.qq.com/s/-U13YRZ3yLVQW4jzzxPMoQ)（2017-09-04）
* [进入Lua的世界]()（2017-09-03）
* [异步、并发、协程原理]()（2017-11-13）

### DB

#### MySQL

* [MySQL索引背后的数据结构及算法原理]()（2016-05-19）

#### Redis

* [Lua在Redis的应用](https://mp.weixin.qq.com/s/-U13YRZ3yLVQW4jzzxPMoQ)（2017-09-04）
* [使用Redis管道提升性能](https://mp.weixin.qq.com/s/5Ak5ss0FnH-nhZ42m35hUg)（2017-08-31）

#### 搜索

* [Elasticsearch检索 — 聚合和LBS](https://mp.weixin.qq.com/s/JYmcsIZAsZM4UVhK7ni0sg)（2017-08-21）
* [Elasticsearch检索实战]()（2017-08-09）
* [Solr的使用 — 检索]()（2017-08-13）
* [Solr的使用 — 部署和数据推送]()（2017-08-12）


