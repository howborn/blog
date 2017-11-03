---
title: 分布式配置管理服务Qconf
date: 2017-11-03 17:32:27
tags:
- 分布式
-  Qconf
categories:
- 分布式
---

[Qconf](https://github.com/Qihoo360/QConf/blob/master/README_ZH.md) 是 360 公司推出的分布式配置管理服务，目前已经支持 c++、go、java、lua、php、python 等语言。

分布式配置管理服务，[选型文章](http://www.cnblogs.com/zhangxh20/p/5464103.html)。

## 安装

### 安装Zookeeper服务

因为 Qconf 使用 Zookeeper 作为配置服务端，若没有安装 Zookeeper，则先安装。

#### 安装JAVA环境

在这里，直接通过 yum 命令来安装。

```Bash
$ yum install java-1.8.0-openjdk*
# 默认安装目录为/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.151-1.b12.el6_9.x86_64
$ java -version
openjdk version "1.8.0_151"
```

配置环境变量，在文件`/etc/profile`后追加如下内容：

```Bash
# 指向安装目录
JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.151-1.b12.el6_9.x86_64
export PTAH=$JAVA_HOME/bin:$PATH
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME CLASSPATH
```

执行`source /etc/profile`，使修改生效。


#### 下载Zookeeper

首先，从 Zookeeper [官方地址](http://mirror.bit.edu.cn/apache/zookeeper/)，下载最新版本源码包。

```Bash
$ wget http://mirror.bit.edu.cn/apache/zookeeper/zookeeper-3.3.6/zookeeper-3.3.6.tar.gz
$ tar zxvf zookeeper-3.3.6.tar.gz
$ cd zookeeper-3.3.6
```

#### 配置并启动Zookeeper

由于编译包解压后无需再编译安装，所以，只需修改配置文件：

```Bash
# 创建data目录
$ mkdir -p /tmp/zookeeper
$ cd conf/
$ mv zoo_sample.cfg zoo.cfg
```

使用`zkServer.sh`脚本启动 Zookeeper 服务：

```Bash
$ cd ..
$ sh bin/zkServer.sh start
# 查看端口监听
$ netstat -tunpl | grep 2181
```

#### 创建配置节点

使用 Zookeeper 提供的`zkCli.sh`脚本创建多个配置节点。

```
$ sh ./zkCli.sh

[zk: localhost:2181(CONNECTED) 0] create /demo demo
[zk: localhost:2181(CONNECTED) 1] create /demo/confs confs
[zk: localhost:2181(CONNECTED) 2] create /demo/confs/conf1 111111
[zk: localhost:2181(CONNECTED) 3] create /demo/confs/conf2 222222
```

同样，可以获取配置的配置节点信息：

```Bash
[zk: localhost:2181(CONNECTED) 0] get /demo/confs/conf1

111111
cZxid = 0x4
... ...
```

### 安装Qconf

#### 下载并安装

首先，从 Qconf [官方地址](https://github.com/Qihoo360/QConf/archive/v1.2.2.tar.gz)，下载源码包。

```Bash
$ wget -O qconf.tar.gz https://github.com/Qihoo360/QConf/archive/v1.2.2.tar.gz
# 解压文件带有版本号
$ tar zxvf qconf.tar.gz
$ cd QConf-1.2.2
$ mkdir build && cd build
$ cmake ..
$ make
$ make install
```

默认安装于`/usr/local/qconf`目录，查看版本信息：

```
$ qconf version
Version : 1.2.2
```

#### 配置并启动

Qconf 配置文件位于安装目录下`conf`目录，主要修改`idc.conf`的 Zookeeper 配置信息：

```Bash
$ vim idc.conf
# 修改为Zookeeper地址
zookeeper.test=127.0.0.1:2181
```

使用`agent-cmd.sh`脚本启动 Qconf 服务：

```Bash
$ cd bin/
$ sh ./agent-cmd.sh start
```

然后，测试并获取 Zookeeper 配置节点信息：

```Bash
# 获取节点值
$ qconf get_conf /demo/confs/conf1
111111
# 获取节点下的所有key
$ qconf get_batch_keys /demo/confs
conf1
conf2
conf3
```

### 安装PHP扩展