---
title: 漫画：什么是B-树？
date: 2017-07-08 14:56:57
tags:
- B-
categories:
- 数据结构
---

> 原文：http://mp.weixin.qq.com/s/raIWLUM1kdbYvz0lTWPTvw

{% asset_img 76ee8b6f-b653-416b-bb44-99101a6fc40f.jpg %}<!--more-->

{% asset_img 059c4183-9028-4abe-89c6-c12d9393d36e.jpg %}

{% asset_img 3adf96f5-9791-44ff-b423-26cb34741be1.jpg %}

{% asset_img 0986b67c-7e37-4411-b057-9dbbf20930bb.jpg %}

{% asset_img 6137cf60-4db5-4e63-ba41-cea1dfe1de61.jpg %}

————————————

{% asset_img  2cd5bcec-3f3f-4ae7-959e-071d07ec1c3b.jpg %}

{% asset_img  9ea9ea0e-d6a6-42ae-aace-5a1661ff9cc4.jpg %}

{% asset_img  6b29f560-e192-4558-a399-5e125ca893e0.jpg %}

{% asset_img  f2725bec-63b0-11e7-907b-a6006ad3dba0.jpg %}

{% asset_img  53719e92-49f8-450b-9ffc-f2cfbb96295a.jpg %}

{% asset_img  a2c81ffd-01f9-4c73-8b03-2aa46d8edf6f.jpg %}

{% asset_img  6421f60a-6bd4-4c11-bd00-e6864b6c2f7c.jpg %}

{% asset_img  1c9bb154-d47b-49ad-a33b-51a74021eb15.jpg %}

{% asset_img  fb9a98ce-0b30-485b-af53-3b6c780aa299.jpg %}

————————————

{% asset_img 20763cbb-12b3-4e9a-a00b-1759e1356231.jpg %}

{% asset_img 14f6e592-ee53-42d7-b06b-050c595b2826.jpg %}

{% asset_img 2ad346da-5243-492e-b30d-560a744c622e.jpg %}

{% asset_img c5a8411b-2233-47b7-9695-c99bf231fcdd.jpg %}

{% asset_img d2135b8d-3cf3-4a54-93af-695145ffa485.jpg %}

{% asset_img 5f468cb8-857c-4d67-8772-d86ee9d9340d.jpg %}

{% asset_img e656282b-2e69-4c66-8351-9b4c9eaff541.jpg %}

{% asset_img 6368f5b1-d08e-488c-b23e-a9cf783ea481.jpg %}

{% asset_img 19301a61-5d3f-422f-b66e-4853fd5c7caf.jpg %}

{% asset_img 180daa1d-b025-423a-89f5-0c5cd94af1e9.jpg %}

{% asset_img 78e65b5a-c9c1-4e19-841b-a06879f70032.jpg %}

{% asset_img 42085b9b-c60f-4d6b-bce4-056bb60f9b82.jpg %}

{% asset_img 86fe22ab-fd0b-4ca0-a846-b5dc701c6581.jpg %}

{% asset_img 855e1037-3a90-49bb-8310-d9e3911962cf.jpg %}

二叉查找树的结构：

{% asset_img e8fd2614-0fc7-432a-b9fd-00ed5f24f3a3.jpg %}

第 1 次磁盘 IO：

{% asset_img d710d2fe-ecee-458f-b478-65b32bedc7d4.jpg %}

第 2 次磁盘 IO：

{% asset_img 842c3607-8a20-405f-8a16-12b26ab75b8d.jpg %}

第 3 次磁盘 IO：

{% asset_img 9ad3c9a8-a874-4a25-a51d-25c8bb440b6c.jpg %}

第 4 次磁盘 IO：

{% asset_img 60f11fd4-1c37-44a9-8d1c-f1a194559e37.jpg %}

{% asset_img b98ea743-190d-449b-9253-b5e036d6d5ee.jpg %}

{% asset_img 5ec15194-a2fa-4431-83ba-53b3ba63be8f.jpg %}

{% asset_img d2ae3188-0d70-4e2e-b1b5-6df2971185cf.jpg %}

{% asset_img 12e9c3d2-280c-41ff-b5fd-67d79d884f3a.jpg %}

下面来具体介绍一下 B- 树（Balance Tree），一个 m 阶的 B 树具有如下几个 **特征** ：

1.根结点至少有两个子女。
2.每个中间节点都包含 k-1 个元素和 k 个孩子，其中 m/2 <= k <= m。
3.每一个叶子节点都包含 k-1 个元素，其中 m/2 <= k <= m。
4.所有的叶子结点都位于同一层。
5.每个节点中的元素从小到大排列，节点当中 k-1 个元素正好是 k 个孩子包含的元素的值域分划。

{% asset_img a73a2881-7837-4b23-9c39-b6044dc0e26c.jpg %}

{% asset_img a9c34b2b-a73c-4611-a05a-a67a0b3e63c5.jpg %}

{% asset_img ba56f5d6-e9e7-41bf-a9d7-3045cbb1f114.jpg %}

{% asset_img 87a0a1d6-fa9e-4a1f-9e9a-6c07ec5c5509.jpg %}

{% asset_img 070ad465-7638-4f4c-8c4d-ef3e7ceff2a6.jpg %}

{% asset_img 05afc638-3c1a-4020-98bd-78fa0ba6826d.jpg %}

{% asset_img 8438d6ce-bd67-4d4e-9dd4-06493d0ef144.jpg %}

第 1 次磁盘 IO：

{% asset_img 4b90f113-fa96-4189-8804-73e8b1ff682e.jpg %}

在内存中定位（和 9 比较）：

{% asset_img c2045edc-f98d-43b1-a21e-d0dbecf39c4b.jpg %}

第 2 次磁盘 IO：

{% asset_img d1c0b5a6-f9c2-4a84-9a0f-dc643fbaf0ef.jpg %}

在内存中定位（和 2，6 比较）：

{% asset_img 9628d43f-4569-4716-a1e4-ce23931b96f7.jpg %}

第 3 次磁盘 IO：

{% asset_img bca1c1cc-587d-4b6c-be28-9f92650ad1e5.jpg %}

在内存中定位（和 3，5 比较）：

{% asset_img 84af8a44-4f88-450b-9286-eec57e8ac003.jpg %}

{% asset_img 112d602b-917a-4a11-a227-f3355bcc5d95.jpg %}

{% asset_img e63df136-c6f7-4cc9-a1f9-c73ddc635e2e.jpg %}

{% asset_img bf42c5e0-2a17-4e30-8e3d-8689f5130652.jpg %}

{% asset_img bc424688-fa4c-4afd-91a9-67a0be2a08ad.png %}

{% asset_img 44f988cf-7a51-4863-88f0-766e99fb9f4e.jpg %}

自顶向下查找 4 的节点位置，发现 4 应当插入到节点元素 3，5 之间。

{% asset_img 454f21ea-4f34-4556-9641-cee74178b34a.jpg %}

节点 3，5 已经是两元素节点，无法再增加。父亲节点 2， 6 也是两元素节点，也无法再增加。根节点 9 是单元素节点，可以升级为两元素节点。于是 **拆分** 节点 3，5 与节点 2，6，让根节点 9 升级为两元素节点 4，9。节点 6 独立为根节点的第二个孩子。

{% asset_img 76ee8b6f-b653-416b-bb44-99101a6fc40f.jpg %}

{% asset_img 520badf6-ab99-4bbb-8c8a-5962900b4a51.jpg %}

{% asset_img 82d68b72-0dd0-4371-a8e7-a66dcf80a0e0.jpg %}

{% asset_img 2c252095-aafa-4f84-8d76-d4c0285d209f.jpg %}

自顶向下查找元素 11 的节点位置。

{% asset_img d242bb97-31cc-41a9-9820-39947f1291b4.jpg %}

删除 11 后，节点 12 只有一个孩子，不符合 B 树规范。因此找出 12,13,15 三个节点的中位数 13，取代节点 12，而节点 12 自身下移成为第一个孩子。（这个过程称为 **左旋**）

{% asset_img ef0015d5-7c1f-4af4-a254-a899753a4126.jpg %}

{% asset_img 0fde9df2-c850-47d8-949d-398b8f3e831f.jpg %}

{% asset_img d36da4d2-723c-4860-a1ae-06ec45c8bbae.jpg %}

{% asset_img 9b9ee0cb-50a2-418d-bcaf-4e30707bd886.jpg %}

{% asset_img 1f161fac-1327-4649-a31e-33bc5efd693a.jpg %}

{% asset_img 397c217f-b0bf-4a11-84b4-34b82d2c6642.jpg %}

<strong>漫画算法系列 [»]()</strong>

* [漫画算法：最小栈的实现](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560419&idx=1&sn=535073d4d69cf7fc45074ccb8c25ba1e&chksm=f1fee120c68968367597137515f21ef8d7a8ab68c9f4fce051dae5f2631afdc48ec11a30dd0e&scene=21#wechat_redirect)
* [漫画算法：判断 2 的乘方](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560448&idx=1&sn=b4ca3d01a438fac78be4077f270974ca&chksm=f1fee143c6896855179eff005164be47c7c662d4c8badf571a79c4acd9e2aca9fd84839ca093&scene=21#wechat_redirect)
* [漫画算法：找出缺失的整数](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560411&idx=1&sn=2e655df46f082a50a4657a40f292d63a&chksm=f1fee118c689680eba2b9ba965780387aeafd08a72eecb2c748eece85b77631b0a5511f2833b&scene=21#wechat_redirect)
* [漫画算法：辗转相除法是什么鬼？](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650560408&idx=1&sn=db553ce9deedf38c44841e16cb095d2e&chksm=f1fee11bc689680d83ff71d40dc191ee9899b8e5ef4bf9b98001ebb4daf13059a5961586ea1a&scene=21#wechat_redirect)
* [漫画算法：什么是动态规划？（整合版）](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650561168&idx=1&sn=9d1c6f7ba6d651c75399c4aa5254a7d8&chksm=f1feec13c6896505f7886d9455278ad39749d377a63908c59c1fdceb11241e577ff6d66931e4&scene=21#wechat_redirect)
* [漫画算法：什么是跳跃表？](http://mp.weixin.qq.com/s?__biz=MzI1MTIzMzI2MA==&mid=2650561205&idx=1&sn=3c4feb6339e00e13bdd8cc6a11eb0304&chksm=f1feec36c689652085b1b89acd6ca07316140f1c7478249e4b251c204b6cf3a5bb276b0275be&scene=21#wechat_redirect)

