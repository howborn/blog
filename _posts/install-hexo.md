---
title: 启用Hexo开源博客系统
date: 2017-03-01
tags:
- 日常
categories:
- 日常
---

前段时间博客一直使用 FireKylin，总体感觉挺好，但是扩展开发和社区是弱点。而 [Hexo](https://hexo.io/) 最大特点为纯静态博客系统，同时社区支持也比较好， 故我转而投向了 Hexo 的怀抱。

![预览图](https://img.fanhaobai.com/2017/03/install-hexo/11b9814d-885a-4aca-9b56-94c3ad908f3f.png)<!--more-->

![预览图](https://img.fanhaobai.com/2017/03/install-hexo/11b9814d-885a-4aca-9b56-94c3ad908f3f.png)

# 安装

Hexo 如官方介绍一样，安装方便快捷。安装前请确保 Node 和 Nginx 环境已经存在，需要安装可以参考 [CentOS 6 安装 Node]() 和 [Nginx 安装]()。

只需使用如下命令即可安装 Hexo。

```Bash
$ npm install hexo-cli -g
$ hexo init blog
$ cd blog
$ npm install
$ hexo server
```

安装完成后目录结构如下：

```Bash
├── _config.yml             # 主配置文件
├── package.json            # 应用程序的信息
├── scaffolds               # 模版文件夹，新建文章时根据这些模版来生成文章的.md文件
├── source                  # 资源文件夹
|   ├── _drafts
|   └── _posts
└── themes                  # 主题文件夹
```

Hexo 默认启动 4000 端口，使用浏览器访问 [http://localhost:4000](http://localhost:4000)，即可看见 Hexo 美丽的面容。

说明：Nginx  配置站点根目录为`yourblog/public`。

# 使用

关于 Hexo 更详细的使用技巧，[见官网文档](https://hexo.io/zh-cn/docs/)，这里只列举常用的使用方法。

## 更换主题

Hexo 提供的可选 [主题](https://hexo.io/themes/) 比较多，总有一款你如意的，我这里主题选择了 [raytaylorism](https://github.com/raytaylorlin/hexo-theme-raytaylorism)，没有为什么，就是看起来舒服而已，后续相关配置也是基于该主题。

找到喜欢的一款后，使用如下命令安装主题：

```Bash
进入博客目录
$ cd yourblog
克隆主题源码到hexo的themes文件夹下
$ git clone https://github.com/xxx/xxx.git themes/xxx
```

最后一步，在`_config.yml`配置中启用新主题。

```Bash
theme: xxx
```

关于主题的相关配置，参考主题源码中的 README.md 文档。


## 写文章

这里只列举我使用过的方法，更多文章的使用方法，[见这里](https://hexo.io/zh-cn/docs/writing.html)。

1） 新建文章

当需要写文章时，使用如下命令新建文章，会在资源文件夹中生成与 title 对应的 .md 文件。

```Bash
$ hexo new [layout] <title>
```

.md 文件就是 markdown 格式的文章表述。格式大致为：

```Bash
title: Hello World
date: 2013/7/13 20:46:25
---                                      # 分隔符
以下为文章的markdown内容
```

文件最上方以`---`为分隔符，分隔符以上为 Front-matter，用于指定与文章相关的基本信息，分隔符以下才为文章的内容区域。

2） Front-matter

Front-matter 内容如下：

```Bash
layout                 布局
title                  标题
date                   建立日期
updated                更新日期
comments               是否开启文章的评论功能
tags                   标签
categories             分类
permalink              覆盖文章网址
```

其中 title、date、tags、categories 这 4 项，在新建文章时需要进行设置，其他项采用默认值即可，不需要在每篇文章中进行设置，故可以将这 4 项基本设置移到模板文件`scaffolds\post.md`中，如下：

```Bash
---
title: {{ title }}
date: {{ date }}
tags:
categories:
---
```

这样在新建文章时，就会自动在文章 .md 文件中加入 4 项基本设置。

特别说明，文章中添加了分类和标签后， Hexo 会自动生成分类页面和统计分类的文章数。关于分类和标签的使用，如下：

```Bash
categories:           # 分类存在顺序关系
- 语言                 # 1级分类
- PHP                 # 2级分类
- PDO                 # 3级分类    
tags:                 # 标签为无序
- PHP                 # 标签1
- PDO                 # 标签2
```

3） 正文

文章正文使用 markdown 格式即可，我使用的 markdown 编辑器主要有 [Typora — Win版](http://typora.io/) 和 [马克飞象 — 网页版](https://maxiang.io)。

Typora 和 马克飞象 的对比：

* Typora 可以在本地使用相对路径预览文章图片，文章中插入图片方法，[见配置部分]()。
* 马克飞象在线编辑，可以同印象笔记时时同步，但是想预览图片，就必须是线上图片地址。

使用编辑器预览编辑完文章后，导出 .md 文件替换新建文章时生成的同名 .md 文件即可。

编辑完文章后，使用`hexo s`命令即可实时预览到文章效果。

## 发布

文章的新增和编辑都是在资源文件夹下（`source`）操作，完成后需要发布才能生成静态文件（`public`），进而才能通过浏览器直接访问。

发布更新命令如下：

```Bash
$ hexo generate
可以简写
$ hexo g
```

发布后，`public`文件夹更新到最新状态，此时即可直接访问。

说明：`hexo s`并没有产生静态文件，而是实时动态解析实现及时访问。

# 插件

## 搜索

安装 [hexo-generator-search](https://github.com/PaicHyperionDev/hexo-generator-search)，在`_config.yml`中添加如下配置代码：

```Bash
search:
  path: search.xml
  field: all
```

## RSS

安装 [hexo-generator-feed](https://github.com/hexojs/hexo-generator-feed)，并按照说明配置（atom.xml 的链接写在`yourblog/source/_data/link.json`的 social 项中，一般无需更改）

## Sitemap

安装 [hexo-generator-sitemap](https://github.com/hexojs/hexo-generator-sitemap)，并`_config.yml`中添加如下配置代码：

```Bash
sitemap:
  path: sitemap.xml
```

在使用 Hexo 生成器时会自动生成最新的站点地图 [sitemap.xml](/sitemap.xml)文件。

# 配置

更多的配置信息，[见这里](https://hexo.io/zh-cn/docs/configuration.html)。我这里只列举比较重要的配置。

## 打开文章资源文件夹功能

在 Hexo 中，相对路径是针对资源文件夹`source`来讲，所以文章的静态图片应放置于资源文件夹下。

可以将所有文章的静态图片统一放置于`source/images`下，但是这样不方便于管理，推荐方法是将每篇文章的图片放置于与该文章同名的资源文件下，然后使用相对路径引用即可。

在配置文件`_config.yml`中开启`post_asset_folder`项，即更改为：

```Bash
post_asset_folder: true
```

开启该项配置后，Hexo 将会在你每一次通过`hexo new [layout] <title>`命令创建新文章时自动创建一个文件名同 .md 文件的文件夹。将所有与你的文章有关的资源放在这个关联文件夹中之后，就可以通过相对路径来引用它们。

写文章时你只需在 markdown 中插入相对 .md 文件的 **相对路径** 的图片即可， hexo-asset-image 自动转化为网站 **绝对路径**。此时，可以直接使用 Hexo 提供的标签`asset_img`来插入图片，但是这样违背了 markdown 语法，无法及时预览，不便于编辑文章。

可以通过以下 markdown 语法在文章中插入图片，这种方式同时也支持本地 markdown 编辑器实时预览。

```Bash
![alt](/post_title/image_name)
# post_title为与文章.md同名的资源文件夹名
# image_name为图片的文件名
```

## URL静态化

Hexo 默认 URL 地址为`year/month/day/title/`形式，而这种形式并不友好，我将之更改为`year/month/title.html`形式，`_config.yml`配置如下：

```Bash
permalink: :year/:month/:title.html
```

特别说明，当开启了文章资源文件夹功能，将 URL 静态化后，使用 Hexo 生成器时会产生一个 **ENOTDIR** 错误，解决办法见下述的 [自定义修改]() 部分。

## 去除代码块行号

修改`_config.yml`配置项如下：

```Bash
line_number: false
```

# 部署

如果采用本地编辑博客，而博客部署在远程服务器上，那么你就需要部署，才能同步本地更新到远程服务器。

## 官方推荐

Hexo 提供了 5 种部署方案，[见这里](https://hexo.io/zh-cn/docs/deployment.html)，这里只介绍以下 2 种：

1） Git

安装 [hexo-deployer-git](https://github.com/hexojs/hexo-deployer-git)。

`_config.yml`配置如下：

```Bash
deploy:
  type: git
  repo: <repository url>                     # 库地址
  branch: [branch]                           # 分支名称
  message: [message]                         # 提交信息
```

该方案适用于采用 github pages 托管博客的用户，当然使用服务器搭建博客的用户可以使用 webhook 方案来实现。

2） Rsync

安装 [hexo-deployer-rsync](https://github.com/hexojs/hexo-deployer-rsync)。

 `_config.yml`配置如下：

```Bash
deploy:
  type: rsync
  host: <host>                         # 远程主机的地址                       
  user: <user>                         # 使用者名称
  root: <root>                         # 远程主机的根目录
  port: [port]                         # 端口，rsync监听端口
  delete: [true|false]                 # 是否删除远程主机上的旧文件
  verbose: [true|false]                # 显示调试信息
  ignore_errors: [true|false]          # 忽略错误
```

显然，该方案适用于使用服务器搭建博客的用户，但是需要在本地安装 Rsync 客户端（[cwRsync](http://pan.baidu.com/s/1jHTNpVC)）。同时，需要在服务器搭建和配置 Rsync 服务，[见这里]()。

> 我尝试在 Win10 下实现这种方案，但是遇到了很多问题，例如 rsync 服务端采用 SSH 认证方式，但是 cwRsync 使用的 SSH 客户端呆板的从`/home/.ssh`目录查找 SSH 配置和公钥，很悲剧 Win10 下无法识别这个路径，导致无法免密登录 SSH，Rsync 同步也无法进行。

总之，部署的目的，就是将发布生成的静态文件`public`更新到服务器上，如果能实现这个目的，途径倒是无所谓了。

## 我的方案

上述推荐部署方案，明显的缺点是本地需要部署 Hexo 环境，无法实现随时随地的更新博客。为了方便写作，我的部署方案见 [我的博客发布上线方案 — Hexo](https://www.fanhaobai.com/2018/03/hexo-deploy.html)。

# 自定义修改

## 修复ENOTDIR错误

当打开文章资源文件夹功能且 URL 静态化后，使用生成器时会产生一个 **ENOTDIR** 错误，此时需要修改`yourblog/node_modules/hexo/lib/models/post_asset.js`中的部分源码。

将`return pathFn.join(post.path, this.slug);`更改为：

```Js
var path = post.path;
if (path.indexOf('.') != -1) {
    path = path.substr(0, path.lastIndexOf('.'));
}
if (path[path.length - 1] !== '/') {
    path += '/';
}
return pathFn.join(path, this.slug);
```

## 在文章摘要中加入预览图

需修改文件`yourblog/node_modules/hexo/lib/plugins/filter/after_post_render/excerpt.js`，修改内容如下：

```Js
content.replace(rExcerpt, function(match, index) {
   data.excerpt = content.substring(0, index).trim();
   data.more = content.substring(index + match.length).trim();
   data.content = data.excerpt.replace(/<img(.*)>/, '') + data.more;
   return '<a id="more"></a>';
});
```

**说明：**文章摘要预览图不会在文章正文中显示。

## 文章归档按月归档

需修改文件`yourtheme/layout/_partial/archive.ejs`。

将：

```Js
var y = item.date.year();
```

修改为：

```Js
var y = date(item.date, 'YYYY年MM月');
```

修改后，归档如下图：

![](https://img.fanhaobai.com/2017/03/install-hexo/es8bUSE01LiIgQtbSESyEWxW.png)

## 样式修改

1） 去除文字不够一行时居中分散样式
需修改文件`yourtheme/source/css/_partial/article.styl`。

删除以下样式代码：

```Js
text-align justify
```

2） 代码块自动换行

在`yourtheme/source/css/lib/prettify-tomorrow-night-eighties.css`文件中增加如下样式：

```CSS
.line span {
  word-break: break-all;
  word-wrap: break-word;
  white-space: pre-wrap;
}
```

## 多说头像HTTPS代理

由于本站全战采用了 HTTPS，而多说头像依然为 HTTP，故这里通过 Nginx 将 HTTP 代理为 HTTPS。

1） Nginx 增加如下代理配置：

```Bash
server {
   ... ...
   location ~ ^/proxy/(.*)$ {               # proxy为标识
       proxy_connect_timeout    10s;        proxy_read_timeout       10s;
       proxy_read_timeout       10s;
       proxy_pass               http://$1;
       proxy_redirect off;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $remote_addr;
       expires max;
   }
   ... ...
}
```

2） 下载并修改多说embed.js文件

首先，替换 embed.js 文件中头像的路径。在`return e.avatar_url||rt.data.default_avatar_url`之前插入如下代码：

```Js
var site = "https://yoursite/proxy/";
if (e.avatar_url) {
    e.avatar_url = (document.location.protocol == "https:") 
    ? e.avatar_url.replace(/^http\:\/\//, site)
    : e.avatar_url;
} else {
    rt.data.default_avatar_url = (document.location.protocol == "https:")
    ? rt.data.default_avatar_url.replace(/^http\:\/\//, site)
    : rt.data.default_avatar_url;
}
```

最后，替换 embed.js 文件中表情的路径。替换`t+=s.message+'</p><div class="ds-comment-footer ds-comment-actions'`中的`s.message`为如下代码：

```Js
((s.message.indexOf("src=\"http:\/\/") == -1) 
? s.message : ((document.location.protocol == "https:") 
? s.message.replace(/src=\"http\:\/\//, "src=\"https://yoursite/proxy/")
: s.message))
```

3） 修改加载路径

将修改完的 embed.js 文件放置于资源文件夹`/source/js`下，在位置为`yourtheme/layout/_partial/plugin/comment.ejs` 的模板文件中，修改加载 embed.js 文件路径。

将：

```Js
ds.src = (document.location.protocol == 'https:' ? 'https:'
   : 'http:') + '//static.duoshuo.com/embed.js';
```

修改为：

```Js
ds.src = (document.location.protocol == 'https:' ? 'https:'
   : 'http:') + '//www.fanhaobai.com/js/embed.js';
```

## 百度统计

在`yourblog/themes/raytaylorism/layout/_partial/plugin/analytics.ejs`文件中追加如下代码：

```Js
<% if (theme.baidu_analytics){ %>
<script>
(function() {
  var hm = document.createElement("script");
  hm.src = "https://hm.baidu.com/hm.js?<%= theme.baidu_analytics %>";
  var s = document.getElementsByTagName("script")[0];
  s.parentNode.insertBefore(hm, s);
})();
</script>
<% } %>
```

并在配置文件`_config.yml`中，加入如下配置信息：

```Js
# 百度分析Uid，若为空则不启用
baidu_analytics: 9f0ecfa73797e6a907d8ea6a285df6a5
```

## 百度分享

由于百度分享也不支持 HTTPS 站点，但是 [hrwhisper](https://github.com/hrwhisper) 已经在 Github 上提供了解决办法，[见这里](https://github.com/hrwhisper/baiduShare)。

1） 下载源码

从 [Github](https://codeload.github.com/hrwhisper/baiduShare/zip/master) 直接下载源码，解压缩后放置于资源文件夹`source`中，因为 Hexo 会压缩 Js 文件，可能会导致 share.js 会报错，可以通过配置`_config.yml`解决。

```Js
skip_render:
  - "static/**"
```

2） 添加加载

从百度分享获取分享代码，插入主题模板文件`yourtheme/layout/_partial/article.ejs`中。

将分享 HTML 代码插入如下位置：

```Html
<div class="card-content">               # 追加到这个div中
  ... ...
  <div style="height:15px;"></div>
  <div class="bdsharebuttonbox">
    <a href="" class="bds_more" data-cmd="more"></a>
    <a href="" class="bds_qzone" data-cmd="qzone" title="分享到QQ空间"></a>
    <a href="" class="bds_tsina" data-cmd="tsina" title="分享到新浪微博"></a>
    <a href="" class="bds_tqq" data-cmd="tqq" title="分享到腾讯微博"></a>
    <a href="" class="bds_renren" data-cmd="renren" title="分享到人人网"></a>
    <a href="" class="bds_weixin" data-cmd="weixin" title="分享到微信"></a>
  </div>
</div>
```


最后，注意将引用 share.js 的 **路径** 替换为自己的站点路径。

```Js
appendChild(createElement('script')).src='https://www.fanhaobai.com
/static/api/js/share.js?v=89860593.js?cdnversion='+~(-new Date()/36e5)
```

## 百度主动推送

为了更好的收录本站文章，这里引进了百度 [主动推送功能](http://zhanzhang.baidu.com/college/courseinfo?id=267&page=2)，只需添加如下 JS代码，每当文章被浏览时都会自动向百度提交链接，这种方式以用户为驱动，较为方便和实用。

在主题模板文件`yourthemes/layout/_partial/article.ejs`中，插入以下代码：

```Js
<script>
(function () {
    var bp = document.createElement('script');
    var curProtocol = window.location.protocol.split(':')[0];
    if (curProtocol === 'https') {
        bp.src = 'https://zz.bdstatic.com/linksubmit/push.js'
    } else {
        bp.src = 'http://push.zhanzhang.baidu.com/push.js'
    }
    var s = document.getElementsByTagName("script")[0];
    s.parentNode.insertBefore(bp, s)
})();
</script>
```

到这里，也终于算是搭建结束了。至于 404 页面打算采用 [腾讯的公益404页面](http://www.qq.com/404/) 来做，[见这里](https://www.fanhaobai.com/404.html)。

<strong>相关文章 [»]()</strong>

* [我的博客发布上线方案 — Hexo](https://www.fanhaobai.com/2018/03/hexo-deploy.html)<span>（2018-03-03）</span>