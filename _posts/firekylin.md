---
title: 颜值超高的FireKylin博客系统
date: 2016-12-11 17:57:59
tags:
- 日常
categories:
- 日常
---

相信大多数人都使用着 WordPress，但是又很难从 WordPress 上找到一款比较满意的主题，你是否想过更换其他优秀的开源博客系统呢？我就是这样的经历，但一直也没找到合适的机会，直到一次偶然 Google 到一篇 [技术博客](https://imququ.com)，打开时眼前一亮，简介大气的排版以及很好地支持移动设备特性深深地吸引了我，随即便开始了瞎鼓捣，于是就有了这篇文章。

![预览图](https://img.fanhaobai.com/2016/12/firekylin/7744c13b-59df-4f6c-9515-5feda06b6570.png)<!--more-->

# FireKylin介绍

国外有一个类似的博客系统，名字叫 [Greyshade](https://github.com/shashankmehta/greyshade)，但是作者很长时间没有进行维护了。而国内同样优秀的 [FireKylin](https://github.com/75team/firekylin) 开源博客系统，是由奇虎 360 公司 Web 前端工程师组成的专业团队 [75Team](https://75team.com) 进行开发和维护，所以选 FireKylin 作为本站的博客系统就是很自然的事情了。

FireKylin 是基于 ThinkJS 开发，所以本篇博客也默认你已安装好了 NodeJS。「[CentOS安装NodeJS](https://www.fanhaobai.com/2016/12/nodejs-install.html)」

# 安装前准备

1）首先需要安装 npm「[npm 使用说明](http://www.runoob.com/nodejs/nodejs-npm.html)」

```Bash
$ yum install –y npm
```

2）下载最新的安装包并解压

```Bash
$ wget http://firekylin.org/release/firekylin_0.13.1.tar.gz
$ tar zxvf ./firekylin_0.13.1.tar.gz
```

# 安装FireKylin

## 安装对应依赖

```Bash
$ cd ./firekylin
$ npm install                 #必须在解压缩目录内执行
```

发现是从国外`https://registry.npmjs.org/upyun`地址下载源，而下载速度较慢，故改用国内淘宝的镜像。

```Bash
$ npm install --registry=https://registry.npm.taobao.org
```

## 访问并安装

```Bash
$ npm start
```

通过配置 Nginx 服务器代理来访问`http://127.0.0.1:8360`，根据提示进行安装。

Nginx 配置如下：

```Nginx
server{
  root  path/to/www;    #指向firekylin目录下的www
  location / {
    proxy_http_version 1.1;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-NginX-Proxy true;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass http://127.0.0.1:8360$request_uri;
    proxy_redirect off;
  }
}
```

## 安装PM2

PM2 是用来在服务器上管理 NodeJS 服务的工具，安装较简单。

1） 安装

```Bash
$ npm install -g pm2 --registry=https://registry.npm.taobao.org
```

2） 配置

```Bash
$ mv ./pm2_default.json ./pm2.json
```

将`pm2.json`文件中 **cwd** 配置值改为项目的当前路径。

3）启动

```Bash
$ pm2 start pm2.json
```

4）配置Nginx

Nginx 服务器的配置可以参考项目目录下的`nginx_default.conf`。

# 几个问题

## 增加文章目录

FireKylin 自动为文章生成的目录，总是感觉怪怪的，于是决定改源码，使之变成我想要的样子。

修改的文件路径为`app/admin/controller/api/post.js`。

原代码：

```JS
markedContent = markedContent.replace(/<h(\d)[^<>]*>(.*?)<\/h\1>/g, function (a, b, c) {
    if (b == 2) {
        return '<h' + b + ' id="' + _this2.generateTocName(c) + '">' + c + '</h' + b + '>';
    }
    return '<h' + b + ' id="' + _this2.generateTocName(c) + '"><a class="anchor" href="#' + _this2.generateTocName(c) + '"></a>' + c + '</h' + b + '>';
    });
markedContent = markedContent.replace(/<h(\d)[^<>]*>([^<>]+)<\/h\1>/, function (a, b, c) {
    return a + '<div class="toc">' + tocContent + '</div>';
});
```

修改为：

```JS
markedContent = markedContent.replace(/<h(\d)[^<>]*>(.*?)<\/h\d>/g, function (a, b, c) {
    return '<h' + b + ' id="' + _this2.generateTocName(c) + '">' + c +'</h' + b + '>';
});
markedContent = (tocContent ? ('<div class="toc"><p><strong>文章目录</strong></p>' + tocContent + '</div>'): '') + markedContent
```

这样每次发表文章的时候会自动根据标题生成文章目录，当然还需要在`theme/firekylin/layout.html`中增加如下样式：

```CSS
@media (max-width: 640px)
article .entry-content .toc {
    float: none;
}
article .toc {
    border: 1px solid #e2e2e2;
    font-size: 14px;
    margin: 0 0 15px 20px;
    max-width: 260px;
    min-width: 120px;
    padding: 6px;
    float: right;
}
```

并在`theme/firekylin/layout.html`中的`article blockquote{}`增加一行`display:-webkit-box;`的样式。

## 修改文章摘要

修改的文件路径为`app/admin/controller/api/post.js`。

如下代码：

```JS
data.summary = data.content.split('<!--more-->')[0].replace(/<[>]*>/g, '');
```

后面增加一行：

```JS
if (!(/!\[alt\]/).test(data.summary)) {
    data.summary += '[...]';
}
```

文章摘要不需要文章目录，且在摘要中不含有图片时增加省略符号`[...]`。

## 增加百度分享

由于本站全面启用了 HTPPS，而百度分享还是使用了 HTTP，当接入百度分享后会存在请求不到`share.js`文件的问题，详细的解决办法点 [这里](https://www.hrwhisper.me/baidu-share-not-support-https-solution) 。  

** 需要两个步骤 **   

1） 下载 github 上已经修改完成的 [源码](https://github.com/hrwhisper/baiduShare)，解压并放置在站点服务器静态资源目录下：

```Bash
$ unzip ./baiduShare-master.zip
$ cd ./baiduShare-master
$ mv ./static/* /data/html/www/static      
#网站静态资源路径自行更改，第2步需要使用
```

2）复制百度分享的代码，并对其引用文件路径部分做如下修改：

原代码为：

```JS
.appendChild(createElement('script')).src='http://bdimg.share.baidu.com/static/api/js/share.js?v=89860593.js?cdnversion='+~(-new Date()/36e5)];
```

修改为：

```JS
.appendChild(createElement('script')).src='/static/api/js/share.js?v=89860593.js?cdnversion='+~(-new Date()/36e5)];
```

请确保上面的 static 静态资源文件目录是直接处于网站根目录下，然后复制修改后的代码插入到`theme/firekylin/post.html`中`<p>本文链接：<a href="{{site_url + http.url | safe}}">{{site_url + http.url | safe}}</a></p>`后面即可。

## 多说头像不支持HTTPS

这里利用 Nginx 做一个代理，也就是通过本站服务器将 HTTPS 地址转发到对应的 HTTP 地址，[原文见这里](https://www.janecc.com/duoshuo-https.html) 。

** 需要的步骤 **

1） 配置Nginx作为代理服务器：

```Nginx
server {
  ... ...
  location ~ ^/proxy/(.*)$ {
    proxy_connect_timeout    10s;
    proxy_read_timeout       10s;
    proxy_pass	           http://$1;
    proxy_redirect off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $remote_addr;
    expires max;
  }
  ... ...
}
```

2） 下载多说的`embed.js`到本地，并作如下修改：  

首先，替换`embed.js`文件中头像的路径。

在`return e.avatar_url||rt.data.default_avatar_url`之前插入如下代码：

```JS
if (e.avatar_url) {
    e.avatar_url = (document.location.protocol == "https:") ? e.avatar_url.replace(/^http\:\/\//, "https://yoursite.com/proxy/") : e.avatar_url;
} else {
    rt.data.default_avatar_url = (document.location.protocol == "https:") ? rt.data.default_avatar_url.replace(/^http\:\/\//, "https://yoursite.com/proxy/") : rt.data.default_avatar_url;
}
```

然后，替换`embed.js`文件中表情的路径。

替换`t+=s.message+'</p><div class="ds-comment-footer ds-comment-actions'`中的`s.message`为如下代码：

```JS
((s.message.indexOf("src=\"http:\/\/") == -1) ? s.message : ((document.location.protocol == "https:") ?    
s.message.replace(/src=\"http\:\/\//, "src=\"https://yoursite.com/proxy/") : s.message))
```

**更新 [»]()**

* [本站Nginx配置](https://www.fanhaobai.com/about-site/)<span>（2017-01-16）</span>
