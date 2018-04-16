---
title: WIN10下VM桥接无网络解决办法
date: 2016-02-02 08:00:00
tags:
- 工具
categories:
- 工具
---

最近系统升级成 win10 后，发现 **VM** 无法通过桥接方式连接到网络了，也尝试重新安装虚拟机，但是都没有解决问题，所以怀疑是否由于 win10 系统所引起。在这里记录自己的解决办法。

![预览图](https://img.fanhaobai.com/2016/02/win10-vm-network/3ecbe34f-7d74-4cb2-871b-ac932d62baa3.png)<!--more-->

操作系统本版号 1151，VM 版本为 pro 12.1.0。

1） 先保证虚拟机处于 **关机状态**

![](https://img.fanhaobai.com/2016/02/win10-vm-network/rSK1reoB3itU--fth7vyPFgr.png)

2） 在系统中打开 **网络与共享中心**，然后在弹出的窗口中点击 **更改适配器设置**

![](https://img.fanhaobai.com/2016/02/win10-vm-network/OEoaw5ml67q-CQafFRFI9XRG.png)

3） 在弹出的 **网络连接** 面板中，选中 **本地连接**（我的是以太网），**右键** 选择 **属性**

![](https://img.fanhaobai.com/2016/02/win10-vm-network/3ZSQ0829kudRZphXSMnYK6Vt.png)

4） 在弹出的窗口中，选中 **VMware Bridge Portocol**，点击 **卸载**，弹出窗口点击 **是**

![](https://img.fanhaobai.com/2016/02/win10-vm-network/SFHEF9xgrtCIABo8c2tR3PFo.png)

5） 上述操作完成后，以 **管理员身份** 运行 **VMware workstation**，打开后选择 **编辑**，并点击 **虚拟网络编辑器**

![](https://img.fanhaobai.com/2016/02/win10-vm-network/DJpNwdNawxrBgSEucYIP0f0e.png)

6） 在新打开的窗口中，点击 **还原默认设置**，弹出的确认窗口中选择 **是**

![](https://img.fanhaobai.com/2016/02/win10-vm-network/iXXHuTApN_8iUjDAOU04reqp.png)

![](https://img.fanhaobai.com/2016/02/win10-vm-network/2NdwyTgdoVzD5CwHCFHgGSWK.png)


7） 在 **网络连接** 中，查看 **本地连接**（我的是以太网）的网卡名为 **Realtek PCIe GBE Family Controller**，将 **桥接模式** 选择到该网卡

![](https://img.fanhaobai.com/2016/02/win10-vm-network/DscyYxjkXQBAWtkmeIG_xtc6.png)

8） **编辑虚拟机设置**，在虚拟机设置面板中选择 **网络适配器**，然后勾选 **启动时连接**，且将 **网络连接** 切换到 **桥接模式**

![](https://img.fanhaobai.com/2016/02/win10-vm-network/7hHPfupgOL5euKi3Y48XnwgX.png)

9） 启动虚拟机进行联网测试

![](https://img.fanhaobai.com/2016/02/win10-vm-network/ecF7lF_6lahMhFJAh94XBdmV.png)

到这里，问题已经解决掉了。
