---
title: 工欲善其事，必先利其器
date: 2017-07-17 22:30:32
tags:
- 工具
categories:
- 工具
---

俗话说，工欲善其事，必先利其器。顺手的工具能提高我们的工作效率，减少时间成本。这里记录我开发过程中所使用到的一些高效工具。

![](https://img0.fanhaobai.com/2017/07/tools/4e4a0e11-4c0d-4909-a838-2a60c47986d2.jpg)<!--more-->

## Host Switch Plus

Host Switch Plus 是 Google Chrome 的一个小插件，它能狗快速切换 Domain-IP 配置而不需要编辑 Hosts 文件，并方便的添加、修改、分组（批量开关）。

![](https://img1.fanhaobai.com/2017/07/tools/a68431a9-aa50-4e03-a54c-25da1383fb49.png)

### 安装

前往 Google [商城](https://chrome.google.com/webstore/category/extensions)，搜索 host switch plus，然后点击 “添加至 CHROME”，即可完成安装。

![](https://img2.fanhaobai.com/2017/07/tools/d432be9d-c671-42cf-ac5c-2239443f0ced.png)

### 添加host

打开 Host Switch Plus 后，选择 Add 后即可添加一行 host 解析记录。

![](https://img3.fanhaobai.com/2017/07/tools/43750698-8113-4ce8-b0a7-3dbd38d481de.png)

### 启用host

添加一条 host 后，在浏览器右上角单击 Host Switch Plus 图标，在弹出的窗口中双击需要启用的记录，即可启用该条 host 解析。

![](https://img4.fanhaobai.com/2017/07/tools/5f54093a-5e69-4b3e-b78a-fc0c51363cb8.png)

成功解析 host 后，可在 Google Chrome 和 Postman 中使用。

## Postman

Postman 作为一个接口调试工具我们已经很熟悉了。

### 安装

Postman 是 Google Chrome 的一个插件，前往 Google [应用商城](https://chrome.google.com/webstore/category/extensions)，搜索 Postman 安装即可。

### 模拟请求

我们平常使用最多的莫过于使用 Postman 发送模拟请求，调试我们开发的接口。

![](https://img5.fanhaobai.com/2017/07/tools/ec2dc0e8-d369-40a8-ad7d-fc1e3d061d16.png)

如上图所示，Postman 可以满足许多场景的接口模拟，且操作比较简单，这里不做过多陈述。

### 按项目分类

Postman 支持按照项目来对接口进行分门别类，进行方便查找和管理。

首先在左侧栏点击 “Collections” 切换项目栏目，点击 “创建文件夹” 图标并填写项目描述即可创建一个名为 "fanhaobai.com” 的项目，如下：

![](https://img0.fanhaobai.com/2017/07/tools/59a36935-0068-4a4c-a004-786bf78993d5.png)

例如地址为`https://www.fanhaobai.com/content.json`接口，这时需要将它放置在 “fanhaobai.com” 项目下，以方便后续反复多次调试。

在接口地址栏后，点击 “Save” 即可保存该接口，在 “Save to existing collection” 项选择 “fanhaobai.com”，如下如所示：

![](https://img1.fanhaobai.com/2017/07/tools/a25a2996-6a5e-4292-b773-651b868d5523.png)

如果后续需要调试该接口时，只需要选择 ”fanhaobai.com“ 项目下对应地址的接口，即可快速方便地调试。

当然，可以将项目中的所有接口配置导出，团队其他成员可以快速导入并调试。

### 环境配置

上述的接口地址直接硬生生写在地址栏中，然而在开发过程中，一个项目会对应多个环境，每个环境接口地址、请求参数等都不一致，这就给我们调试带来了不便，不同环境需要手动更改地址或者参数。此时，使用 Postman 的环境配置功能就可轻松解决。

将一些因为环境不一致而导致变化的值配置为 **环境变量**，例如：

| 名称          | 值                  | 说明 |
| ----------- | -------------------- | ----- |
| host        | api.d.ziroom.com     | 环境地址  |
| app_version | 5.1.0                | 客户端版本 |
| os          | ios                  | 客户端类型 |
| timestamp   | 1501412607           | 请求时间  |
| sign        | ...........          | 签名    |

接下来，以 phoenix 项目为例，配置每个环境的环境变量。点击 Postman 右上角 “设置” 图标，如下图：

![](https://img2.fanhaobai.com/2017/07/tools/974dbaee-be3f-4a9c-874c-68c5de584403.png)

点击 ”Manage Environments“，即可配置环境变量。Postman 支持全局环境变量，点击 “Globals” 可以设置全局环境变量，这里点击 ”Add“ 配置一个开发环境和测试环境，如图：

![](https://img3.fanhaobai.com/2017/07/tools/e3089043-bd3d-4a0f-b284-669b6f07a791.png)

host-api 这个环境变量的值，取决于相应环境，每个环境都定义了各自的接口地址值。这里只是将 host-api 配置在各个环境变量中，而将 app_version、os、timestamp、sign 跟客户端相关的特性配置成 **全局环境变量**。

最后，只需使用已经定义好的环境变量即可，环境变量表达式为 `{name}`，name 为变量名。

使用环境变量后，接口地址和请求参数类似如下：

![](https://img4.fanhaobai.com/2017/07/tools/a3b57584-fb7b-470f-84e4-5213f25113ea.png)

### 自动测试

Postman 支持自动测试，对一个接口设置了相应的测试规则后，即可自动完成接口的测试。

首先，在接口地址栏下，点击 “Tests” 设置接口测试规则，如下：

```JS
var responseJSON;

try { 
    //解析json
    responseJSON = JSON.parse(responseBody); 
    tests['response is valid JSON'] = true;
}
catch (e) { 
    //数据异常
    responseJSON = {}; 
    tests['response is valid JSON'] = false;
}
//数据格式是否正常
tests['response has data'] = _.has(responseJSON, 'status');
//数据响应是否成功
tests['response is success'] = (responseJSON.status === 'success');
```

接下来，就可以测试该接口了，点击主面板左上角的 “Runner”，如下图所示：

![](https://img5.fanhaobai.com/2017/07/tools/365e357b-8a3f-48c7-a9a3-76611d66986a.png)

设置测试 “项目” 和 “环境”，点击 “Start Test”。最后，测试结果如下：

![](https://img0.fanhaobai.com/2017/07/tools/972d2bac-0d4b-4095-b0ba-28a5f252f314.png)

按照这些步骤，只要配置了每个接口的测试规则，Postman 就可以自动测试完项目的所有接口，并给出测试结果。

## Charles

Charles 是在 Mac 下常用的截取网络封包的工具（现在也支持 Win），在开发工程中，我们常需要截取网络包并分析通讯协议，这时使用 Charles 就可轻松完成。

![](https://img1.fanhaobai.com/2017/07/tools/0dc3e6f6-250e-4172-af30-83b91cfddf76.png)

Charles 的使用指南，[见这里](https://www.fanhaobai.com/2017/07/charles.html)。

## SwitchHosts

[SwitchHosts](https://github.com/oldj/SwitchHosts/blob/master/README_cn.md) 是一个免费开源的 Hosts 管理软件，使用它切换和配置 host 极为方便。

![预览图](https://img2.fanhaobai.com/2017/07/tools/f5a0c313-9404-4152-9bd1-ea24f7b1edc1.png)

从 [官方地址](https://github.com/oldj/SwitchHosts/releases) 下载自己系统的安装包，安装即可。

## 键位映射工具 — [AutoHotKey](https://www.autohotkey.com/)

不得不说 AutoHotKey 是个好工具，它可以用脚本方式定义键位映射关系，然后编译成可执行文件。

需求：在 Win10 下我希望使用 A（左）、D（右）、W（上）、S（下）来替代方向键，因为这样操作方便，下面通过 AutoHotKey 来示例。 

![预览图](https://img3.fanhaobai.com/2017/07/tools/11be684a-44ad-40e8-a291-e123d0df58ca.png)

首先，从 [官方地址](https://www.autohotkey.com/download/) 下载安装包，安装后鼠标 “右键 >> 新建” 菜单会增加 “AutoHotKey Script” 项，点击 “AutoHotKey Script” 即可创建脚本。

然后，创建名为`keyboard.ahk`的脚本文件，内容如下：

```Bash
; # Win (Windows logo key)
; ! Alt
; ^ Control
; + Shift
; & An ampersand may be used between any two keys or mouse buttons to combine them into a custom hotkey.

; ::btw::
;   MsgBox btw!!
; Return

; 方向键定义
RSHIFT & a::Send, {Left}
RSHIFT & d::Send, {Right}
RSHIFT & w::Send, {Up}
RSHIFT & s::Send, {Down}
```

> 其中`;`表示注释，更多语法见 [Documentation](https://www.autohotkey.com/docs/AutoHotkey.htm)。

最后，在`keyboard.ahk`脚本文件右击，选择 “Compile Script” 编译脚本，生成`keyboard.exe`的可执行文件，双击运行即可生效映射关系。

## 其他工具
* [PhpStorm的使用姿势](https://www.fanhaobai.com/2017/05/phpstorm-posture.html)
* [常用Git命令清单](https://www.fanhaobai.com/2017/04/git-command.html)
* [Composer安装和使用](https://www.fanhaobai.com/2017/05/composer.html)
* [使用GoAccess分析Nginx日志](https://www.fanhaobai.com/2017/06/go-access.html)
* [启用Hexo开源博客系统](https://www.fanhaobai.com/2017/03/install-hexo.html)

<strong>更新 [»](#)</strong>
* [Postman](#Postman)（2017-07-30）
* [Charles](#Charles)（2017-08-04）
* [SwitchHosts](#SwitchHosts)（2018-04-13）
* [键位映射工具 — AutoHotKey](#键位映射工具 — AutoHotKey)（2018-04-19）
