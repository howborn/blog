---
title: 我的博客发布上线方案 — Hexo
date: 2018-03-03 16:14:00
tags:
- 系统设计
- 工具
categories:
- 系统设计
---

之前一直在使用 [Hexo](https://www.fanhaobai.com/2017/03/install-hexo.html#官方推荐) 推荐的发布方案，缺点是本地依赖 Hexo 环境，无法随时随地地更新博客。为了摆脱 Hexo 环境约束进而高效写作，有了下述的发布方案。

![预览图](https://img.fanhaobai.com/2018/03/hexo-deploy/082786eb-0903-4776-a345-e52d25de2e49.png)<!--more-->

本文的发布方案中，Git 仓库只是托管 md 文件，通过 Webhook 通知服务器拉取 md 文件，然后执行构建静态文件操作，完成一个发布过程。

我的写作环境为 [Typora](https://www.typora.io/)（Win10），博客发布在阿里云的 [ECS](https://www.fanhaobai.com)（CentOS）上，文章托管在 [GitHub](https://github.com/fan-haobai/blog)。

## 需求迭代

随着时间成本的增高，只能利用碎片时间来进行写作。因此，我的写作场景变成了这样：

* 习惯使用 MarkDown 写原稿，有 MarkDown 编辑器就行；
* 写作场地不限定，有电脑就行；
* 写作时间不确定，有灵感就写；

## 新的问题

之前（包括 Hexo 推荐）的发布方案，都是先本地编写 MarkDown 源文件，然后本地构建静态文件，最后同步静态文件到服务器。发布流程图如下：

![原来的发布流程](https://img.fanhaobai.com/2018/03/hexo-deploy/f2ec7449-ae8a-4f6a-8dfa-95d6abf4aaa6.png)

显而易见，若继续使用之前的发布方案，那么每当更换写作场地时都需要安装 Hexo 环境，写作场地和时间都受到限制，不满足需求。

## 新的方案

问题主要是，本地受制于构建静态文件时需要的 Hexo 环境，那么是否可以将构建静态文件操作放到服务器端？

### 发布流程

首先，看下新方案的发布流程图：

![我的发布流程](https://img.fanhaobai.com/2018/03/hexo-deploy/bf3adf97-088b-47cd-b5ab-377a4f4acd44.png)

如流程图所示，整个发布系统共涉及到 3 个环境，分别为本地（写作）、Git 仓库（托管 md 源文件）、服务器（Web 服务）环境。在服务器环境构建静态文件，因此只需要在服务器端安装 Hexo 环境。 

一个完整的发布流程包含 3 个部分：

* 流程 ① ：[写作流程](#写作流程)；
* 流程 ② ：[发布流程](#发布流程)；
* 流程 ③ ：[构建流程](#构建流程)；

#### 写作流程

采用按分支开发策略，当写作完成后，只需要 push 修改到对应分支即可。只要有 MarkDown 编辑器，以及任何文本编辑器，甚至 [马克飞象](https://maxiang.io/) 都可以随时随地写作。

![写作流程](https://img.fanhaobai.com/2018/03/hexo-deploy/cd4f6674-aba5-4cbc-87e6-18c0c230585b.png)

当然，你可能说还需要 Git 环境呀？好吧，如果你是一名合格的 Coder，竟然没有 Git，你知道该干嘛了！再说没有 Git 环境，还可以通过 [GitHub](https://github.com) 来完成写作。 

#### 发布流程

采用 master 发布策略，当需要发布时，需要将对应开发分支 merge 到 master 分支，然后`push master`分支，即可实现发布。

![发布流程](https://img.fanhaobai.com/2018/03/hexo-deploy/12b62d2e-7e26-4a3c-a770-e0d16d5c2254.png)

#### 构建流程

这里使用到 Webhook 机制，触发服务器执行构建操作，构建脚本见 [Webhook 脚本](#Webhook脚本) 部分。

当流程 ① 和 ② 结束后，Git 仓库都会向服务器发起一次 HTTP 请求，记录如下：

![Webhook请求](https://img.fanhaobai.com/2018/03/hexo-deploy/9ee84981-7d79-47f5-98f8-e7500eff6e67.png)

当收到构建请求后，执行构建操作。构建流程图如下：

![构建流程图](https://img.fanhaobai.com/2018/03/hexo-deploy/3b8f20b3-f3b2-498d-afa4-d60391c47db5.png)

首先检查当前变更分支，只有为 master 分支时，执行 pull 操作拉取 md 文件更新，然后再执行 `hexo g`完成静态文件的构建。 

### Webhook脚本

[Webhook](https://github.com/fan-haobai/webhook) 脚本使用 PHP 实现，代码如下：

主流程方法如下：

```PHP
public function run()
{
    //校验token
    if ($this->checkToken()) {
        echo 'ok';
    } else {
        echo 'error';
    }
    fastcgi_finish_request();       //返回响应
    if ($this->checkBranch()) {     //校验分支
        $this->exec();              //执行操作逻辑
    }
}
```

这里使用 shell 脚本实现构建所需的所有操作，方便扩展。执行操作方法如下：

```PHP
public function exec()
{
    //shell文件
    $path = $this->config['bash_path'];
    $result = shell_exec("sh $path 2>&1");
    $this->accessLog($result);
    return $result;
}
```

构建 shell 脚本如下：

```Bash
#!/usr/bin/env bash

export NODE_HOME=/usr/local/node
export PATH=$NODE_HOME/bin:$PATH

pwd='/data/html/hexo'
cd $pwd/source
git pull
cd $pwd
$pwd/node_modules/hexo/bin/hexo g
```

## 总结

新发布方案与之前方案的区别是：一个本地只需编写 md 文件，博客服务器构建静态文件；另一个是本地编写 md 文件后，需要本地构建静态文件，然后博客服务器只同步静态文件。

当然，有很多办法可以解决当前问题，比如可以使用 [持续集成](https://formulahendry.github.io/2016/12/04/hexo-ci/)。本文只是提供一个发布思路，在项目的生成环境中，我们也很容易应用上这种发布思路，开发出自己的发布系统。

<strong>相关文章 [»]()</strong>

* [启用Hexo开源博客系统](https://www.fanhaobai.com/2017/03/install-hexo.html)<span>（2017-03-01）</span>