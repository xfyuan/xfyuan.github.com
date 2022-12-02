---
layout: post
title: Rails render path 继承关系一例
author: xfyuan
categories: [ Programming ]
tags: [ruby, rails]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a004.jpg"
---

近两天在 Rails 的开发中，突然发现了关于 render path 的一个之前未曾注意到的有趣地方。

代码中有一个父类 Controller，假设为 `FruitsController`；两个子类 Controller，假设为 `ApplesController`，`OrangesController`。

`ApplesController#show`，`OrangesController#show` 的 View 中，大部分都是一样的，已经抽出来了一个 partial 模版，假设为 `_fruit_content.erb`。这样两个 Controller#show 的模版内，都会有这么一行：

```
render 'path/to/fruit_content'
```

那么 `_fruit_content.erb` 放到哪个 path 比较合适呢？当然 shared 目录是一个选择，但由于一些其他原因已经排除了，所以不做考虑。

如果放在

```
views/apples
```

下，那么 `OrangesController#show` 的模版内那一行 render 就必须指明 `_fruit_content.erb` 完整path：

```
render 'apples/fruit_content'
```

反之亦然。无论哪种都感觉不太符合 Rails “Convension over Configration” 的原则。

最后无意中却发现 Rails 竟然“原来对此早有准备的”～

答案很简单。

由于 `ApplesController`，`OrangesController` 都继承于 `FruitsController`，所以我们只需把 `_fruit_content.erb` 放在

```
views/fruits
```

然后无论是 `ApplesController#show` 还是 `OrangesController#show` 的模版内那一行 render 都只需写为：

```
render 'fruit_content'
```

即可。

搞定收工。
