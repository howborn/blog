---
title: Lua在Nginx的应用
date: 2017-09-09 21:25:59
tags:
- Nginx
- Lua
categories:
- 语言
- Lua
---

当 Nginx 标准模块和配置不能灵活地适应系统要求时，就可以考虑使用 Lua 扩展和定制 Nginx 服务。[OpenResty](http://openresty.org/en/) 集成了大量精良的 Lua 库、第三方模块，可以方便地搭建能够处理超高并发、扩展性极高的 Web 服务，所以这里选择 OpenResty 提供的 [lua-nginx-module](https://github.com/openresty/lua-nginx-module) 方案。

![](https://www.fanhaobai.com/2017/09/lua-in-nginx/63113174-45d7-4a27-8472-d037675c2cbd.jpg)<!--more-->

## 安装Lua环境

lua-nginx-module 依赖于 LuaJIT 和 ngx_devel_kit。LuaJIT 需要安装，ngx_devel_kit 只需下载源码包，在 Nginx 编译时指定 ngx_devel_kit 目录。

### 系统依赖库

首先确保系统已安装如下依赖库。

```Bash
$ yum install readline-devel pcre-devel openssl-devel gcc
```

### 安装LuaJIT

首先，安装 [LuaJIT](http://luajit.org/index.html) 环境，如下所示：

```Bash
$ wget http://luajit.org/download/LuaJIT-2.0.5.tar.gz
$ tar zxvf LuaJIT-2.0.5.tar.gz
$ cd LuaJIT-2.0.5
$ make install
# 安装成功
==== Successfully installed LuaJIT 2.0.5 to /usr/local ====
```

设置 LuaJIT 有关的环境变量。

```Bash
$ export LUAJIT_LIB=/usr/local/lib
$ export LUAJIT_INC=/usr/local/include/luajit-2.0
$ echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
$ ldconfig
```

### 下载相关模块

下载 [ngx_devel_kit](https://github.com/simpl/ngx_devel_kit/tags) 源码包，如下：

```Bash
$ wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
$ tar zxvf v0.3.0.tar.gz
# 解压缩后目录名
ngx_devel_kit-0.3.0
```

**接下来**，下载 Lua 模块  [lua-nginx-module](https://github.com/openresty/lua-nginx-module) 源码包，为 Nginx 编译作准备。

```Bash
$ wget https://github.com/openresty/lua-nginx-module/archive/v0.10.10.tar.gz
$ tar zxvf v0.10.10.tar.gz
# 解压缩后目录名
lua-nginx-module-0.10.10
```

### 加载Lua模块

Nginx 1.9 版本后可以动态加载模块，但这里由于版本太低只能重新编译安装 Nginx。下载 Nginx 源码包并解压：

```Bash
$ wget http://nginx.org/download/nginx-1.13.5.tar.gz
$ tar zxvf nginx-1.13.5.tar.gz
```

编译并重新安装 Nginx：

```Bash
$ cd nginx-1.13.5
# 增加--add-module=/usr/src/lua-nginx-module-0.10.10 --add-module=/usr/src/ngx_devel_kit-0.3.0
$ ./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_v2_module --with-http_stub_status_module --with-pcre --add-module=/usr/src/lua-nginx-module-0.10.10 --add-module=/usr/src/ngx_devel_kit-0.3.0
$ make
$ make install
# 查看是否安装成功
$ nginx -v
```

### 配置Nginx环境

现在只需配置 Nginx，即可嵌入 Lua 脚本。首先，在 http 部分配置 Lua 模块和第三方库路径：

```Nignx
# 第三方库（cjson）地址luajit-2.0/lib
lua_package_path '/home/www/lua/?.lua;;';
lua_package_cpath '/usr/local/include/luajit-2.0/lib/?.so;;';
```

接着，配置一个 Lua 脚本服务：

```Nginx
# hello world测试
server {
    location /lua_content {
        # 定义MIME类型
        default_type 'text/plain';
        content_by_lua_block {
            ngx.say('Hello,world!')
        }
    }
}
```

测试安装和配置是否正常：

```Bash
$ service nginx test
$ service nginx reload
# 访问地址/lua_content输出
Hello,world!
```

## Lua调用Nginx

lua-nginx-module 模块中已经为 Lua 提供了丰富的 Nginx 调用 API，每个 API 都有各自的作用环境，详细描述见 [Nginx API for Lua](https://github.com/openresty/lua-nginx-module#nginx-api-for-lua)。这里只列举基本 API 的使用 。

先配一个 Lua 脚本服务，配置文件如下：

```Nginx
location ~ /lua_api {  
    # 示例用的Nginx变量  
    set $name $host;
    default_type "text/html";  
    # 通过Lua文件进行内容处理
    content_by_lua_file /home/www/nginx-api.lua;  
}
```

### 请求部分

* [ngx.var](https://github.com/openresty/lua-nginx-module#ngxvarvariable)

可以通过`ngx.var.var_name`形式获取或设置 Nginx 变量值，例如 request_uri、host、request 等。

```Lua
-- ngx.say打印内容
ngx.say(ngx.var.request_uri)
ngx.var.name = 'www.fanhaobai.com'
```

* [ngx.req.get_headers()](https://github.com/openresty/lua-nginx-module#ngxreqget_headers)

该方法会以表的形式返回当前请求的头信息。查看请求的头信息：

```Lua
ngx.say('Host : ', ngx.req.get_headers().host, '<br>')
for k,v in pairs(ngx.req.get_headers()) do
    if type(v) == "table" then
        ngx.say(k, " : ", table.concat(v, ","), '<br>')
    else
        ngx.say(k," : ", v, '<br>')
    end
end
```

当然，通过 [ngx.req.set_header()](https://github.com/openresty/lua-nginx-module#ngxreqset_header) 也可以设置头信息。

```Lua
ngx.req.set_header("Content-Type", "text/html")
```

* [ngx.req.get_uri_args()](https://github.com/openresty/lua-nginx-module#ngxreqget_uri_args)

该方法以表形式返回当前请求的所有 GET 参数。查看请求 query 为`?name=fhb`的 GET 参数：

```Lua
ngx.say('name : ', ngx.req.get_uri_args().name, '<br>')
for k,v in pairs(ngx.req.get_uri_args()) do
    if type(v) == "table" then
        ngx.say(k, " : ", table.concat(v, ","), '<br>')
    else
        ngx.say(k," : ", v, '<br>')
    end
end
```

同样，可以通过 [ngx.req.set_uri_args()](https://github.com/openresty/lua-nginx-module#ngxreqset_uri_args) 设置请求的所有 GET 参数。

```Lua
ngx.req.set_uri_args({name='fhb'}) --{name='fhb'}可以为query形式name=fhb
```

* [get_post_args()](https://github.com/openresty/lua-nginx-module#ngxreqget_post_args)

该方法以表形式返回当前请求的所有 POST 参数，POST 数据必须是 application/x-www-form-urlencoded 类型。查看请求`curl --data 'name=fhb' localhost/lua_api`的 POST 参数：

```Lua
--必须先读取body体
ngx.req.read_body()
ngx.say('name : ', ngx.req.get_post_args().name, '<br>')
for k,v in pairs(ngx.req.get_post_args()) do
    if type(v) == "table" then
        ngx.say(k, " : ", table.concat(v, ","), '<br>')
    else
        ngx.say(k," : ", v, '<br>')
    end
end
```

通过 [ngx.req.get_body_data()](https://github.com/openresty/lua-nginx-module#ngxreqget_body_data) 方法可以获取未解析的请求 body 体内容字符串。

* [ngx.req.get_method()](https://github.com/openresty/lua-nginx-module#ngxreqget_method)

获取请求的大写字母形式的请求方式，通过 [ngx.req.set_method()](https://github.com/openresty/lua-nginx-module#ngxreqset_method) 可以设置请求方式。例如：

```Lua
ngx.say(ngx.req.get_method())
```

### 响应部分

* [ngx.header](https://github.com/openresty/lua-nginx-module#ngxheaderheader)

通过`ngx.header.header_name`的形式获取或设置响应头信息。如下：

```Lua
ngx.say(ngx.header.content_type)
ngx.header.content_type = 'text/plain'
```

* [ngx.print()](https://github.com/openresty/lua-nginx-module#print)

ngx.print() 方法会填充指定内容到响应 body 中。如下所示：

```Lua
ngx.print(ngx.header.content_type)
```

* [ngx.say()](https://github.com/openresty/lua-nginx-module#ngxsay)

如上述使用，ngx.say() 方法同 ngx.print() 方法，只是会在后追加一个换行符。

* [ngx.exit()](https://github.com/openresty/lua-nginx-module#ngxexit)

以某个状态码返回响应内容，状态码常量对应关系见 [HTTP status constants](https://github.com/openresty/lua-nginx-module#http-status-constants) 部分，也支持数字形式的状态码。

```Lua
ngx.exit(403)
```

* [ngx.redirect()](https://github.com/openresty/lua-nginx-module#ngxredirect)

重定向当前请求到新的 url，响应状态码可选列表为 301、302（默认）、303、307。

```Lua
ngx.redirect('http://www.fanhaobai.com')
```

### 其他

* [ngx.re.match](https://github.com/openresty/lua-nginx-module#ngxrematch)

该方法提供了正则表达式匹配方法。请求`?name=fhb&age=24`匹配 GET 参数中的数字：

```Lua
local m, err = ngx.re.match(ngx.req.set_uri_args, "[0-9]+")
if m then
    ngx.say(m[0])
else
    ngx.say("match not found")
end
```

* [ngx.log()](https://github.com/openresty/lua-nginx-module#ngxlog)

通过该方法可以将内容写入 Nginx 日志文件，日志文件级别需同 log 级别一致。

* [ngx.md5()](https://github.com/openresty/lua-nginx-module#ngxmd5) | [ngx.encode_base64()](https://github.com/openresty/lua-nginx-module#ngxencode_base64) | ngx.decode_base64()

它们都是字符串编码方式。ngx.md5() 可以对字符串进行 md5 加密处理，而 ngx.encode_base64() 是对字符串 base64 编码， ngx.decode_base64() 为 base64 解码。

## Nginx中嵌入Lua

上面讲述了怎么在 Lua 中调用 Nginx 的 API 来扩展或定制 Nginx 的功能，那么编写好的 Lua 脚本怎么在 Nginx 中得到执行呢？其实，Nginx 是通过模块指令形式在其 11 个处理阶段做插入式处理，指令覆盖 http、server、server if、location、location if 这几个范围。

### 模块指令列表

这里只列举基本的 Lua 模块指令，更多信息参考 [Directives](https://www.nginx.com/resources/wiki/modules/lua/#directives) 部分。

| 指令    | 所在阶段 | 使用范围               | 说明             |
| ------- | -------- | ---------------------- | ---------------- |
| init_by_lua<br>init_by_lua_file          | 加载配置文件  | http                                     | 可以用于初始化全局配置      |
| set_by_lua<br>set_by_lua_file            | rewrite | server<br>location<br>location if        | 复杂逻辑的变量赋值，注意是阻塞的 |
| rewrite_by_lua<br>rewrite_by_lua_file    | rewrite | http<br>server<br>location<br>location if | 实现复杂逻辑的转发或重定向    |
| content_by_lua<br>content_by_lua_file    | content | location<br>location if                  | 处理请求并输出响应        |
| header_filter_by_lua<br>header_filter_by_lua_file | 响应头信息过滤 | http<br>server<br>location<br>location if | 设置响应头信息          |
| body_filter_by_lua<br>body_filter_by_lua_file | 输出过滤    | http<br>server<br>location<br>location if | 对输出进行过滤或修改       |

### 使用指令

注意到，每个指令都会有`*_lua`和`*_lua_file`两个指令，`*_lua`指令后为 Lua 代码块，而`*_lua_file`指令后为 Lua 脚本文件路径。下面将只对`*_lua`指令进行说明。

* init_by_lua

该指令会在 Nginx 的 Master 进程加载配置时执行，所以可以完成 Lua 模块初始化工作，Worker 进程同样会继承这些。

`nginx.conf`配置文件中的 http 部分添加如下代码：

```Nginx
-- 所有worker共享的全局变量
lua_shared_dict shared_data 1m;  
init_by_lua_file /usr/example/lua/init.lua;
```

`init.lua`初始化脚本为：

```Lua
local cjson = require 'cjson'
local redis = require 'resty.redis'
local shared_data = ngx.shared.shared_data
```

* set_by_lua

我们直接使用 set 指令很难实现很复杂的变量赋值逻辑，而 set_by_lua 模块指令就可以解决这个问题。

`nginx.conf`配置文件 location 部分内容为：

```Nginx
location /lua {
    set_by_lua_file $num /home/www/set.lua;
    default_type 'text/html';
    echo $num;
}
```

`set.lua`脚本内容为：

```Lua
local uri_args = ngx.req.get_uri_args()
local i = uri_args.a or 0
local j = uri_args.b or 0
return i + j
```

上述赋值逻辑，请求 query 为`?a=10&b=2`时响应内容为 12。

* rewrite_by_lua

可以实现内部 URL 重写或者外部重定向。`nginx.conf`配置如下：

```Nginx
location /lua {
    default_type "text/html";
    rewrite_by_lua_file /home/www/rewrite.lua;
}
```

`rewrite.lua`脚本内容：

```Lua
if ngx.req.get_uri_args()["type"] == "app" then
    ngx.req.set_uri("/m_h5", false);
end
```

* access_by_lua

用于访问权限控制。例如，只允许带有身份标识用户访问，`nginx.conf`配置为：

```Nginx
location /lua {  
    default_type "text/html";
    access_by_lua_file /home/www/access.lua;
}  
```

`access.lua`脚本内容为：

```Lua
if ngx.req.get_uri_args()["token"] == "fanhb" then
    return ngx.exit(403)
end
```

* content_by_lua

该指令在 [Lua调用Nginx](#Lua调用Nginx) 部分已经使用过了，用于输出响应内容。

## 案例

### 访问权限控制

使用 Lua 模块对本站的 ES 服务做受信操作控制，即非受信 IP 只能查询操作。`nginx.conf`配置如下：

```Lua
location / {
    set $allowed '115.171.226.212';
    access_by_lua_block {
        if ngx.re.match(ngx.req.get_method(), "PUT|POST|DELETE") and not ngx.re.match(ngx.var.request_uri, "_search") then
	    start, _ = string.find(ngx.var.allowed, ngx.var.remote_addr)
	    if not start then
		ngx.exit(403)
	    end
	end
    }
	
    proxy_pass http://127.0.0.1:9200$request_uri;
}
```

### 访问频率控制

在 Nginx 配置文件的 location 部分配置 Lua 脚本基本参数，并配置 Lua 模块指令：

```Nginx
default_type "text/html";
set rate_per 300
access_by_lua_file /home/www/access.lua;
```

Lua 脚本实现频率控制逻辑，使用 Redis 对单位时间内的访问次数做缓存，key 为访问 uri 拼接 token 后的 md5 值。具体内容如下：

```Lua
local redis = require "resty.redis"
local red = redis:new()

local limit = tonumber(ngx.var.rate_per) or 200
local expire_time = tonumber(ngx.var.rate_expire) or 1000
local key = "rate.limit:string:"

red:set_timeout(500)
local ok, err = red:connect("www.fanhaobai.com", 6379)
if not ok then
    ngx.log(ngx.ERR, "failed to connect redis: " .. err)
    return
end

key = key .. ngx.md5(ngx.var.request_uri .. (ngx.req.get_uri_args()['token'] or ngx.req.get_post_args()['token']))
local times, err = red:incr(key)
if not times then
    ngx.log(ngx.ERR, "failed to exec incr: " .. err)
    return
elseif times == 1 then
    ok, err = red:expire(key, expire_time)
    if not ok then
        ngx.log(ngx.ERR, "failed to exec expire: " .. err)
        return
    end
end

if times > limit then
    return ngx.exit(403)
end

return
```

