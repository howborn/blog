---
title: APP接口多版本处理
date: 2017-08-19 18:36:09
tags:
- PHP
categories:
- 语言
- PHP
---

在开发 APP 端 API 接口时，随着 APP 的版本迭代，尽管通常 APP 只需要保持 4-5 个版本可用，过老版本会强制更新，但 API 接口避免不了出现多个版本的情况，那么 API 接口的多版本问题服务端怎么解决呢？

![](//www.fanhaobai.com/2017/08/api-version/114d5a46452f82018a1f0aaee82fdfab.png)<!--more-->

要实现 API 的版本控制，常见的方法就是引入版本号。本文结合 Yii 2 来进行演示。

## 版本号

传递 API 的版本号大致有两种方式：

* 版本号配置为子域名，但由于版本号变更频繁，该方式采用较少；
* 版本号嵌入 URL 中，如百度 API 的`http://api.map.baidu.com/direction/v2/transit`；
* 版本号放入 HTTP 请求头的 Accept 中，如`Accept: application/json; version=1`；

这两种方式都存在不足，第 1 种版本号跟资源不相关，所以违背 Restful 风格，第 2 种接口版本信息又不够直观。Yii 2 中混合了这两种方法实现了主版本号和小版本号，如下：

* 把每个主版本的 API 实现在一个单独的模块（例如 v1，v2），因此，API 的 URL 会包含主版本号；
* 在每一个主要版本（即相应的模块），使用 Accept 请求头确定小版本号实现具体业务逻辑；

之所以使用大小版本号是为了更好地分离代码。当小迭代或者 bug 修复时，更新小版本号，大的需求变更或者一次开发周期中迭代次数较多则更新大版本号。

## 版本兼容

每个版本代码放置于一个独立的目录下，由于项目中每个 API 同时存在多个版本，如果都是独立的多份代码，相邻版本之间逻辑大致相同，所以代码冗余较高，另外存在需要修改多份代码的情况，不易维护。

另一种方式是通过调整代码结构，新版本 [继承](#) 上一个版本，通过 [重写](#) 来更好地进行功能迭代和升级，同时也能版本兼容。

### 目录结构

根据大版本号分离成模块后，项目目录结构如下：

```PHP
api/
    controllers/
        BaseAction.php  #版本控制
        BaseController.php  #基础控制器 
    models/
        logics/
            RoomLogic.php   #房源的相关公用检索逻辑
        SolrModel.php       #solr基础Model
        RoomModel.php       #房源数据源
    modules/
        v1/                     #v1
            controllers/
                room/
                    ListAction.php  #List方法所有版本
                RoomController.php  #v1版的房源控制器,继承自BaseController
            models/
                logics/
                    RoomLogic.php   #v1版的房源检索逻辑,继承自RoomLogic.php
            Module.php
        v2/                     #v2
            controllers/
                room/
                    ListAction.php  #List方法所有版本
                RoomController.php  #v2版的房源控制器,继承自BaseController
            models/
                logics/
                    RoomLogic.php   #v2版的房源检索逻辑,继承自v1/RoomLogic.php
            Module.php
```

### 代码示例

在编码时，尽量将每个版本公有逻辑提出到 common 下，只将版本特有逻辑放置于对应版本下。

#### common

公有部分，包括公有逻辑，数据源 model 等，放置于 controllers、models 部分。

* BaseAction.php

BaseAction 用户处理小版本路由，后续的 Action 都继承自此。

```PHP
namespace api\controllers;

use yii\base\InvalidCallException;
use yii\helpers\ArrayHelper;

class BaseAction extends \yii\base\Action
{
    /**
     * 版本逻辑
     */
    public function run()
    {
        $version = ArrayHelper::getValue(\Yii::$app->response->acceptParams, 'version', 1);
        if (method_exists($this, "version$version")) {
            call_user_func([$this, "version$version"]);
        } else {
            throw new InvalidCallException('invaild version.');
        }
    }
}
```

* RoomModel.php

```PHP
namespace api\models;

class RoomModel extends SolrModel
{
}
```

* RoomLogic.php

```PHP
namespace api\models\logics;

use api\models\RoomModel;

class RoomLogic
{
    /**
     * 统计房源数
     * @param array $params
     * @return array
     */
    public static function countRoomByResblock(array $params)
    {
        $model = new RoomModel();
        echo '从solr获取信息', PHP_EOL;
    }
}
```

#### v1

v1 版本为初始版本，大部分逻辑只需继承自公有逻辑`common/RoomLogic.php`。

* v1/RoomController.php

```PHP
namespace api\modules\v1\controllers;

use api\modules\v1\models\logics\RoomLogic;

class RoomController extends \api\controllers\BaseAction
{
    public function actions()
    {
        return [
            'list' => ['class' => 'api\modules\v1\controllers\room\ListAction']
        ];
    }
}
```

* v1/ListAction.php

```PHP
namespace api\modules\v1\controllers\room;

use api\modules\v1\models\logics\RoomLogic;
use yii\base\DynamicModel;

class ListAction extends \api\controllers\BaseAction
{
    //v1.1版本
    public function version1()
    {
        echo 'v1：', PHP_EOL;
        RoomLogic::countRoomByResblock($form->attributes);
    }
    
    //v1.2版本
    public function version2()
    {
        echo 'v1.2：', PHP_EOL;
        RoomLogic::countRoomByResblock($form->attributes);
    }
}
```

* v1/RoomLogic.php

```PHP
namespace api\modules\v1\models\logics;

class RoomLogic extends \api\models\logics\RoomLogic
{
    /**
     * v1版统计房源
     * @param array $params
     * @return array
     */
    public static function countRoomByResblock(array $params)
    {
        parent::countRoomByResblock($params);
    }
}
```

v1 版结果如下：

```Js
//请求信息
GET /v1/room/list.json
Accept: application/json; version=1
//响应
v1：
从solr获取信息
```

#### v2

v2 版逻辑对 v1 版进行了扩展，比如返回小区房源的最低价、小区房源总数等。

* v2/RoomController.php

```PHP
namespace api\modules\v2\controllers;

use api\controllers\BaseController;
use api\modules\v2\models\logics\RoomLogic;

class RoomController extends BaseController
{
    public function actions()
    {
        return [
            'list' => ['class' => 'api\modules\v2\controllers\room\ListAction']
        ];
    }
}
```

* v2/ListAction.php

```PHP
namespace api\modules\v2\controllers\room;

use api\modules\v2\models\logics\RoomLogic;
use yii\base\DynamicModel;

class ListAction extends \api\controllers\BaseAction
{
    //v2.1版本
    public function version1()
    {
        echo 'v2：', PHP_EOL;
        RoomLogic::countRoomByResblock($form->attributes);
    }
}
```

* v2/RoomLogic.php

```PHP
namespace api\modules\v2\models\logics;

class RoomLogic extends \api\modules\v1\models\logics\RoomLogic
{
    /**
     * v2版统计房源
     * @param array $params
     * @return array
     */
    public static function countRoomByResblock(array $params)
    {
        parent::countRoomByResblock($params);
        echo '我扩展了v1版逻辑', PHP_EOL;
    }
}
```

v2 版结果如下：

```Js
//请求信息
GET /v2/room/list.json
Accept: application/json; version=1
//响应
v2：
从solr获取信息
我扩展了v1版逻辑
```

#### v3

 如果某一天，数据源需要从 solr 切换到 es，那么只需改写共有`RoomLogic.php`并保持数据结构不变，老版本数据也就切换为 es 了。

RoomModel 修改：

```PHP
namespace api\models;

class RoomModel extends EsModel
{
}
```

RoomLogic 部分修改 countRoomByResblock 方法：

```PHP
namespace api\models\logics;

use api\models\RoomModel;

class RoomLogic
{
    public static function countRoomByResblock(array $params)
    {
        $model = new RoomModel();
        echo '从es获取信息', PHP_EOL;
    }
}
```

v3 版结果如下：

```Js
v3：
从es获取信息
我扩展了v1版逻辑
```

老版本 v2 版结果如下；

```Js
v2：
从es获取信息
我扩展了v1版逻辑
```

## 总结

本文叙述的方式，虽然多个版本时代码不会冗余，但是每个版本之间会有较强的依赖关系，并没有做到应用解耦。实际中还需根据业务场景选择合适的版本处理方案，本文仅提供一种实现思路。
