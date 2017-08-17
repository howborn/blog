---
title: 漫画：什么是 Bitmap 算法？
date: 2017-08-16 23:10:42
tags:
- Bitmap
categories:
- 算法
---

> 转自 [伯乐专栏 玻璃猫](https://mp.weixin.qq.com/s?__biz=MjM5OTA1MDUyMA==&mid=2655438893&idx=2&sn=42383086a358b718d7de569c42b5fbf8&chksm=bd73045a8a048d4c4237d362d7007889740f4b75de565325ee28aeba183380e3e03d1dce37b8&mpshare=1&scene=23&srcid=0817azlyj8TR6xsyxW0KNolG##)

本文的灵感来源于京东金融数据部张洪雨同学的项目经历，感谢这位大神的技术分享。

{% asset_img e897a05e-90c5-442f-8700-b07650c5bb79.png %}<!--more-->

{% asset_img de158ff0-a75a-4742-890f-7f8fa54e8429.jpg %}

{% asset_img b94d2ee6-08b8-46bb-bc14-648d25f3d1b0.jpg %}

{% asset_img 2ecb7934-8521-4b03-a13d-27a884d2cb18.jpg %}

{% asset_img f9dc49b3-503c-427e-8256-7db81b39466f.jpg %}

为满足用户标签的统计需求，小灰利用 MySQL 设计了如下的表结构，每一个维度的标签都对应着 MySQL 表的一列：

{% asset_img 98132f45-baeb-4317-823f-28994b6a1b53.jpg %}

要想统计所有 90 后的程序员该怎么做呢？

用一条求交集的 SQL 语句即可：

```SQL
SELECT COUNT(DISTINCT name) AS 用户数 FROM table WHERE age = '90后' AND occupation = '程序员'
```

要想统计所有使用苹果手机或者 00 后的用户总合该怎么做？用一条求并集的 SQL 语句即可：

```SQL
SELECT COUNT(DISTINCT name) AS 用户数 FROM table WHERE phone = '苹果' OR age = '00后'
```

两个月之后——

{% asset_img 57833b05-cf4c-4f30-8ff2-a5c5f3682139.jpg %}

———————————————

{% asset_img f0c74969-652b-4fa2-b980-fc4f5f99c61d.jpg %}

{% asset_img b94201a7-beaf-4613-beda-f7a3674f5228.jpg %}

{% asset_img bf6bf8d3-3801-4fca-b229-8cc83ea5ba81.jpg %}

{% asset_img bf0f2d59-b0de-4f96-b598-ffccb8677758.jpg %}

1.给定长度是 10 的 bitmap，每一个 bit 位分别对应着从 0 到 9 的 10 个整型数。此时 bitmap 的所有位都是 0。

{% asset_img 5ad4199b-e5d1-45f9-9657-98f2f2c34960.png %}

2.把整型数 4 存入 bitmap，对应存储的位置就是下标为 4 的位置，将此 bit 置为 1。

{% asset_img 2f3a90c8-afe8-4d5c-995a-d064ac1f5336.png %}

3.把整型数 2 存入 bitmap，对应存储的位置就是下标为 2 的位置，将此 bit 置为 1。

{% asset_img fc1939b6-a486-4998-9507-c3e5825bce9a.png %}

4.把整型数 1 存入 bitmap，对应存储的位置就是下标为 1 的位置，将此 bit 置为 1。

{% asset_img eda83296-8ff6-4558-975c-a73860cccc54.png %}

5.把整型数 3 存入 bitmap，对应存储的位置就是下标为 3 的位置，将此 bit 置为 1。

{% asset_img f4079a06-d308-4f25-ad37-46f2d1baf851.png %}

要问此时 bitmap 里存储了哪些元素？显然是 4,3,2,1，一目了然。

bitmap 不仅方便查询，还可以去除掉重复的整型数。

{% asset_img 92401d1b-02ac-446f-908e-3057fa9c7fd4.jpg %}

{% asset_img 8be164ef-9f6a-4a56-8a5d-53b417c9310a.jpg %}

{% asset_img 3933f7cb-934c-42e7-8fc7-989b3e021010.jpg %}

{% asset_img e0e6f586-03ce-4d11-a390-34ff3c25400b.jpg %}

1.建立用户名和用户 ID 的映射。

{% asset_img a134be42-9acb-41c6-bc80-469b86de8ba0.png %}

2.让每一个标签存储包含此标签的所有用户 ID，每一个标签都是一个独立的 bitmap。

{% asset_img 1dbec168-cbf6-4b42-bb56-ca143f559d06.jpg %}

3.这样，实现用户的去重和查询统计，就变得一目了然。

{% asset_img 3c423c70-2ed7-4cc4-a6fa-ce56bf285a5b.jpg %}


{% asset_img 63f0f0a2-22e4-49dd-bcec-47e43fc69787.jpg %}

{% asset_img 1da4242d-018f-4cf4-82c3-e3421b4cf003.jpg %}

{% asset_img a9997194-b4d8-4cf5-bb3e-33a68229729b.jpg %}

1.如何查找使用苹果手机的程序员用户？

{% asset_img d68e8fa2-433a-47dc-8aed-ff1b993cf082.png %}

2.如何查找所有男性或者00后的用户？

{% asset_img 45ef8692-b1d3-4b4b-a6ed-dbe105fb3f97.png %}

{% asset_img 97c98774-03b3-47ed-852c-71d1a546a65c.jpg %}

{% asset_img d14eff84-5eb1-4268-87ae-4776c66af4a5.jpg %}

{% asset_img 1605c694-bf55-4500-9531-9832df13b082.jpg %}

{% asset_img 24836d0b-efb2-450f-9307-d078722e2c72.jpg %}

{% asset_img e72e268a-facd-4480-85be-c779db24ee74.jpg %}

[说明]()：该项目最初的技术选型并非 MySQL，而是内存数据库 hana。本文为了便于理解，把最初的存储方案写成了 MySQL 数据库。

<strong>漫画算法系列 [»]()</strong>

* [漫画算法：最小栈的实现](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560419&idx=1&sn=535073d4d69cf7fc45074ccb8c25ba1e&chksm=f1fee120c68968367597137515f21ef8d7a8ab68c9f4fce051dae5f2631afdc48ec11a30dd0e&scene=21#wechat_redirect)
* [漫画算法：判断 2 的乘方](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560448&idx=1&sn=b4ca3d01a438fac78be4077f270974ca&chksm=f1fee143c6896855179eff005164be47c7c662d4c8badf571a79c4acd9e2aca9fd84839ca093&scene=21#wechat_redirect)
* [漫画算法：找出缺失的整数](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560411&idx=1&sn=2e655df46f082a50a4657a40f292d63a&chksm=f1fee118c689680eba2b9ba965780387aeafd08a72eecb2c748eece85b77631b0a5511f2833b&scene=21#wechat_redirect)
* [漫画算法：辗转相除法是什么鬼？](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560408&idx=1&sn=db553ce9deedf38c44841e16cb095d2e&chksm=f1fee11bc689680d83ff71d40dc191ee9899b8e5ef4bf9b98001ebb4daf13059a5961586ea1a&scene=21#wechat_redirect)
* [漫画算法：什么是动态规划？（整合版）](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650561168&idx=1&sn=9d1c6f7ba6d651c75399c4aa5254a7d8&chksm=f1feec13c6896505f7886d9455278ad39749d377a63908c59c1fdceb11241e577ff6d66931e4&scene=21#wechat_redirect)
* [漫画算法：什么是跳跃表？](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650561205&idx=1&sn=3c4feb6339e00e13bdd8cc6a11eb0304&chksm=f1feec36c689652085b1b89acd6ca07316140f1c7478249e4b251c204b6cf3a5bb276b0275be&scene=21#wechat_redirect)
* [漫画算法：什么是 B 树？](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650561220&idx=1&sn=2a6d8a0290f967027b1d54456f586405&chksm=f1feec47c689655113fa65f7911a1f59bbd994030ad685152b30e53d643049f969eefaa13058&scene=21#wechat_redirect)
* [漫画算法：什么是 B+ 树？](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650561244&idx=1&sn=df3abafd3aa2f5a3abfe507bfc26982f&chksm=f1feec5fc6896549f89cbb82ee3d8010c63da76814030b285fa29322795de512ccca207064ee&scene=21#wechat_redirect)
* [漫画算法：什么是一致性哈希？](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650561254&idx=1&sn=7500e3e54a573b19ce2fbfa0a82f2b13&chksm=f1feec65c689657386c8913f819bb5253bece3bd56f7fcc725201c925723e2fbc5bfcb962b9c&scene=21#wechat_redirect)
* [漫画算法：无序数组排序后的最大相邻差值](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560503&idx=1&sn=461c62e9c88fb6fbd30a0a4a59bce76f&chksm=f1fee174c68968628afbcdc7fdbba04daef811dd94de94bf90a6a4e0b907d1b67638eaabe2ff&scene=21#wechat_redirect)
