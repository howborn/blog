---
title: 如何向搜索引擎提交链接
date: 2017-01-17 22:51:23
tags:
- 日常
categories:
- 日常
---

> 文档：http://zhanzhang.baidu.com/college/courseinfo?id=267&page=2

由于本站博客文章数收录情况，相比下谷歌比百度好，而原因是谷歌的抓取频率较百度高，所以这里采取了向搜索引擎主动提交本站新产生链接的办法，增加搜索引擎对本站链接的收录量。
![](https://img3.fanhaobai.com/2017/01/push-links/sZTgr9Q8To0jF44eBUP43Ux5.png)<!--more-->

下面记录了本站向搜索引擎提交链接的整个过程。部署后，查看谷歌对本站的 **抓取统计情况**，可知谷歌对本站链接的抓取处于 **正常状态** 。

![](https://img4.fanhaobai.com/2017/01/push-links/H3MLaW62k4BDaqThyncU8WpY.png)

# 提交方式

搜索引擎一般都会提供 **2种** 提交链接的方式，已满足站长的不同需求。

## 自动推送

该方式在对新产出的链接对搜索引擎收录具有较高的实时性时使用，搜索引擎能够及时发现新产出的链接，并使得链接第一时间被收录。

这里使用百度的 [自动推送](http://zhanzhang.baidu.com/college/courseinfo?id=267&page=2) 来说明。百度的自动推送方式又可分为 **2** 种：

1） **使用推送接口**

推送接口地址为：`http://data.zz.baidu.com/urls?site=www.yoursite.com&token=yourtoken`。该方式可以一次提交多个链接地址，但是需要服务器端通过某种机制触发推送。

使用 PHP 语言的推送如下：

```PHP
$urls = array(
    'https://www.fanhaobai.com/post/push-links.html',
    'https://www.fanhaobai.com/post/update-sitemap.html',
);
$api = 'http://data.zz.baidu.com/urls?site=www.fanhaobai.com&token=rctEsv2vzZhP1dnE';
$ch = curl_init();
$options =  array(
    CURLOPT_URL => $api,
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POSTFIELDS => implode("\n", $urls),
    CURLOPT_HTTPHEADER => array('Content-Type: text/plain'),
);
curl_setopt_array($ch, $options);
$result = curl_exec($ch);
echo $result;
```

2） **使用JS推送**

使用 JS 推送代码是百度站长平台为提高站点新增网页发现速度而推出，安装自动推送 JS 代码的网页，在页面被访问时，页面 URL 将立即被推送给百度。

只需将下述 JS 代码插入到需要推送的网页即可，该方式是 [**通过用户行为为驱动，不需要服务端参与推送过程**](#)。

```JS
<script>
(function(){
    var bp = document.createElement('script');
    var curProtocol = window.location.protocol.split(':')[0];
    if (curProtocol === 'https') {
        bp.src = 'https://zz.bdstatic.com/linksubmit/push.js';        
    }
    else {
        bp.src = 'http://push.zhanzhang.baidu.com/push.js';
    }
    var s = document.getElementsByTagName("script")[0];
    s.parentNode.insertBefore(bp, s);
})();
</script>
```

**本站** 对于新产出链接收录的实时性要求并不高，所以 **采取了更加便捷的JS推送方式** 。

## 站点地图

站点地图分为 [HTML格式](#) 和 [XML格式](http://www.fanhaobai.com/sitemap.xml)，如何实现自动更新站点地图的部署，[点这里查看](https://www.fanhaobai.com/2017/01/update-sitemap.html)，站点地图的地址从 robots.txt 文件中指出。

这里使用谷歌和百度两大搜索引擎来说明。

1） **谷歌**

谷歌的站点地图提交地址，[见这里](https://www.google.com/webmasters/tools/sitemap-list?hl=zh-CN) 。只需点击`添加测试站点地图`按钮即可，操作较为简单，提交成功后如下图所示：

![](https://img5.fanhaobai.com/2017/01/push-links/uJB4Wv8GViZLhZKn5gUY587W.png)

2） **百度**

百度的站点地图提交地址，[见这里](http://zhanzhang.baidu.com/linksubmit/index)。只需在该页面选中`自动提交`并选择`sitemap`，出现如下图所示，填写完毕提交即可。

![](https://img0.fanhaobai.com/2017/01/push-links/MxLZN0EoqTT42hFffpy2yLD-.png)

提交成功后，如下图所示：

![](https://img1.fanhaobai.com/2017/01/push-links/4phD1vo4GCBNNsJBFmcpshgp.png)

需要说明，[**当已经从站点地图提交地址提交一次站点地图后，搜索引擎会根据提交的站点地图地址，自动定期检测站点地图是否更新，不需要再次手动提交更新后的站点地图**](#)。

# 部署建议

**自动推送** 和 **站点地图** 提交方式我们都应该部署，[**因为自动推送是实时提交新产出的链接，而站点地图是搜索引擎爬取站点时的导向地图，此时可以批量提交新产出的链接，它们之间并不冲突，一起使用链接提交效果更好**](#)。

<strong>相关文章 [»](#)</strong>

* [自动更新站点地图的部署](https://www.fanhaobai.com/2017/01/update-sitemap.html) <span>（2017-01-16）</span>
* [Robots协议的那些事](https://www.fanhaobai.com/2017/01/robots.html) <span>（2017-01-12）</span>
