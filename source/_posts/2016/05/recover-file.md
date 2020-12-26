---
title: Linux下恢复误删除的文件
date: 2016-05-20 00:00:00
tags:
- Linux
categories:
- Linux
---

> 原文：http://www.libenfu.com/vim-分区下误删的文件，恢复文件全记录-转

以前总是在网上看到很多人问怎么恢复 Linux 下误删除的文件，现在记录自己的恢复文件全过程。

![](//img5.fanhaobai.com/2016/05/recover-file/Vv0jLUo_qMOT_N5y4Ha4KhBA.jpg)<!--more-->

当时我的工作目录是`/source/needrecovered`。

```Shell
$ pwd
/source/needrecovered
```

原本打算清空其中的一个子文件。

```Shell
$ rm -rf canbedeleted/html
```

却打成如下命令：

```Shell
$ rm -rf canbedeleted/ *
```

当时我琢磨着今天怎么删个小文件夹这么慢呢。等我仔细看了下命令，反应过来的时候，已经太迟了，整个工作目录被清空了 。

没辙了，只能先到网上找找解决方案了，网上大致提到的方法有两种：一种是利用 debugfs，第二种是利用 ext3grep。

第一种方法，我尝试了若干次都以失败告终，第二种成功了。但是相同的是：[两种方法首先提到的都是将对该分区进行操作的应用先全部关闭](#)，具体如下：

以下的操作尽量使用 root 操作，以提高数据恢复的成功率。

```Shell
#该命令用于列出操作该分区的进程
$ fuser -v -m /source
#如果没有很重要的进程，利用下面的命令将其全部 kill 掉
$ fuser -k -v -m /source
```

执行上面命令的时候，务必要将你的工作目录切换到`/source`以外，否则你的 sshd 会被 kill 掉。

** 这样子可以达到两个好处 **：

1） 防止新的文件操作影响数据的恢复；

2） 方便对磁盘或者分区进行进一步的操作，如：mount 和 umount；


接下来我们看看磁盘分区情况：

```Shell
$ df -Th
Filesystem    Type    Size  Used Avail Use% Mounted on
/dev/sda8     ext3    7.9G  6.3G  1.2G  84% /source
/dev/sdb1  fuseblk    299G  266G   33G  90% /data/
```

需要恢复的分区是`/dev/sda8`，挂载点是`/source`。

先将此分区卸载，并在`/data`分区建立一个用于存储备份数据的文件夹。

```Shell
$ umount -v /source
$ mkdir -p /data/recovery
```

现在轮到主角登场了，先去下载一份 ext3grep 的源码，并安装：

```Shell
$ cd /data/recovery
#此链接地址以官网最新版本为准
$ wget http://ext3grep.googlecode.com/files/ext3grep-0.10.2.tar.gz
$ tar xfz ext3grep-0.10.2.tar.gz
$ cd ext3grep-0.10.2
$ ./configure --prefix=/data/recovery
$ make && make install
```

接下来就进入正式的恢复工作，先对需要恢复的磁盘进行扫描。

```Shell
$ cd /data/recovery
#建议使用 nohup 和 &，因为如果分区很大的话耗时比较长
$ nohup /data/recovery/bin/ext3grep /dev/sda8 --ls --inode 2 &
```

扫描完毕后，`/data/recovery`中会出现两个分别名为`c0d2.ext3grep.stage1`和`c0d2.ext3grep.stage2`的文件。前者可以直接忽略，后者里面保存着可以被恢复备份的文件名。

由于我需要备份的文件很多，几十个 G，就用下面这个命令进行全部恢复。

```Shell
$ cd /data/recovery'
#建议使用 nohup 和 &，因为如果分区很大的话耗时比较长
$ nohup /data/recovery/ext3grep/bin/ext3grep /dev/sda8 --restore-all &
```

需要注意的是，`restore-all`参数会将整个磁盘所有文件（已删除可恢复的文件和未被删除还存在的文件）进行恢复和备份处理，所以请确认你的存放恢复文件的分区有足够的空间。

如果仅仅是恢复几个文件的话，建议使用`restore-file`参数备份的文件会存放在工作目录的名为`RESTORED_FILES`的文件夹里，本文中就是`cd /data/recovery/RESTORED_FILES`。

最后补充一句话：慎用`rm -rf`。
