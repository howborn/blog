---
title: MySQL中处理重复数据
date: 2017-09-02 13:53:49
tags:
- MySQL
categories:
- DB
- MySQL
---

在需要保证数据唯一性的场景中，个人觉得任何使用程序逻辑的重复校验都是不可靠的，这时只能在数据存储层做唯一性校验。MySQL 中以唯一键保证数据的唯一性，那么若新插入重复数据时，我们可以让 MySQL 怎么来处理呢？<!--more-->

MySQL 支持 3 种数据重复时的原子操作，下面结合示例进行说明。示例的表结构为：

```SQL
CREATE TABLE `allowed_user`
(
  `id` INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uid` VARCHAR(36)  DEFAULT ''  NOT NULL,
  `last_time` TIMESTAMP  NOT NULL,
  UNIQUE (uid)
)

INSERT INTO `allowed_user` (`uid`, `last_time`) VALUES ('8e9b8c14-fae8-49d4-bbac-a733c09ec82f', '2017-09-03 19:31:15')
```

## Replace Into

Replace Into 方式的行为为当存在 Unique 相同的记录，则 [覆盖](#) 原有记录。实则为 Delete 和 Insert 两组合的原子操作，会改变该条记录的主键。

```SQL
REPLACE INTO `allowed_user` (`uid`, `last_time`) VALUES ('8e9b8c14-fae8-49d4-bbac-a733c09ec82f', '2017-09-01 19:31:15')
```

注意执行影响行数为 2：

```SQL
2 rows affected in 76ms
```

## On Duplicate Key Update

该方式当存在 Unique 相同的记录时，执行 Update 子句更新记录，否则执行 Insert 子句插入新记录。在 Update 时记录的主键并不会改变。

```SQL
INSERT INTO `allowed_user` (`uid`, `last_time`) VALUES ('8e9b8c14-fae8-49d4-bbac-a733c09ec82f', '2017-09-01 19:31:15') ON DUPLICATE  KEY UPDATE `last_time` = '2017-09-01 19:40:15'
```

SQL 执行影响记录数为 2 条。

## Ignore

Ignore 方式为在 Unique 相同的记录时，不做任何更新和插入操作，忽略本条记录，一般不使用。

```SQL
INSERT IGNORE INTO `allowed_user` (`uid`, `last_time`) VALUES ('8e9b8c14-fae8-49d4-bbac-a733c09ec82f', '2017-09-01 19:41:15')
```

## 场景案例

在某个活动场景中，需要区分用户是否具有资格，而只要签过约的用户就认为具有这种资格。以上述示例表作为用户资格关系的存储。

推送 uid 为 8e9b8c14-fae8-49d4-bbac-a733c09ec82f 用户的资格接口操作逻辑，大概是这样：

```PHP
try {
    $user = $model->query("SELECT * FROM `allowed_user` WHERE `uid` = '8e9b8c14-fae8-49d4-bbac-a733c09ec82f'");
    if ($user) {
       $model->exec("UPDATE `allowed_user` SET `last_time` = '2017-09-01 19:50:15' WHERE `uid` = '8e9b8c14-fae8-49d4-bbac-a733c09ec82f'");
    } else {
       $model->exec("INSERT INTO `allowed_user` (`uid`, `last_time`) VALUES ('8e9b8c14-fae8-49d4-bbac-a733c09ec82f', '2017-09-01 19:50:15'");
    }
} catch(Exception $e) {

}
```

这段代码通过程序逻辑去试图保证唯一性，但是在高并发情况下，并不能保证数据唯一性，因为不是原子性操作，修改后为：

```PHP
try {
    $model->exec("INSERT INTO `allowed_user` (`uid`, `last_time`) VALUES ('8e9b8c14-fae8-49d4-bbac-a733c09ec82f', '2017-09-01 19:50:15') ON DUPLICATE  KEY UPDATE `last_time` = '2017-09-01 19:50:15'");
} catch(Exception $e) {

}
```

