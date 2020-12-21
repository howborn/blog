---
title: CentOS6.5升级GCC-4.8
date: 2016-12-08 01:18:46
tags:
- Linux
categories:
- Linux
---

CenOS6.5 系统中默认带有 gcc4.4.7 版本，在编译一些库时无法编译成功，所以需要进行升级。但由于 CentOS6.5 系统源中提供的 gcc 最新版本为 4.4.7，所以不能直接使用`yum upgrade gcc`命令完成自动完成更新。如下采用源码编译安装。<!--more-->

# 安装依赖

```Shell
$ yum install -y gcc texinfo-tex flex zip libgcc.i686 glibc-devel.i686 gcc-c++ gcc
```

# 编译

编译前准备。

```Shell
$ wget http://gcc.skazkaforyou.com/releases/gcc-4.8.2/gcc-4.8.2.tar.gz
$ tar zxvf ./gcc-4.8.2.tar.gz
```

下载一些必备的依赖包。

```Shell
$ ./contrib/download_prerequisites
```

创建一个供编译后的程序文件存放目录：

```Shell
$ mkdir /usr/src/gcc-make
$ cd /usr/src/gcc-make/
```

生成编译文件：

```Shell
$ /usr/src/gcc-4.8.2/configure --enable-checking=release --enable-languages=c,c++ --disable-multilib
```

执行编译：

```Shell
$ make
```

1） 可能错误1

```Shell
configure: error: C++ compiler missing or inoperational         
make[2]: *** [configure-stage1-libcpp] Error 1 
make[2]: Leaving directory /usr/local/gcc-make
make[1]: *** [stage1-bubble] Error 2
make[1]: Leaving directory /usr/local/gcc-make
```

出现该问题，请先确认所需要的依赖都全部安装，否则可能是在编译 gcc 时，由于内存不足导致的中途报错退出，可划分 1G 的 [swap](http://smilejay.com/2012/09/new-or-add-swap) 分区来解决问题。 

2） 可能错误2

```
error: Building GCC requires GMP 4.2+, MPFR 2.4.0+ and MPC 0.8.0+.
```

则需要执行：

```Shell
$ yum install gmp-devel mpfr-devel libmpc-devel
```

# 安装

```Shell
$ make install
```

查看 gcc 版本，检测是否安装成功。  

```Shell
$ gcc -v
```

# 替换系统低版本gcc

系统自带低版本 gcc 文件位置为`/usr/bin/gcc`和`/usr/bin/lib`，此时需要将这两个部分删掉，或者后缀加上`.bak`，然后通过建立软连接的方式替换系统默认位置的 gcc、c++、g++ 文件。 

```Shell
$ mv /usr/bin/c++ /usr/bin/c++.bak
$ ln -s /usr/local/bin/c++ /usr/bin/c++
$ mv ./g++ ./g++.bak
$ ln -s /usr/local/bin/g++ /usr/bin/g++
$ mv ./gcc ./gcc.bak 
$ ln -s /usr/local/bin/gcc /usr/bin/gcc
```

# 替换系统gcc动态链接库

```Shell
$ strings /usr/lib64/libstdc++.so.6 | grep GLIBC
```

输出结果如下, 可以看出，gcc 的动态库还是处于旧版本，说明生成的动态库没有替换旧版本 gcc 的动态库。 

```Shell
GLIBCXX_3.4
GLIBCXX_3.4.1
GLIBCXX_3.4.2
GLIBCXX_3.4.3
GLIBCXX_3.4.4
GLIBCXX_3.4.5
GLIBCXX_3.4.6
GLIBCXX_3.4.7
GLIBCXX_3.4.8
GLIBCXX_3.4.9
GLIBCXX_3.4.10
GLIBCXX_3.4.11
GLIBCXX_3.4.12
GLIBCXX_3.4.13
```

查找编译 gcc 时生成的最新动态库。

```Shell
$ find / -name "libstdc++.so*"
```

列出了新版的 gcc 动态链接库位置。

```Shell
/usr/local/lib64/libstdc++.so.6.0.18
```

将上面的最新动态库`libstdc++.so.6.0.18`复制到`/usr/lib64`目录下，并重新建立软连接。

```Shell
$ cp /usr/local/lib64/libstdc++.so.6.0.18 /usr/lib64 
$ cd /usr/lib64/
$ rm -f ./libstdc++.so.6
$ ln -s libstdc++.so.6.0.18 libstdc++.so.6
```

再次查看 gcc 版本，以下结果表示动态库升级完成。

```Shell
...
GLIBCXX_3.4.13 
GLIBCXX_3.4.14
GLIBCXX_3.4.15  
GLIBCXX_3.4.16  
GLIBCXX_3.4.17 
GLIBCXX_3.4.18  
GLIBCXX_3.4.19
```