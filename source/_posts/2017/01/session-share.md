---
title: SESSION共享问题
date: 2017-01-10 00:52:11
tags:
- PHP
categories:
- 语言
- PHP
---

随着应用访问量的增加，单台服务器已经扛不住这样的访问压力，所以需要部署多台服务器，并需要做负载均衡。那么，默认的 SESSION 存储方式会造成用户不同时间访问不同服务器时 SESSION 丢失，进而导致用户登录状态丢失，这时需要使用 [SESSION共享](http://www.onmpw.com/tm/xwzj/network_144.html) 来解决。

![](//img0.fanhaobai.com/2017/01/session-share/nC3zafy-N82Vr7NgGZKHiyOL.png)<!--more-->


# SESSION共享方案

实现 SESSION 共享的方案大致有以下几种：

1） ** 基于NFS的SESSION共享 **

NFS是 [Net FileSystem](#) 的简称，该方案相对简单，无需做过多的二次开发，仅需同步各个服务器的本地 SESSION 文件记录，缺点是 NFS 依托于复杂的安全 机制和文件系统，因此并发效率不高。

2） ** 基于数据库的SESSION共享 **

这就是所说的 SESSION 入库，该方案实用性较强。它的缺点在于 SESSION 的并发读写能力取决于 MySQL 数据库的性能，同时需要实现 SESSION 的 gc 逻辑。

3） ** 基于COOKIE的SESSION共享 **

这个方案相对比较陌生，但它在大型网站中使用比较普遍。原理是将全站用户的 SESSION 信息加密、序列化后以 COOKIE 的形式，统一种植在根域名下，利用浏览器访问该根域名下的所有二级域名站点时，会传递与之域名对应的所有 COOKIE 内容的特性，从而实现用户的 COOKIE 化 SESSION 在多服务间的共享访问，缺点是需要一定的技术成本。

4） ** 基于内存缓存的SESSION共享 **

采用内存缓存服务器（ Memcache 或 Redis ）作为 SESSION 的存储介质，因为内存缓存服务器一般都是共享型的，且其在并发处理能力上占据了绝对优势，所以该方案成为我的首选。

[下面是采用 Redis 作为缓存服务器并在 PHP 语言环境下实现 SESSION 共享。](#)


# 基于缓存的SESSION共享

基于 Redis 的 SESSION 共享方案结构大致如下：

![](//img1.fanhaobai.com/2017/01/session-share/JGwh9o3k7y41aMqKRQa4vCgT.jpg)

## 搭建Redis环境

首先，需要搭建一个 Redis 服务器环境，[方法见这里](https://www.fanhaobai.com/2016/08/redis-install.html) 。

## 更改SESSION存储介质

这里介绍 3 种方法，分别为：

1） 直接修改php.ini配置

```PHP
session.save_handler = redis               
#将session存储介质由Files改为Redis
session.save_path ="tcp://fanhaobai.com:6379?database=0&auth=fhb"   
#更改session保存地址
```
> 需要说明的是，当 Redis 服务端设置了密码，需要在 save_path 配置中以 GET 方式传递 auth 值，当然也可以选择数据库。

配置成功后，查看`phpinfo`如下图。

![](//img2.fanhaobai.com/2017/01/session-share/K-fAtQd9WszI3rhXLWzfk2Ve.png)

2） 通过ini_set()设置配置

在某些使用环境下，`php.ini`配置文件是不允许进行修改的，且这样的修改对全局有效，所以可以采用`ini_set()`函数来设置当前脚本有效的配置信息。

只需在项目的入口文件位置增加以下内容：

```PHP
ini_set('session.save_handler', 'redis');        
#将session存储介质由File改为Redis
ini_set('session.save_path', 'tcp://fanhaobai.com:6379?database=0&auth=fhb');     
#更改session保存地址
```
> 注意设置只是当前脚本有效，并未修改`php.ini`配置文件。

3） 通过session_set_save_handler()自定义会话存储

`session_set_save_handler()`函数支持对 SESSION 机制的 open（打开）、close（关闭）、read（读） 、write（写） 、destroy（删除） 、gc（垃圾回收）这 6 种操作进行自定义更改。

参考 ID 为 [sd2536888](http://www.thinkphp.cn/extend/547.html) 所分享的 SESSION 的 Redis 分布式驱动来说明。

* ** 打开SESSION **

```PHP
public function open($savePath, $sessName) {
    return true;
}
```

* ** 关闭SESSION **

```PHP
public function close() {
    if ($this->options['persistent'] == 'pconnect') {
	$this->handler->close();
    }
    return true;
}
```

* ** 读取SESSION **

```PHP
public function read($sessID) {
    $this->connect(0);
    $this->get_result = $this->handler->get($this->options['prefix'].$sessID);
    return $this->get_result;
}
```

* ** 写入SESSION **

```PHP
public function write($sessID, $sessData) {
    if (!$sessData || $sessData == $this->get_result) {
	return true;
    }
    $this->connect(1);
    $expire = $this->options['expire'];
    $sessID = $this->options['prefix'].$sessID;
    if(is_int($expire) && $expire > 0) {
        $result = $this->handler->setex($sessID, $expire, $sessData);
    } else {
        $result = $this->handler->set($sessID, $sessData);
    }
    return $result;
}
```

* ** 删除SESSION **

```PHP
public function destroy($sessID) {
    $this->connect(1);
    return $this->handler->delete($this->options['prefix'].$sessID);
}
```

* ** 垃圾回收 **

```PHP
public function gc($sessMaxLifeTime) {
    return true;
}
```

# 总结

其实第①和第②种，是 PHP 已经自动实现了基于 Redis 的 SESSION 自定义存储过程，只需要修改配置即可，而第③种就需要我们自主实现自定义存储过程，本质上是一样的原理，建议使用第②种方法。
