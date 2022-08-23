---
layout: post
title: "Turbo: Streams vs. Frames"
author: Mr.Z
categories: [ Translation, Programming ]
tags: [ruby, rails, hotwire, turbo]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20220823.jpeg"
rating: 4
---

*本文已获得原作者（Yaroslav Shmarov）和 [Bearer](https://www.bearer.com/)授权许可进行翻译。原文对 Rails Hotwire 技术栈核心 Turbo 的成员：Streams 和 Frames 进行了详细的对比。看过本文后对两者各自的区别，以及分别适用于哪种场景，就会有一个清晰的了解了。*

- 原文链接：[The difference between Turbo Streams and Turbo Frames](https://www.bearer.com/blog/turbo-streams-and-turbo-frames)
- 作者：[Yaroslav Shmarov](https://twitter.com/yarotheslav)
- 站点：Bearer 是一家专注于数据保护业务的公司，致力于构建第一流的数据安全平台来帮助用户公司的成长。

*【正文如下】*

我们痴迷于 [Hotwire](https://www.bearer.com/blog/why-hotwire) 技术。[Hotwire](https://www.bearer.com/blog/why-hotwire) 是一种技术集，让我们发送 HTML（而非 JSON 或 XML）直接“over the wire”，给予我们以 SPA 应用般的所见、所感和响应速度，而无需任何额外的 JavaScript。

Turbo 是 Hotwire 生态圈的一个核心组成部分，而 Turbo Frames 和 Turbo Streams 则是 Turbo 的两种风味。**站在一个更高的层次而言，Frames 和 Streams 是殊途同归。**它们都能让我们在 HTML 页面上操作元素，无需整个页面重载，并从服务端发送回 HTML 的响应。

## 同，又不同

初一看，貌似它们是解决了相同的问题，但实际上，Frames 和 Streams 有很大区别。它们工作方式不一样，并且有不同的用例场景。我们来深入研究下 Turbo 组件如何独特。尽管 Frames 和 Streams 都可操作 HTML 页面上的元素，但它们在如下几个方面有所区别。

Turbo Frames **只操作它们自身**，且这种操作总是一种**更新（update）**。

Turbo Streams 则相反，可以操作页面上**任何位置**的**任何** DOM 元素。这种操作，可以**更新**已有内容，移除元素，把内容**前置或后置插入**到一个元素内，向 DOM 中所匹配的元素之前或之后**添加** HTML 元素，乃至**替换**整个元素。

而且当 Turbo Frames 和 Streams 响应以 HTML 时，各自是以**不同的事件**来触发这些响应。

## Frames and Streams: UI 上的事件

对于 Turbo Frames， **在 Frame 内**的交互所触发的**任何请求**都将会包含一个 Turbo-Frame header，并因此会从服务端触发一个 Turbo 响应。

*说明：这些响应，不管服务端返回的是什么，都只会更新 Frame 自身。无论服务端返回的是一个 HTML 片段还是一整个 HTML 页面，Hotwire 在处理 Turbo 响应时都能聪明地自动移除任何不需要的内容（比如 layouts）。*

此外，data 属性可被用来从 **Frame 外部**更新一个特定的 Turbo Frame：

```erb
data: { turbo_frame: "my_frame_id" }
```

或者是触发整个页面的重载：

```erb
data: { turbo_frame: "_top" }
```

Turbo Streams，类似地，可被用来从服务端发送返回响应以处理**用户交互**，但这种交互可以出自于页面的任何位置，而服务端的响应可以更新页面上任何位置的任何内容。例如，提交一个表单创建一个新对象就可以从`controller#create`方法发送一个 Stream 响应来把新对象插入到页面上某处的对象列表末端。

## Frames: 页面加载时

对于 Turbo Frames，src 和 loading 属性允许我们独立于初始页面的加载来加载一个 Frame。

这可以通过 **eager loading** 来实现：例如，一个 Frame 可以在初始页面加载之后，触发一个请求来直接加载它自身的内容：

```erb
<turbo-frame id="greeting" src="/greet" loading=”eager”></turbo-frame>
```

或者使用 **lazy loading**，这会仅在 Frame 自身在页面上可见时再加载其内容：

```erb
<turbo-frame id="greeting" src="/greet" loading=”lazy”></turbo-frame>
```

注意：Eager loading 是默认的。如下两种方式等价：

```erb
# explicit eager loading
<turbo-frame id="greeting" src="/greet" loading=”eager”></turbo-frame>
# default with implied eager loading
<turbo-frame id="greeting" src="/greet"></turbo-frame>
```

## Streams: 服务端的事件

不像 Frames 那样，Streams 可由许多**服务端的事件**来触发。例如，Streams 能够直接从 Rails 的 Model 中播发【broadcast】出来。这对于诸如在某个特定 model 更新了或者某个后台任务完成了的时候向用户显示提醒信息的情况，都是极为适合的。

*注意：Streams 通常是针对 POST 或非 GET 请求来触发的，不像 Frames 通过 GET 请求（比如 lazy loading）来进行更新。*

## Streams or Frames?

我们如何决定使用 Turbo Frame 还是 Stream 呢？来看一些场景。

当我们想要把一个页面拆分为多个内容块，且这些块能被独立于页面单独更新时，使用 Turbo Frames 是极好的。例如，我们可以使用 Frame 来展示一个对象列表，当用户筛选列表时让 Frame 更新其自身。Modal 则是另一个很棒的用例。

使用 Eager 和 lazy loading 的 Turbo Frames 是改进初始页面加载时间的好方式。Lazy loading 可以提升页面性能，当有很多内容初始隐藏在视图中的时候。例如，tab 或 accordion 形式的内容，或者内容远远超出当前视图时。

相反的是，当我们想要从一个单独请求来对一个页面的多个位置进行多处修改时，Turbo Streams 则是极好的。例如，当添加一个新对象，我们期望把它插入到列表末端，并更新页面某处的总对象计数，同时把按钮状态从 disabled 改为 active 的时候。

Turbo Streams 在基于服务端的事件发生时（非直接来自于用户的交互）进行一些变更也是极好的，比如显示提醒消息。

一般来说，我们总是尽可能使用 Turbo Frames。当 Frames 满足不了需求时再使用 Turbo Streams。

## It’s Frames and Streams All The Way Down

可能现在我们对于 Turbo Frames 和 Turbo Streams 之间的差别有一个更清晰的理解了。尽管二者都处理类似的目的——实现局部页面更新而无需手写 JavaScript——但他们彼此独立，且有着不同的用例场景。

然而，尽管有这些区别，Frames 和 Streams 也能够彼此交互。例如，我们能够使用 Turbo Stream 在一个 Turbo Frame 内去更新内容，或更新整个 Frame 自身。是否应该这样做可能是另一个问题，最佳实践的问题，但了解在 Hotwire 中能做到这种交互总是很好的。
