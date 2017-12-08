---
title: 使用Charles抓包
date: 2017-07-22 09:58:18
tags:
- 工具
categories:
- 工具
---

Charles 是在 Mac 下常用的截取网络封包的工具（Win 环境也已支持），在移动端开发过程中，我们常需要截取网络包分析服务端的通讯协议。Charles 将自己设置成系统的网络访问代理服务器，不仅可以提供 SSL 代理，还支持流量的控制、支持重发网络请求、支持修改网络请求参数、支持网络响应截获并动态修改。
{% asset_img 0dc3e6f6-250e-4172-af30-83b91cfddf76.png %}<!--more-->

### 安装Charles

从 Charles 的 [官方网站](https://www.charlesproxy.com/download/) 下载最新的安装包，下载晚完成安装即可。

Charles 是付费软件，当然免费状态也可以使用。可以使用如下信息完成注册：

```Bash
Registered Name: https://zhile.io
License Key: 48891cf209c6d32bf4
```

如果注册失败，可以尝试 [这种方法](http://charles.iiilab.com/)。

### 设置成系统代理服务器

由于 Charles 是通过将自己设置成代理服务器来完成封包截取的，所以第一步是需要将 Charles 设置成系统的代理服务器。

启动 Charles 后，菜单中的 “Proxy” -> “Windos Proxy（或者Mac OS X Proxy）”， 来将 Charles 设置成系统代理。如下所示：

{% asset_img 0a6e7c09-6361-4e9f-9bc4-778bb7656bc4.png %}

配置后，就可以在界面中看到截取的网络请求。但是，Chrome 和 Firefox 浏览器默认并不使用系统的代理服务器设置， 所以需要将 Chrome 和 Firefox 设置成使用系统的代理服务器，或者直接设置成地址`127.0.0.1：8888`。

如果 Chrome 已安装了 Host Switch Plus 插件，则需要暂时关闭。

{% asset_img 4e97e097-b884-4db0-b07f-292a78a77544.png %}

### 过滤网络请求

一般情况下，我们只需要监听指定服务器上发送的请求，可以使用如下办法解决：

* 方式1：在主界面 “Sequence” -> “Filter” 栏位置输入需要过滤的关键字即可。例如输入`fanhaobai`，则过滤输出只包含 fanhaobai 信息的请求。
* 方式2：在 Charles 的菜单栏选择 “Proxy” -> ”Recording Settings”，并选择 Include 栏，添加一条永久过滤规则，主要填入需要截取网站的协议、主机地址、端口号。

  {% asset_img 647b22ba-8441-45db-8386-1c64b6ca520e.png %}
* 方式3：右击需要过滤的网络请求，选择 “Focus” 选项即可。

方式 1 和方式 3 可以快速地过滤临时性网络请求，使用方式 2 过滤永久性网络请求。

### 截取移动设备网络包

Charles 除了可以截取本地的网络包，作为代理服务器后，同样可以截取移动设备的网络请求包。

#### 设置Charles

截取移动设备网络包时，需要先将 Charles 的代理功能打开。在 Charles 的菜单栏上选择 “Proxy” -> ”Proxy Settings”，填入默认代理端口 8888，且勾选 “Enable transparent HTTP proxying” 就完成了设置。如下图所示：

{% asset_img 28fe758a-e2c2-48ab-8132-f26f438e79e0.png %}

####  iPhone

首先，通过 Charles 的顶部菜单的 “Help” -> ”Local IP Address” 获取本地电脑的 IP 地址，例如我的本机电脑为`192.168.1.102`。

在 iPhone 的 ”设置“ -> ”无线局域网“ 中，对当前局域网连接设置 HTTP 代理（端口默认为 8888），如下图：

{% asset_img bfd83ef1-1e78-4bbb-aa0d-50e4591ca04e.jpg %}

设置完成后，打开 iPhone 的任意程序，在 Charles 就可以弹出连接确认窗口，点击 ”Allow” 即可。

{% asset_img d40b7bd9-3b1d-4901-816a-dd706909c48b.png %}

#### Android 

在 Android 上操作同 iPhone，只是某些系统设置方式不一致而已。

### 截取 Https 包

如果需要截取并分析 Https 协议信息，需要安装 Charles 的 CA 证书。

#### 本地通信信息

点击 Charles 的顶部菜单，选择 “Help” -> “SSL Proxying” -> “Install Charles Root Certificate”，即可完成证书的安装。如下图所示：

{% asset_img 7af98999-1276-478b-a443-b92b8986b788.png %}

建议将证书安装在 ”受信任的根证书颁发机构“ 存储区。

特别说明，即使安装完证书后，Charles 默认是不会截取 Https 网络通讯的信息。对于需要截取分析站点 Https 请求，可以右击请求记录，选择 SSL proxy 即可，如图所示：

{% asset_img 255707e0-725c-4e8e-932a-34b870031e40.png %}

#### 移动设备的通信信息

如果在 iPhone 或 Android 机器上截取 Https 协议的通讯内容，需要手机上安装相应的证书。点击 Charles 的顶部菜单，选择 “Help” -> “SSL Proxying” -> “Install Charles Root Certificate on a Mobile Device or Remote Browser”，然后按照 Charles 的提示的安装教程安装即可。如下图所示：

{% asset_img 1bfe09f1-69a9-4b43-a39c-3d26e067d27a.png %}

{% asset_img d97cf8fa-5e7f-4c3e-905f-ec0ed12038dd.png %}

在上述 [截取移动设备网络包]() 为手机设置好代理后，手机浏览器中访问地址`http://chls.pro/ssl`，即可打开证书安装的界面。安装完证书后，就可以截取手机上的 Https 通讯内容了。注意，同样需要在要截取的网络请求上右击，选择 SSL proxy 菜单项。

如果  SSL proxy 后出现如下错误：

{% asset_img 1fb741c8-4170-47fa-ad0f-1929ae7857fd.png %}

可将证书设置为信任即可，例如 iPhone 下 “设置” -> “通用” -> “关于本机” -> “证书信任设置” 下：

{% asset_img fab69a4a-17c1-4944-81c9-255ff33ff815.png %}

### 模拟慢请求

在做 App 开发调试时，经常需要模拟慢请求或者高延迟网络，以测试应用在网络异常情况变现是否正常，而这使用 Charles 就轻松帮我们完成。

在 Charles 的菜单上，选择 “Proxy” -> ”Throttle Setting” 项，在弹出的窗口中，可以勾选上 “Enable Throttling”，并且可以设置 Throttle Preset 的类型。如下图所示：

{% asset_img 41bdb338-fcba-4d56-ac55-207aed5560b4.png %}

当然可以通过 “Only for selected hosts” 项，只模拟指定站点的慢请求。

### 修改请求内容

有时为了调试服务端的接口，我们需要反复尝试不同参数的网络请求。Charles 可以方便地提供网络请求的修改和重发功能。只需在该网络请求上点击右键，选择 “Compose”，即可创建一个可编辑的网络请求。

我们可以修改该请求的任何信息，包括 URL 地址、端口、参数等，之后点击 “Execute” 即可发送该修改后的网络请求。Charles 支持我们多次修改和发送该请求，这对于我们和服务器端调试接口非常方便，如下图所示：

{% asset_img 25753d81-3257-43b7-8f35-89436d888974.png %}

### 修改响应内容

有候为方便我们调试一些特殊情况，需要服务器返回一些特定的响应内容。例如数据为空或者数据异常的情况，部分耗时的网络请求超时的情况等。通常让服务端配合，构造相应的数据显得会比较麻烦，这个时候，使用 Charles 就可以满足我们的需求。

根据不同的场景需求，Charles 提供了 Map 功能、 Rewrite 功能以及 Breakpoints 功能，都可以达到修改服务器返回内容的目的。这三者在功能上的差异是：

* Map 功能适合长期地将某一些请求重定向到另一个网络地址或本地文件。
* Rewrite 功能适合对网络请求进行一些正则替换。
* Breakpoints 功能适合做一些临时性的修改。

#### Map功能

Charles 的 Map 功能分 Map Remote 和 Map Local 两种。Map Remote 是将指定的网络请求重定向到另一个网址请求地址，而 Map Local 是将指定的网络请求重定向到本地文件。在 Charles 的菜单中，选择 “Tools” -> ”Map Remote” 或 “Map Local” ，即可进入到相应功能的设置页面。

对于 Map Remote 功能（选中 Enable Map Remote），我们需要填写网络重定向的源地址和目的地址，对于其他非必需字段可以留空。下图是一个示例，我将测试环境`t.fanhaobai.com`的请求重定向到了生产环境`www.fanhaobai.com`。

{% asset_img fe7c1302-4101-4882-ae0f-a3d395bdb960.png %}

对于 Map Local 功能（选中 Enable Map Local），我们需要填写的重定向的源地址和本地的目标文件。对于有一些复杂的网络请求结果，我们可以先使用 Charles 提供的 “Save Response…” 功能，将请求结果保存到本地并稍加修改，成为我们的目标映射文件。

{% asset_img dfa1e7c1-9072-4e33-836a-cdd62709af67.png %}

#### Rewrite功能

Rewrite 功能功能适合对某一类网络请求进行一些正则替换，以达到修改结果的目的。

例如，将服务端返回的`www.fanhaobai.com`全部替换为`www.baidu.com`，如下：

{% asset_img 4ccdcd7b-0b54-43df-bf09-4887edf7800e.png %}

将响应中的`www.fanhaobai.com`全部替换为`www.baidu.com`。于是在 “Tools” -> "Rewrite" 下配置如下的规则：

{% asset_img b037c6ae-8a8a-45fd-9a1f-b3628db8b8d6.png %}

选中 “Enable Rewrite”  启用 Rewrite 功能 ，响应如下：

{% asset_img c8e71602-2bde-4b7a-850f-bde0b0a17084.png %}

#### Breakpoints功能

上面提供的 Rewrite 功能最适合做批量和长期的替换，但是很多时候，我们只是想临时修改一次网络请求结果，这个时候，我们最好使用 Breakpoints 功能。

在需要打断点的请求上右击并选择 “Breakpoints”，重新请求该地址，可以发现客户端被挂起，Charles 操作界面如下：

{% asset_img 73350a4e-816d-4f91-91d5-2a6d1104c722.png %}

此时可以修改请求信息，但这里只修改响应信息，故点击 “Execute” 后选择 “Edit Response” 项，修改 title 为`fanhaobai.com`，如下：

{% asset_img  0fa6ff3f-c1f8-4179-b458-b21cc63e02c2.png %}

继续点击 “Execute” ，可看见响应的 title 已经变为`fanhaobai.com`。

### 压力测试

我们可以使用 Charles 的 Repeat 功能来简单地测试服务器的并发处理能力。在想压测的网络请求上右击，然后选择 "Repeat Advanced” 项，如下所示：

{% asset_img b0875e59-e049-4b62-93f7-02311d0d47e7.png %}

这样我们就可以在上图的对话框中，选择压测的并发线程数以及压测次数，确定之后，即可开始压力测试了。

### 反向代理

Charles 的反向代理功能允许我们将本地的端口映射到远程的另一个端口上。

{% asset_img d3193cee-783b-43c0-99c3-ac98ec52aaa6.png %}
