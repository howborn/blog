---
title: curl时设置Expect的必要性
date: 2017-08-06 09:33:32
tags:
- TCP/IP
categories:
- 语言
- PHP
---

curl 在项目中使用频率较高，比如内部接口、第三方 api、图片存储服务等，但是我们在使用 curl 时可能并没有注意到 Expect 这个请求头信息，而 Expect 设置不正确，会导致不必要的一次 HTTP 请求，甚至可能会导致业务逻辑错误。
{% asset_img d6ab643f-3c28-4721-a362-1e9133c6bc14.png %}<!--more-->

## 问题

在不设置 **Expect** 头信息使用 curl 发送 POST 请求时，如果 POST 数据大于 **1kb**，curl [默认行为](http://www.w3.org/Protocols/rfc2616/rfc2616-sec8.html#sec8.2.3) 如下：

1. 先追加一个`Expect: 100-continue`请求头信息，发送这个不包含 POST 数据的请求；
2. 如果服务器返回的响应头信息中包含`Expect: 100-continue`，则表示 Server 愿意接受数据，这时才 POST 真正数据给 Server；

通过 [tcpdump](http://www.cnblogs.com/ggjucheng/archive/2012/01/14/2322659.html) 工具抓包 curl 客户端网络请求。查看 HTTP 请求响应头以及数据：

```Bash
$ tcpdump -A -s 0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'
```

请求信息内容：

```HTTP
23:04:15.498902 IP bogon.35808 > 10.16.**.***.http: Flags [P.], seq 1749154338:1749154696, ack 673671676, win 14600, length 358
E.....@.@.8...U.
......PhA."('i.P.9.]Q..POST /* HTTP/1.1
User-Agent: GuzzleHttp/6.2.1 curl/7.19.7
Content-Type: application/json
Host: *.t.ziroom.com
Content-Length: 24343
Expect: 100-continue
```

响应信息：

```HTTP
23:04:15.499869 IP 10.16.**.***.http > bogon.35808: Flags [P.], seq 1:26, ack 358, win 64240, length 25
E..A......2.
.....U..P..('i.hA..P.......HTTP/1.1 100 Continue
```

可见此时，curl 发送了一次不必要的 HTTP 请求，从系统性能上来说这是不允许的。另外，并不是所有的 Server 都会正确响应`100-continue`，反而会返回`417 Expectation Failed`，curl 端不会发起数据 POST 请求，则会造成业务逻辑错误，我们应该避免这种情况的发生。

## 解决办法

如果查看过一些开源类库（guzzle、qq第三方api，不过 [solarium](https://github.com/solariumphp/solarium) 并未支持），你就会发现他们在 curl 时已经注意到并解决这个问题了，只需 [设置 Expect 请求头为空]() 即可。

```PHP
// qq第三方api
curl_setopt($ch, CURLOPT_HTTPHEADER, array('Expect:'));

// guzzle的curl Adapter
if (!$request->hasHeader('Expect')) {
    $conf[CURLOPT_HTTPHEADER][] = 'Expect:';
}
```

再次 tcpdump 抓包，发现使用 curl 发送超过 1kb 的 POST 数据时，也并未出现 100-continue 的 HTTP 请求。
