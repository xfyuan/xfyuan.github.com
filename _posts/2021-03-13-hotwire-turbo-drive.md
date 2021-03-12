---
layout: post
title: Hotwire之使用Turbo Drive导航
author: Mr.Z
categories: [ Translation, Programming ]
tags: [rails, hotwire, turbo]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210220_140448.jpg"
---

本文是对 Turbo Drive 的详细说明，原文出自：[https://turbo.hotwire.dev/handbook/drive](https://turbo.hotwire.dev/handbook/drive)。

Turbo Drive 是 Turbo 的一部分，用于增强页面级别的导航。它监控着点击链接和表单提交，使其在后台执行，并更新页面而无需做全页面的重载。它是[Turbolinks](https://github.com/turbolinks/turbolinks) 库的进化版本。

## Page Navigation Basics

Turbo Drive 把页面导航建模为使用一种行为对一个页面位置（URL）的访问。

这种访问展现了从点击到渲染的整个导航生命周期，包含更改浏览器访问历史，发出网络请求，从缓存中恢复一个页面的拷贝，渲染最终的响应，以及更新页面滚动的位置。

有两种类型的访问：一种是 *application* 访问，其行为是 *advance* 或 *replace*。而另一种是 *restoration* 访问，其行为是 *restore*。

## Application Visits

Application 访问由一个启用 Turbo Drive 的链接，或者程序中调用`Turbo.visit(location)`，而被初始化的。

一个 application 访问总是会发出一个网络请求。当响应返回，Turbo Drive 就渲染其页面并结束这次访问。

可能的话，Turbo Drive 会在访问开始时立即从缓存中渲染一个页面的预览。这就提高了在相同页面间频繁导航的感知速度。

如果访问的位置包含一个锚点，Turbo Drive 会尝试滚动到所锚住的元素。否则，会滚动到页面顶部。

Application 访问会导致浏览器访问历史的变更，而访问的行为决定了该变更是怎样的。

![https://s3.amazonaws.com/turbolinks-docs/images/advance.svg](https://s3.amazonaws.com/turbolinks-docs/images/advance.svg)

默认的访问行为是 *advance*。在一次 advance 访问期间，Turbo Drive 使用`history.pushState`向浏览器访问历史推入一个新条目。

使用 Turbo Drive 的 [iOS adapter](https://github.com/hotwired/turbo-ios) 的应用程序通常处理 advance 访问是推入一个新的 view controller 到导航堆栈之上。类似地，使用 [Android adapter](https://github.com/hotwired/turbo-android) 的应用程序通常是推入一个新的 activity 到 back stack 之上。

![https://s3.amazonaws.com/turbolinks-docs/images/replace.svg](https://s3.amazonaws.com/turbolinks-docs/images/replace.svg)

你可能想要访问一个位置而不推入一个新访问历史条目到历史堆栈之上。*replace* 行为使用`history.replaceState`来丢弃最顶层的历史条目，并以新的位置来替换它。

要指定如下链接能触发一个 replace 访问，以`data-turbo-action="replace"`注释链接即可：

```html
<a href="/edit" data-turbo-action="replace">Edit</a>
```

要在程序中以 replace 行为访问一个位置，把`action: "replace"`选项传入`Turbo.visit`即可：

```javascript
Turbo.visit("/edit", { action: "replace" })
```

使用 Turbo Drive 的 [iOS adapter](https://github.com/hotwired/turbo-ios) 的应用程序通常处理 replace 访问是放弃最顶层的 view controller 并推入一个新的 view controller 到导航堆栈之上，不带动画的方式。

## Restoration Visits

当你使用浏览器的后退或前进按钮导航时，Turbo Drive 会自动初始化一个复位访问。使用 [iOS](https://github.com/hotwired/turbo-ios) 或 [Android](https://github.com/hotwired/turbo-android) adapters 的应用程序在导航堆栈中后移时会初始化一个复位访问。

![https://s3.amazonaws.com/turbolinks-docs/images/restore.svg](https://s3.amazonaws.com/turbolinks-docs/images/restore.svg)

可能的话，Turbo Drive 就从缓存中渲染一个页面的拷贝而不发出请求。否则，它将会通过网络获取一个页面的全新拷贝。查看下面的 Understanding Caching 以了解更多细节。

Turbo Drive 在导航离开每个页面时都会记住其滚动位置，在复位访问时会自动滚动回该位置处。

复位访问有一个 *restore* 行为，Turbo Drive 预留它们是为了内部使用。你无需尝试使用`restore`的行为来注释链接或执行`Turbo.visit`。

## Canceling Visits Before They Start

Application 访问在其开始之前是可以被取消的，而不管它们是由点击链接还是由调用`Turbo.visit`来初始化的。

在访问开始的时候监听`turbo:before-visit`事件，并使用`event.detail.url`（使用 jQuery 时是`$event.originalEvent.detail.url`）来检查访问的位置。然后通过调用`event.preventDefault()`来取消访问。

复位访问不能被取消，且不会触发`turbo:before-visit`。Turbo Drive 发出复位访问来响应对已有的历史记录进行导航，通常是通过浏览器的后退或前进按钮。

## Disabling Turbo Drive on Specific Links or Forms

可以禁用一个元素的Turbo Drive，通过在它或其上级元素上添加`data-turbo="fale"`的方式。

```html
<a href="/" data-turbo="false">Disabled</a>

<form action="/messages" method="post" data-turbo="false">
  ...
</form>

<div data-turbo="false">
  <a href="/">Disabled</a>
  <form action="/messages" method="post">
    ...
  </form>
</div>
```

在上级元素已禁用时要重新启用，使用`data-turbo="true"`：

```html
<div data-turbo="false">
  <a href="/" data-turbo="true">Enabled</a>
</div>
```

禁用了 Turbo Drive 的链接和表单仍然会被浏览器正常处理。

## [﹟](https://turbo.hotwire.dev/handbook/drive#displaying-progress)Displaying Progress

在 Turbo Drive 导航期间，浏览器将不会展示其原生的进度条了。Turbo Drive 安装了一个基于 CSS 的进度条来在发出请求时给以反馈。

该进度条默认是启用的。它对任何载入时间超过 500 ms 的页面都会自动显示。（你可以使用`Turbo.setProgressBarDelay`方法修改这个值。）

该进度条是一个`<div>`元素，其 class 名为`turbo-progress-bar`。它的默认样式会首先呈现于 document，且可以被之后的规则所覆盖。

例如，下面的 CSS 将会呈现一个绿色的窄进度条：

```css
.turbo-progress-bar {
  height: 5px;
  background-color: green;
}
```

要完全禁用该进度条，把其`visibility`样式设为`hidden`：

```css
.turbo-progress-bar {
  visibility: hidden;
}
```

## Reloading When Assets Change

Turbo Drive 可以在一个页面到另一个页面时跟踪`<head>`中的 asset 元素的 URL，如果它们有所变动则自动请求一次全量重载。这确保了用户始终会拥有你应用程序的 script 和 style 的最新版本。

使用`data-turbo-track="reload"`注释 asset 元素并在 asset URL 中包含一个版本标识符。该标识符可以是一个数字，一个最近修改的时间戳，或者更好点，一个 asset 内容的 digest，类似如下：

```html
<head>
  ...
  <link rel="stylesheet" href="/application-258e88d.css" data-turbo-track="reload">
  <script src="/application-cbd3cd4.js" data-turbo-track="reload"></script>
</head>
```

## Ensuring Specific Pages Trigger a Full Reload

你可以通过在页面的`<head>`中包含一个`<meta name="turbo-visit-control">`元素来确保在访问某个页面时始终会触发一次全量重载。

```html
<head>
  ...
  <meta name="turbo-visit-control" content="reload">
</head>
```

这个设置可能在第三方 JavaScript 库不能很好地跟 Turbo Drive 页面变更进行交互时是一个有用的解决方案。

## Setting a Root Location

默认情况下，Turbo Drive 只会加载同源 URL——比如，跟当前页面相同的协议，域名，端口。访问任何其他 URL 都会导致一次全量的页面加载。

有些场景中，你可能想要进一步定义 Turbo Drive 到同源的一个 path 上。例如，如果你的 Turbo Drive 应用位于`/app`，而非 Turbo Drive 的帮助站点位于`/help`，从前者到后者的链接不应该使用 Turbo Drive。

在页面的`<head>`中包含一个`<meta name="turbo-root">`元素以定义 Turbo Drive 到特定的 root 位置。Turbo Drive 将只加载那个 path 前缀的同源 URL。

```html
<head>
  ...
  <meta name="turbo-root" content="/app">
</head>
```

## Redirecting After a Form Submission

Turbo Drive 以一种类似于链接点击的方式处理表单提交。关键区别是表单提交可以使用 HTTP POST 方法发出有状态的请求，而链接点击只会发出无状态的 HTTP GET 请求。

在有状态的表单提交后，Turbo Drive 期望服务端返回一个 [HTTP 303 redirect response](https://en.wikipedia.org/wiki/HTTP_303)，其将被用以导航和页面更新而无需重载。

这条规则的例外情况是当响应是 4xx 或 5xx 的时候。这可以让服务端响应为`422 Unprocessable Entity`时呈现表单的校验错误，以及响应为`500 Internal Server Error`时显示服务端出错了。

Turbo 不允许对于 200 的常规渲染的原因是浏览器已有内置的行为来处理 POST 访问的重载，会展示一个“你确认想要重新提交表单吗？”的对话框，这是 Turbo 无法复制的。相反，Turbo 会在一个表单提交后尝试渲染页面时驻留在当前 URL 上，而不是变更到表单的 action，因为重载会发出到那个 action 所指向 URL 的一个 GET 请求，而该 URL 甚至可能根本不存在。

## Streaming After a Form Submission

服务端也可以借助 [Turbo Streams](https://turbo.hotwire.dev/handbook/streams) 消息，通过发送 header `Content-Type: text/vnd.turbo-stream.html`，然后在响应内容中包含一个或多个`<turbo-stream>`元素，来响应表单提交，这让你可以无需导航即可更新页面的多个部分。

