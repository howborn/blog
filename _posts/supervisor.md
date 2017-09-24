---
title: 使用Supervisord管理进程
date: 2017-09-23 17:56:57
tags:
- Supervisor
categories:
- 工具
---

[Supervisor](http://supervisord.org) 是一款使用 Python 开发的非常优秀的进程管理工具。它可以在类 UNIX 系统上让用户精确地监视与控制多组指定数量的服务进程。当监控的服务进程意外退出时，会尝试自动启动这些服务，当然它也支持 HTTP 协议来监控服务进程状态。

![](https://www.fanhaobai.com/2017/09/supervisord/d42decd3-2342-4e8f-a34f-48b47fc6e557.png)<!--more-->

## 安装

Supervisor [官方](http://www.supervisord.org/installing.html) 提供的安装方式较多，这里采用 pip 方式安装。

### 安装pip

```Bash
$ yum install python-pip
# 升级pip
$ pip install --upgrade pip
$ pip -V
pip 9.0.1
```

### 安装Supervisor

通过 pip 安装 Supervisor：

```Bash
$ pip install supervisor
Successfully installed supervisor-3.3.3
```

安装 Supervisor 后，会出现 supervisorctl 和 supervisord 两个程序，其中 supervisorctl 为服务监控终端，而 supervisord 才是所有监控服务的大脑。查看 supervisord 是否安装成功：

```Bash
$ supervisord -v
3.3.3
```

### 开机启动

将 supervisord 配置成开机启动服务，下载官方 [init 脚本](https://github.com/Supervisor/initscripts/blob/master/redhat-init-mingalevme)。

修改关键路径配置：

```Bash
PIDFILE=/var/run/supervisord.pid
LOCKFILE=/var/lock/subsys/supervisord
OPTIONS="-c /etc/supervisord.conf"
```

移到该文件到`/etc/init.d`目录下，并重命名为 supervisor，添加可执行权限：

```Bash
$ chmod 777 /etc/init.d/supervisor
```

配置成开机启动服务：

```Bash
$ chkconfig supervisor on
$ chkconfig --list | grep "supervisor"
supervisor  0:off 1:off 2:on 3:on 4:on 5:on 6:off
```

## 配置

### 生成配置文件

Supervisord 安装后，需要使用如下命令生成配置文件。

```Bash
$ mkdir /etc/supervisor
$ echo_supervisord_conf > /etc/supervisor/supervisord.conf
```

### 主配置部分

`supervisord.conf`的主配置部分说明：

```Ini
[unix_http_server]
file=/tmp/supervisor.sock   ; socket文件的路径
;chmod=0700                 ; socket文件权限
;chown=nobody:nogroup       ; socket文件用户和用户组
;username=user              ; 连接时认证的用户名
;password=123               ; 连接时认证的密码

[inet_http_server]          ; 监听TCP
port=127.0.0.1:9001         ; 监听ip和端口
username=user               ; 连接时认证的用户名
password=123                ; 连接时认证的密码

[supervisord]
logfile=/var/log/supervisord.log ; log目录
logfile_maxbytes=50MB        ; log文件最大空间
logfile_backups=10           ; log文件保持的数量
loglevel=info                ; log级别
pidfile=/var/run/supervisord.pid
nodaemon=false               ; 是否非守护进程态运行
minfds=1024                  ; 系统空闲的最少文件描述符
minprocs=200                 ; 可用的最小进程描述符
;umask=022                   ; 进程创建文件的掩码
;identifier=supervisor       ; supervisord标识符
;directory=/tmp              ; 启动前切换到的目录
;nocleanup=true              ; 启动前是否清除子进程的日志文件
;childlogdir=/tmp            ; AUTO模式，子进程日志路径
;environment=KEY="value"     ; 设置环境变量

[rpcinterface:supervisor]    ; XML_RPC配置
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock ; 连接的socket路径
;username=chris               ; 用户名
;password=123                 ; 密码
prompt=mysupervisor           ; 输入用户名和密码时的提示符
;history_file=~/.sc_history   ; 历史操作记录存储路径

[include]                     ; 包含文件，将每个进程配置为一个文件并包含
files = /etc/supervisor/*.ini ; 多个进程的配置文件
```

这部分我们不需要做太多的配置修改，如果需要开启 WEB 终端监控，则需要配置并开启 inet_http_server 项。

### 进程配置部分

Supervisor 需管理的进程服务配置，示例如下：

```Ini
[program:work]                      ; 服务名，例如work
command=php -r "sleep(10);exit(1);" ; 带有参数的可执行命令
process_name=%(process_num)s        ; 进程名，当numprocs>1时，需包含%(process_num)s
numprocs=2                          ; 启动进程的数目数
;directory=/tmp                     ; 运行前切换到该目录
;umask=022                          ; 进程掩码
;priority=999                       ; 子进程启动关闭优先级
autostart=true                      ; 子进程是否被自动启动
startsecs=1                         ; 成功启动几秒后则认为成功启动
;startretries=3                     ; 子进程启动失败后，最大尝试启动的次数
autorestart=unexpected            ; 子进程意外退出后自动重启的选项，false, unexpected, true。unexpected表示不在exitcodes列表时重启
exitcodes=0,2                     ; 期待的子程序退出码
;stopsignal=QUIT                  ; 进程停止信号，可以为TERM,HUP,INT,QUIT,KILL,USR1,or USR2等信号，默认为TERM
;stopwaitsecs=10                  ; 发送停止信号后等待的最大时间
;stopasgroup=false                ; 是否向子进程组发送停止信号
;killasgroup=false                ; 是否向子进程组发送kill信号
;redirect_stderr=true             ; 是否重定向日志到标准输出
stdout_logfile=/data/logs/work.log ; 进程的stdout的日志路径
;stdout_logfile_maxbytes=1MB      ; 日志文件最大大小
;stdout_logfile_backups=10
;stdout_capture_maxbytes=1MB
;stderr_logfile=/a/path           ; stderr的日志路径
;stderr_logfile_maxbytes=1MB
;stderr_logfile_backups=10
;stderr_capture_maxbytes=1MB
;environment=A="1",B="2"          ; 子进程的环境变量
;serverurl=AUTO                   ; 子进程的环境变量SUPERVISOR_SERVER_URL 
```

通常将每个进程的配置信息配置成独立文件``，并通过 include 模块包含，这样方便修改和管理配置文件。

## 启动

配置完成后，启动 supervisord 守护服务：

```Bash
$ supervisord -c /etc/supervisor/supervisord.conf
```

常用的命令参数说明：

* -c：指定配置文件路径
* -n：是否非守护态运行
* -l：日志文件目录
* -i：唯一标识

查看 supervisord 启动情况：

```Bash
$ ps -ef | grep "supervisor"
root  24901  1  0 Sep23 ? 00:00:30 /usr/bin/python /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
$ netstat -tunpl
tcp 0 0 127.0.0.1:9001  0.0.0.0:*  LISTEN  24901/python
```

## 监控进程

Supervisor 提供了多种监控服务的方式，包括 supervisorctl 命令行终端、Web 端、XML_RPC 接口多种方式。

### 命令终端

直接使用 supervisorctl 即可在命令行终端查看所有服务的情况，如下：

```Bash
$ supervisorctl 
work:0      RUNNING   pid 31313, uptime 0:00:07
work:1      RUNNING   pid 31318, uptime 0:00:06
# -u 用户名 -p 密码
```

supervisorctl 常用命令列表如下；

* [status]()：查看服务状态
* [update]()：重新加载配置文件
* [restart]()：重新启动服务
* [stop]()：停止服务
* [pid]()：查看某服务的 pid
* [tail]()：输出最新的 log 信息
* [shutdown]()：关闭 supervisord 服务

### Web

在配置中开启 inet_http_server 后，即可通过 Web 界面便捷地监控进程服务了。

![](https://www.fanhaobai.com/2017/09/supervisord/9d28cc24-a0d8-11e7-abc4-cec278b6b50a.png)