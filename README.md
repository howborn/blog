# [后端搬运工](https://www.fanhaobai.com)

[![](https://img.shields.io/github/issues/fan-haobai/blog.svg)](https://github.com/fan-haobai/blog/issues)  [![](https://img.shields.io/github/forks/fan-haobai/blog.svg)](https://github.com/fan-haobai/blog/network) [![](https://img.shields.io/github/stars/fan-haobai/blog.svg)](https://github.com/fan-haobai/blog/stargazers)

![预览图](https://www.fanhaobai.com/view.png)

## 关注公众号获取文章推送

![公众号](https://www.fanhaobai.com/wechat.jpeg)

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

* [2021年终总结](https://www.fanhaobai.com/2022/01/2021-personal-summary.html)（2022-01-12）
* [从北京回到成都的这3个月](https://www.fanhaobai.com/2018/06/beijing-to-chengdu.html)（2018-06-27）
* [使用Charles抓包](https://www.fanhaobai.com/2017/07/charles.html)（2017-07-22）
* [身份证的编码规则](https://www.fanhaobai.com/2017/08/id-card.html)（2017-08-20）
* [Robots协议的那些事](https://www.fanhaobai.com/2017/01/robots.html)（2017-01-12）

### 架构

* [如何实现一个自定义规则引擎](https://www.fanhaobai.com/2024/04/design-rule-engine.html)（2024-04-23）
* [基于准实时规则引擎的业务风控方案](https://www.fanhaobai.com/2022/06/risk-rule.html)（2022-06-28）
* [自如2018新年活动系统 — 抢红包](https://www.fanhaobai.com/2018/01/2018-new-year-activity.html)（2018-01-30）
* [千人千面个性化推荐系统](https://www.fanhaobai.com/2023/01/recommender-system.html)（2023-01-02）
* [Flink在用户画像上的应用](https://www.fanhaobai.com/2022/12/user-profile-use-flink.html)（2022-12-23）
* [使用Docker轻松部署Hexo博客系统](https://www.fanhaobai.com/2020/12/hexo-to-docker.html)（2020-12-27）
* [自建一个简易的OpenAPI网关](https://www.fanhaobai.com/2020/07/openapi.html)（2020-07-15）
* [在分布式系统使用Kafka](https://www.fanhaobai.com/2020/05/use-kafka.html)（2020-05-12）
* [商品价格的多币种方案](https://www.fanhaobai.com/2019/02/multi-currency-price.html)（2019-02-28）
* [我的博客发布上线方案 — Hexo](https://www.fanhaobai.com/2018/03/hexo-deploy.html)（2018-03-03）
* [ELK集中式日志平台之三 — 进阶](https://www.fanhaobai.com/2017/12/elk-advanced.html)（2017-12-22）
* [ELK集中式日志平台之二 — 部署](https://www.fanhaobai.com/2017/12/elk-install.html)（2017-12-21）
* [ELK集中式日志平台之一 — 平台架构](https://www.fanhaobai.com/2017/12/elk.html)（2017-12-16）
* [分布式配置管理Qconf](https://www.fanhaobai.com/2017/11/qconf.html)（2017-11-03）

### 算法

* [负载均衡算法 — 平滑加权轮询](https://www.fanhaobai.com/2018/11/load-balance-smooth-weighted-round-robin.html)（2018-12-30）
* [负载均衡算法 — 轮询](https://www.fanhaobai.com/2018/11/load-balance-round-robin.html)（2018-12-29）
* [王者编程大赛之五 — 最短路径](https://www.fanhaobai.com/2017/12/2017-ziroom-king-5.html)（2017-12-06）
* [王者编程大赛之四 — 约瑟夫环](https://www.fanhaobai.com/2017/12/2017-ziroom-king-4.html)（2017-12-06）
* [王者编程大赛之三 — 01背包](https://www.fanhaobai.com/2017/12/2017-ziroom-king-3.html)（2017-12-05）
* [王者编程大赛之二 — 蓄水池](https://www.fanhaobai.com/2017/12/2017-ziroom-king-2.html)（2017-12-05）
* [王者编程大赛之一](https://www.fanhaobai.com/2017/12/2017-ziroom-king-1.html)（2017-12-05）
* [什么是Bitmap算法？](https://www.fanhaobai.com/2017/08/bitmap.html)（2017-08-16）
* [按照奖品概率分布抽奖的实现](https://www.fanhaobai.com/2017/05/draw-by-prob.html)（2017-05-18）
* [求非负元素数组所有元素能组合的最大字符串](https://www.fanhaobai.com/2017/04/array-form-max-string.html)（2017-04-03）
* [PHP生成随机红包算法](https://www.fanhaobai.com/2017/02/reward.html)（2017-02-13）
* [什么是B-树？](https://www.fanhaobai.com/2017/07/b-.html)（2017-07-08）

### 语言

* [用PHP玩转进程之二 — 多进程PHPServer](https://www.fanhaobai.com/2018/09/process-php-multiprocess-server.html)（2018-09-02）
* [用PHP玩转进程之一 — 基础](https://www.fanhaobai.com/2018/08/process-php-basic-knowledge.html)（2018-08-28）
* [使用Supervisor管理进程](https://www.fanhaobai.com/2017/09/supervisor.html)（2017-09-23）
* [APP接口多版本处理](https://www.fanhaobai.com/2017/08/api-version.html)（2017-08-19）
* [Lua在Nginx的应用](https://www.fanhaobai.com/2017/09/lua-in-nginx.html)（2017-09-09）
* [Lua在Redis的应用](https://www.fanhaobai.com/2017/09/lua-in-redis.html)（2017-09-04）
* [进入Lua的世界](https://www.fanhaobai.com/2017/09/lua.html)（2017-09-03）
* [异步、并发、协程原理](https://www.fanhaobai.com/2017/11/synchronised-asynchronized-coroutine.html)（2017-11-13）

### DB

#### MySQL

* [MySQL索引背后的数据结构及算法原理](https://www.fanhaobai.com/2016/05/mysql-index.html)（2016-05-19）

#### Redis

* [Lua在Redis的应用](https://www.fanhaobai.com/2017/09/lua-in-redis.html)（2017-09-04）
* [使用Redis管道提升性能](https://www.fanhaobai.com/2017/08/redis-pipelining.html)（2017-08-31）

#### 搜索

* [Elasticsearch检索 — 聚合和LBS](https://www.fanhaobai.com/2017/08/elasticsearch-advanced-search.html)（2017-08-21）
* [Elasticsearch检索实战](https://www.fanhaobai.com/2017/08/elasticsearch-search.html)（2017-08-09）
* [Solr的使用 — 检索](https://www.fanhaobai.com/2017/08/solr-search.html)（2017-08-13）
* [Solr的使用 — 部署和数据推送](https://www.fanhaobai.com/2017/08/solr-install-push.html)（2017-08-12）


