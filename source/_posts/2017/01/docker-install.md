---
title: CentOS-6.8安装Docker
date: 2017-01-19 00:09:20
tags:
- 工具
categories:
- 工具
---

[Docker](https://www.docker.com/) 使用 Go 语言开发实现，基于 Linux 内核的 cgroup、namespace，以及 AUFS 类的 Union FS 等技术，对进程进行封装隔离，属于操作系统层面的 **虚拟化技术**，也被称之为容器。Docker 在容器的基础上，进行了进一步的封装，极大的简化了容器的创建和维护，使得 Docker 技术比虚拟机技术更为轻便、快捷。
![](//img3.fanhaobai.com/2017/01/docker-install/kiHBGrNdKNv5n0xKauf6mjKK.png)<!--more-->

下面就以 **CentOS 6.8** 为例，简述 Docker 的安装，[原文见这里](https://yq.aliyun.com/articles/68321?spm=5176.100240.searchblog.165.c9fyZL) 。

# 安装环境准备

Docker 使用 EPEL 发布，RHEL 系的 OS 在安装前，要确保已经持有 EPEL 仓库，否则先检查 OS 的版本，然后安装相应的 EPEL 包。

## 查看系统版本

安装 Docker 前，先查看系统的版本信息。

```Shell
$ cat /etc/redhat-release
CentOS release 6.8 (Final)
```

## 安装EPEL

OS 版本为 CentOS 6.8，而 Docker 官方要求最低支持 CentOS 7，这里通过安装 EPEL 解决。

```Shell
$ sudo rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
$ sudo yum update -y
```

# 安装Docker

如果服务器内存较小，可划分 1G 的 [swap](http://smilejay.com/2012/09/new-or-add-swap) 分区来缓解内存压力。

## 手动安装

可以使用脚本`curl -sSL https://get.docker.com/ | sh`自动安装 Docker 。但这里，使用 rpm 安装神器的 yum 来完成 Docker 的安装。

```Shell
$ sudo yum -y install docker-io
```

安装成功后，查看 Docker 版本信息：

```Shell
$ docker version
Client version: 1.7.1
Client API version: 1.19
Go version (client): go1.4.2
Git commit (client): 786b29d/1.7.1
```

## 建立用户组

默认情况下，docker 命令会使用 Unix socket 与 Docker 引擎通讯。而只有 root 用户和 docker 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用root 用户。因此，更好地做法是将需要 **使用 Docker 的用户** 加入 **docker 用户组**。

首先，建立 docker 用户组：

```Shell
$ groupadd docker
```

再创建需要使用 Docker 的用户，并将其加入 docker 用户组：

```Shell
$ useradd docker -g docker
$ passwd docker
```

## 启动Docker引擎

一切就绪后，以 root 用户启动 Docker  引擎：

```Shell
$ service docker start
```

提示：如下命令分别为 **停止** 和 **重启** Docker 引擎。

```Shell
$ service docker stop
$ service docker restart
```

## Docker命令

使用 docker 命令可以查看 Docker 所有的命令，列表如下：

```Shell
attach    Attach to a running container                 # 当前 shell 下 attach 连接指定运行镜像
build     Build an image from a Dockerfile              # 通过 Dockerfile 定制镜像
commit    Create a new image from a container changes   # 提交当前容器为新的镜像
cp        Copy files/folders from the containers filesystem to the host path   # 从容器中拷贝指定文件或者目录到宿主机中
create    Create a new container                        # 创建一个新的容器，同 run，但不启动容器
diff      Inspect changes on a container filesystem     # 查看 docker 容器变化
events    Get real time events from the server          # 从 docker 服务获取容器实时事件
exec      Run a command in an existing container        # 在已存在的容器上运行命令
export    Stream the contents of a container as a tar archive   
# 导出容器的内容流作为一个 tar 归档文件[对应 import ]
history   Show the history of an image                  # 展示一个镜像形成历史
images    List images                                   # 列出系统当前镜像
import    Create a new filesystem image from the contents of a tarball    # 从tar包中的内容创建一个新的文件系统映像[对应 export]
info      Display system-wide information               # 显示系统相关信息
inspect   Return low-level information on a container   # 查看容器详细信息
kill      Kill a running container                      # kill 指定 docker 容器
load      Load an image from a tar archive              # 从一个 tar 包中加载一个镜像[对应 save]
login     Register or Login to the docker registry server    
# 注册或者登陆一个 docker 源服务器
logout    Log out from a Docker registry server        # 从当前 Docker registry 退出
logs      Fetch the logs of a container                 # 输出当前容器日志信息
port      Lookup the public-facing port which is NAT-ed to PRIVATE_PORT    # 查看映射端口对应的容器内部源端口
pause     Pause all processes within a container        # 暂停容器
ps        List containers                               # 列出容器列表
pull      Pull an image or a repository from the docker registry server   # 从docker镜像源服务器拉取指定镜像或者库镜像
push      Push an image or a repository to the docker registry server    # 推送指定镜像或者库镜像至docker源服务器
restart   Restart a running container                   # 重启运行的容器
rm        Remove one or more containers                 # 移除一个或者多个容器
rmi       Remove one or more images                     # 移除一个或多个镜像[无容器使用该镜像才可删除，否则需删除相关容器才可继续或 -f 强制删除]
run       Run a command in a new container              # 创建一个新的容器并运行一个命令
save      Save an image to a tar archive                # 保存一个镜像为一个 tar 包[对应 load]
search    Search for an image on the Docker Hub         # 在 docker hub 中搜索镜像
start     Start a stopped containers                    # 启动容器
stop      Stop a running containers                     # 停止容器
tag       Tag an image into a repository                # 给源中镜像打标签
top       Lookup the running processes of a container   # 查看容器中运行的进程信息
unpause   Unpause a paused container                    # 取消暂停容器
version   Show the docker version information           # 查看 docker 版本号
wait      Block until a container stops, then print its exit code   
# 截取容器停止时的退出状态值
```

# 镜像加速器

国内访问 Docker Hub 有时会遇到困难，此时可以配置镜像加速器。

## 加速器地址

国内很多云服务商都提供了加速器服务，例如：

* [阿里云加速器](https://cr.console.aliyun.com/#/accelerator)
* [DaoCloud加速器](https://www.daocloud.io/mirror#accelerator-doc)
* [灵雀云加速器](http://docs.alauda.cn/feature/accelerator.html)

从上述服务商处注册用户并申请加速器后，会获得如`https://jxus37ad.mirror.aliyuncs.com`这样的地址。我们需要将其配置给 Docker 引擎。

## 加速器配置

CentOS 7 下镜像加速器的配置，[见官方文档](https://yeasy.gitbooks.io/docker_practice/install/mirror.html) 。这里主要介绍CentOS 6 下的配置。

CentOS 6 下配置 Docker 镜像加速器，是通过编辑 **`/etc/sysconfig/docker`** 配置文件来完成，即将配置项`other_args`修改为：

```Shell
other_args="--registry-mirror=https://jxus37ad.mirror.aliyuncs.com"    
# your address
```

然后通过下述命令，重启`docker daemon`：

```Shell
$ service docker restart
```

## 检查加速器

Linux 系统下配置完 **加速器需要检查是否生效**，执行以下命令：

```Shell
$ ps -ef | grep docker
```

如果从结果中看到了配置的`--registry-mirror`参数说明配置成功，如下所示：

```Shell
root  20728 1  0 23:27 pts/1  00:00:00 /usr/bin/docker -d --registry-mirror=https://2ykl5eof.mirror.aliyuncs.com
```

# 运行镜像

启动 Docker 引擎后，用 docker 用户登录系统获取并运行镜像。[Docker Hub](https://hub.docker.com/explore) 上有大量的高质量的镜像可以用，这里就以 MongoDB 来说明。

## 获取镜像

从 Docker Registry 获取镜像的命令是`docker pull`。其命令格式为：

```Shell
$ docker pull [选项] [Docker Registry地址]<仓库名>:<标签>
```

获取 MongoDB 命令为：

```Shell
$ docker pull mongo
```

想要列出 **本地镜像**，可以使用`docker images`命令：

```Shell
$ docker images
REPOSITORY  TAG      IMAGE ID     CREATED    VIRTUAL SIZE
mongo    latest    35dc92f524d0   4 days ago     402 MB
```

## 新建并启动容器

使用命令`docker run`，即可通过新获取的镜像新建和启动一个容器了。如下：

```Shell
$ docker run --name mongodb -p 27017:27017 -d mongo
```

参数说明：

* --**name**：指定容器名称；
* --**restart**：容器是否进行重启，当设置为 always 时，可以在 docker 启动后自动启动容器
* -**p**：指定容器监听端口映射到本地宿主端口号；
* -**d**：守护态运行容器；
* -**v**：创建一个数据卷并挂载到容器里；

## 查看所有容器

用`docker ps`命令可以查看已经创建的容器，使用如下命令可以查看 **所有已经创建** 的包括 **终止状态** 的 **容器**：

```Shell
$ docker ps -a
CONTAINER ID  IMAGE   COMMAND          CREATED       STATUS         PORTS                   NAMES
8dbabb08f3d5  mongo  "/entrypoint.sh mong 10 hours ago Up 19 minutes  0.0.0.0:27017->27017/tcp  mongodb
```

查看宿主端口监听状态：

```Shell
$ netstat -tunpl
Proto Recv-Q Send-Q  Local Address Foreign Address State  PID/Program name         
tcp   0       0      0.0.0.0:27017   0.0.0.0:*    LISTEN  20997/docker-proxy 
```

此时，就表示 MongoDB 已经在 Docker 中成功运行了。


> 文档：[Docker —— 从入门到实践](https://yeasy.gitbooks.io/docker_practice/content/container/rm.html)

