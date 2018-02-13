---
title: 自动更新站点地图的部署
date: 2017-01-16 18:56:24
tags:
- 日常
categories:
- 日常
---

<style>
.entry-content li .more {
    color:#999;
    margin-left:4px;
    font-size:14px;
}
</style>

[站点地图](http://baike.baidu.com/link?url=ztt5Ynwbu27ulWT62PphpF9XCs4oE9xKriqZ_QnrLw3INX7Xf795vrdIhXgyspnaB4xrFq-CkTJyrTY6c_9Nu_)，又称网站地图。它是一个网站所有链接的容器，作用是引导搜索引擎机器人抓取网站页面，增加网站重点内容的收录。站点地图一般存放在站点根目录下并命名为 **sitemap** 。<!--more-->

本站 [博客](https://www.fanhaobai.com) 为了 SEO，已经支持了 [Robots协议](https://www.fanhaobai.com/2017/01/robots.html)。

由于本站博客文章是不定时进行更新，因此站点地图也需要进行时时更新，而本站对于站点地图更新的时效性要求不高，所以本站采用了 PHP 脚本定时更新站点地图的方案。

# 指定路径

站点建立了 robots.txt 文件后， [HTML格式]() 和 [XML格式](http://www.fanhaobai.com/sitemap.xml) 的站点地图路径就在 robots.txt 文件中指定， 即在该文件最后行加入如下代码：

```Ini
Sitemap: http://www.fanhaobai.com/map.xml                 #谷歌推荐格式
Sitemap: http://www.fanhaobai.com/map.html                #百度推荐格式
```

注意，对于全站为 https 协议的站点，也推荐使用 http 协议。只需在 Nginx 配置中增加如下信息：

```Nginx
server {
  listen 80;
  server_name fanhaobai.com www.fanhaobai.com;
  #网站地图地址
  location ~ /(map\.html)|(map\.xml)|(robots\.txt)$ {
     root /data/html/www/www;
     expires off;
  }
  ... ...
}
```

# 脚本分析

本站自动更新站点地图的脚本是 PHP 语言实现，并封装成了一个 Map 类。下面逐一介绍该类实现的主要方法。

## 构造方法

构造方法主要是完成一些配置信息的初始化，并初始化系统，建立 MySQL 数据库的连接。

```PHP
//构造方法
public function __construct($config) {
    //设置默认配置
    $config['db_port'] = isset($config['db_port']) ? $config['db_port'] : 3306;
    $config['log_path'] = isset($config['log_path']) ? $config['log_path'] : __DIR__ . '/';
    $config['log_name'] = isset($config['log_name']) ? $config['log_name'] : 'update_map.log';
    $config['map_path'] = isset($config['map_path']) ? $config['map_path'] : __DIR__ . '/';
    $config['map_name'] = isset($config['map_name']) ? $config['map_name'] : 'sitemap';
    self::$config = $config;
    //初始化
    $this->start = $this->microtime();               //时间记录
    $this->accessLog('-');                           //执行日志
    $this->accessLog('start');
    $this->iniSystem();
}
```

## 初始化系统

初始化系统方法主要是建立 MySQL 数据库的连接，为后续操作数据库做下基础。这里采用 PDO 方式连接 MySQL 数据库。

```PHP
private function iniSystem() {
    $config = self::$config;
    $dsn = "mysql:host={$config['db_host']};port={$config['db_port']};dbname={$config['db_name']}";
    //连接mysql
    try {
        $this->db = new PDO($dsn, $config['db_user'], $config['db_pwd']);
        //设置字符集
        $this->db->query('set names utf8');
    } catch (Exception $e) {
        $this->errorLog("connect mysql failed: {$e->getMessage()}");
    }
    $this->accessLog('connect mysql successful');
}
```

## 获取文章

该方法是查询出所有文章的 **标题** 、**url地址** 、**创建时间** 、**最后更新时间** 信息。

```PHP
private function getPost() {
    $sql = 'SELECT
               `type`,`title`,`pathname`,DATE_FORMAT(update_time,"%Y-%m-%d") update_time
            FROM
               `table_name`
            WHERE
               `status` = 3 AND `is_public` = 1
            ORDER BY
               `type`,`create_time` DESC';
    $postArr = array();
    try {
        $result = $this->db->query($sql);
        $result->setFetchMode(PDO::FETCH_ASSOC);
        $postArr = $result->fetchAll();
    } catch (PDOException $e) {
        $this->errorLog('query question error: ' . $sql);
    }
    $this->accessLog('query question successful');
    return $postArr;
}
```

## 更新网站地图

该部分由 4 个方法构成，主要是解析 HTML 格式和 XML 格式模板，并更新 HTML 格式和 XML 格式的网站地图文件。

1） 获取HTML格式LI标签内容

```PHP
public function getHtmlLi($post) {
    $type = array('post', 'page');
    $strArr = array(
        'article'  =>  '',
        'page'     =>  ''
     );
    //拼接li
    $host = self::$config['host'];
    $li = "\r\n<li><a href='{$host}/%s/%s.html' target='_blank'>%s</a></li>";
    foreach ($post as $one) {
        $index = $one['type'] ? 'page' : 'article';
        $strArr[$index] .= sprintf($li, $type[$one['type']], $one['pathname'], $one['title']);
    }
    return $strArr;
}
```

2） 解析HTML格式模板并更新网站地图文件

```PHP
private function getHtml($post) {
    $filePath = __DIR__ . '/map.html';
    if (!file_exists($filePath)) {
        $this->errorLog('map.html file not exist');
    }
    $html = file_get_contents($filePath);
    $content = $this->getHtmlLi($post);
    $mapUrl = self::$config['host'] . '/' . self::$config['map_name'] . '.html';
    $html = str_replace('{host}', self::$config['host'], $html);
    $html = str_replace('{sitemap_url}', $mapUrl, $html);
    //获取文章
    $html = str_replace('{article}', $content['article'], $html);
    //获取导航
    $html = str_replace('{page}', $content['page'], $html);
    $html = str_replace('{update_date}', date('Y-m-d H:i:s'), $html);
    //更新文件
    $mapPath = self::$config['map_path'] . self::$config['map_name'] . '.html';
    if (false === $this->addToFile($mapPath, $html, true)) {
        $this->errorLog('update ' . self::$config['map_name'] . '.html failed');
    }
    $this->accessLog('update ' . self::$config['map_name'] . '.html successful');
}
```

解析 XML 格式模板和更新网站地图文件的方法类似于上述解析和更新 HTML 格式的 2 个方法。

## 析构方法

```PHP
public function __destruct() {
    $date = $this->microtime() - $this->start;
    $this->accessLog('used time:' . $date);
    $memory = $this->memory();
    $this->accessLog('used memory:' . $memory);
    $this->accessLog('end');
}
```

## 主方法

该方法主要是外部调用，执行整个更新流程。

```PHP
public function run()
{
    //获取内容
    $post = $this->getPost();
    //生成map.html文件
    $this->getHtml($post);
    //生成map.xml文件
    $this->getXml($post);
}
```

## 类实例化

按照下面的少许配置，就可以使用该地图类。

```PHP
//配置信息
$config = array(
    //数据库配置
    'db_host'   =>  'localhost',
    'db_name'   =>  'db_name',
    'db_user'   =>  'db_user',
    'db_pwd'    =>  'db_pwd',
    //网站域名
    'host'      =>  'https://www.fanhaobai.com',
    //网站地图配置
    'map_path'  =>  '/path/',
    'map_name'  =>  'map',
);
//实例化并执行脚本
$map = new Map($config);
$map->run();
```

# 更新流程

自动更新实现的大致流程为：

1） 根据一定条件按照时间倒序从数据库中`select`文章的 **标题** 、**url地址** 、**创建时间** 、**最后更新时间** 字段；
2） 循环生成 HTML 格式中的`<ul>`标签内容和 XML 格式中的`<url>`标签；
3） 分别从模板文件中获取 HTML 格式和 XML 格式模板，并分别用②中`<ul>`和`<url>`标签替换模板中的指定字符；
4） 将替换后的模板内容写入到站点地图文件；

上述过程是通过 [**Linux 的 crontab 定时机制，实现每隔 2 天循环一次执行的更新频率**]()。

```Bash
0 1 */2 * * /usr/local/php7/bin/php /data/html/www/sitemap/map_create.php
```

<strong>相关文章 [»]()</strong>

* [如何向搜索引擎提交链接](https://www.fanhaobai.com/2017/01/push-links.html) <span>（2017-01-17）</span>
* [Robots协议的那些事](https://www.fanhaobai.com/2017/01/robots.html) <span>（2017-01-12）</span>
