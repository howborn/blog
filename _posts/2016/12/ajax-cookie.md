---
title: 二级域名站点统一登陆入口问题
date: 2016-12-25 01:11:49
tags:
- JS
categories:
- 语言
- JS
---

同一个项目中两个不同后台管理系统，并分别采用 PHP 和 JAVA 语言独立开发。前期两个项目都有各自的登录入口，现在项目上线需要整合成统一登录入口。

在业务方面，JAVA 开发的公司管理后台可以直接分配给 PHP 开发的园所管理后台用户，进而公司用户从公司后台登录，园所用户从园所后台登录，两个项目 **不共享用户数据**，且部署在不同服务器上。

![](https://img.fanhaobai.com/2016/12/ajax-cookie/8UUZlAcsiDmkZgWhKw0dhv-4.png)<!--more-->

为了后续描述，先假定公司后台管理系统入口地址为：`company.vxin365.com`，园所管理后台入口地址为：`yundong.vxin365.com`，整合后的统一登录入口地址为：`company.vxin365.com`，即统一登录入口放置在公司管理后台上，用户登录标志采用 SESSION 存储。

# 问题描述

为了实现整合统一登录入口需求，登录页面整合成 **选项卡** 形式，用户切换选项卡选择登录不同的后台，所以我负责的园所后台需要提供登录接口。提供登录接口后，公司后台 JAVA 开发人员反馈无法通过登录接口登录到园所后台，登录接口返回登录成功，但是跳转到登录成功的回调地址后，又弹回了登录页面。

登录接口返回 JSON 格式

```JS
{
  "code": 1,
  "msg": "操作成功",
  "data": "//yundong.vxin365.com/index.php/home/index/index"       //登录成功回调地址
}
```

# 问题分析

通过上述登录问题反馈可知，登录接口返回登录成功，也就是调用登录接口后，用户登录状态已经存在。但是跳转到回调地址后，又弹出了登录页面，说明用户登录状态丢失，导致登录拦截逻辑拦截后续请求，直接弹回了登录页面。

而登录接口后端和园所后台后端同运行于一台服务器，且主域名一致，SESSION 的有效域也设置成了`.vxin365.com`，即子域名和主域名都共享 SESSION，所以排除了服务器端 SESSION 不能共享的问题。

![](https://img.fanhaobai.com/2016/12/ajax-cookie/YOfO7obkR5uQ4PUsyVxZ4G5s.png)

那么大致猜测可能导致的原因是：调用登录接口的请求（①处）和跳转到成功回调地址的请求（②处）的 COOKIE 不一致或者丢失，导致存于 COOKIE 中的 SessionID 不一致或者丢失，无法获取到当前已登录用户的登录状态（③处）。

通过询问公司后台 JAVA 开发人员，得知他们是通过 AJAX 调用我提供的登录接口，那么接下来工作就是需要让登录 [问题复现]() 。

# 问题复现

为了复现问题，需要本地配置一个`company.vxin365.com`和`yundong.vxin365.com`的域名指向，并将项目分别运行于两个服务器上。将子域名为 company 项目的登录页面，更改为登录时通过 AJAX 将登录的用户信息提交到子域名为 yundong 项目中。

1） 后端解决AJAX跨域问题
```PHP
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Origin: *');                              //允许跨域域名    * 所有域名
header('Access-Control-Allow-Methods: POST');
```

2） 登录AJAX处理
```JS
//登录按钮的点击事件
$('#submit').on('click', function(ev) {
    var event = ev||event;
    event.preventDefault();
    //校验
    if(!checkName() || !checkPwd()) return;
    //发送请求
    $.ajax({
        type: "post",
        url: 'http://yundong.vxin365.com/index.php/api/login/login',       //登录接口
        dataType: "json",
        data: $('form').serialize(),
        success: function (json) {
           if (json.code == 1) {
              //登录成功则跳转到回调地址，测试已注释掉
              //window.location.href= 'http://' + json.data;
           } else { 
               //登录失败提示信息逻辑
              ...
           }
        }
    });
});
```

首先，需要清除浏览器所有站点 COOKIE 信息，并先访问`company.vxin365.com`并做登录测试（①处）。

1） 请求头

```HTTP
Accept:application/json, text/javascript, */*; q=0.01
... ...
Host:yundong.vxin365.com
Origin:http://company.vxin365.com
Referer:http://company.vxin365.com/index.php/home/login/index
User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36
```
可以发现由于已经清除了 COOKIE 信息，请求头并无携带 COOKIE 信息，无任何异常现象。

2） 响应头

```HTTP
Access-Control-Allow-Credentials:true
Access-Control-Allow-Methods:POST
Access-Control-Allow-Origin:*
... ...
Content-Type:application/json; charset=utf-8
Set-Cookie:auth_flag=1; path=/
Set-Cookie:login_flag=1; path=/
Set-Cookie:PHPSESSID=lm8t5767el6j5g67tcbeuh0ab0; path=/      //需要设置SeesionID
```

可以发现，接口返回登录成功，且由于登录接口将登录状态存储与 SESSION 中，所以响应头中要求设置了一项为 PHPSESSID 的 COOKIE 信息，无任何异常现象。

那么，现在已经从 company 子域下成功登录到 yundong 子域下，如果一切正常，我们使用同一浏览器访问 yundong 子域（②处），应该会直接成为已登录状态并可以访问到首页。但是，访问 yundong 子域后只弹回了登录页面，并未成功登录。

1） 请求头

```HTTP
Accept:text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
... ...
Host:yundong.vxin365.com
Upgrade-Insecure-Requests:1
User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36
```
可以发现请求头并无携带 COOKIE 信息，但是在（①处）已经设置了 yundong 子域的 COOKIE 信息，此处异常说明 COOKIE 设置并 **未生效** ，那么（③处）也无用户的登录状态，不能标识为同一用户的操作。

2） 响应头

```HTTP
Access-Control-Allow-Credentials:true
Access-Control-Allow-Methods:POST
Access-Control-Allow-Origin:*
... ...
Content-Type:application/json; charset=utf-8
Set-Cookie:auth_flag=1; path=/
Set-Cookie:login_flag=1; path=/
Set-Cookie:PHPSESSID=lm8t5767el6j5g67tcbeuh0ab0; path=/     //又重新设置SeesionID
```
由于请求头无 COOKIE 信息，未标识为同一用户操作，所以服务器又重新分配 PHPSESSID。

3） 响应状态码

```HTTP
Status Code:302 Found
```
由于 SessionID 获取失败，导致丢失用户的登录状态，从而又重定向到了登录页面。

最后，为了验证是 COOKIE 设置并 **未生效** 的猜测，需要再次从 company 子域请求 yundong 域的登录接口，查看请求头信息为：

```HTTP
Accept:application/json, text/javascript, */*; q=0.01
... ...
Content-Type:application/x-www-form-urlencoded; charset=UTF-8
Host:yundong.vxin365.com
Origin:http://company.vxin365.com
Referer:http://company.vxin365.com/index.php/home/login/index
User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.99 Safari/537.36
```

可以看出第二次请求登录接口，也并未带上 COOKIE 信息，那么就验证了导致登录失败原因是：[由于 AJAX 跨域请求，默认是不获取和设置 COOKIE 信息的]() 。


# 解决问题

通过问题复现，知道了问题所在是：由于 AJAX 跨域请求，默认是不获取和设置 COOKIE 信息的，那么只需要做如下两处修改即可。

1） 登录AJAX处理增加行
```JS
xhrFields: {
    withCredentials: true                        //跨域请求携带COOKIE
}
```
2） 后端解决AJAX跨域问题修改行
```PHP
header('Access-Control-Allow-Origin: http://company.vxin365.com');  
//允许跨域域名，此处不能设为通配符 '*'，否则JS会抛出错误
```

再次从 company 子域下通过 AJAX 登录到 yundong 子域下，已成功登录并跳转到了 yundong 子域的首页，问题已解决。

# 问题思考

由于两个后台用户数据不共享，所以没有将两个后台的登录逻辑合并为一个统一入口，只是将登录页面通过选项卡形式合并到一个登录入口，然后通过 AJAX 请求各自后台的登录逻辑接口，以实现统一登录入口需求，但是这个问题并不能通过将 SESSION 存储于公用缓存中（Redis），进而不同服务器共享 SESSION 来解决，因为问题是客户端登录前后一次 AJAX 请求和一次跳转回调地址请求 SessionID 丢失导致的。

当然如果将两个后台的登录逻辑整合在一端，那么不同站点可以通过共享 SESSION 来实现 **单点登录**。
