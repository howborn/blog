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

![](https://www.fanhaobai.com/2017/11/qconf/bce19607-8181-41fd-8885-5572ee1de166.jpg)<!--more-->

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

```Bash
$ sh bin/zkCli.sh

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

PHP 使用 Qconf 需要安装客户端扩展，安装如下：

```Bash
# 进入Qconf源码目录
$ QConf-1.2.2/driver/php
$ /usr/local/php/bin/phpize
# Qconf安装目录为/usr/local/qconf
$ ./configure --with-php-config=/usr/local/php/bin/php-config --with-libqconf-dir=/usr/local/qconf/include --enable-static LDFLAGS=/usr/local/qconf/lib/libqconf.a
$ make
$ make install
```

修改`php.ini`配置文件使 Qconf 扩展生效。

```Bash
$ vim /usr/local/php/lib/php.ini
# 追加如下配置
extension=qconf.so
```

重启 php-fpm，并查看 Qconf 扩展是否安装成功。

```Bash
$ php --ri qconf

qconf support => enabled
qconf version => 1.2.2
```

## 配置Qconf

Qconf 默认安装，其配置文件路径为`/usr/local/qconf/conf`。配置文件共有`agent.conf`、`idc.conf`、`localidc` 这三个，`agent.conf`为 Qconf 的 agent 相关配置，`idc.conf` 和 `localidc` 为与 Zookeeper 相关的连接信息配置。

### 配置agent

`agent.conf`的配置内容如下，一般不需要进行修改。

```INI
# 工作模式 0 => console mode; 1 => background mode. 
daemon_mode=1
# 日记级别 debug => 0; trace => 1; info => 2; warning => 3; error => 4; fatal_error => 5
log_level=4
# Zookeeper超时
zookeeper_recv_timeout=30000
# 执行执行超时
script_execute_timeout=3000
# Register the node on zookeeper server
register_node_prefix=/qconf/__qconf_register_hosts
# Zookeeper日志
zk_log=zoo.err.log
# 最大共享内存的读取次数
max_repeat_read_times=100
feedback_enable=0
# 共享内存大小，采用lru策略
shared_memory_size=100000
```

### 配置Zookeeper信息

`idc.conf`配置文件指定 Zookeeper 的配置信息，并支持多个环境（测试环境、开发环境、生产环境）的配置。

```INI
zookeeper.prod=www.fanhaobai.com:2181
zookeeper.test=127.0.0.1:2181
```

然后，将每个环境下的`localidc`配置文件内容配置为对应的环境名称。如测试环境则为 test，生产环境为 prod，这样就可以根据不同环境获取对应的配置信息。

## API

这里只通过 PHP 的 Qconf 客户端为例，来对 Qconf 的 API 使用进行说明。Qconf 为 PHP 封装的  API 操作类类名为 [Qconf](https://github.com/Qihoo360/QConf/wiki/QConf-PHP-Doc)。

### getConf

[getConf(path, idc, get_flag)]()
返回配置节点的值，失败返回 NULL。

**参数**

* path - 配置节点路径
* idc - 指定从那个 idc 获取配置信息，不指定则取 localidc 的值
* get_flag - 如果设置为 0，QConf 在未命中共享内存的 path 时，会同步等待从 Zookeeper 拉取的操作，直到返回结果。否则未命中则直接返回 NULL

```PHP
# 从idc为test上获取/demo/confs/conf1节点的配置
$ php -r "echo Qconf::getConf('/demo/confs/conf1');"
888888
# 从idc为prod上获取/demo/confs/conf1节点的配置
Qconf::getConf('/demo/confs/conf1', 'prod');
111111
```

### getBatchKeys

[getBatchKeys(path, idc, get_flag)]()
获取该节点路径所有 [下一级]() 子节点的名称，失败返回 NULL。

**参数**

参数见 [getConf](#getConf) 参数部分。

```PHP
Qconf::getBatchKeys('/demo/confs', 'test');

array(3) {
  [0] =>
  string(5) "conf1"
  [1] =>
  string(5) "conf2"
  [2] =>
  string(5) "conf3"
}
```

### getBatchConf

[getBatchConf(path, idc, get_flag)]()
获取该节点路径所有 [下一级]() 子节点的名称和配置值，失败返回 NULL。

**参数**

参数见 [getConf](#getConf) 参数部分。

```PHP
Qconf::getBatchConf('/demo/confs', 'test');
array(3) {
  'conf1' =>
  string(6) "888888"
  'conf2' =>
  string(6) "999999"
  'conf3' =>
  string(6) "101010"
}

Qconf::getBatchConf('/demo', 'test');
array(1) {
  'confs' =>
  string(5) "confs"
}
```

### getHost和getAllHost

[getHost(path, idc, get_flag)]() 或 [getAllHost(path, idc, get_flag)]()
返回该配置节点全部或一个可用服务，失败返回 NULL。

**参数**

参数见 [getConf](#getConf) 参数部分。

```PHP
Qconf::getHost('demo/confs/conf1');
```

## 植入代码

... ...

## 管理后台

未完待续。(●'◡'●)

> 选型参考：http://www.cnblogs.com/zhangxh20/p/5464103.html
