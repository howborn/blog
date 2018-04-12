---
title: 自动化代码规范检测 — PHP_CodeSniffer
date: 2018-04-12 21:00:00
tags:
- 工具
categories:
- 工具
---

当你看到一个代码乱七八糟的项目时，心里肯定很各种  /_ \，代码阅读性特差，不易维护。优秀的项目应该是看起来像是出自一个人之手，这就需要一套代码规范来约束，当然还必须要求项目成员落实这套规范。
![预览图](https://img.fanhaobai.com/2018/04/php-code-sniffer/4b3745ff-6a6a-4381-9b25-5bb2a8033c3f.png)<!--more-->

这里推荐一款自动化的 PHP 代码规范检查工具 —— [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer)，当 CodeSniffer 结合 PhpStrom 和 Git 时，自动化代码规范极为方便。

## 安装

CodeSniffer 支持 [5](https://github.com/squizlabs/PHP_CodeSniffer#installation) 种安装方式，这里使用 [pear](pear.php.net) 方式安装。

如果本地未安装 pear，参考 [pear 安装方法](http://pear.php.net/manual/en/installation.getting.php) 安装：

```Bash
$ wget https://pear.php.net/go-pear.phar
# 按1可以选择安装目录，我安装的目录为/usr/local/pear
$ php go-pear.phar
# 在/etc/profile中设置环境变量，追加内容
PATH=/usr/local/pear/bin:$PATH
$ source /etc/profile
```

安装 PHP_CodeSniffer：

```Bash
# 安装1.5.3版本
$ pear install PHP_CodeSniffer-1.5.3
install ok: channel://pear.php.net/PHP_CodeSniffer-1.5.3
$ phpcs --version
PHP_CodeSniffer version 1.5.3 
```

> PHP_CodeSniffer 安装后，phpcs 可执行文件路径同 pear。

## 配置

配置 CodeSniffer 的检测规则，如下：

```Bash
# 设置编码字符集
$ phpcs --config-set encoding utf-8
# 设置规范标准,内置标准有PEAR、PHPCS、PSR1、PSR2、Squiz、Zend
$ phpcs --config-set default_standard Jumei

$ phpcs --config-show
Array
(
    [encoding] => utf-8
    [default_standard] => Jumei
)
```

CodeSniffer 内置 PEAR、PHPCS、PSR1、PSR2、Squiz 和 Zend 等几套代码规范，存放路径为`/path/to/pear/share/pear/PHP/CodeSniffer/Standards`。当然，也可以制定自己的代码规范（例如 Jumei），实现 CodeSniffer 相应接口，并存放于上述路径即可。

## 代码规范检测

一切配置妥当后，就可以进行代码规范检测了。

```Bash
$ phpcs /home/www/init.php
FILE: /home/www/init.php
-------------------------------------------------------------
FOUND 2 ERROR(S) AFFECTING 2 LINE(S)
-------------------------------------------------------------
  1 | ERROR | Extra newline found after the open tag
 13 | ERROR | Missing function doc comment
-------------------------------------------------------------
```

## 配置PhpStrom

在 PhpStrom 完成 CodeSniffer 配置后，就可以在 PhpStrom 中时时检测代码是否规范，并做出提醒。

首先，在 “Settings” -> "Code Sniffer" 配置中，“Configuration” 项后点击`...`并输入 phpcs 路径，可以使用 "Validate" 按钮检测 phpcs 路径是否正确。

[phpcs路径面板](https://img.fanhaobai.com/2018/04/php-code-sniffer/482b161b-7c73-40ad-94d1-27cf67393ced.png)
[选择phpcs路径](https://img.fanhaobai.com/2018/04/php-code-sniffer/7c4a474b-266e-4da5-9261-3e40caef10f7.png)

然后，在 “Settings” -> "Inspections" 配置项中，勾选上 "PHP Code Sniffer validation"。为了醒目，可以将所有 Warning 更改为 Error，如下图：

[启用validation项]https://img.fanhaobai.com/2018/04/php-code-sniffer/8ef974a6-3e2f-11e8-b467-0ed5f89f718b.png)

最后，就可以在 PhpStrom 中提醒出不满足规范的代码了。

[不满足代码规范提醒]https://img.fanhaobai.com/2018/04/php-code-sniffer/711dbc8e-3e30-11e8-b467-0ed5f89f718b.png)

## 配置hook

为了严格执行代码规范，当发现不满足规范的代码时，是不允许提交至代码仓库，可以通过配置 hook 来实现。

这里使用 Mercurial 进行代码管理，所以使用了 hg 命令。Mercurial 提供了 Bash 和 Python 这 2 种 [hook](https://www.mercurial-scm.org/wiki/Hook) 的支持，Bash 脚本适用于 Linux 或者 Mac 系统，Python 脚本使用于 Win 系统，更多示例见 [HookExamples](https://www.mercurial-scm.org/wiki/HookExamples)。

> Hook 脚本中，0 和 “False” 都表示为成功，“True” 和任意异常都表示为失败。

### Bash

创建名为`pre-commit` 的可执行脚本，内容如下：

```Bash
#!/bin/bash

commit_files=`hg status -nam`
args='-n -s'
php_files="";
php_files_count=0;

for f in $commit_files; do
    # 未找到文件或者不是php文件
    if [[ ! -e $f || $f != *.php ]]; then
        continue;
    fi
    php_files_count=$((php_files_count+1))
    # 拼接变更的php文件
    php_files="$php_files $f"
done;
# php语法错误检测
for file in $php_files; do
    eval php -l $file
done;
# 没有php文件更新
if [[ $php_files_count -eq 0 ]]; then
    exit 0;
fi
# 忽略文件
[ -f .csignore ] && ignore_file="`tr '\n' ',' < .csignore |sed 's/,$//g'`"
[ -n $ignore_file ] && args=`echo "${args} --ignore='${ignore_file}'"`
# 异常退出码为1
eval phpcs $args $php_files
```

在`.hg/hgrc`中配置使其生效：

```Bash
[hooks]
precommit.phpcs = \path\to\pre-commit
```

> 注意 pre-commit 脚本的可执行权限，否则执行`sudo chmod +x \path\to\pre-commit`增加可执行权限。

### Python

创建名为`pre-commit.py`的脚本文件，内容如下：

```Python
# coding: utf8
import sys
import os
import platform

def phpcs(ui, repo, hooktype, node=None, source=None, **kwargs):
    cmd_git = "hg status -n"
    args = "-n -s"
    php_files = csignore_files = ''
    php_files_count = 0
    # 所有变更的文件
    for item in os.popen(cmd_git).readlines() :
        if item.find("php") == -1 :
            continue
        # php语法检测
        php_syntax = os.popen("php -l %s" % (item)).read()
        if php_syntax.find("No syntax errors") == -1 :
            ui.warn(php_syntax)
        # 待phpcs检测的文件
        php_files = php_files + " " + item
        php_files_count = php_files_count + 1
    # 忽略文件
    for item in open(".csignore").readlines() :
        csignore_files = csignore_files + "," + item.strip()
    csignore_args = "--ignore='%s'" % (csignore_files.strip(','))

    if php_files_count > 0 :
        cmd_phpcs = "phpcs %s %s %s" % (args, csignore_args, php_files)
        msg = os.popen(cmd_phpcs).read().strip('.\r\n')
        if msg != '' :
            ui.warn(msg + "\r\n")
            return True
    return False
```

在`.hg/hgrc`配置使其生效：

```Bash
precommit.phpcs = python:C:\path\to\pre-commit.py:phpcs
```

> 需要注意在 Win 下，安装有 hg、php、phpcs 的环境且已配置环境变量。

### 拦截效果

当提交不符合规范的代码时，拦截效果如下：

```Bash
FILE: \home\www\init.php
---------------------------------------------------------
FOUND 1 ERROR(S) AFFECTING 1 LINE(S)
---------------------------------------------------------
 12 | ERROR | Missing function doc comment
    |       | (Jumei.Commenting.FunctionComment.Missing)
---------------------------------------------------------
abort: precommit.phpcs hook failed
```

最后，推荐一个 PHP 代码质量检测工具 [phpmd](https://phpmd.org/rules/index.html)。