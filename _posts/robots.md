---
title: Robots协议的那些事
date: 2017-01-12 12:33:20
tags:
- SEO
categories:
- SEO
---

由于本站文章搜索引擎搜索机器人（以下简称：爬虫）爬取效果不是很理想，出现了导航链接大量被爬取，而文章链接爬取较少。所以准备对本站加入 SEO，其实也就是引入了 [Robots协议](http://baike.baidu.com/link?url=2cB03FvdeTNWMUFlQEQxT4E6FxQ7DGXQr7Q6tAt702pNePMjVODT4Sj1vxp9W5ehdG9QP6dUZBrsiIJNYphnkPz6M9D8nHmbo7sdLNEydcg7QVqgnu4LUIGKTg5v-3ii0JqcHLrvxcBzN1UNBBH3fWBWmVlh3Jh0kSpoybswT7_) 。Robots 协议（也称为爬虫协议、机器人协议等）的全称是「[网络爬虫排除标准](http://baike.baidu.com/link?url=qZmXuLBjgnHeD9Q-gV4Rg1QAZOF04_MbuFOQRLaA_jZqIBgqVkbtVA-8YAzHo3mFwtrL2l0vrfmgw97OlU2R36hMv0KGgRTFOnl2lonhJ7J4Uspy3WCTiGCtpGK65BCc)」（Robots Exclusion Protocol）。网站通过 Robots 协议告诉搜索引擎哪些页面可以抓取，哪些页面不能抓取，而 **robots.txt 文本文件** 就是 Robots 协议的表述。

{% asset_img n9DQpbXNbazisDMy_bouP7HN.png %}<!--more-->

Robots 协议代表了互联网领域的一种契约精神，互联网企业只有遵守这一规则，才能保证网站及用户的隐私数据不被侵犯，违背 Robots 协议将带来巨大安全隐忧——例如，[百度诉奇虎360违反“Robots协议”抓取、复制其网站内容侵权一案](http://tech.ifeng.com/internet/special/baidupk360/content-1/detail_2012_08/29/17183239_0.shtml)。

# 爬取过程

互联网的网页都是通过超链接互相关联的，进而形成了网页的网状结构。所以爬虫的工作方法就如蜘蛛在网络上沿着超链接按照一定的爬取规则爬取网页。

{% asset_img FozbmxH8U0MTs0N-teFaCtWa.jpg %}

基本流程大致为：

1） 喂给爬虫一堆 URL，称之为 **种子**（Seeds）；
2） 爬虫爬取 Seeds，**分析** HTML 网页，抽取其中的 **超链接**；
3） 爬虫接着爬取这些 **新发现** 的超链接指向的 HTML 网页；
4） 对过程 2），3）**循环往复**；

# 协议作用

Robots协议 **主要功能** 为以下 4 项：

1） 网站通过该协议告诉搜索引擎哪些页面可以抓取，哪些页面不能；
2） 可以屏蔽一些网站中比较大的文件，如：图片，音乐，视频等，节省服务器带宽；
3） 可以屏蔽站点的一些死链接，方便搜索引擎抓取网站内容；
4） 设置网站地图导向，方便引导蜘蛛爬取页面；

可以想象，如果一个站点没有引入 Robots 协议，那么爬虫就会漫无目地爬取，爬取结果一般不尽人意。反之，将我们站点内容通过 Robots 协议表述出来并引入 Robots 协议，爬虫就会按照我们的意愿进行爬取。


# 协议原则

Robots 协议是国际互联网界通行的 **道德规范**，基于以下 ** 原则** 建立：

1） 搜索技术应服务于人类，同时尊重信息提供者的意愿，并维护其隐私权；
2） 网站有义务保护其使用者的个人信息和隐私不被侵犯；

#  协议表述

Robots 协议是通过 robots.txt 文件来进行表述的，[robots.txt文件规范见这里](http://www.robotstxt.org/robotstxt.html) 。robots.txt 文件是一个 **文本文件**，使用任何一个常见的文本编辑器都可以对它进行查看与编辑。当然，也可以使用 [Robots 文件生成工具](http://tool.chinaz.com/robots) 方便地生成我们所需要的 robots.txt 文件。

提示： robots.txt 文件应该放置在网站根目录下。

## 协议表述规范

对规范大致描述为：

```Bash
User-agent: *                           # *代表所有的搜索引擎种类，是一个通配符，其他常用值：百度-Baiduspider，搜狗-sogou spider，谷歌-Googlebot
Disallow: /admin/                       # 禁止抓取admin目录下面的目录
Disallow: /require/                     # 禁止抓取require目录下面的目录
Disallow: /static/                      # 禁止抓取static目录下面的目录
Disallow: /cgi-bin/*.htm                # 禁止抓取/cgi-bin/目录下的所有以".htm"为后缀的URL(包含子目录)。
Disallow: /*?*                          # 禁止抓取网站中所有包含问号 (?) 的网址
Disallow: /.jpg$                        # 禁止抓取网站中所有的.jpg格式的图片
Disallow: /public/404.html              # 禁止爬取public文件夹下面的404.htm文件。
Allow: /home/　                         # 允许抓取home目录下面的目录
Allow: /home                            # 允许抓取home的整个目录
Allow: .htm$                            # 允许抓取以".htm"为后缀的URL。
Allow: .gif$                            # 允许抓取gif格式图片
Sitemap: http://你的网址/map.xml          # 建议加入xml格式的文件,这个是谷歌标准格式
Sitemap: http://你的网址/map.html         # 建议加入html格式的文件,这个是百度标准格式
```

一般情况下不需要指定 Allow 这项配置。

## 网站地图规范

* **XML格式**

这里参照了百度站长的 [官方文档](http://zhanzhang.baidu.com/college/courseinfo?id=267&page=2#h2_article_title3)，大致描述如下：

```PHP
<?xml version="1.0" encoding="utf-8"?>
<!-- XML文件需以utf-8编码-->
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<!--必填标签-->
    <url>
        <!--必填标签,这是具体某一个链接的定义入口，每一条数据都要用<url>和</url>包含在里面，这是必须的 -->
        <loc>http://www.yoursite.com/yoursite.html</loc>
        <!--必填,URL链接地址,长度不得超过256字节-->
        <lastmod>2009-12-14</lastmod>
        <!--可以不提交该标签,用来指定该链接的最后更新时间-->
        <changefreq>daily</changefreq>
        <!--可以不提交该标签,用这个标签告诉此链接可能会出现的更新频率 -->
        <priority>0.8</priority>
        <!--可以不提交该标签,用来指定此链接相对于其他链接的优先权比值，此值定于0.0-1.0之间-->
    </url>
</urlset>
```

* **HTML格式**

主体结构为完整的 HTML，将需要被爬的链接以`<a></>`标签的形式加入到`body`中即可。

```HTML
... ...
<body>
    <a href="https://www.fanhaobai.com" title="首页">
    <a href="https://www.fanhaobai.com/xxx/robots.html" title="Robots协议的那些事">
    ... ...
</body>
... ...
```

## 本站配置

* ** 本站博客 **

本站拒绝了雅虎爬虫的爬取，对其他的爬虫，theme、static 目录下的 2 个逻辑代码目录 api、module 和 4 个静态资源目录 font、css、img、js 做了限制爬取，对 static 目录下 upload 做了允许爬取处理，并配置了后缀为`.xml`和`.htm`文件的站点地图。

```Bash
# robots.txt for fanhaobai.com 2017.01.12
# yahoo disallow
User-agent: Slurp
Disallow: /
# other allow
User-agent: *
Disallow: /admin
Disallow: /theme/
Disallow: /static/api/
Disallow: /static/module/
Disallow: /static/font/
Disallow: /static/css/
Disallow: /static/img/
Disallow: /static/js/
Sitemap: http://www.fanhaobai.com/map.xml
Sitemap: http://www.fanhaobai.com/map.html
```

查看本站的 **网站地图**，[HTML格式]() 和 [XML格式](https://www.fanhaobai.com/sitemap.xml) 。

* ** 本站维基 **

```Bash
User-agent: *
Disallow: /
```

# 提交文件

一般情况下，站点根目录下加入了 robots.txt 文件后，各种搜索引擎的爬虫就会自动爬取该文件。尽管如此，还是建议手动将 robots.txt 文件提交到搜索引擎，同时也能帮助检测 robots.txt 文件是否存在错误。

本站手动将 robots.txt 提交到谷歌和百度两个搜索引擎：

1） [谷歌测试工具](https://www.google.com/webmasters/tools/robots-testing-tool?hl=zh-CN)

{% asset_img 5PCU9neptZdG3aY5veYsls0v.png %}

2） [百度测试工具](http://zhanzhang.baidu.com/robots/index)

{% asset_img xWjjcJzJrrhkjH6lWy7aZib_.png %}

按照对应提示操作即可，出现上图情况则表示 robots.txt 手动提交成功。

# 总结

Robots 协议只是爬虫抓取站点内容的一种规则，需要搜索引擎爬虫的配合才行，并不是每个搜索引擎爬虫都遵守的。但是，目前看来，绝大多数的搜索引擎爬虫都遵守 Robots 协议的规则。

值得注意的是，robots.txt 文件虽说是提供给爬虫使用，但是正如它的名称——网络爬虫排除标准，它具有消极的排爬虫抓取作用。所以百度官方建议，** [仅当网站包含不希望被搜索引擎收录的内容时，才需要使用 robots.txt 文件。如果您希望搜索引擎收录网站上所有内容，请勿建立robots.txt 文件]() **。

<strong>相关文章 [»]()</strong>

* [如何向搜索引擎提交链接](https://www.fanhaobai.com/2017/01/push-links.html) <span>（2017-01-17）</span>
* [自动更新站点地图的部署](https://www.fanhaobai.com/2017/01/update-sitemap.html) <span>（2017-01-16）</span>

> 推荐一篇相关文章：http://lusongsong.com/reed/732.html。