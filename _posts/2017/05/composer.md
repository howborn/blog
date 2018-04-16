---
title: Composer安装和使用
date: 2017-05-03 22:50:49
tags:
- 工具
categories:
- 工具
---

[Composer](https://getcomposer.org/) 是一个 PHP 依赖包管理工具，我们通过在 composer.json 配置中申明项目依赖后，它会自动在的项目中安装完成项目所需依赖。一些常用的项目依赖包列表，[见这里](https://packagist.org/)。

![](https://img.fanhaobai.com/2017/05/composer/bb8a-6ddaa3977.png)<!--more-->

## 安装

### 下载并安装

这里在 Linux 环境下全局安装 Composer。

```Bash
$ wget https://getcomposer.org/installer
$ php installer --install-dir=/usr/local/bin --filename=composer
```

如果出现如下错误，可以在`php installer`命令后追加`--disable-tls`参数。

```Bash
The "https://getcomposer.org/download/1.4.1/composer.phar.sig" file could not be downloaded: SSL: Connection reset by peer
# 或者
Failed to decode zlib stream
```

安装完成后，查看 Composer 版本信息。

```Bash
$ composer --version
Composer version 1.4.1 2017-03-10 09:29:45
```

### 切换中国镜像

由于国外镜像存在被墙的问题，所以这里将 Composer 镜像切换为 [中国镜像](https://pkg.phpcomposer.com/)。

```Bash
$ composer config -g repo.packagist composer https://packagist.phpcomposer.com
```

## 命令

常用命令：

```Bash
require         # 添加包到composer.json并安装
update          # 更新composer.json中的包至最新版本，并更新composer.lock文件
remove          # 删除包及其依赖
create-project  # 创建一个项目并安装依赖
dump-autoload   # 自动加载
init            # 创建composer.json
install         # 从composer.lock安装项目的依赖包
config          # 设置配置信息
search          # 查找一个包
self-update     # 更新composer至最新版本
show            # 查看包信息
status          # 查看本地修改的包
validate        # 校验composer.json和composer.lock
```

还有一些较少使用的命令，这里不一一列出。

## 搭建私有仓库

私有仓库是团队开发项目中不可或缺的，这里使用 [Satis](https://github.com/composer/satis) 来实现这一需求。

### 下载安装

这里通过 Composer 方式拉取 Satis 源码。

```Bash
$ cd /home/www     # $path
$ composer create-project composer/satis:dev-master --keep-vcs
```
安装后的默认目录名为 `/$path/satis`。

### 配置

修改`satis.json`文件，在这里列举出仓库所有包的托管仓库地址，以 GitHub 上的开源 MongoDB 地址为例，讲述配置详情。

```Bash
$ cd satis/
$ vim satis.json
```

内容如下所示：

```Js
{
  "name": "Fhb Repository",      //名称
  "homepage": "http://packagist.fanhaobai.com",  //satis仓库地址
  "repositories": [             //所有包托管仓库地址
    {
      "type": "vcs",          //仓库类型，github|gitlab为vcs
      "url": "git@github.com:fan-haobai/yii2-mongodb.git"  //MongoDB仓库地址
    },
    ... ...                     //其他需要索引的仓库地址
  ],
  "require-all": true           //获取全网所有镜像，建议不这样设置
  "archive": {
    "directory": "dist",
    "format": "tar",
    "skip-dev": true
  }
}
```

需要说明的是，如果包托管仓库也是采用开源版本管理系统搭建，那么这里`require-all`可以设置为 true。否则，建议只列举出需要索引的包名称以及版本号，因为设置为 true 会扫描全网所有包地址。例如仓库地址设为 GitHub，那么扫描的全网包数量巨大，非常耗时。所以在本例中修改为如下：

```Bash
... ....
"require": {
  "yiisoft/yii2-mongodb": "^2.1.0"
}
... ...
```

### 运行

```Bash
$ php bin/satis build satis.json /home/www/packagist -v
```

`-v`表示显示出索引详细。`/home/www/packagist`目录为生成的仓库目录，Nginx 配置站点目录指向此处，即`packagist.fanhaobai.com`指向此处。因为后续更新包索引也需要运行该命令，所以将该命令写为`build.sh`。

如果看到`Installing xxx/xxx Downloading: 100% ...`信息，就说明索引成功，访问 [站点](http://packagist.fanhaobai.com) 即可。

![](https://img.fanhaobai.com/2017/05/composer/bb8a-6ddaa3977.png)

## 发布包

这里将 Satis 作为 Composer 包私有仓库，以 GitHub 作为包代码托管仓库，列出大致的包发布流程：

1) 先将需要发布的包发布到代码管理仓库，例如 GitHub；

直接 fork 阿里云 OSS 官方 SDK 封装，地址为：[git@github.com:fan-haobai/yii2-aliyun-oss.git]()，并打一个 V1.0.0 版本的标签，这样 Satis 默认可以将 tag 名称作为包版本号。

2) 在配置文件`satis.json`中增加包仓库地址，以及索引版本；

```Js
"repositories": [
  ... ...
  {
    "type": "vcs",
    "url": "git@github.com:fan-haobai/yii2-aliyun-oss.git"
  }
  ... ...
"require": {
  ... ...
  "chonder/yii2-aliyun-oss": "^1.0.0"    #包composer.json中的name
  ... ...
}
```

3) 执行`build.sh`脚本更新索引；

出现以下内容即为包索引更新成功。

```Bash
Installing chonder/yii2-aliyun-oss (V1.0.0) Downloading: 100% Extracting archive
```

## 安装包

### 切换包仓库地址

需要安装 Satis 索引的 Composer 包，只需在项目的`composer.json`文件中将 repositories 配置为 Satis 仓库地址即可。

```Js
{
  "config": {
    "process-timeout": 1800,
    "secure-http": false
  },
  "repositories": [{
    "type": "composer",
    "url": "http://packagist.fanhaobai.com"
  }]
}
```

config 项用于设置超时时间和 https，如果 Satis 站点是 http 协议，则将`secure-http`设置为 false。

### 安装包

在项目的`composer.josn`同目录下，运行：

```Bash
$ composer require chonder/yii2-aliyun-oss:^1.0.0
```

出现如下信息则安装包成功。

```Bash
Package operations: 1 install, 0 updates, 0 removals       
  - Installing chonder/yii2-aliyun-oss (V1.0.0): Downloading (100%)
Writing lock file
Generating autoload files
```

## 包管理工具

在团队开发中，经常需要进行包的增加和删除，如果直接修改`satis.json`文件，显得比较麻烦，此时使用 [satisfy](https://github.com/ludofleury/satisfy) 的 Web 界面即可实现包的管理。

![](https://img.fanhaobai.com/2017/05/composer/810b7e47-f510-4116-a79c-4499057e2189.png)

> 注意：操作 satisfy 后，只是更新了`satis.json`文件的 repositories 地址，所以 satisfy 只适用于私有云仓库的情况；同时操作 satisfy 并没有触发 satis 进行 build，所以从 satisfy 中新增和删除一个包后，Composer 仓库包并没有立即发生变化，需要主动触发 satis 进行一次 build，当然可以使用 crontab 周期性来进行 build。 

<strong>更新 [»]()</strong>

* [包管理工具](https://www.fanhaobai.com/2017/05/composer.html#包管理工具)（2017-07-30）
