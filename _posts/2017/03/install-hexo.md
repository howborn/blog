---
title: 启用Hexo开源博客系统
date: 2017-03-01
tags:
- 日常
categories:
- 日常
---

前段时间博客一直使用 FireKylin，总体感觉挺好，但是扩展开发和社区是弱点。而 [Hexo](https://hexo.io/) 最大特点为纯静态博客系统，同时社区支持也比较好， 故我转而投向了 Hexo 的怀抱。

![预览图](https://img5.fanhaobai.com/2017/03/install-hexo/11b9814d-885a-4aca-9b56-94c3ad908f3f.png)<!--more-->

![预览图](https://img0.fanhaobai.com/2017/03/install-hexo/11b9814d-885a-4aca-9b56-94c3ad908f3f.png)

# 安装

Hexo 如官方介绍一样，安装方便快捷。安装前请确保 Node 和 Nginx 环境已经存在，需要安装可以参考 [CentOS 6 安装 Node]() 和 [Nginx 安装]()。

只需使用如下命令即可安装 Hexo。

```Shell
$ npm install hexo-cli -g
$ hexo init blog
$ cd blog
$ npm install
$ hexo server
```

安装完成后目录结构如下：

```Shell
├── _config.yml             # 主配置文件
├── package.json            # 应用程序的信息
├── scaffolds               # 模版文件夹，新建文章时根据这些模版来生成文章的.md文件
├── source                  # 资源文件夹
|   ├── _drafts
|   └── _posts
└── themes                  # 主题文件夹
```

Hexo 默认启动 4000 端口，使用浏览器访问 [http://localhost:4000](http://localhost:4000)，即可看见 Hexo 美丽的面容。

说明：Nginx 配置站点根目录为`public`。

# 使用

关于 Hexo 更详细的使用技巧，[见官网文档](https://hexo.io/zh-cn/docs/)，这里只列举常用的使用方法。

## 更换主题

Hexo 提供的可选 [主题](https://hexo.io/themes/) 比较多，总有一款你如意的，我这里主题选择了 [hexo-theme-yilia](https://github.com/fan-haobai/hexo-theme-yilia)，没有为什么，就是看起来舒服而已，后续相关配置也是基于该主题。

找到喜欢的一款后，使用如下命令安装主题：

```Shell
# 进入博客目录
$ cd yourblog
# 克隆主题源码到hexo的themes文件夹下
$ git clone https://github.com/fan-haobai/hexo-theme-yilia.git themes/hexo-theme-yilia
```

最后一步，在`_config.yml`配置中启用新主题。

```Shell
theme: hexo-theme-yilia
```

关于主题的相关配置，参考主题源码中的 README.md 文档。

> [hexo-theme-yilia](https://www.fanhaobai.com) 主题我做了较多的修改，如果你觉得我的修改也适合你，那么你只要 [pull](https://github.com/fan-haobai/hexo-theme-yilia) 下来即可，而不需要再做 [自定义修改](#自定义修改——非必须) 部分的修改。

## 写文章

这里只列举我使用过的方法，更多文章的使用方法，[见这里](https://hexo.io/zh-cn/docs/writing.html)。

1） 新建文章

当需要写文章时，使用如下命令新建文章，会在资源文件夹中生成与 title 对应的 md 文件。

```Shell
$ hexo new [layout] <title>
```

md 文件就是 Markdown 格式的文章表述。格式大致为：

```Shell
title: Hello World
date: 2013/7/13 20:46:25
---                                      # 分隔符
# 以下为文章的Markdown内容
```

文件最上方以`---`为分隔符，分隔符以上为 Front-matter，用于指定与文章相关的基本信息，分隔符以下才为文章的内容区域。

2） Front-matter

Front-matter 内容如下：

```Shell
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

```Shell
---
title: {{ title }}
date: {{ date }}
tags:
categories:
---
```

这样在新建文章时，就会自动在文章 md 文件中加入 4 项基本设置。

特别说明，文章中添加了分类和标签后， Hexo 会自动生成分类页面和统计分类的文章数。关于分类和标签的使用，如下：

```Shell
categories:           # 分类存在顺序关系
- 语言                 # 1级分类
- PHP                 # 2级分类
- PDO                 # 3级分类    
tags:                 # 标签为无序
- PHP                 # 标签1
- PDO                 # 标签2
```

3） 正文

文章正文使用 Markdown 格式即可，我使用的 Markdown 编辑器主要有 [Typora — Win版](http://typora.io/) 和 [马克飞象 — 网页版](https://maxiang.io)。

Typora 和 马克飞象 的对比：

* Typora 可以在本地使用相对路径预览文章图片，文章中插入图片方法，[见配置部分]()。
* 马克飞象在线编辑，可以同印象笔记时时同步，但是想预览图片，就必须是线上图片地址。

使用编辑器预览编辑完文章后，导出 md 文件替换新建文章时生成的同名 md 文件即可。

编辑完文章后，使用`hexo s`命令即可实时预览到文章效果。

## 发布

文章的新增和编辑都是在资源文件夹下（`source`）操作，完成后需要发布才能生成静态文件（`public`），进而才能通过浏览器直接访问。

发布更新命令如下：

```Shell
$ hexo generate
# 可以简写为
$ hexo g
```

发布后，`public`文件夹更新到最新状态，此时即可直接访问。

# 插件

## 搜索

安装 [hexo-generator-search](https://github.com/PaicHyperionDev/hexo-generator-search)，在`_config.yml`中添加如下配置代码：

```YAML
search:
  path: search.xml
  field: all
```

## RSS

安装 [hexo-generator-feed](https://github.com/hexojs/hexo-generator-feed)，并按照说明配置（atom.xml 的链接写在`source/_data/link.json`的 social 项中，一般无需更改）

## jsonContent

安装 [hexo-generator-json-content](https://github.com/alexbruno/hexo-generator-json-content)，即可生成所有文章的 json 描述。需在`_config.yml`中添加如下配置代码：

```YAML
jsonContent:
  meta: false
  pages: false
  posts:
    title: true
    date: true
    path: true
    text: false
    raw: false
    content: false
    slug: false
    updated: false
    comments: false
    link: false
    permalink: false
    excerpt: false
    categories: false
    tags: true
```

## Sitemap

安装 [hexo-generator-sitemap](https://github.com/hexojs/hexo-generator-sitemap)，并在`_config.yml`中添加如下配置代码：

```YAML
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

```YAML
post_asset_folder: true
```

开启该项配置后，Hexo 将会在你每一次通过`hexo new [layout] <title>`命令创建新文章时自动创建一个文件名同 md 文件的文件夹。将所有与你的文章有关的资源放在这个关联文件夹中之后，就可以通过相对路径来引用它们。

写文章时你只需在 Markdown 中插入相对 md 文件的 **相对路径** 的图片即可，[hexo-asset-image]() 自动转化为网站 **绝对路径**。此时，可以直接使用 Hexo 提供的标签`asset_img`来插入图片，但是这样违背了 Markdown 语法，无法及时预览，不便于编辑文章。

可以通过以下 Markdown 语法在文章中插入图片，这种方式同时也支持本地 Markdown 编辑器实时预览。

```Shell
![alt](/post_title/image_name)
# post_title为与文章.md同名的资源文件夹名
# image_name为图片的文件名
```

## URL静态化

Hexo 默认 URL 地址为`year/month/day/title/`形式，而这种形式并不友好，需更改为`year/month/title.html`形式。这里我已经将`source`目录下的 md 文件按`year/month`手动归档了，所以 Hexo 发布时只需要`title.html`这部分。配置如下：

```YAML
permalink: title.html
```

## 去除代码块行号

修改`_config.yml`配置项如下：

```YAML
highlight:
  line_number: false
```

# 部署

如果采用本地编辑博客，博客部署在远程服务器上，那么你就需要部署，才能同步本地更新到远程服务器。

## 官方推荐

Hexo 提供了 5 种部署方案，[见这里](https://hexo.io/zh-cn/docs/deployment.html)，这里只介绍以下 2 种：

1） Git

安装 [hexo-deployer-git](https://github.com/hexojs/hexo-deployer-git)。

`_config.yml`配置如下：

```YAML
deploy:
  type: git
  repo: <repository url>                     # 库地址
  branch: [branch]                           # 分支名称
  message: [message]                         # 提交信息
```

该方案适用于采用 Github Pages 托管博客的用户，当然使用服务器搭建博客的用户可以使用 Webhook 方案来实现。

2） Rsync

安装 [hexo-deployer-rsync](https://github.com/hexojs/hexo-deployer-rsync)。

 `_config.yml`配置如下：

```YAML
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

# 自定义修改——非必须

## 在文章摘要中加入预览图

需修改文件`node_modules/hexo/lib/plugins/filter/after_post_render/excerpt.js`，内容修改为如下：

```Js
// 此处有更改
content.replace(rExcerpt, function(match, index) {
   data.excerpt = content.substring(0, index).trim();
   data.more = content.substring(index + match.length).trim();
   // 去掉img标签
   data.content = data.excerpt.replace(/<img(.*)>/, '') + data.more;
   return '<a id="more"></a>';
});
```

**说明：**文章摘要预览图不会在文章正文中显示。

## 更好地支持Shell代码高亮

由于 [highlight.js]() 对 Shell 语法高亮解析效果并不理想，为此我对 [languages/shell.js](https://github.com/fan-haobai/highlight.js/blob/master/src/languages/shell.js) 部分做了修改来更好地支持 Shell，你只需要 [pull](https://github.com/fan-haobai/highlight.js) 并替换掉原 [languages/shell.js]() 文件即可。

```Shell
$ git clone https://github.com/fan-haobai/highlight.js.git
$ cp highlight.js/src/languages/shell.js node_modules/highlight.js/lib/languages/shell.js
```

并将 [shell.js]() 中的如下部分：

```Js
function(hljs)
```

修改为：

```Js
module.exports = function(hljs)
```

## 评论

由于后来多说的关站，就再也找不到合适的第三方评论服务了。换来换去，最后还是觉得只有 [Disqus](https://disqus.com) 合适，但是需要先解决被墙的问题，不过 [fooleap](https://github.com/fooleap) 已经提供了一个较好的解决方案—— [disqus-php-api](https://github.com/fooleap/disqus-php-ap)。你只需要 [pull](https://github.com/fan-haobai/disqus-php-api) 代码到境外服务器，部署一个 PHP 服务即可。

我部署后域名为 [disqus.fanhaobai.com](https://disqus.fanhaobai.com)。首先在`layout/_partial/article.ejs`文件中追加以下内容：

```Js
<% if (!index && post.comments){ %>
  <% if (theme.disqus || theme.disqus.shortname){ %>
  <%- partial('post/disqus', {
      title: post.title,
      url: config.url+url_for(post.path)
    }) %>
  <% } %>
<% } %>
```

然后，在`layout/_partial/post`目录下创建`disqus.ejs`文件，内容如下：

```Js
<div id="disqus_thread"></div>
<link rel="stylesheet" href="/disqus.css">
<script src="/disqus.js"></script>
<script>
  (function () {
    var disqus = new iDisqus('disqus_thread', {
      forum: '<%= theme.disqus.shortname %>',
      site: '<%= config.url %>',
      api: '<%= theme.disqus.api %>',
      url: '<%= url %>',
      mode: 2,
      timeout: 3000,
      init: true,
      autoCreate: true,
      relatedType: false
    });
    disqus.count();
  })();
</script>
```

最后，在`_config.yml`增加如下配置：

```YAML
disqus:
  shortname: 'fanhaobai'
  api: '//disqus.fanhaobai.com'
```

> 有关 Disqus 更详细的配置，见 [Disqus 设置](https://github.com/fan-haobai/disqus-php-api#disqus-%E8%AE%BE%E7%BD%AE) 部分。

## 百度统计

首先，在`layout/_partial/after-footer.ejs`文件中追加如下代码：

```Js
<%- partial('baidu-analytics') %>
```

并在`layout/_partial`目录下创建`baidu-analytics.ejs`文件，内容为：

```Js
<% if (theme.baidu_analytics){ %>
<script>
var _hmt = _hmt || [];
(function() {
  var hm = document.createElement("script");
  hm.src = "https://hm.baidu.com/hm.js?<%= theme.baidu_analytics %>";
  var s = document.getElementsByTagName("script")[0]; 
  s.parentNode.insertBefore(hm, s);
})();
</script>
<% } %>
```

然后，在配置文件`_config.yml`中，增加如下配置信息：

```Js
# 百度分析Uid，若为空则不启用
baidu_analytics: 9f0ecfa73797e6a907d8ea6a285df6a5
```

## 百度主动推送

为了更好的收录本站文章，这里引进了百度 [主动推送功能](http://zhanzhang.baidu.com/college/courseinfo?id=267&page=2)，只需添加如下 JS代码，每当文章被浏览时都会自动向百度提交链接，这种方式以用户为驱动，较为方便和实用。

在主题模板文件`layout/_partial/article.ejs`中，追加以下代码：

```Js
<% if (!index){ %>
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
<% } %>
```

到这里，也终于算是搭建结束了。至于 404 页面打算采用 [腾讯的公益404页面](http://www.qq.com/404/) 来做，[见这里](https://www.fanhaobai.com/404.html)。

<strong>更新 [»]()</strong>

* [主题更换为 hexo-theme-yilia](https://github.com/fan-haobai/hexo-theme-yilia)<span>（2017-10-30）</span>
* [自定义分享](#)<span>（2017-11-28）</span>
* [去除百度统计](#)<span>（2018-07-04）</span>
* [科学使用 Disqus](#评论)<span>（2018-07-04）</span>
* [更好地支持 Shell 代码高亮](#更好地支持Shell代码高亮)<span>（2018-09-09）</span>

<strong>相关文章 [»]()</strong>

* [我的博客发布上线方案 — Hexo](https://www.fanhaobai.com/2018/03/hexo-deploy.html)<span>（2018-03-03）</span>
