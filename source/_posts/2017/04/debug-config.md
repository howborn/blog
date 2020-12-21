---
title: 安全使用调试模式
date: 2017-04-18 23:18:48
tags:
- YII
categories:
- 语言
- PHP
---

在开发过程中我们会开启调试模式，方便我们能快速定位错误和发现潜在问题。但是，项目上线后必须关闭这类敏感信息，难道只能通过更改代码逻辑或者配置文件来实现吗？<!--more-->

这里提供了一种思路，我觉得是比较好的一种实现方式。

# 实现思路

通过代码运行环境来确定是否开启调试模式，不同环境通过预定义服务变量（$_SERVER）来标识。

# 代码示例

通过以下代码来直观感受：

```PHP
<?php
# 运行环境
$env = isset($_SERVER['APP_ENV']) ? $_SERVER['APP_ENV'] : 'dev';
# 调试模式
$debug = isset($_SERVER['APP_DEBUG']) ? $_SERVER['APP_DEBUG'] : false;

defined('YII_DEBUG') or define('YII_DEBUG', $debug);
defined('YII_ENV') or define('YII_ENV', $env);
```

# 服务端配置

在需要开启调试模式的环境配置服务变量，向`fastcgi_params`配置文件追加以下参数，并重启 nginx。

```PHP
# Debug
fastcgi_param  APP_ENV           dev;
fastcgi_param  APP_DEBUG         true;
```

# 校验

然后，输出 $_SERVER 即可发现存在上述预定义服务变量。

```PHP
# $_SERVER
array(35) {
  ... ...
  "APP_ENV"=>
  string(3) "dev"
  "APP_DEBUG"=>
  string(4) "true"
  ... ...
}
```

此时，无须修改任何代码，代码就能根据运行环境切换调试模式，减少了开发人员误操作的可能性，操作也比较安全。

# 总结

当然，这种使用预定义环境变量的方式，不仅仅应用于调试模式的启用，而且数据库的等这类配置信息也可以采用该方式。
