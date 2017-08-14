---
title: 解决YII2验证码不刷新问题
date: 2017-06-21 21:33:35
tags:
- Yii
categories:
- 语言
- PHP
---

在 Yii 2 中的验证码功能的确很方便，但是会存在刷新页面并不会刷新验证码的现象，不知道作者这么做有什么意图？在实际应用中，有较多的场景需要刷新页面并刷新验证码，这里在不修改框架源码的情况下，给出了可供参考的解决办法。

{% asset_img 72ac98c8-56b4-4b12-b720-8aa703a017d3.png %}<!--more-->

## 抛出问题

示例中的验证码配置如下：

```PHP
class SiteController extends Controller
{
    public function actions()
    {
        return [
            'captcha' => [
                'class' => 'yii\captcha\CaptchaAction',
                'testLimit' => 1,
                'minLength' => 6,
                'maxLength' => 6,
            ],
        ];
    }
}
```

### 页面刷新验证码不刷新

通过 Widgets 渲染出验证码，连续刷新页面多次，验证码并未刷新。

{% asset_img 72ac98c8-56b4-4b12-b720-8aa703a017d3.png %}

### 点击刷新发送两次请求

点击验证码，可以刷新验证码，交互流程如下图所示。

{% asset_img 062108a6-c588-4589-892c-3cfa86b53cc9.png %}

第 1 次请求只返回获取新验证码的地址，响应内容如下：

```Js
{
    hash1: 654,
    hash2: 654,
    url: "/index.php?r=site/captcha&v=594aa9aa20d37"
}
```

第 2 次请求新验证码地址，才能获取到新的验证码。共发送 2 次请求，本可以 1 次请求解决的问题。可见，刷新页面不刷新验证码的问题也可以通过这种方式解决。

## 分析问题

至于为什么直接刷新页面没有刷新验证码，而通过点击验证码就能刷新验证码呢？先分析源码。

```PHP
class CaptchaAction extends Action
{
    /**
     * The name of the GET parameter indicating whether the CAPTCHA image should be regenerated.
     */
    const REFRESH_GET_VAR = 'refresh';
    ... ...
    
    public function run()
    {
        if (Yii::$app->request->getQueryParam(self::REFRESH_GET_VAR) !== null) {
            // AJAX request for regenerating code
            $code = $this->getVerifyCode(true);
            Yii::$app->response->format = Response::FORMAT_JSON;
            return [
                'hash1' => $this->generateValidationHash($code),
                'hash2' => $this->generateValidationHash(strtolower($code)),
                // we add a random 'v' parameter so that FireFox can refresh the image
                // when src attribute of image tag is changed
                'url' => Url::to([$this->id, 'v' => uniqid()]),
            ];
        } else {
            $this->setHttpHeaders();
            Yii::$app->response->format = Response::FORMAT_RAW;
            return $this->renderImage($this->getVerifyCode());
        }
    }
}
```

通过源码可以看出，请求时携带 refresh 字段，即认为是 AJAX 请求，并以 JSON 格式返回新的验证码地址；如果没有携带该字段，则直接渲染验证码图片。那么，为什么携带 refresh 字段请求后再直接请求验证码，就会刷新验证码呢？2 个流程分支中都调用了 getVerifyCode() 方法，但是参数并不同。查看 getVerifyCode() 方法源码：

```PHP
/**
 * Gets the verification code.
 * @param bool $regenerate whether the verification code should be regenerated.
 * @return string the verification code.
 */
public function getVerifyCode($regenerate = false)
{
    if ($this->fixedVerifyCode !== null) {
    	return $this->fixedVerifyCode;
    }
    $session = Yii::$app->getSession();
    $session->open();
    $name = $this->getSessionKey();
    if ($session[$name] === null || $regenerate) {
        $session[$name] = $this->generateVerifyCode();
        $session[$name . 'count'] = 1;
    }
    return $session[$name];
}
```

可见 getVerifyCode() 方法是根据 $regenerate 值，确定是否获取新的验证码值，所以可以直接将 run()  中的调用都更改为 getVerifyCode(true)。更改后，调试发现验证码可以跟随页面刷新，但是为了方便维护，不建议直接修改源码。

## 解决问题

通过上述分析可知，修改 run() 方法中调用为 getVerifyCode(true) 可以解决问题，但是又不能修改源码，这时可以采取继承并重载的方法来实现了。

```PHP
namespace admin\controllers\action;

use yii\web\Response;

class CaptchaAction extends \yii\captcha\CaptchaAction
{

    /**
     * 默认验证码刷新页面不会自动刷新
     */
    public function run()
    {
        $this->setHttpHeaders();
        \Yii::$app->response->format = Response::FORMAT_RAW;
        return $this->renderImage($this->getVerifyCode(true));
    }

}
```

在 SiteController 控制器中注册 CaptchaAction 方法：

```PHP
public function actions()
{
    return [
        //默认验证码刷新页面不会自动刷新
        'captcha' => [
            'class' => 'admin\controllers\action\CaptchaAction',
            'testLimit' => 1,
            'maxLength' => 6,
            'minLength' => 6,
            'padding' => 1,
            'height' => 50,
            'width' => 140,
            'offset' => 1,
        ],
    ];
}
```

设置验证码验证规则：

```PHP
class JoinForm extends \yii\base\Model
{
    /**
     * 验证码
     * @var
     */
    public $captcha;
    ... ...
    /**
     * 规则
     */
    public function rules()
    {
        return [
            [['captcha'], 'required'],
            //验证码校验
            ['captcha', 'captcha', 'captchaAction' => '/site/captcha'],
        ];
    }
}
```

## 验证

经过修改后，每次刷新页面验证码也会刷新，刷新验证码也只需要请求 1 次即可。

{% asset_img b055c2be-3113-190f-5ea9-4f98b2e77e89.png %}

{% asset_img 4e4de2c6-3098-c251-4c66-82c429ab991c.png %}
