---
title: Solr的使用 — 部署和数据推送
date: 2017-08-12 17:19:01
tags:
- Solr
categories:
- Lucene
---

来到 ziroom 后，我使用 Solr 支持业务也有段时间了，大多数情况下 Solr 满足业务需求，但由于 Solr 随着数据量急剧上升后检索性能和更新索引效率衰退较快，同时一些历史遗留原因导致字段较多不易维护，现架构上已将搜索引擎迁移到了 ES。在这里整理记录自己使用 Solr 的点滴，供后续学习和使用时参考。
![](https://img.fanhaobai.com/2017/08/solr-install-push/43735106-acb6-4f42-a136-dd5ab347ef49.png)<!--more-->

[Solr的使用]() 系列的重点应是 Solr 的检索，如果需要可以直接传送到 [Sorl检索](https://www.fanhaobai.com/2017/08/solr-search.html) 部分。

## 部署

由于该 Solr 平台只供学习使用，所以直接采用 Docker 方式部署，这样能避免一些复杂的依赖环境导致的问题。

### 下载

从 [Hub](https://hub.docker.com) 拉取 Solr [官方镜像](https://hub.docker.com/_/solr/) 到本地，这里只选择 5.5 版本：

```Bash
$ docker pull solr:5.5
```

### 安装

Docker 需要通过挂载宿主机目录的方式持久化数据，先创建供挂载目录（注意目录读写权限）：

```Bash
$ mkdir -p /home/docker/solr
```

**启动** 容器，挂载数据目录，隐射监听端口：

```Bash
$ docker --name solr -p 127.0.0.1:8983:8983 -v /home/docker/solr:/opt/solr/server/solr -d solr:5.5
```

我们往往需要修改容器的一些默认参数（Solr 的配置），需要我们登入容器：

```Bash
$ docker exec -it solr /bin/bash
```

> 注：由于容器中 /opt/solr/server/solr 会默认存在一些 Solr 启动的必须配置文件，直接将空目录挂载到该目录，会导致容器启动失败。可以先将目录挂载到 /opt/solr/mydata 目录，启动容器后`cp /opt/solr/server/solr/* /opt/solr/mydata/`，获得这些配置文件后，重新以上述地址挂载启动容器即可。

### 配置Web服务

Solr 容器启动成功后，配置 Web 服务器到 8983 端口，访问后看到 [Solr Admin](http://solr.fanhaobai.com) 页面，就表示安装成功了。

向 Solr 里推送数据，需要先建立 Core（核），然后在 Core 上创建或更新 Document（文档）。

## 新建Core

Core 默认路径为`/opt/solr/server/solr`。有两种方式新建 Core，**方式一** 是使用命令：

```Bash
$ bin/solr create_core -c books
Creating new core 'books'
{
  "responseHeader":{
    "status":0,
    "QTime":1140
  },
  "core":"books"
}

#删除核使用delete
```

**方式二**：在 Admin 面板点击 “Core Admin >> Add Core"，填写 name、instanceDir、dataDir、config、schema（文档的字段类型描述） 信息即可。由于 config 和 schema 配置可由模板生成，所以我偏向于使用命令方式创建。

> 注：方式一和方式二，其实都是通过`/solr/admin/cores?action=CREATE`这个 API 来完成创建任务。

新建 Core 后，可选中 books 核，点击 “Files”，这里列举出后面需要使用的 2 个配置文件：

```Bash
$ pwd
/opt/solr/server/solr/bools/conf
#使用命令创建后自动生成，后续新建文档的字段类型描述需加入其中
managed-schema
solrconfig.xml
```

## 新建Document(s)

Document 存放着数据记录，新建 Document 后就可以使用 Solr 检索了。这里需存入 book 的数据格式（例如 json）如下：

```Js
{
    "id" : "978-0641723445",
    "cat" : ["book", "hardcover"],
    "name" : "The Lightning Thief",
    "author" : "Rick Riordan",
    "price" : 12.50
}
```

### 配置字段类型

如果没有配置字段映射类型推送数据时，Solr 会自动根据字段值设置字段的映射类型，并保存在`core-name/conf/managed-schema`文件，但是有时结果并不是我们想要的，所以配置文档的字段类型描述很有必要。

从上述 book 的数据可得，各个 Document 的字段类型关系：

| 字段名    | 类型      | 是否只被索引 |
| ------ | ------- | ------ |
| id     | string  | √      |
| cat    | strings |        |
| name   | string  |        |
| author | strings |        |
| price  | tdouble |        |

字段类型通过文件`schema.xml`描述，需放置于 Core 的 conf 目录，文档格式可以参考`managed-schema`文件，基本要素大致为：

```Xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- ![需更改]schema.name需要同core名一致 -->
<schema name="books" version="1.6">
    <!-- ![需更改]唯一键，重复时记录会覆盖 -->
    <uniqueKey>id</uniqueKey>
    <!-- ![无需更改]fieldType定义字段值类型,这里只列举了部分 -->
    <fieldType name="boolean" class="solr.BoolField" sortMissingLast="true"/><!-- as: true -->
    <fieldType name="booleans" class="solr.BoolField" sortMissingLast="true" multiValued="true"/><!-- as: [true,false,true] -->
    <fieldType name="int" class="solr.TrieIntField" positionIncrementGap="0" precisionStep="0"/>
    ... ...
    <!-- ![需更改]field定义各字段类型,type为fieldType.name定义值,indexed=false使用只用于返回而无需进行搜索的字段,stored=false适用只需要搜索而无需返回的字段,required=true字段值必须存在 -->
    <field name="_version_" type="long" indexed="true" stored="true"/>
    <field name="author" type="strings"/>
    <field name="cat" type="strings"/>
    <field name="id" type="string" indexed="true" required="true" stored="true"/>
    <field name="name" type="string"/>
    <field name="price" type="tdouble"/>
    ... ...
    <!-- ![无需更改]dynamicField -->
    <dynamicField name="*_s" type="string" indexed="true" stored="true"/>
    ... ...
    <copyField source="*" dest="_text_"/>
</schema>
```

> 注：如果后续更新 schema.xml 配置后，需要对 Core 进行 Reload 操作，否则检索时字段类型可能未变更。可以点击 “Core Admin >> Reload” 操作。

### 推送数据

Solr 支持的数据源类型较多，为 xml、json、csv 等格式。

**方式一**：使用 post 命令：

```Bash
#post工具
$ bin/post -c books server/solr/data/books.json 
```

`books.json`是以 json 格式描述的一些 book，可以批量推送数据。

**方式二**：在 Admin 面板点击 “books >> Documents”，在 Document(s) 一栏中输入一个 book 信息，并点击 “ Submit Document” 即可。成功右侧会返回：

```Js
Status: success
Response:
{
  "responseHeader": {
    "status": 0,
    "QTime": 12
  }
}
```

也可以通过 [检索](http://solr.fanhaobai.com/solr/books/select?q=*:*&wt=json&indent=true)，可以查看数据推送是否成功，检索结果为：

```Js
"docs": [
{
    "id": "978-0641723445",
    "cat": [
        "book",
        "hardcover"
    ],
    "name": "The Lightning Thief",
    "author": [
        "Rick Riordan"
    ],
    "price": 12.5,
    "_version_": 1575546976608452600
}]
```

> 注：方式一和二其实是殊途同归，都是 POST 请求`solr/books/update?wt=json`这个 API。

## 删除Document(s)

删除 Document 其实也是 update 操作，同样有两种方式。

先使用 xml 格式构建需要删除 Document 的条件描述`del-book.xml`，如删除 id 为 978-0641723445 的 book 信息：

```Xml
<delete>
    <!-- 要删除文档的query条件 -->
    <query>id:978-0641723445</query>
</delete>
<!-- commit一定要，否则不会提交修改到索引 -->
<commit/>
```

**方式一**：同样使用 post 命令：

```Bash
$ bin/post -c books server/solr/data/del-book.xml
#这里会自动提交commit,所以del-book.xml中无commit也可以
COMMITting Solr index changes to http://localhost:8983/solr/books/update..
```

**方式二**：在 Admin 面板点击 “books >> Documents”，Document Type 项选择 xml，然后在 Document(s) 一栏中输入需要删除 book 的条件描述（del-book.xml 内容），并点击 “ Submit Document” 即可。

重新检索，可以发现 id 为 978-0641723445 的 book 信息已经被成功删除。

> 注：方式一和二都是 POST 请求`solr/books/update?wt=json`这个 API。

## 总结

本文仅仅叙述了 Solr 的 Docker 单节点部署和简单的数据推送实现，由于个人能力和时间限制，并未涉及到其生成环境的应用环节。后续的一篇文章将会记录 Solr 的检索语法和 PHP 作为客户端调用 Solr 服务的一种方案。

<strong>相关文章 [»]()</strong>

* [Solr的使用 — 检索](https://www.fanhaobai.com/2017/08/solr-search.html) <span>（2017-08-13）</span>
