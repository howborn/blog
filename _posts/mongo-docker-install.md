---
title: MongoDB在Docker中的部署
date: 2017-01-20 18:03:33
tags:
- MongoDB
- Linux
categories:
- DB
- MongoDB
---

MongoDB 作为 [NOSQL](http://baike.baidu.com/link?url=NTbBo0uTFuveD-bigzlZ_LODG6-c9jkat2nOgPV8u4A0LA_84txdJy0YgcBgnE5TtIPrlKVHFW5hHoVklxcb0K) 的典型代表之一，它是非关系数据库当中最像关系数据库的。并且支持类似于面向对象的查询语言，所以几乎可以实现类似关系数据库单表查询的绝大部分功能，同时还支持索引。因此，在大数据的时代，大型 Web 应用难免会使用到 MongoDB 作为大数据存储服务。这里记录我在开发环境下，在 Docker 中部署 MongoDB 的过程。

{% asset_img Z6lofG8iRih1k6pKqsMPp9sn.png %}<!--more-->

由于 Docker 不受宿主环境影响的特性，所以部署 MongoDB 较容易。 Docker 的安装，[见这里](https://www.fanhaobai.com/2017/01/docker-install.html)。

# 获取镜像

这里使用 Docker 官方库提供的 MongoDB 镜像安装， MongoDB 镜像仓库地址，[见这里](https://hub.docker.com/_/mongo)。

所以执行以下命令，就可以获取 MongoDB 的镜像，默认获取最新版本镜像。

```Bash
$ docker pull mongo
```

查看新获取的 MongoDB 镜像信息，如下：

```Bash
$ docker images mongo
REPOSITORY    TAG      IMAGE ID      CREATED        VIRTUAL SIZE
mongo         latest   50fa1fa47718  11 hours ago   402 MB
```

# 启动容器

该镜像中默认会在`27017`端口启动 MongoDB，当然这里需要开启端口映射，使 MongoDB 容器对外网访问开放。

```Bash
$ docker run --name mongo -v /home/docker/mongo:/data/db -p 27017:27017 -d mongo
```

参数说明：

* -**v**：创建一个位置 /home/docker/mongo数据卷并挂载到容器的/data/db位置
* -**p**：指定容器27017端口映射到本地宿主27017端口，以便mongo裸露在外网 
* -**d**：守护态运行mongo


查看启动的容器，如果出现如下信息，则说明 MongoDB 容器启动成功。

```Bash
$ docker ps -a
CONTAINER ID   IMAGE   COMMAND          CREATED         STATUS        PORTS                      NAMES
d83cab80f13d   mongo   "/entrypoint.sh  3 seconds ago   Up 2 seconds   0.0.0.0:27017->27017/tcp   mongo
```

使用可视化连接工具  [Robomongo](https://robomongo.org/) 进行连接测试，测试成功如下图所示：

{% asset_img Z6lofG8iRih1k6pKqsMPp9sn.png %}

到这里，Docker 环境下 MongoDB 已经部署完毕，但是现在 MongoDB 数据库处于极度危险的状态，因为没有做 auth 认证，不久之后就会发现 MongoDB 数据库被人删了，并多了一些恐吓信息，这就是最近闹的比较大的 [MongoDB赎金事件](http://www.mongoing.com/archives/3738?utm_source=tuicool&utm_medium=referral)。

所以 MongoDB 服务器必须要做 auth 认证。

# 增加权限认证

使用以下命令进入正在运行的 MongoDB 容器中，后续命令都是在容器中执行，除非特别说明外。

```Bash
$ docker exec -it mongo /bin/bash
```

## 增加用户

在容器中运行如下命令连接 MongoDB 数据库，并选择名为 admin 的数据库：

```Bash
$ mongo
$ use admin
```

创建一个管理员账户：

```Bash
$ db.createUser({user:"admin",pwd:"admin",roles: [{role: "root",db: "admin"}]})
```

查看 admin 数据库中多了`system.users`集合，其中添加了如下 **文档** 信息：

```Json
{
    "_id" : "admin.admin",
    "user" : "admin",
    "db" : "admin",
    "credentials" : {
        "SCRAM-SHA-1" : {
            "iterationCount" : 10000,
            "salt" : "N1nx+GL6a1HcWfiDMi0Siw==",
            "storedKey" : "PbMi21yI1+Gpvh2aGUioEWESqvC=",
            "serverKey" : "1r2tSEsdH2T4z5qmSGE9ONeRSEk="
        }
    },
    "roles" : [ 
        {
            "role" : "root",
            "db" : "admin"
        }
    ]
}
```

测试新添加管理员账户的认证情况，如果返回 1 ，则表示认证成功。

```Bash
$ db.auth('admin','admin')
```

## 开启认证

这里需要修改容器根目录下的`entrypoint.sh`文件，由于无法直接从容器中修改，所以复制该文件到挂载的数据卷中。

```Bash
$ cp /entrypoint.sh /data/db
```

由于启动 MongoDB 容器时，通过参数`-v`挂载了数据卷，所以将`entrypoint.sh`文件复制到`/data/db`下，实际是复制文件到宿主环境的`/home/docker/mongo`目录下。

在 **宿主环境** 下执行：

```Bash
$ vim /home/docker/mongo/entrypoint.sh
```

在`exec gosu mongodb "$@"`之前增加一行内容**`set -- "$@" "--auth"`**。由于是在数据卷位置修改，所以可以在容器中`/data/db`目录使用`# cat /data/db/entrypoint.sh`命令查看`entrypoint.sh`修改部分：

```Shell
if [[ "$1" == mongo* ]] && [ "$(id -u)" = '0' ]; then
    if [ "$1" = 'mongod' ]; then
	chown -R mongodb /data/configdb /data/db
    fi
    set -- "$@" "--auth"                                       #开启auth认证
    exec gosu mongodb "$BASH_SOURCE" "$@"
fi
```

将修改应用到容器中。首先，直接替换容器根目录下`entrypoint.sh`文件：

```Bash
$ cp -f /data/db/entrypoint.sh /
$ exit
```

接着，使用命令`docker restart mongo`重启容器即可。

最后，通过 **用户名** 和 **密码** 使用 Robomongo 连接测试，如下图表示修改成功。

{% asset_img xtY6PnmbCYZcPWY0gw6_rDFq.png %}

# 更新镜像

为了便于后续的持续部署，所以需要将修改后的容器使用 commit 命令构建成新的镜像，后续只需部署新构建的镜像即可。

在 **宿主环境** 下执行：

```Bash
$ docker diff mongo                              #查看容器所修改内容
$ docker commit -a "fanhaobai" -m "add auth" mongo mongo:latest
$ docker images mongo
```

# 总结

到这里，Docker 环境下部署 MongoDB 就结束了。因为使用 Docker 部署，所以 MongoDB 安装过程就比较简单，且持续部署也极为方便，而增加 auth 认证过程相对比较复杂。
