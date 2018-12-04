---
title: Nginx错误日志的配置
date: 2017-01-14 21:47:15
tags:
- Nginx
categories:
- 服务器
- Nginx
---

在使用 Nginx 过程中，日志是我们分析数据和调试时不可或缺的。而我们一般都会，默认配置开启错误日志记录，并不知道 Nginx 的错误日志有多达 **6种** 记录等级。<!--more-->

# 开启错误日志

开启错误日志，只需使用如下配置即可：

```Nginx
error_log path/error.log 
```

# 错误日志等级

查看 Nginx 配置的 [官方文档](http://nginx.org/en/docs/ngx_core_module.html#error_log) ，如下所示：

![](https://img1.fanhaobai.com/2017/01/nginx-error-log/bV28VaqG_Zxq4KG0QjFIyC0j.png)

从上图可知，Nginx 的 error_log **等级** 如下：

<strong>[ debug | info | notice | warn | error | crit | alert | emerg ]</strong>

这里暂且称之为 **第一级别等级** 。按照上述顺序，从 [**左至右日志记录等级逐次降低**](#)，debug 最详细，而 emerg 最粗略。例如：默认等级 error ，则表示 error，crit，alert，emerg 的信息会被记录到错误日志中。当然，这些都可以从`ngx_log.h`源码文件中得到验证。

```C
#define NGX_LOG_EMERG             1
#define NGX_LOG_ALERT             2
#define NGX_LOG_CRIT              3
#define NGX_LOG_ERR               4
#define NGX_LOG_WARN              5
#define NGX_LOG_NOTICE            6
#define NGX_LOG_INFO              7
#define NGX_LOG_DEBUG             8

#define NGX_LOG_DEBUG_CORE        0x010
#define NGX_LOG_DEBUG_ALLOC       0x020
#define NGX_LOG_DEBUG_MUTEX       0x040
#define NGX_LOG_DEBUG_EVENT       0x080
#define NGX_LOG_DEBUG_HTTP        0x100
#define NGX_LOG_DEBUG_MAIL        0x200
#define NGX_LOG_DEBUG_STREAM      0x400
```

从源码中可知，`error_log`还有 **第二级别等级**。

其值为：debug_core、debug_alloc、debug_mutex、debug_event、debug_http、debug_mail、debug_mysql，第二级别等级日志是当启动调试日志级别时才有效。

# 日志等级关系

通过查看`ngx_log.c`源码，大致可以知道如何使用这些日志级别，部分源码如下：

```C
static char *
ngx_log_set_levels(ngx_conf_t *cf, ngx_log_t *log)
{
    ngx_uint_t   i, n, d, found;
    ngx_str_t   *value;
    if (cf->args->nelts == 2) {
        log->log_level = NGX_LOG_ERR;
        return NGX_CONF_OK;
    }
    value = cf->args->elts;
    for (i = 2; i < cf->args->nelts; i++) {
        found = 0;
        for (n = 1; n <= NGX_LOG_DEBUG; n++) {
            if (ngx_strcmp(value[i].data, err_levels[n].data) == 0) {
                if (log->log_level != 0) {
                    ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
                                       "duplicate log level \"%V\"",
                                       &value[i]);
                    return NGX_CONF_ERROR;
                }
                log->log_level = n;
                found = 1;
                break;
            }
        }
        for (n = 0, d = NGX_LOG_DEBUG_FIRST; d <= NGX_LOG_DEBUG_LAST; d <<= 1) {
            if (ngx_strcmp(value[i].data, debug_levels[n++]) == 0) {
                if (log->log_level & ~NGX_LOG_DEBUG_ALL) {
                    ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
                                       "invalid log level \"%V\"",
                                       &value[i]);
                    return NGX_CONF_ERROR;
                }
                log->log_level |= d;
                found = 1;
                break;
            }
        }
        if (!found) {
            ngx_conf_log_error(NGX_LOG_EMERG, cf, 0,
                               "invalid log level \"%V\"", &value[i]);
            return NGX_CONF_ERROR;
        }
    }
    if (log->log_level == NGX_LOG_DEBUG) {
        log->log_level = NGX_LOG_DEBUG_ALL;
    }
    return NGX_CONF_OK;
}
```

按照上述代码逻辑，可以得出：

1） **第一级别日志之间是互斥关系**

如果配置文件内配置如下：

```Nginx
error_log path/error.log warn;  
error_log path/error.log info;  
```

则在检查配置文件语法时，会出现如下报错：

```Nginx
[emerg]: duplicate log level "info" in /path/conf/nginx.conf:xx
```

但是值得注意的是，[**在配置文件中不同 block 中时允许重新定义错误日志的**](#) 。

2） **第二级别日志是可多选关系**

当用户开启 debug 级别错误日志时，默认会输出所有 debug 相关的调试信息，所以可以通过`debug_core|debug_http`类似 **组合配置** 的形式，来输出所需要的调试信息。

# 特殊说明

## 关闭错误日志

关于关闭错误日志的方法，Nginx 官方文档中说明如下：

![](https://img2.fanhaobai.com/2017/01/nginx-error-log/Y9dl4sFCEwGsFmUFvKYey-bI.png)

所以，通过 **error_log off** 并不能关闭错误日志记录，而它只是表示将日志文件写入一个文件名为 **off** 的文件中。

如果需要关闭错误日志记录，应使用以下配置：

```Nginx
error_log /dev/null crit;                  # 把存储位置设置为linux的黑洞
```

## 日志写入权限

值得注意`0.7.53`版本，Nginx 在读取配置文件指定的错误日志路径前将使用编译的默认日志位置，如果运行 Nginx 的用户对该位置没有写入权限，Nginx 将出现错误：

```Nginx
[alert]: could not open error log file: open() "/var/log/nginx/error.log" failed (13: Permission denied) 
log_not_found 语法：log_not_found on | off
```

## 不记录404错误

使用`log_not_found`，可以指定是否记录 **404** 请求错误的日志，通常用于站点不存在 robots.txt 和 favicon.ico 文件的情况：

```Nginx
location = /robots.txt {
    log_not_found off;
 }
```

说明：符号`#`代表获取 root 权限操作。

> 友情提示，当修改了 Nginx 配置后，应该使用命令`# /usr/local/nginx/sbin/nginx –t`测试配置是否存在错误，然后使用命令`nginx -s reload`进行 Nginx 服务器重载。
