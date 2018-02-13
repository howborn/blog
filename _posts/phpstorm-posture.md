---
title: PhpStorm的使用姿势
date: 2017-05-23 21:12:32
tags:
- 工具
categories:
- 工具
---

俗话说，工欲善其事必先利其器。作为一名码农，合适开发工具能提高我们的开发效率，而 PhpStorm 是 PHPer 不可或缺的工具，这里整理了一些编码过程中常用的 PhpStorm 使用姿势。

![预览图](https://img.fanhaobai.com/2017/05/phpstorm-posture/837dac58-9c01-4748-949e-57ba18a524ea.png)<!--more-->

## 安装

本文 PhpStorm 版本为 2017.1.1。PhpStorm 在 Win 平台安装比较容易，直接参考 [此处](https://www.jetbrains.com/phpstorm/download/#section=windows) 即可。Linux 平台安装相对比较坎坷，请移步 [这里](https://www.fanhaobai.com/2016/05/lnmp.html#Phpstorm)。至于注册码，见 [@lan yu](http://idea.lanyus.com/) 提供的方法。

##  配置

以下是基于个人的喜好，所做的偏好设置。

### Setting项

* 更改工作区间主题
  在”Editor >> Colors & Fonts“下将工作区间主题更改为“Monokai”，并将字体设置为“Source Code Pro”。如下图所示：
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/ede1d136-3e29-11e7-a919-92ebcb67fe33.png)

* 更改Terminal字体
  在”Editor >> Console Font”下将字体更改为“Source Code Pro”。

* 关闭拼写错误检查
  在“Editor >> Colors & Fonts >> Inspections”下将“Typo”项勾掉，如下图所示：
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/64f85ab7-f5ce-4146-b8a1-b103f7a0aab9.png)

* 关闭函数参数名和类型提示
  由于此版本默认开启此功能，让一行代码看起来变长很多，感觉很不舒服。在“Editor >> General >> Appearance”下将“Show parameter name hints”项勾掉。如下图：
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/1e8c3964-3e2c-11e7-a919-92ebcb67fe33.png)

* 代码模板
  在代码起始位置，往往需要添加作者的信息和代码用途说明，可以通过模板来实现。将"Editor >> File and Code Templates"修改如下：
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/7faf906a-6dd4-43f7-b1d1-d9dfa2683df3.png)

## 快捷键

### 查询

* F4 查找变量来源
* Ctrl + N 查找指定类
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/f797c144-3fba-11e7-a919-92ebcb67fe33.png)

* Ctrl + Shift + N 全局搜索文件
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/8715f962-3fbb-11e7-a919-92ebcb67fe33.png)

* Ctrl + Shift + Alt + N 查找php类名/变量名/js方法名和变量名/css选择器
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/9f3564fa-3fbc-11e7-a919-92ebcb67fe33.png)

* Ctrl + B  定位变量来源（同Ctrl + 单击）
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/7568394e-3fbd-11e7-a919-92ebcb67fe33.png)

* Ctrl + Alt + B  找到父级的所有子类
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/f4123ede-3fbd-11e7-a919-92ebcb67fe33.png)

* Ctrl + G 定位行
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/3cea2b6c-3fbe-11e7-a919-92ebcb67fe33.png)

* Ctrl + F 在当前窗口查找文本
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/9b5aecc2-3fbe-11e7-a919-92ebcb67fe33.png)

* Ctrl + Shift + F 在指定路径查找
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/f76994dc-3fbe-11e7-a919-92ebcb67fe33.png)

* Ctrl + R 当前窗口替换文本
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/688eeafe-3fbf-11e7-a919-92ebcb67fe33.png)

* Ctrl + Shift + R 在指定路径替换文本
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/b1c4c23e-3fbf-11e7-a919-92ebcb67fe33.png)

* Ctrl + E 查看最近打开的文件
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/0b66bdb0-3fc0-11e7-a919-92ebcb67fe33.png)

### 自动代码

* Ctrl + J 自动代码提示和补全
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/abfc1072-3fc0-11e7-a919-92ebcb67fe33.png)

* Ctrl + Alt + L 格式化代码
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/110f81f6-3fc1-11e7-a919-92ebcb67fe33.png)

* Ctrl + Alt + I 自动缩进
* Ctrl + P 方法参数提示
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/96be6d1c-3fc1-11e7-a919-92ebcb67fe33.png)

* Ctrl + Insert 生产类的get|set方法|构造函数等
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/46058594-3fc2-11e7-a919-92ebcb67fe33.png)
* Ctrl + H 显示类层级关系图
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/fae803a0-3fc3-11e7-a919-92ebcb67fe33.png)

* Ctrl + F12 显示文件结构
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/29b45a8a-3fc4-11e7-a919-92ebcb67fe33.png)

* Ctrl + W 块状态选中代码
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/9b4ffbae-3fc4-11e7-a919-92ebcb67fe33.png)

* Ctrl + O 类的魔术方法
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/d02a9352-3fc4-11e7-a919-92ebcb67fe33.png)

* Ctrl + Shift + I 快速定义变量和方法
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/378ef9e8-3fc5-11e7-a919-92ebcb67fe33.png)

* Ctrl + [] 光标移动到{}开头或结尾
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/06eca43d-481b-4762-a0af-7742482c0696.png)

* Ctrl + Shift + [] 选中光标至[]之间的代码块
* Ctrl + / 单行注释/取消注释
* Ctrl + Shift + / 块注释/取消块注释
* Shift + ⬆/⬇/➡/⬅ 进行区域性选中代码
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/88d5ee69-fae4-406c-aed7-ddd0a7ff2108.png)

* Ctrl + Shift + U 选中的字符大小写转换
* Ctrl + . 折叠/展开选中的代码块
* Ctrl + Alt + ➡/⬅ 返回上次编辑的位置
* Alt + ➡/⬅ 切换选项卡
* Alt + ⬆/⬇ 在方法间快速移动
* Ctrl + Shift + Enter 智能补全代码
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/40abd94d-e333-40cf-bd4b-30a27ad8484a.png)

* Ctrl + Shift + ⬆/⬇ 选中区域进行上下移动
* Shift + F6 重命名文件名/类名/函数名/变量名
  ![](https://img.fanhaobai.com/2017/05/phpstorm-posture/a2d96914-f897-4ab0-89b2-26c4f805e282.png)

* Alt + 7 显示当前类/函数结构
* F5 复制文件或文件夹
* Ctrl + C 复制
* Ctrl + V 粘贴
* Ctrl + X  剪切 / 删除行
* Ctrl + Y 删除行
* Ctrl + D 复制行
* Shift + F2 警告快速定位

### 编辑

* F5 复制文件夹/文件
* F6 移动
* Ctrl + Q 快速文档查询
* Ctrl + I 快速实现类的魔术方法
* Shift + Tab 缩进/取消缩进选中的行
* Ctrl + Delete 删除单个字（word）
* Ctrl + Z 插销
* Ctrl + Shift + Z 向前撤销

### 运行

* Ctrl + Shift + F12 切换最大化编辑器
* Shift + F10 运行
* Shift + F9 调试
* Ctrl + Shift + X 运行命令行
* Alt + Shift + F9 选择配置并调试
* Alt + Shift + F10 选择的配置并运行
* Esc 光标返回编辑框
* Shift + Esc 光标返回编辑框并关闭无用窗口
* Ctrl + F4 关闭当前的选项卡
* Ctrl + Alt + V引入变量
* Ctrl + Tab 键切换选项卡和工具窗口
* Ctrl + Shift + A 查找

### 调试

* F8 步过
* F7 步入
* Shift + F7 智能进入
* Shift + F8 步骤
* ALT + F9 运行到光标
* F9 恢复程序
* Ctrl + F8 切换断点
* Ctrl + Shift + F8 查看断点

## 工具

### SSH

PhpStorm 内置了 SSH 会话工具，通过该工具就可以与服务器建立 SSH 通信，不需要编码调试时来回切换工作窗口，即可在编码窗口完成调试和对服务器的操作。

打开"Tools >> Start SSH Session"，配置连接信息如下：
![](https://img.fanhaobai.com/2017/05/phpstorm-posture/6cee9eb9-c0a8-4273-926e-8775fe8d15e8.png)

连接成功后，所有操作同 Xshell，如下图所示：
![](https://img.fanhaobai.com/2017/05/phpstorm-posture/bb2a5138-34c7-4026-b7e4-44679dc5d5cd.png)

但是，这样每次在打开"Start SSH Session"时，都会要求重新输入连接信息，比较麻烦。能不能像 Xshell 一样，保存住连接信息呢？可以通过配置”Tools >> Deployment >> Configuration“来解决，新增一个 Deployment，如下图所示：
![](https://img.fanhaobai.com/2017/05/phpstorm-posture/071895d0-6428-45fa-ba5c-7eec225600bb.png)

其中，Type 项建议选择为 SFTP，将主机信息填写完整后点击保存即可。再次打开”Start SSH Session“，会出现所新增的 Deployment，点击选择即可直接连接成功，如下图所示。
![](https://img.fanhaobai.com/2017/05/phpstorm-posture/5f58b311-0a37-4711-9036-97f89dc908f0.png)

**中文乱码问题**
在用 PhpStorm 内置 SSH 工具连接服务器后，可能会出现如下中文乱码情况。
![](https://img.fanhaobai.com/2017/05/phpstorm-posture/514e834c-e7b4-48a5-bdb2-dcc82da75975.png)

此问题是由 SSH 客户端字符集设置不正确导致，在配置“Tools >> SSH Terminal”项下将“Default encoding”由 GBK 更改为 UTF-8 后保存，并重新启动 PhpStorm 即可。
![](https://img.fanhaobai.com/2017/05/phpstorm-posture/0fa2c25a-6d55-4430-9733-7b1fab722f72.png)

### Database

PhpStorm 已经集成了数据库管理插件 Database，我们只需配置基本连接信息即可使用。

点击右侧“Database >> + >> Data source”，选择对应类型数据库（Mysql），如下：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/64e32996-f122-46fe-bf79-0a736e0d2a53.png)

填写 Host、Port、User、Password 这些基本连接信息，可点击”Test Connection“测试配置是否正确，然后点击”OK“。当然还可以使用 SSH 隧道加密连接。

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/b1599018-5b7f-46d8-b97c-e129e0ea631e.png)

双击查看维基站的 wiki_archive 表，如下：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/edb7eb37-1565-4a0c-a4e6-f3629246fb09.png)

在数据表列表选中 wiki_archive 右键，即可对表进行操作：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/e4daad6b-c360-4581-a974-c84292e4fe92.png)

执行 SQL，需要在 Database 面板上点击”QL“图标（或者 Ctrl + Alt + F10），输入需要执行的 SQL 并敲 Ctrl + Enter，如下：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/c61f19e2-9067-4d83-b71a-8a6097113968.png)

总体上集成的 Database 工具已经满足了大部分数据库操作，集成到 PhpStorm 后开发快速便捷。

### Git

Git 已经成为了我们常用的版本管理工具，PhpStorm 中也集成了 Git 工具。

在“VCS >> Git >> Clone”，即可从仓库拉取代码：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/cf18c3c6-893b-480b-8f23-9e307795aea0.png)

需要向本地库添加新文件时，点击“Git >> Add“即可。

Commit 修改时，选中项目目录点击“Git >> Commit Directory”，如下：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/671a31a8-d6ab-4360-85be-e91b558aa42f.png)

创建分支时，点击“Git >> Repository >> Branches”，如下：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/c70747a5-72b1-4e86-b403-6de95a7ad7c3.png)

Pull 和 Push 代码时，直接点击“Git >> Repository >> Pull/Push“。

查看某个文件的提交记录，只需选中文件并右击 “Git >> Show History”，如下：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/18b8699d-36c8-481e-ac72-3fe842c895fb.png)

在 PhpStorm 底部栏“Version Control”中，可查看到 Git 相关的日志信息。

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/93de4c13-d30b-4d36-a017-44cb7e5078a5.png)

PhpStorm 中的 Git 工具，使得我们可以更加集中管理代码，推荐使用。

### Xdebug

![](https://img.fanhaobai.com/2017/09/xdebug-in-docker/7f7c8948-5e61-4086-b52d-fa9ceab69d3b.png)

PhpStorm 结合 Xdebug 进行远程调试，使得开发和调试变得非常方便，[见这里](https://www.fanhaobai.com/2017/09/xdebug-in-docker.html)。

### REST Client

REST Client 工具用来调试 API，点击“Tools >> Test RESTful Web Service“，如下图所示：

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/4bc4c68f-6760-49bf-811d-e055d92de6bb.png)

值得一提的是，REST Client 支持 Xdebug 断点调试，为调试 API 提供了便利。

![](https://img.fanhaobai.com/2017/05/phpstorm-posture/0e835fc8-3fd6-4531-8480-44cd33a83655.png)

<strong>更新 [»]()</strong>
* [Database](https://www.fanhaobai.com/2017/05/phpstorm-posture.html#Database)（2017-08-06）
* [Git](https://www.fanhaobai.com/2017/05/phpstorm-posture.html#Git)（2017-08-06）
* [Xdebug](https://www.fanhaobai.com/2017/05/phpstorm-posture.html#Xdebug)（2017-09-01）
* [REST Client](https://www.fanhaobai.com/2017/05/phpstorm-posture.html#REST Client)（2017-09-01）
