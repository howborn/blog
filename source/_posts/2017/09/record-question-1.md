---
title: 记录 — Redis与接口签名问题
date: 2017-09-21 13:09:59
tags:
- Redis
categories:
- DB
- Redis
---

最近比较忙，要上新的项目，也没时间打理博客了。今天中午抽午睡时间记录下这几天工作上遇到的 [接口签名错误](#) 和 [Redis 集群 VIP 漂移故障](#) 。

![](https://img2.fanhaobai.com/2017/09/record-question-1/0188ae67-31cc-464e-a986-d999f3507427.png)<!--more-->


## 接口签名错误

今天一大早就升级 IOS 11 尝鲜，并习惯性打开 [APP](https://static8.ziroom.com/card_clean)，点着点着就发现 [通勤找房](#) 功能异常。

![](https://img3.fanhaobai.com/2017/09/record-question-1/5727d810-6ea5-476c-8479-bcec444805d7.jpg)

Charles 抓包查看接口信息：

```Js
URL v7/commute/search.json
JSON Text
0b6f781984b042cd184563c73a091732d67d049d5b396b18a10443d4aa0d77803e59dbdf86e902ff525e396bd95e0...
```

由于该新上线功能已经接入网关，所以响应内容是密文。使用解密工具解密后：

```Js
{
    "code": "100002",
    "data": [],
    "message": "接口签名错误",
    "requestId": "a493b6f6a75b45e8abcbe6970aca12dc",
    "status": "failure"
}
```

很明显，出现了接口签名错误。然后查看该功能模块的另一个配置接口并无异常，未接入网关的其他接口也无异常，且该接口在 IOS 11 以下版本并无异常。

到公司后，首先跟 APP 端使用 IOS 11 版本在测试环境复现该问题，发现测试环境也存在一样的问题，于是 APP 端打开调试 Log，同时在服务端抓取该次调试请求参数并对比，果不出意外，签名的 sign 值不一致。

```Js
sign=00aca6ddf61da553e1d3a152d2531241&city_code=110000&zoom=2&transport=transit&clng=116.53516158527775&minute=45&uid=0&max_lat=40.050779703285322&clat=40.038686258547742&min_lng=116.52039350058239&imei=b08572622e0b803bd72298d223febd10f782e348&min_lat=40.024114254242676&timestamp=1506155272&max_lng=116.54241877617007
```

首先，我们怀疑可能是 md5 加密方式问题，所以将相同的请求参数串和盐加密，两端对比发现是一致的。然后开始怀疑是网关加密解密导致 sign 不一致，同样 APP 打印传入网关的参数与服务端请求参数对比，发现也是保持一致。不过有了意外发现，APP 计算 sign 时参数和传入网关参数存在浮点数精度不一致问题。最后 APP 排查到是由于在 IOS 11 中使用了某个 JSON 方法，导致浮点数精度前后不一致。

解决办法是，[服务端针对该版本取消接口签名校验](#)，APP 端下个版本进行修复。

## [VIP漂移故障](#)

### 初期方案

PM 说有一个类似于抢购的小需求，我们第一反应就想到是典型的防止库存超卖场景，于是理所因当地选用了 Redis 方案。只要保证是原子操作，即可防止库存超卖，自然想到使用 Incr/Decr 这类原子操作。

查看 PHP 的 Redis 扩展关于 [Incr](http://redis.io/commands/incr) 方法的说明：

```PHP
/**
 * Increment the number stored at key by one.
 *
 * @param   string $key
 * @return  int    the new value
 * @link    http://redis.io/commands/incr
 *      
 */
public function incr( $key ) {}
```

可见，Incr 方法返回的是 key 操作后的新值，即 ++1 后的值，于是我们写出了如下代码：

```PHP
$num = $redis->incr($key);
if ($num < $max) {
    //入抢购成功队列，异步去执行抢购成功逻辑
} else {
    //不好意思呢，已经被抢完了
}
```

不知道你有没有闻到这段代码的坏味道，在大部分情况下会如你所想地运行，但是特殊场景下会 [出现判断失效](#) 的逻辑问题，例如：

1、key 由于某些原因失效了；
2、Incr 操作失败了，不会抛异常并返回 false；

上述两种情况，都会导致`$num < $max`条件成立，进而导致更严重的逻辑问题，最终超卖。

### 问题描述与分析

我们就抢购开始后就遇到了上述的第二种情况，下面描述整个过程。先通过 [Cat](https://github.com/dianping/cat) 监控平台观察到访问量急剧上升，开始担心应用服务坑不住，随后日志平台报警 Incr 操作存在异常几率，再然后就出现超卖情况，紧急情况只能关闭业务开关。是什么原因导致判断条件成立？

通过日志定位到 Incr 操作问题，便 Telnet 连接到线上 Redis 服务，发现了异常情况：

```Shell
# 查看值
GET key
100
# 尝试修改
INCR key
READONLY You can't write against a read only slave

INFO
# Replication
role:slave
```

可以看出来，该连接的机器目前处于从机状态，不可写操作，所以 Incr 操作返回 false，同时 PHP 不同类型比较会存在隐式转化，所以`false < $num`恒成立，导致计数器失效。而这一切又是由于 Redis 高可用不完善，当主从切换后，[VIP 未能成功漂移](http://www.178linux.com/2466)，这部分是运维的锅，研发代码不够健壮，这锅同样要背 >﹏<。

### 优化方案

首先，修改代码使其更加健壮，增加计数器容错处理：

```PHP
$num = $redis->incr($key);
if ($num > 0 && $num < $max) {
    //入抢购成功队列，异步去执行抢购成功逻辑
} else {
    //不好意思呢，已经被抢完了
}
```

然后，切换 Redis 源到高可用集群（Codis），测试并重新上线，第二日的抢购已经正常，看着 Cat 上流量逐渐平稳，心里也踏实了。

### 总结

这个事故后，该系统也由二级系统升级为一级系统，并将制定一些弱类型语言规范，如这件事的惨痛教训：

* 比较操作时尽量判大不判小，例如库存是否 <= 0
* 写代码就是写的是异常

另外，如果使用 Redis 支持业务，必须考虑 Redis 的读/写操作量，以便选择合适并高可用的集群。这里由于产品前期提需时就指出是一个小需求，所以没去顾及到这些。好吧，貌似不能把锅甩给产品，[代码写健壮才是王道](#)。

