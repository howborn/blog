---
title: Swoole提供PHP异步特性
date: 2016-02-17 08:00:00
tags:
- PHP
- Swoole
categories:
- PHP
---

[Swoole](https://www.swoole.com/)

注意，Swoole 从 2.0.12 版本后不再支持 PHP5。


## 扩展安装

### 编译安装

```Bash
# http://pecl.php.net/package/swoole
$ cd /usr/src
$ wget http://pecl.php.net/get/swoole-1.9.23.tgz
$ tar zxvf swoole-1.9.23.tgz
$ cd swoole-1.9.23
$ phpize
$ ./configure
$ make && make install
Installing shared extensions:     /usr/local/php/lib/php/extensions/no-debug-non-zts-20131226/
```

### 配置

```Bash
$ vim /usr/local/php/lib/php.ini
extension=swoole.so

$ php --ri swoole
swoole support => enabled
Version => 1.9.23
```
