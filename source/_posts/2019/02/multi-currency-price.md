---
title: 商品价格的多币种方案
date: 2019-02-28 13:00:00
tags:
- 架构
categories:
- 架构
- PHP
---

假若，你是某个国内电商平台的商品中心项目负责人。突然今天，接到了一个这样的需求：商品在原人民币价格的基础架构上，须支持卢比（印度）价格。

![预览图](//www.fanhaobai.com/2019/02/multi-currency-price/434ddc25-3b51-4753-b5d5-b765ac5ca30c.jpg)<!--more-->

## 需求

需求点，可以描述为：

* 购买的用户，商品价格需要支持卢比；
* 营运人员，商品管理系统依然使用人民币价格；

同样这个需求，定了以下两个硬指标：

* 必须实现需求；
* 必须快速上线；

## 问题

首先，我们必须承认的是，这确实是个简单的需求，但这也是个够坑爹的需求。主要遇到的问题如下：

* 涉及商品价格的系统众多；
* 各上层系统调用商品价格接口繁多；
* 商品价格相关字段较多；

为了实现快速上线，我们在原人民币的商品价格基础架构上，只能进行少量且合适的改造。所以，最后我们的改造方向为：尽量只改造商品价格源头系统，即商品中心，其他上层系统尽量不改动。

## 可行性调研

改造商品中心，商品价格支持卢比。可行的改造方案有 2 种：

1、数据表价格字段存卢比

将原人民币价格相关的数据表字段，存卢比值，数据表并新增人民币字段。

2、接口输出数据时转化为卢比

原人民币相关的数据表字段依然存人民币值，在接口输出数据时，将价格相关字段值转化为卢比。

针对以上方案，我们需要注意 2 个问题：

* 汇率会每天变化，所以商品价格也会变化；
* 后续商品价格，可能须支持多币种；

上述 [方案 ①](#)，商品中心只需改造数据表。然后每天根据汇率刷新商品价格，原价格字段就都变成了卢比。方案相对简单，也容易操作，但缺点是：对任然需要人民币价格的系统，即商品管理系统须改造。
[方案 ②](#)，需要改造商品中心业务逻辑。由于涉及的价格字段较多，改造较复杂，主要优点是：汇率变动对商品价格影响较小，且可拓展支持多币种价格（可以根据地区标识，获取相应的商品价格）。

## 解决方案

最终，为了系统的可扩展性，我们选择了方案 ②。

![解决方案](//www.fanhaobai.com/2019/02/multi-currency-price/b5c63729-fd94-4f3b-b107-1b345d26c1c6.png)

这里主要改造了商品中心，主要解决 [透传地区标识](#透传地区标识) 和 [支持多币种价格](#支持多币种价格) 这 2 个问题。

### 透传地区标识

我们的业务系统主要分为 API 和 Service 项目，API 暴露出 HTTP 接口，API 与 Service 和 Service 与 Service 之前使用 RPC 接口通信。由于商品中心涉及到价格的接口繁多，不可能对每个接口都增加地区标识的参数。所以我们弄了一套调用链路透传地区标识的机制。

#### 机制原理

思路就是，先将地区标识放在全局上下文中，API 接口通过 Header 头`X-Location`携带地区标识；而对于 RPC 接口，我们的 RPC 框架已支持了 Context，不需要改造。

![透传地区标识机制](//www.fanhaobai.com/2019/02/multi-currency-price/4ff6ceb3-44c9-4edf-bfdb-23cf50b22c6f.png)

#### 代码实现

##### 传递全局上下文

由于 RPC 框架已支持了 Context，所以 API 和 RPC 接口透传全局上下文略有不同。实现如下：

```PHP
class Location
{
    public static function init()
    {
        global $context;

        if (empty($context['location'])) {
            return;
        }

        // API在这里直接获取X-Location头
        if (!empty($_SERVER['HTTP_X_LOCATION'])) {
            $context['location'] = $_SERVER['HTTP_X_LOCATION'];
        }
        // RPC Server会自动获取Context
    }
}
```

> 上述`init()`方法，需要在项目入口位置初始化。

其中，RPC 接口不需要操作全局上下文。因为 RPC Client 在调用时会自动获取全局变量`$context`值并在 RPC 协议数据中追加 Context，同时 RPC Server 在收到请求时会自动获取 RPC 协议数据中的 Context 值并设置全局变量`$context`。

RPC Client 传递 Context 实现如下：

```PHP
protected function addGlobalContext($data)
{
    global $context;

    $context = !is_array($context) ? array() : $context;
    
    // data为待请求的RPC协议数据
    $data['Context'] = $context;
    return $data;
}
```

RPC Server 获取 Context 实现如下：

```PHP
public function getGlobalContext($packet)
{
    global $context;
    
    $context = array();
    // packet为接收的RPC协议数据
    if(isset($packet['Context'])) {
        $context = $packet['Context'];
    }
}
```

当设置了 Context 后，RPC 通信时协议数据会携带`location`字段，内容如下：

```Json
RPC
325
{"data":"{\"version\":\"1.0\",\"user\":\"xxx\",\"password\":\"xxx\",\"timestamp\":1553225486.5455,\"class\":\"xxx\",\"method\":\"xxx\",\"params\":[1]}","signature":"xxx","Context":{"location":"india"}}
```

##### 设置地区标识

到这里，我们只需要在全局上下文设置地区标识即可。一旦我们设置了地区标识，所有业务系统就会在本次的调用链路中透传这个地区标识。实现如下：

```PHP
class Location
{
    public static function set($location)
    {
        global $context;

        $context['location'] = $location;
        // API需要在这里单独设置X-Location头
        header('X-Location: ' . $context['location']);
    }
}
```

##### 获取地区标识

设置了地区标识后，就可以在本次调用链路的所有业务系统中直接获取。实现如下：

```PHP
class Location
{
    public static function get()
    {
        global $context;

        if (!isset($context['location'])) {
            return 'china';
        }

        return $context['location'];
    }
}
```

### 支持多币种价格

#### 商品中心

有了地区标识后，商品中心服务就可以根据地区标识对价格字段进行转化了。因为设计到价格的数据表和价格字段较多，这里直接从数据层（Model）进行改造。

##### 改造获取数据方法

下述的`ReadBase`类是所有数据表 Model 的基类，所有获取数据表数据的方法都继承或调用自`getOne()` 和`getAll()`方法，所以我们只需要改造这两个方法。

```PHP
class ReadBase
{
    public function getOne(array $cond, $fields)
    {
        $data = $this->getReader()->select($this->getFields($fields))->from($this->getTableName())->where($cond)->queryRow();
        
        return $this->getExchangePrice($data);
    }
    
    public function getAll(array $cond, $fields)
    {
        $data = $this->getReader()->select($this->getFields($fields))->from($this->getTableName())->where($cond)->queryAll();
        
        if ($data) {
            foreach ($data as &$one) {
                 $this->getExchangePrice($one);
            }
        }
        
        return $data;
    }
}
```

##### 后缀匹配价格字段

由于涉及到价格字段名字较多，且具有不确定性，所以这里使用后缀方式匹配。为了防止一些字段命名不规范，这里引入了黑名单机制。

```PHP
protected function isExchangeField($field)
{
    $priceSuffix = array('cost', '_price');
    $black = array();
    $len = strlen($field) ;

    foreach ($priceSuffix as $suffix) {
        $lastPos = $len - strlen($suffix);
        // 非黑名单且非is_
        if (!in_array($field, $black)
            && false === strpos($field, 'is_')
            && $lastPos === strpos($field, $suffix)
        ) {
            return true;
        }
    }

    return false;
}
```

> 前缀为`is_`的字段一般定义为标识字段，默认为非价格字段。

##### 计算地区价格

上述`getExchangePrice()`方法，用来根据地区标识转化价格覆盖到原价格字段，并自增以`_origin`后缀的人民币价格字段。

```PHP
public function getExchangePrice(&$data)
{
    if (empty($data)) {
        return $data;
    }

    $originPrice = array();
    foreach ($data as $field => &$value) {
        // 是否是价格字段
        if ($this->isExchangeField($field)) {
            $originField = $field . '_origin';
            $originPrice[$originField] = $value;
            // 获取对应地区的价格
            $value = $this->getExchangePrice($value);
        }
    }
    
    $data = array_merge($originPrice, $data);

    return $data;
}

public static function getExchangePrice($price)
{
    // 获取地区标识
    $location = Location::get();
    // 汇率
    $exchangeRateConfig = \Config::$exchangeRate;
    if ($location === 'china') {
        return $price;
    } else if (isset($exchangeRateConfig[$location])) {
        $exchangeRate = $exchangeRateConfig[$location];
    } else {
        throw new \BusinessException("not found $location exchange rate");
    }
    // 向上取值并保留两位小数
    $exchangePrice = bcmul($price, $exchangeRate, 3);

    return number_format(ceil($exchangePrice * 100) / 100, 2, '.', '');
}
```

其中，`getExchangePrice()`方法会调用`Location::get()`获取地区标识，并根据汇率计算实时价格。

最终，商品中心改造后，得到的部分商品价格信息，如下：

```PHP
# 人民币价格10，汇率10.87
market_price: 108.7
market_price_origin: 10
```

#### API系统

对于所有 API 的项目，我们只需要让客户端在所有的请求中增加`X-Location`头即可。

```Nginx
GET /product/detail/1 HTTP/1.1

Request Headers
  X-Location: india
```

API 项目需在入口文件处，初始化地区标识。如下：

```PHP
Location::init();
```

#### 商品管理系统

对于商品管理系统，我们为了方便运营操作，所有商品价格都应以人民币。因此，我们只需要初始化地区标识为中国，如下：

```PHP
Location::init();
// 地区设置为中国
Location::set('china');
```

## 总结

为了实现需求很容易，但是要做到合理且快速却不简单。本文的实现的方案，避免了很多坑，但同时也可能又埋下了一些坑。没有一套方案是万能的，慢慢去优化吧！
