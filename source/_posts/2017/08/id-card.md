---
title: 身份证的编码规则
date: 2017-08-20 11:39:31
tags:
- PHP
categories:
- 语言
- PHP
---

在我国现行的身份证系统中共有 15 位和 18 位两种身份证号码，第一代身份证大多为 15 位号码，由于 15 位身份证只能为 1900.01.01 到 1999.12.31 出生的人编码（千年虫问题），所以后来逐步替换为 18 位的身份证号码。

![](//www.fanhaobai.com/2017/08/id-card/05f73384-a9ba-4a80-8433-563331dfd896.jpg)<!--more-->

## 编码规则

### 15位

15 位身份证编码规则为：[DDDDDD YYMMDD XXS](#)

各组成部分说明：

| 部分名    | 描述                            |
| ------ | ----------------------------- |
| DDDDDD | 6 位地区编码                       |
| YYMMDD | 出生年月。年份用 2 位表示                |
| XXS    | 顺序码。<br>其中 S 为性别识别码，奇数为男，偶数为女 |

例如某个 15 位 ID 为：513701930509101。

### 18位

18 位身份证较 15 位身份证，出生年月改变为 8 位，并引入了校验位。编码规则为：[DDDDDD YYYYMMDD XXX Y](#)

各组成部分说明：

| 部分名      | 描述              |
| -------- | --------------- |
| DDDDDD   | 6 位地区编码         |
| YYYYMMDD | 出生年月。年份用 4 位表示  |
| XXX      | 顺序码。奇数为男，偶数为女   |
| Y        | 校验位。前 17 位值计算而得 |

校验位 Y 取值范围为 [1, 0, X, 9, 8, 7, 6, 5, 4, 3, 2]，其采用加权方式校验，校验规则为：p = mod(∑(Ai×Wi), 11)

参数说明：
* i 为身份证数字所在的位数，1-17；
* Ai 为身份证第 i 位对应的数字值；
* Wi 为加权因子，值为 [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]；
* p 表示获取 Y 范围值的第 p+1 个值作为校验值 Y；

例如某个 18 位 ID 位：513701199305091010，校验位后续计算得出。

## 格式校验

通过分析身份证的 [编码规则](#编码规则)，我们就可以得出身份证的校验规则，这里使用正则表达式去进行匹配。

### 15位

15 位身份证`DDDDDD YYMMDD XXS`的每部分的正则匹配表达式为：

| 部分名    | 正则表达式                                    |
| ------ | ---------------------------------------- |
| DDDDDD | [1-9]\d{5}                               |
| YYMMDD | (\d{2})(0\[1-9\]&#124;(1\[0-2\]))((\[0-2\]\[1-9\])&#124;([1-2]0)&#124;31) |
| XXS    | \d{3}                                    |

由此可得 15 位身份证证正则匹配表达式为：

```Js
'^[1-9]\d{5}\d{2}(0[1-9]|(1[0-2]))(([0-2][1-9])|([1-2]0)|31)\d{3}$'
//可简化为:
'^[1-9]\d{7}(0[1-9]|1[0-2])([0-2][1-9]|[1-2]0|31)\d{3}$'
```

PHP 中校验为：

```PHP
const ID_15_PREG = '/^[1-9]\d{7}(0[1-9]|1[0-2])([0-2][1-9]|[1-2]0|31)\d{3}$/';

public static function validate($id)
{
    if (!is_string($id) || empty($id)) {
        return false;
    } else if (strlen($id) == 15 && preg_match(static::ID_15_PREG, $id)) {
        return true;
    }
    return false;
}
```

### 18位

同理，18 位身份证`DDDDDD YYYYMMDD XXX Y`的每部分的正则匹配表达式为：

| 部分名      | 正则表达式                                    |
| -------- | ---------------------------------------- |
| DDDDDD   | [1-9]\d{5}                               |
| YYYYMMDD | (\[1-9\]\d{3})(0\[1-9\]&#124;(1\[0-2\]))((\[0-2\]\[1-9\])&#124;([1-2]0)&#124;31) |
| XXX      | \d{3}                                    |
| Y        | \d                                       |

由此可得 18 位身份证证正则匹配表达式为： 

```Js
'^[1-9]\d{5}([1-9]\d{3})((0[1-9]|(1[0-2]))(([0-2][1-9])|([1-2]0)|31)\d{3}\d|[Xx]$'
//可简化为：
'^[1-9]\d{5}[1-9]\d{3}(0[1-9]|1[0-2])([0-2][1-9]|[1-2]0|31)(\d{4}|\d{3}[Xx])$'
```

根据校验位校验规则，实现 **校验位** 的编码：

```PHP
public static function getCheckBit($id)
{
    if (18 !== strlen($id)) {
        return false;
    }
    $yArr = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
    $wArr = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    $sum = 0;
    for ($i = strlen($id)-2; $i>=0; $i--) {
        $sum += $id[$i] * $wArr[$i];
    }
    $key = $sum % 11;
    return $yArr[$key];
}
```

所以，PHP 中校验逻辑为:

```PHP
const ID_18_PREG = '/^[1-9]\d{5}[1-9]\d{3}(0[1-9]|1[0-2])([0-2][1-9]|[1-2]0|31)(\d{4}|\d{3}[Xx])$/';

public static function validate($id)
{
    if (!is_string($id) || empty($id)) {
        return false;
    } else if (strlen($id) == 18 && preg_match(static::ID_18_PREG, $id) && strtoupper($id[17]) === self::getCheckBit($id)) {
       return true;
    } else if (strlen($id) == 15 && preg_match(static::ID_15_PREG, $id)) {
        return true;
    }
    return false;
}
```

## 15位转化为18位

在金融等某些特殊行业，需要将 15 位身份证号码格式化为 18 位。由于 15 位身份证颁发年份都是 19\*\* 年，所以在转化为 18 位时补充出生年份时直接添加 19 即可。

转化步骤：
* 年份补全成 4 位，年份前直接添加 19；
* 补全上步的新号码为 18 位，可以在原号码末尾直接追加 X；
* 计算新号码的校验位并替换原校验位值；

15 位身份证转化为 18 位的代码如下：

```PHP
public static function format18($id)
{
    if (!static::validate($id)) {
        return '';
    } else if (15 !== strlen($id)) {
        return $id;
    }
    $newId = substr($id, 0, 6) . '19' . substr($id, -9) . 'X';
    $newId[17] = static::getCheckBit($newId);
    return $newId;
}
```

转化示例结果：

```PHP
//15位---------------------18位
'370725881105149' => '37072519881105149X'
```

