---
title: PHP接入Protocol Buffer并实现二进制流传输
date: 2017-02-24 18:06:40
tags:
- PHP
- TCP/IP
categories:
- 语言
- PHP
---

> 原文：http://hansionxu.blog.163.com/blog/static/241698109201562442831489

我们这边是一个 PHP 的 Web 系统，需要新接入一个业务，是通过 Protocol Buffer 协议通信，而且只提供了一个 C++ 的接入例子。 对于我们的 PHP 系统来说，除了接入 Protocol Buffer 之外，还需要处理二进制流的 TCP 传输通信，而 PHP 实际上并不太擅长做这些事情。<!--more-->

PHP 版本的 Protocol Buffer 接入，有官方的支持实现版本 —— [Protocol Buffer for PHP](https://code.google.com/p/pb4php/)。

这里需要注意的点，就是安全中心提供的 proto 文件里面有一些东西是我们的 PHP 无法识别的。

1） 头部的 package，无法识别直接注释掉。
2） pb_parser 文件里的标量类型做一下调整，之后就可以顺利生成我们需要使用的 PHP 库文件哈。

![](https://img.fanhaobai.com/2017/02/protocol-buffer/49FdBzeNpkelIh0Y8eaMttuF.png)

生成的代码：

```PHP
require_once('./parser/pb_parser.php'); 
$test = new PBParser(); 
$test->parse('scintf.proto');
```

于是，我们得到了 PHP 使用的库文件 pb_proto_scintf.php，下一步就是编写实际的程序代码。

![](https://img.fanhaobai.com/2017/02/protocol-buffer/xGcf67WPCRtWw_sMgGqohg.png)

我们经常使用 PHP  来做字符串的 socket 通信，但是，处理这种二进制格式的 socket 传输，PHP 并不太擅长。

我们也只能通过 [pack/unpack](http://php.net/manual/zh/function.pack.php) 的方式，来将字符串转为二进制流。将传输字符串 pack 为二进制，传输出去，获取回包后，在 unpack 为字符串，再进行处理。

![](https://img.fanhaobai.com/2017/02/protocol-buffer/Ygl0353JmGdSnwraJtnyK8me.jpg)

在这里，因为我们的 PHP 是安装了内部的扩展的，我们刚开始犯了一个小错误，就是直接使用了内部类，读取 socket 回包内容直接使用了 read_line（内部实现其实是 fgets）。这种做法，会引起 2 个问题：

1） 当 TCP 传输只有 1 个内容数据包的时候，read_line 能够读取全部内容，在后续的 unpack 操作中，一切正常那个。但是，当 TCP 传输的超过 1 个内容数据包的时候，read_line 只能读取到第一个包的内容，后面的包没有获取到，在 unpack 的时候，会报头部解析出来的长度和实际数据内容大小对不上。

![](https://img.fanhaobai.com/2017/02/protocol-buffer/b-10-CLAkDRq9-p9B5yYeFcp.png)

这个有点奇怪的现象，我们是通过 [tcpdump](http://baike.baidu.com/link?url=6VCJQWje9na7WG0qzOpTMGL6rE16rkZQmDpLhJf6WMxtNOT2rXfbCrk68UBX4CUgSJOnlV8U4bV3XEQIYll7Dq) 抓包分析后发现的：

![](https://img.fanhaobai.com/2017/02/protocol-buffer/ShgNJxsFMocvcalRfy4XWwGU.png)

2） read_line 是按照行读取内容，而二进制流中不会以换行符结束，因此，这里还会引起 read socket timeout，虽然我们也能顺利读取到内容。

解决的方式，其实也很简单，就是直接使用 fread，这个函数本身就可以用在二进制读取。
