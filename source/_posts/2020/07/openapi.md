---
title: 自建一个简易的OpenAPI网关
date: 2020-07-15 19:30:00
tags:
- 系统设计
categories:
- 语言
- Go
---

网关（API Gateway）是请求流量的唯一入口，可以适配各类渠道和业务，处理各种协议接入、路由与报文转换、同步异步调用等，来管理 API 接口和进行请求流量控制，在微服务架构中，网关尤为重要。

![预览图](https://img1.fanhaobai.com/2020/07/openapi/ffc6e25d-7044-467d-8b7c-910831249968.jpeg)<!--more-->

## 背景

当然，现在已有很多开源软件，如 [Kong](https://github.com/Kong/kong)、[Gravitee](https://gravitee.io/)、[Zuul](https://github.com/Netflix/zuul)。

这些开源网关固然功能齐全，但对于我们业务来说，有点太重了，我们有部分定制化需求，为此我们自建了一个轻量级的 OpenAPI 网关，主要供第三方渠道对接使用。

## 简介

### 功能特性

#### 接口鉴权

* 请求 5s 自动过期
* 参数 md5 签名
* 模块粒度的权限控制

#### 接口版本控制

* 支持转发到不同服务
* 支持转发到同一个服务不同接口

#### 事件回调

* 事件订阅
* 最大重试 3 次
* 重试时间采用衰减策略（30s、60s、180s）

### 系统架构

从第三方请求 API 链路来说，第三方渠道通过 HTTP 协议请求 OpenAPI 网关，网关再将请求转发到对应的内部服务端口，这些端口层通过 gRPC 调用请求到服务层，处理完请求后依次返回。

从事件回调请求链路来说，服务层通过 HTTP 协议发起事件回调请求到 OpenAPI 网关，并立即返回成功。OpenAPI 网关异步完成第三方渠道事件回调请求。 

![系统架构](https://img2.fanhaobai.com/2020/07/openapi/f227c462-b9b9-4846-aeae-23c579b05087.jpeg)

## 实现

### 网关配置

由于网关存在内部服务和第三方渠道配置，更为了实现配置的热更新，我们采用了 ETCD 存储配置，存储格式为 JSON。

#### 配置分类

配置分为以下 3 类：

* 第三方 AppId 配置
* 内外 API 映射关系
* 内部服务地址

#### 配置结构

a、第三方 AppId 配置

![AppId配置](https://img3.fanhaobai.com/2020/07/openapi/9655aec3-aa6c-4353-819e-a095a0fdd5bf.png)

b、内部服务地址

![内部服务地址](https://img4.fanhaobai.com/2020/07/openapi/48e89e9b-eede-4aec-b98f-ce50cc112c99.png)

c、内外 API 映射关系

![API映射关系](https://img5.fanhaobai.com/2020/07/openapi/676dcc84-628d-493c-8ab6-c9f2ec3053df.png)

#### 配置更新

利用 ETCD 的 watch 监听，可以轻易实现配置的热更新。

![配置热更新](https://img0.fanhaobai.com/2020/07/openapi/549e72de-cdbd-4b8d-a238-085f226d7555.jpg)

当然也还是需要主动拉取配置的情况，如重启服务的时候。

![拉取热更新](https://img1.fanhaobai.com/2020/07/openapi/ae062ec1-7f3c-4535-916b-c9cd08734a7d.jpg)


### API 接口

第三方调用 API 接口的时序，大致如下：

![API调用时序](https://img2.fanhaobai.com/2020/07/openapi/a4768e8e-f961-4270-ba9d-69d2a317d49b.png)

#### 参数格式

为了简化对接流程，我们统一了 API 接口的请求参数格式。请求方式支持 POST 或者 GET。

![API调用时序](https://img3.fanhaobai.com/2020/07/openapi/d0131310-b7f8-4deb-aa9e-fcc6b28a47a2.png)

#### 接口签名

签名采用 md5 加密方式，算法可描述为：

1、将参数 p、m、a、t、v、ak、secret 的值按顺序拼接，得到字符串；
2、md5 第 1 步的字符串并截取前 16 位， 得到新字符串；
3、将第 2 步的字符串转化为小写，即为签名；

PHP 版的请求，如下：

```PHP
$appId = 'app id';
$appSecret = 'app secret';
$api = 'api method';

// 业务参数
$businessParams = [
  'orderId' => '123123132',
];

$time = time();
$params = [
  'p'  => json_encode($businessParams),
  'm'  => 'inquiry',
  'a'  => $api,
  't'  => $time,
  'v'  => 1,
  'ak' => $appId,
];

$signStr = implode('', array_values($params)) . $appSecret;
$sign = strtolower(substr(md5($signStr), 0, 16));

$params['s'] = $sign;
```

#### 接口版本控制

不同的接口版本，可以转发请求到不同的服务，或同一个服务的不同接口。

![接口版本控制](https://img4.fanhaobai.com/2020/07/openapi/c6987388-682d-403f-8621-caa1fa6cd266.png)


### 事件回调

通过事件回调机制，第三方可以订阅自己关注的事件。

![接口版本控制](https://img5.fanhaobai.com/2020/07/openapi/4b6660db-0e0c-4c6d-9716-0e63820f45e1.png)

## 对接接入

### 渠道接入

只需要配置第三方 AppId 信息，包括 secret、回调地址、模块权限。

![渠道AppId配置](https://img0.fanhaobai.com/2020/07/openapi/3321e082-1857-4c2b-8d19-a60334f9b4f5.png)

即，需要在 ETCD 执行如下操作：

```bash
$ etcdctl set /openapi/app/baidu '{
    "Id": "baidu",
    "Secret": "00cf2dcbf8fb6e73bc8de50a8c64880f",
    "Modules": {
        "inquiry": {
            "module": "inquiry",
            "CallBack": "http://www.baidu.com"
        }
    }
}'

```

### 服务接入

a、配置内部服务地址

![配置内部服务地址](https://img1.fanhaobai.com/2020/07/openapi/1a902abb-fb35-42e1-9f3a-c18e12074f11.png)

即，需要在 ETCD 执行如下操作：

```bash
$ etcdctl set /openapi/backend/form_openapi '{
    "type": "form",
    "Url": "http://med-ih-openapi.app.svc.cluster.local"
}'
```

b、配置内外 API 映射关系

![配置内部服务地址](https://img2.fanhaobai.com/2020/07/openapi/39befe95-381e-47ad-879d-e5433e778078.png)

同样，需要在 ETCD 执行如下操作：

```bash
$ etcdctl set /openapi/api/inquiry/createMedicine.v2 '{
    "Module": "inquiry",
    "Method": "createMedicine",
    "Backend": "form_openapi",
    "ApiParams": {
        "path": "inquiry/medicine-clinic/create"
    }
}'
```

c、接入事件回调

接入服务也需要按照第三方接入方式，并申请 AppId。回调业务参数约定为：

![配置内部服务地址](https://img3.fanhaobai.com/2020/07/openapi/ba4a385e-add6-40fe-aa30-40866f8e4f40.png)

Golang 版本的接入，如下：

```golang
const (
	AppId = "__inquiry"
	AppSecret = "xxxxxxxxxx"
	Version = "1"
)

type CallbackReq struct {
	TargetAppId string                 //目标APP Id
	Module      string                 //目标模块
	Event       string                 //事件
	Params      map[string]interface{} //参数
}

func generateData(req CallbackReq) map[string]string {
    params, _ := json.Marshal(req.Params)
	p := map[string]interface{}{
		"ak": req.TargetAppId,
		"m":  req.Module,
		"e":  req.Event,
		"p":  string(params),
	}

	pStr, _ := json.Marshal(p)
	postParams := map[string]string{
		"p":  string(pStr),
		"m":  "callback",
		"a":  "callback",
		"t":  fmt.Sprintf("%d", time.Now().Unix()),
		"v":  Version,
		"ak": AppId,
	}

	postParams["s"] = sign(getSignData(postParams) + AppSecret)
	
	return postParams
}

func getSignData(params map[string]string) string {
	return strings.Join([]string{params["p"], params["m"], params["a"], params["t"], params["v"], params["ak"]}, "")
}

func sign(str string) string {
	return strings.ToLower(utils.Md5(str)[0:16])
}
```

## 未来规划

* 后台支持配置 AppId
* 事件回调失败请求支持手动重试
* 请求限流
