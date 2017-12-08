---
title: Yii支持多域名cors原理
date: 2017-08-05 17:42:43
tags:
- YII
categories:
- 语言
- PHP
---

平常我们遇到跨域问题时，常使用 cors（Cross-origin resource sharin）方式解决。不知你是否注意到，在设置响应头 Access-Control-Allow-Origin 域的值时，只允许设置一个域名，这意味着不能同时设置多个域名来共享资源。而在 Yii2 中直接使用`'Origin' => ['http://www.site1.com', 'http://www.site2.com']`的形式却可以设置多个 cors 域名值，Why?
{% asset_img b353a007-0c9c-4ee2-b0a9-85ccc205a145.png %}<!--more-->

其实，Yii2 中采用了动态设置 Access-Control-Allow-Origin 域值的方法来解决这个问题。

> 说明：测试使用的接口域名`api.d.fanhaobai.com`，cros 多域名为`www.d.yii.com`和`www.fq.yii.com`。

## Nginx设置多域名

尝试直接通过 Nginx 的`add_header`模块追加 Access-Control-Allow-Origin 值实现，如下：

```Nginx
add_header Access-Control-Allow-Origin http://www.fq.yii.com;
add_header Access-Control-Allow-Origin http://www.d.yii.com;
```

接口 **请求** 和 **响应头** 如下：

```Dos
Response Headers
Access-Control-Allow-Origin: http://www.fq.yii.com
Access-Control-Allow-Origin: http://www.d.yii.com
Connection: keep-alive
Content-Type: application/json; charset=UTF-8
... ...

Request Headers
Accept: */*
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.8
Host: api.d.fanhaobai.com
Origin: http://www.fq.yii.com
Proxy-Connection: keep-alive
... ...
```

当前域为`www.fq.yii.com`，需跨域请求`http://api.d.fanhaobai.com/v1/config/list.json`的资源。浏览器抛出如下跨域错误：

```Bash
XMLHttpRequest cannot load http://api.d.fanhaobai.com/v1/config/list.json. The 'Access-Control-Allow-Origin' header contains multiple values 'http://www.fq.yii.com, http://www.d.yii.com', but only one is allowed. Origin 'http://www.fq.yii.com' is therefore not allowed access.
```

以上信息明确说明，Access-Control-Allow-Origin 只能设置为一个值，即每次请求只能对应一个域名值。故通过该方法不能设置多域名进行 cors。

##  Yii2设置多域名

Yii2 设置多域名 cors，只需在对应控制器（ConfigController）中设置 cors 行为，如下：

```PHP
class BaseController extends Controller
{
    /**
     * @inheritdoc
     */
    public function behaviors()
    {
        return [
            'corsFilter' => [
                'class' => \yii\filters\Cors::className(),
                'cors' => [
                    //运行cors域名列表
                    'Origin' => ['http://www.d.yii.com', 'http://www.fq.yii.com'],
                    'Access-Control-Allow-Credentials' => true,
                ]
            ],
        ];
    }
}
```

重新在`www.fq.yii.com`发送 cors 请求，发现此时已经不存在跨域问题。**响应头** 如下：

```DOS
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: http://www.fq.yii.com
Connection: keep-alive
Content-Type: application/json; charset=UTF-8
... ...
```

我们会发现，Access-Control-Allow-Origin 域的值为`http://www.fq.yii.com`，刚好为当前域名一致，且只有一个值，并未出现设置的`http://www.d.yii.com`值。

同时，在`www.d.yii.com`下发送 cors 请求，也不存在跨域问题。响应头中 Access-Control-Allow-Origin 值为`http://www.d.yii.com`。

由此可知，Yii2 在控制器行为中设置 Origin 项，只是一个域名白名单，而返回的 Access-Control-Allow-Origin 同请求的域名一致且在这个白名单中，这个 Access-Control-Allow-Origin 由 Yii2 根据当前请求所在域名进行了动态处理。

## Yii2动态Access-Control-Allow-Origin

查看 Yii2 的`\yii\filters\Cors`类源码，如下：

```PHP
class Cors extends ActionFilter
{
    /**
     * @var array CORS所用的响应头
     */
    public $cors = [
        'Origin' => ['*'],
        'Access-Control-Request-Method' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'],
        'Access-Control-Request-Headers' => ['*'],
        'Access-Control-Allow-Credentials' => null,
        'Access-Control-Max-Age' => 86400,
        'Access-Control-Expose-Headers' => [],
    ];
    
    /**
     * 执行action前要做的事
     * @inheritdoc
     */
    public function beforeAction($action)
    {
        $this->request = $this->request ?: Yii::$app->getRequest();
        $this->response = $this->response ?: Yii::$app->getResponse();
        ... ...
        $requestCorsHeaders = $this->extractHeaders();
        //获取cors所用的响应头
        $responseCorsHeaders = $this->prepareHeaders($requestCorsHeaders);
        //设置cors所用的响应头
        $this->addCorsHeaders($this->response, $responseCorsHeaders);
        return true;
    }
    
    /**
     * 处理cors所用的响应头，动态处理Access-Control-Allow-Origin域
     * @param array $requestHeaders CORS headers we have detected
     * @return array CORS headers ready to be sent
     */
    public function prepareHeaders($requestHeaders)
    {
    	$responseHeaders = [];
        //$requestHeaders['Origin']为源地址，请求所在域名
        if (isset($requestHeaders['Origin'], $this->cors['Origin'])) {
            //源地址在白名单中，则设置Access-Control-Allow-Origin为源地址
            if (in_array('*', $this->cors['Origin']) || in_array($requestHeaders['Origin'], $this->cors['Origin'])) {
                $responseHeaders['Access-Control-Allow-Origin'] = $requestHeaders['Origin'];
            }
        }
        ... ...
     }
}
```

主要思想就是，查看源地址是否在 cors 白名单中，在则设置 Access-Control-Allow-Origin 域的值为源地址。这样就能满足 Access-Control-Allow-Origin 为一个值的限制，同时也能允许指定的域名进行 cors。

> 注意：使用该方法请确保 Nginx 配置中未操作 Access-Control-Allow-Origin 域。

## 总结

通过 Nginx 设置 Access-Control-Allow-Origin 进行 cors，有且只能有一个特定域名，局限性较大。通过代码逻辑操作 Access-Control-Allow-Origin 来实现 cors，则比较灵活，能解决多个域名进行 cors 的需求，但是如果接口异常，跨域设置则会失效。
