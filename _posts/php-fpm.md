---
title: CGI与fastcgi和php-fpm与php-cgi的关系
date: 2017-03-09 22:21:22
categories:
- 语言
- PHP
tags:
- php-fpm
- CGI
---

> 原文：http://www.lcode.cc/2017/01/15/php-fpm.html

之前因为服务器内存爆了，导致 php-fpm 起不来，然后 php 访问就解析不了了，所以去查了一下 php-fpm 到底是什么东西，找到了这篇文章，篇幅不长，解释的却很到位，通俗易懂。<!--more-->

CGI 与 fastcgi 对比：

* CGI 是一个协议，它规定了服务器 Nginx 会将那些数据传送给 php-cgi。
* fastcgi 也可以说是一个协议。fastcgi 是对 CGI 的性能的一次提高。fastcgi 会先启动一个 master，解析配置文件（php.ini 等），初始化执行环境，然后再启动多个 worker，当请求过来时，master 会传递给一个 worker，然后等待下一个请求。

php-fpm 与 php-cgi 对比：

* php-fpm 是实现了 fastcgi 这个协议的程序，用来管理 php-cgi 的（php-fpm 是 fastcgi 进程管理器）。
* php-cgi 是解释 php 程序的。

刚开始对这个问题我也挺纠结的，看了《HTTP权威指南》后，感觉清晰了不少。

首先，CGI 是干嘛的？CGI 是为了保证 web server 传递过来的数据是标准格式的，方便 CGI 程序的编写者。

>web server（比如说 nginx）只是内容的分发者。比如，如果请求 /index.html，那么 web server 会去文件系统中找到这个文件，发送给浏览器，这里分发的是静态数据。好了，如果现在请求的是 /index.php，根据配置文件，Nginx 知道这个不是静态文件，需要去找 PHP 解析器来处理，那么他会把这个请求简单处理后交给 PHP 解析器。Nginx 会传哪些数据给 PHP解析器呢？url 要有吧，查询字符串也得有吧，POST 数据也要有，HTTP header 不能少吧，好的，CGI 就是规定要传哪些数据、以什么样的格式传递给后方处理这个请求的协议。仔细想想，你在 PHP 代码中使用的用户从哪里来的。
>
>当 web server 收到 /index.php 这个请求后，会启动对应的 CGI 程序，这里就是 PHP 的解析器。接下来 PHP 解析器会解析 php.ini 文件，初始化执行环境，然后处理请求，再以规定 CGI 规定的格式返回处理后的结果，退出进程。web server 再把结果返回给浏览器。

好了，CGI 是个协议，跟进程什么的没关系。那 fastcgi 又是什么呢？fastcgi 是用来提高 CGI 程序性能的。

>提高性能，那么 CGI 程序的性能问题在哪呢？"PHP 解析器会解析 php.ini 文件，初始化执行环境"，就是这里了。标准的 CGI 对每个请求都会执行这些步骤（不闲累啊！启动进程很累的说！），所以处理每个时间的时间会比较长。这明显不合理嘛！那么 fastcgi 是怎么做的呢？首先，fastcgi 会先启一个 master，解析配置文件，初始化执行环境，然后再启动多个 worker。当请求过来时，master 会传递给一个 worker，然后立即可以接受下一个请求。这样就避免了重复的劳动，效率自然是高。而且当 worker 不够用时，master 可以根据配置预先启动几个 worker 等着；当然空闲 worker 太多时，也会停掉一些，这样就提高了性能，也节约了资源。这就是 fastcgi 的对进程的管理。

那 php-fpm 又是什么呢？是一个实现了 fastcgi 的程序，被 PHP 官方收了。

>大家都知道，PHP 的解释器是 php-cgi。php-cgi 只是个 CGI 程序，他自己本身只能解析请求，返回结果，不会进程管理（皇上，臣妾真的做不到啊！）所以就出现了一些能够调度 php-cgi 进程的程序，比如说由 lighthttpd 分离出来的 spawn-fcgi。好了php-fpm 也是这么个东东，在长时间的发展后，逐渐得到了大家的认可（要知道，前几年大家可是抱怨 php-fpm 稳定性太差的），也越来越流行。

网上有的说，fastcgi 是一个协议，php-fpm 实现了这个协议？

>对。

有的说，php-fpm 是 fastcgi 进程的管理器，用来管理 fastcgi 进程的？

>对。php-fpm 的管理对象是 php-cgi。但不能说 php-fpm 是 fastcgi 进程的管理器，因为前面说了 fastcgi 是个协议，似乎没有这么个进程存在，就算存在 php-fpm 也管理不了他（至少目前是）。 有的说，php-fpm 是 php 内核的一个补丁。
>
>以前是对的。因为最开始的时候 php-fpm 没有包含在 PHP 内核里面，要使用这个功能，需要找到与源码版本相同的 php-fpm 对内核打补丁，然后再编译。后来 PHP 内核集成了 php-fpm 之后就方便多了，使用 -- enalbe-fpm 这个编译参数即可。

有的说，修改了 php.ini  配置文件后，没办法平滑重启，所以就诞生了 php-fpm？

>是的，修改 php.ini 之后，php-cgi 进程的确是没办法平滑重启的。php-fpm 对此的处理机制是新的 worker 用新的配置，已经存在的 worker 处理完手上的活就可以歇着了，通过这种机制来平滑过度。

还有的说 php-cgi 是 PHP 自带的 fastcgi 管理器，那这样的话干吗又弄个 php-fpm 出来？

>不对。php-cgi 只是解释 PHP 脚本的程序而已。
