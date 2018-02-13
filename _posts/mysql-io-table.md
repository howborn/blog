---
title: MySQL命令行导入和导出数据
date: 2017-01-10 18:52:29
tags:
- MySQL
categories:
- DB
- MySQL
---


在某些情况下，不方便使用第三方工具操作数据库，这时用 MySQL 命令行客户端成为了必选。<!--more-->

下面介绍了 4 种常用命令行下操作数据库的方法。

# 导入表数据

```Mysql
source /home/root/example.sql
```

# 导出表数据

```Mysql
select * from table into outfile "/home/root/example.sql" where +条件
```

# 导入数据库

```Bash
$ mysqldump -uroot -p --default-character-set=utf8 dbname tablename >  /home/root/example.sql
```

# 转载数据

```Mysql
load data local infile "/home/table.txt" into table `table`;
```
