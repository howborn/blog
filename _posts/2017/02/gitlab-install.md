---
title: 搭建本地GitLab仓库
date: 2017-02-24 23:23:32
tags: 
- 工具
categories:
- 工具
---

[GitLab](https://www.gitlab.com) 是一个用于仓库管理系统的开源项目，非常适合在团队内部使用。很多公司为了代码安全，不会选择在公网代码管理仓库中托管代码，而会选择在公司内网服务器自主搭建 GitLab 服务，以便开发团队协作使用，这里记录我的搭建过程。

![预览图](https://img.fanhaobai.com/2017/02/gitlab-install/f8facee3-ddff-4d5a-a6a6-904951891ad5.png)<!--more-->

系统环境为 CentOS 6.8，如果系统版本较低，请先使用命令`sudo yum -y update`进行升级。这里参考 Github [官方安装文档](https://github.com/gitlabhq/gitlab-recipes/tree/master/install/centos)，可以直接移步到这里。

# 安装前准备

## 添加EPEL存储库

EPEL（Extra Packages for Enterprise Linux），这个软件仓库提供了许多有价值的软件，对 RHEL 标准 yum 源是一个很好的补充，而且完全免费使用。

从 [fedoraproject](https://fedoraproject.org/keys) 下载 EPEL 存储库的 GPG 密钥，并将其安装在系统上：

```Bash
$ wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 https://getfedora.org/static/0608B895.txt
$ rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
```

验证密钥是否成功安装：

```Bash
$ rpm -qa gpg*
gpg-pubkey-c105b9de-4e0fd3a3
```

现在安装`epel-release-6-8.noarch`软件包，这将在系统上启用 EPEL 存储库：

```Bash
$ rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
```

## 添加Remi的RPM存储库

Remi 的 RPM 存储库是 Centos / RHEL 的非官方存储库，提供一些软件的最新版本。我们这里利用 Remi 的 RPM 存储库获取最新版本的 Redis 。

下载 Remi 的存储库的 GPG 密钥，并将其安装在系统上：

```Bash
$ wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-remi http://rpms.famillecollet.com/RPM-GPG-KEY-remi
$ rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi
```

验证密钥是否已成功安装：

```Bash
$ rpm -qa gpg*
gpg-pubkey-00f97f56-467e318a
gpg-pubkey-c105b9de-4e0fd3a3
```

现在安装`remi-release-6`软件包，这将在系统上启用 remi-safe 存储库：

```Bash
$ rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
```

验证 EPEL 和 remi-safe 存储库是否已启用，如下所示：

```Bash
$ yum repolist
仓库标识           仓库名称                              状态
base              CentOS-6 - Base                      5,062
epel              Extra Packages                       9,994
extras            CentOS-6 - Extras                    39
remi-safe         Safe Remi's RPM repository           115
updates           CentOS-6 - Updates                   644
repolist: 15,854
```

如果看不到它们列出，请使用 folowing 命令（从yum-utils包）启用它们：

```Bash
$ yum-config-manager --enable epel --enable remi-safe
```

## 安装GitLab所需的工具

```Bash
$ yum -y groupinstall 'Development Tools'
$ yum -y install readline readline-devel ncurses-devel gdbm-devel glibc-devel tcl-devel openssl-devel curl-devel expat-devel db4-devel byacc sqlite-devel libyaml libyaml-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libicu libicu-devel system-config-firewall-tui redis sudo wget crontabs logwatch logrotate perl-Time-HiRes git cmake libcom_err-devel.i686 libcom_err-devel.x86_64 nodejs        # 自定义选择安装，我系统中已经安装了git、redis、nodejs，这里可以不安装
$ yum -y install python-docutils
```

## 安装邮件服务器

为了接收邮件通知，请确保安装邮件服务器。推荐的是 postfix，安装如下：

```Bash
$ yum -y install postfix
```

## 源码安装Git

必须确保 Git 的版本是 2.7.4 或更高版本。

```Bash
$ git --version
```

如果版本低于 2.7.4，首先删除 Git：

```Bash
$ yum -y remove git
```

先安装 Git 编译的必备依赖：

```Bash
$ yum install zlib-devel perl-CPAN gettext curl-devel expat-devel gettext-devel openssl-devel
```

下载并安装 Git：

```Bash
$ mkdir /usr/src && cd /usr/src
$ curl --progress https://www.kernel.org/pub/software/scm/git/git-2.9.0.tar.gz | tar xz
$ cd git-2.9.0
$ ./configure
$ make
$ make prefix=/usr/local install
```

确保 Git 在系统的环境变量 $PATH 中，并升级成功。

```Bash
$ which git
$ git --version
git version 2.9.0
```

注意：可能需要注销并重新登录后，环境变量 $PATH 才能生效。

# 安装Ruby

如果系统存在 Ruby 并且版本低于 1.8，则需要使用命令`yum remove ruby`删除旧的 Ruby 1.8。GitLab只支持 Ruby 2.1 版本系列。

下载 Ruby 并编译安装：

```Bash
$ cd /usr/src
$ curl --progress https://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.9.tar.gz | tar xz
$ cd ruby-2.1.9
$ ./configure --disable-install-rdoc
$ make
$ make prefix=/usr/local install
```

安装 Bundler Gem：

```Bash
$ gem install bundler --no-doc
```

查看 Ruby 安装是否成功安装。

```Bash
$ ruby -v
```

# 安装Go

从 GitLab 8.0 开始，Git HTTP 请求由 gitlab-workhorse（以前称为gitlab-git-http-server）处理。这是一个在 Go 写的小守护进程。要安装 gitlab-workhorse，我们需要一个 Go 编译器。

```Bash
$ yum install golang golang-bin golang-src
```

#  创建系统用户

`git`为 Gitlab 创建一个用户：

```Bash
$ adduser --system --shell /bin/bash --comment 'GitLab' --create-home --home-dir /home/git/ git
```

重要：为了包括`/usr/local/bin`到`git`用户的`PATH`，一种方法是编辑 sudoers 文件。作为根运行：

```Bash
$ visudo
```

然后将该行：

```Bash
Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin
```

附加`/usr/local/bin`，更改为：

```Bash
Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
```

# 安装数据库

Gitlab 支持 PostgreSQL 和 MySQL 两种数据库，这里只介绍 MySQL的相关配置。

使用`yum`安装 MySQL：

```Bash
$ yum install -y mysql-server mysql-devel
```

将`mysqld`添加到`service `，并配置开机自启。

```Bash
$ chkconfig mysqld on
$ service mysqld start
```

对 MySQL 进行初始化设置：

```Bash
$ mysql_secure_installation
```

连接 MySQL 服务器，默认密码为空：

```Bash
$ mysql -u root -p
```

创建一个用于 GitLab  使用的数据库的用户，`your password`替换成需要设置成的密码。

```Mysql
mysql> CREATE USER 'git'@'localhost' IDENTIFIED BY 'your password';
```

确保数据库存储引擎为 InnoDB，如果不是则修改：

```Mysql
mysql> SET storage_engine=INNODB;
```

创建 GitLab 需要使用的数据库：

```Mysql
mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
```

给`git`用户分配新创建数据库的相关权限：

```Mysql
mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES, REFERENCES ON `gitlabhq_production`.* TO 'git'@'localhost';
```

退出连接终端并重新使用`git`用户登录 MySQL 服务器：

```Mysql
mysql> show databases;

+---------------------+
| Database            |
+---------------------+
| information_schema  |
| gitlabhq_production |
+---------------------+
```

# 安装Redis

GitLab 要求 Redis 版本不能低于 2.8。

如果系统已经安装 Redis 且版本低于 2.8，则需卸载：

```Bash
$ yum remove redis
```

从 Remi 的 RPM 存储库获取 Redis 安装包并安装：

```Bash
$ yum --enablerepo=remi,remi-test install redis
```

将 Redis 设置为开机自启：

```Bash
$ chkconfig redis on
```

创建 Redis 配置文件：

```Bash
$ cp /etc/redis.conf /etc/redis.conf.orig
```

对配置文件`/etc/redis.conf`作如下修改：

1） 禁止 Redis 侦听 TCP 协议

```Bash
port 0
```

2） 配置CentOS下Redis套接字的默认路径

```Bash
unixsocket /var/run/redis/redis.sock
unixsocketperm 0770
```

创建包含套接字的目录：

```Bash
$ mkdir /var/run/redis
$ chown redis:redis /var/run/redis
$ chmod 755 /var/run/redis
```

将`git`用户添加到`redis`组：

```Bash
$ usermod -aG redis git
```

重启Redis服务，使配置生效。

```Bash
$ service redis restart
```

# 安装GitLab

这里将 GitLab 安装在`/home/git`目录下：

```Bash
$ cd /home/git
```

## 克隆源

```Bash
$ sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 8-9-stable gitlab
```

## 配置GitLab

```Bash
$ cd /home/git/gitlab
# 配置文件
$ sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml
$ sudo -u git -H editor config/gitlab.yml

# 配置密钥文件
$ sudo -u git -H cp config/secrets.yml.example config/secrets.yml
$ sudo -u git -H chmod 0600 config/secrets.yml

# 更改 log/ 和 tmp/ 目录权限，使 GitLab 具有写权限
$ sudo chown -R git log/
$ sudo chown -R git tmp/
$ sudo chmod -R u+rwX,go-w log/
$ sudo chmod -R u+rwX tmp/

# 更改 tmp/pids/ 和 tmp/sockets/ 目录权限，使 GitLab 具有写权限
$ sudo chmod -R u+rwX tmp/pids/
$ sudo chmod -R u+rwX tmp/sockets/

# 创建 uploads 目录，且只有 GitLab 有该目录操作权限
$ sudo -u git -H mkdir public/uploads/
$ sudo chmod 0700 public/uploads

$ sudo chmod ug+rwX,o-rwx /home/git/repositories/

# 更改 builds/ 和 shared/artifacts/ 目录权限
$ sudo chmod -R u+rwX builds/
$ sudo chmod -R u+rwX shared/artifacts/

# 配置 unicorn 配置文件
$ sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb

# 查看单个用户可用的最大进程数
$ nproc

# 更改配置文件 unicorn.rb，其中 worker_processes 项至少要为单个用户可用的最大进程数，我设为 2
$ sudo -u git -H vim config/unicorn.rb

# 配置 Rack attack 配置文件
$ sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb

$ sudo -u git -H git config --global core.autocrlf input
$ sudo -u git -H git config --global gc.auto 0

# 配置 Redis 连接设置
$ sudo -u git -H cp config/resque.yml.example config/resque.yml
```

**重要说明：**请同时配置`gitlab.yml`和`unicorn.rb`，确保配置适应系统。

**注意：**如果要使用 HTTPS，请参阅 [使用HTTPS](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/installation.md#using-https) 了解其他步骤。

## 配置数据库设置

```Bash
# MySQL配置文件
$ sudo -u git cp config/database.yml.mysql config/database.yml

# 配置数据库配置文件，只需保留 production 部分配置即可，需要将 secure password 更改为 git 用户的数据库密码 
$ sudo -u git -H vim config/database.yml

# 只让 GitLab 具有 config/database.yml 的操作权限
$ sudo -u git -H chmod o-rwx config/database.yml
```

## 安装Gems

```Bash
$ cd /home/git/gitlab

# 修改 bundle 源服务器地址
$ sudo -u git -H bundle config mirror.https://rubygems.org https://ruby.taobao.org

# 适用于MySQL，安装过程相对比较长
$ sudo -u git -H bundle install --deployment --without development test postgres aws kerberos
```

## 安装GitLab shell

GitLab Shell是一个专门为 GitLab 开发的 SSH 访问和存储库管理软件。

```Bash
$ sudo -u git -H bundle exec rake gitlab:shell:install[v3.0.0] REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production

# 查看 gitlab-shell 的配置文件，默认不需要修改
$ sudo -u git -H vim /home/git/gitlab-shell/config.yml

$ restorecon -Rv /home/git/.ssh
```

运行上述第 1 条命令，如果出现如下错误：

```Bash
rake aborted!
Errno::ENOENT: No such file or directory - /usr/bin/git
```

可以通过执行`ln -s /usr/local/bin/git /usr/bin/git`命令解决。


## 安装gitlab-workhorse

```Bash
$ cd /home/git
$ sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-workhorse.git
$ cd gitlab-workhorse
$ sudo -u git -H git checkout v0.7.5
$ sudo -u git -H make
```

## 初始化数据库并激活高级功能

```Bash
$ cd /home/git/gitlab

# your password 替换成需要设置的密码，your email 替换成邮箱地址，提示时输入 yes
$ sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production GITLAB_ROOT_PASSWORD=your password GITLAB_ROOT_EMAIL=your email
```

## 安装Init脚本

```Bash
$ cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

将 GitLab 服务设置成开机自启：

```Bash
$ chkconfig gitlab on
```

## 设置logrotate

```Bash
$ cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
```

## 检查应用程序状态

使用如下命令，检查 GitLab 及其环境是否正确配置。

```Bash
$ sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

## 编译Assets

```Bash
$ sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production
```

## 启动GitLab实例

```Bash
$ service gitlab start
```

# 配置Web服务器

这里用 Nginx 作为 Web 服务器。如果系统没有安装 Nginx，可以使用`yum`安装：

```Bash
$ yum -y install nginx
$ chkconfig nginx on
```

## 站点配置

```Bash
$ cd /home/git/gitlab

# 复制 GitLab 提供的参考配置文件到 Nginx 配置文件目录，并需要将 YOUR_SERVER_FQDN 替换成需要设置成的域名
$ cp lib/support/nginx/gitlab /etc/nginx/conf.d/gitlab.conf
```

将`nginx`用户添加到`git`组：

```Bash
$ usermod -a -G git nginx
$ chmod g+rx /home/git/
```

## 测试配置

```Bash
$ nginx -t
```

如果提示 29 行存在错误，则修改`gitlab.conf`如下：

```Bash
listen       80 default_server;
listen       [::]:80 default_server;
server_name localhost;                           # 域名替换成需要的域名
```

## 启动服务

```Bash
$ service nginx start
```

# 完成

## 检查应用状态

为了确保没有错过任何配置，运行一个更彻底的检查：

```Bash
$ cd /home/git/gitlab
$ sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```
如果 **所有项目都是绿色** 的，那么祝贺您 **成功安装 GitLab **！

## 启动和停止GitLab

```Bash
$ service gitlab start
$ service gitlab stop
```

![预览图](https://img.fanhaobai.com/2017/02/gitlab-install/f8facee3-ddff-4d5a-a6a6-904951891ad5.png)