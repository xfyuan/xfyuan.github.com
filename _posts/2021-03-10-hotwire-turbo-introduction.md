---
layout: post
title: Hotwire之Turbo介绍
author: Mr.Z
categories: [ Translation, Programming ]
tags: [rails, hotwire, turbo]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210220_134511.jpg"
---

我去年 7 月的博客[对 Hey.com 技术栈的期待](https://xfyuan.github.io/2020/07/dhh-talk-about-heystack/) 中提到了 DHH 在 HEY 中所使用的新技术栈。而在去年 12 月 23 日，DHH 不负所望，如期宣布了他的“NEW MAGIC”：[Hotwire](https://hotwire.dev/)

![LQ2YA5](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/LQ2YA5.png)

Hotwire 由 [Turbo](https://turbo.hotwire.dev/)、[Stimulus](https://stimulus.hotwire.dev/) 和 Strada（将于2021公布） 构成。Strada 尚未发布先不论，Stimulus 也是早就发布的技术，并非新事物，所以真正的焦点就是 Turbo 了。这篇博客即是 Turbo 的一个概览。原文出自：[https://turbo.hotwire.dev/handbook/introduction](https://turbo.hotwire.dev/handbook/introduction)

## Introduction

Turbo 把几种技术集成到一起以创建快速的、现代的、渐进式增强的 Web 应用而毋需使用太多的 JavaScript。对于流行的把所有业务逻辑都置于前端，且把服务端限制在仅提供 JSON API 的那些客户端框架，它提供了一种更简单的替代方案。

借助 Turbo，你让服务端直接发布 HTML，这意味着所有业务逻辑，诸如权限检查、直接与你的领域模型交互，以及编写应用程序所需的其他一切，都能或多或少地只用你所喜欢的编程语言即可实现。而不用再把这些逻辑在被 JSON 所划分的两端都镜像实现。所有的逻辑都位于服务端，而浏览器只处理最终的 HTML。

你可以在 [Hotwire 站点](https://hotwire.dev/)阅读到关于 HTML-over-the-wire 方案的更多优点。下面则是 Turbo 带来的使之成为可能的技术。

## Turbo Drive: Navigate within a persistent process

传统单页面应用的关键吸引力，比较于老式、单独页面的方案而言，就是导航跳转的速度。SPA 是通过仅在第一个页面初始化而非不断地中断应用程序进程从而获得如此高的响应速度的。

Turbo Drive 通过使用同样的持久化进程模型为你赋予了同样的高速响应，但无需你围绕范式来构建你的应用。没有了要维护的客户端路由，没有了要仔细管理的客户端状态。持久化进程由 Turbo 来管理，而你编写自己的服务端代码，仿佛又回到了早年间的时光——与当今 SPA 怪兽的复杂性幸福地隔离开了。

这通过拦截所有在<a href>链接上的点击到相同的领域而实现。当你点击一个链接时，Turbo Drive 阻止浏览器的响应，使用[History API](https://developer.mozilla.org/en-US/docs/Web/API/History)改变浏览器的 URL，使用 [`fetch`](https://developer.mozilla.org/en-US/docs/Web/API/fetch) 来获取新页面，然后渲染 HTML 响应。

对于表单是同样的处理。它们的提交都被转化为 [`fetch`](https://developer.mozilla.org/en-US/docs/Web/API/fetch) 请求，Turbo Drive 将根据这些请求遵循重定向并渲染 HTML 响应。

在渲染期间，Turbo Drive 会完全替换掉当前的`<body>`元素并合并`<head>`元素的内容。JavaScript 的 window 和 document 对象，以及`<html>`元素，会在一个页面到下一个页面的渲染中保持持久化。

尽管可以直接与 Turbo Drive 进行交互以控制访问如何发生或进入请求的生命周期，但在大多数情况下，这是一种即插即用的替代方法，只需遵循一些约定即可免费享受那种高速响应。

## Turbo Frames: Decompose complex pages

大多数 Web 应用程序显示的页面都包含几个独立的片段。对一个讨论区页面，你可能有一个导航栏在顶部，一个消息列表在中间，一个表单在底部以添加新消息，以及一个包含相关主题的侧边栏。生成这种讨论区页面通常意味着以一种序列化方式生成每个片段，把它们拼接在一起，然后把结果以单个 HTML 的响应发布给浏览器。

借助 Turbo Frames，你可以把这些独立片段置于 frame 元素之内，以限制其导航范畴并做懒式加载。限制其导航范畴意味着所有交互在 frame 内部，比如点击链接或者提交表单，都发生于那个 frame 之内，而避免更改或重新加载页面的其余部分。

要将一个独立片段封装在它自己的导航上下文中，把它包在一个`<turbo-frame>` 标签内即可。例如：

```html
<turbo-frame id="new_message">
  <form action="/messages" method="post">
    ...
  </form>
</turbo-frame>
```

当你提交上面的表单时，Turbo 把匹配的`<turbo-frame id="new_message">`元素从重定向的 HTML 响应中提取出来，并把其内容交换到已有的的`new_message` frame 元素中。页面的其余部分保持原样。

除了限制导航范畴之外，Frames 也可以懒式加载其内容。要懒式加载一个 frame，添加一个其值为 URL 的`src`属性即可自动加载。与作用域导航一样，Turbo 从响应结果中查找并提取出匹配的 frame 并交换其内容到定位中：

```html
<turbo-frame id="messages" src="/messages">
  <p>This message will be replaced by the response from /messages.</p>
</turbo-frame>
```

这可能听起来很像旧时的 frames，甚至`<iframe>`，然而 Turbo Frames 是同一 DOM 的一部分，因此没有任何与“真实” frames 相关的怪异或妥协。Turbo Frames 由同样的 CSS 定义样式，是同一 JavaScript 上下文的一部分，且不受任何其他内容安全性限制。

除了把你的片段转化为独立上下文，Turbo Frames 还为你提供了：

- **高效缓存**：在上面的讨论区页面范例中，相关主题的侧边栏当一个新主题呈现时（缓存）就需要过期，但中间的消息列表则不用。所有东西只在一个页面时，一旦任何一个片段过期则整个缓存都会过期。借助 frames，每个片段都被独立缓存，因此你可以获得更少依赖 key 的寿命更长的缓存。
- **并行执行**：每个懒式加载的 frame 都由其自己的 HTTP 请求/响应所生成，这意味着它可以被单个进程来处理。这允许并行执行而不用手动管理进程。一个复杂的组合页面需要花费 400 ms 完成端到端渲染，则可以被分解为 frames，初始请求可能只需要 50 ms，而三个懒式加载的 frames 每个都耗费 50 ms。现在整个页面 100 ms 就可加载完成，因为那三个 frames 的50 ms 请求是并发而非序列式的。
- **Mobile 友好**：在 mobile app 中，你通常不会有大而复杂的组合页面。每个片段都需要专用的屏幕。借助 Turbo Frames 构建的应用，你就已经完成了把复杂页面转换为片段的工作。然后这些片段就可以呈现在原生的表格和屏幕中，无需改动（因为它们都有独立的 URL）。

## Turbo Streams: Deliver live page changes

响应异步操作而进行页面的部分更改是我们使应用保持活力的方式。尽管 Turbo Frames 给予了我们这种更新以响应在单个 frame 内的直接交互，而 Turbo Streams 则让我们得以响应通过 WebSocket 连接、SSE 或其他传输所发送的更新来更改页面的任何部分。

Turbo Streams 提供了一个`<turbo-stream>`元素，带有五种基本行为：`append`、`prepend`、`replace`、`update`和`remove`。借助这些行为，跟指定了你所想操作元素的 ID 的`target`属性一起，就可以编码所有需要的变更内容来刷新页面。你甚至可以组合几个 stream 元素在一个单独的 stream 消息中。只用把你需要插入或替换的 HTML 包含在一个 **[template tag](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/template)** 中，Turbo 会做好剩下的一切：

```html
<turbo-stream action="append" target="messages">
  <template>
    <div id="message_1">My new message!</div>
  </template>
</turbo-stream>
```

该 stream 元素将会获取带新消息的`div`并把它 append 到 ID 为`messages`的容器中。要简单地替换掉已有的元素则可：

```html
<turbo-stream action="replace" target="message_1">
  <template>
    <div id="message_1">This changes the existing message!</div>
  </template>
</turbo-stream>
```

这是 Rails 世界中的一种概念上的持续（起初被称作 [RJS](https://weblog.rubyonrails.org/2006/3/28/rails-1-1-rjs-active-record-respond_to-integration-tests-and-500-other-things/)，然后被称作 [SJR](https://signalvnoise.com/posts/3697-server-generated-javascript-responses)），却是无需任何 JavaScript 的一种实现。优点是同样的：

- **重用服务端模板**：实时页面改动的生成都跟初次加载页面一样使用同样的服务端模板。
- **HTML over the wire**：由于所有我们所发送的都是 HTML，你就无需任何客户端 JavaScript （超越 Turbo，当然如此）来处理更新了。是的，HTML 的负荷可能比 JSON 要大一点，但借助 gzip，这点差异通常都是微不足道的，然而你节省了所有客户的的工作：获取 JSON 并把其转为 HTML。
- **更简单的控制流**：当消息通过 WebSocket、SSE 到达或者响应表单提交时，会发生什么是很清晰的。再也没有路由、事件冒泡或其他的间接处理。它就仅是被变更的 HTML 而已，被封装在一个单独的 tag 中。

现在，不像 RJS 和 SJR ，调用自定义的 JavaScript 函数来作为 Turbo Streams 行为的一部分是不可能的了。但这是一个特性，不是 bug。当发送太多 JavaScript 跟响应一起时，这些技术很容易最终导致乱七八糟的混乱状况。Turbo 专注于仅更新 DOM，然后假设你会使用 [Stimulus](https://stimulus.hotwire.dev/) 的 action 和生命周期回调来连接任何额外行为。

## Turbo Native: Hybrid apps for iOS & Android

Turbo Native 是构建适用于 iOS 和 Android 的 hybrid apps 的理想选择。你可以使用你现有的服务端渲染的 HTML 来得到在一个原生封装里的 app 功能的基线范畴。然后你就可以把所有节省下来的时间花在使受益于高保真原生控件的几个屏幕变得更好上。

像 Basecamp 这样的应用由上百个屏幕。重写每个单独的屏幕都会是一个收益极低的巨大工作。为真正需要高保真的重度交互保留“火力”才更好。例如，类似于 Basecamp 中的“New For You” inbox，这里我们使用轻扫控制需要恰到好处。但大多数页面，比如显示一条单独消息的页面，则不会比完全原生的做到更好。

使用 hybrid 不仅可以加快开发过程，还可以让你拥有更大的自由来升级 app，而无需经历缓慢而繁琐的应用商店发布过程。任何 HTML 做成的东西都可以在你的 web 应用程序中被更改，并即刻为所有用户所用。无需等待技术大牛来批准你的更改，也无需让用户等待升级。

Turbo Native 假设你正在使用对于 iOS 和 Android 所推荐的可用的开发实践。它不是一个抽象出原生 API 或者甚至让你的原生代码在多个平台之间共享的框架。共享的部分是在服务端渲染的 HTML。但是原生的控制是由所推荐的原生 API 写就。

参考 [Turbo Native: iOS](https://github.com/hotwired/turbo-ios) 和 [Turbo Native: Android](https://github.com/hotwired/turbo-android)  代码库的更多文档。去看看 HEY 在 [iOS](https://apps.apple.com/us/app/hey-email/id1506603805) 和 [Android](https://play.google.com/store/apps/details?id=com.basecamp.hey&hl=en_US&gl=US) 上的原生 app 以感受下使用 Turbo 所制作的 hybrid app 有多么出色吧。

## Integrate with backend frameworks

你不需要任何后端框架即可使用 Turbo。它的所有特性都可直接使用，无需更多的抽象。但如果你有机会使用一个后端框架来整合 Turbo，将会发现一切变得更简单了。[我们已经为与 Ruby on Rails 做这样的整合创建了一份实现的参考](https://github.com/hotwired/turbo-rails)。

