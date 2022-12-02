---
layout: post
title: Hotwire之构建Turbo应用
author: xfyuan
categories: [ Translation, Programming ]
tags: [rails, hotwire, turbo]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210220_133340.jpg"
---

本文是对构建 Turbo 应用的具体描述，原文出自：https://turbo.hotwire.dev/handbook/building。

Turbo 之所以快是因为当你点击链接或者提交表单时它防止了整个页面的重新加载。你的应用成为浏览器中常驻而不停运转的进程。这就需要你重新考虑组织你的 JavaScript 的方式。

特别是，你可以不再依赖于页面的每次导航时整个页面的载入来重置你的环境。JavaScript 的`window`和`document`对象在页面变更期间保持其状态，而任何其他你放入内存的对象将会留在内存中。

有了这个意识，并稍微小心一点，你就能对应用进行设计以优雅地处理这种约束，而无需与 Turbo 紧密耦合在一起。

## Working with Script Elements

浏览器会自动载入并执行任何初始页面加载的`<script>`元素。

当你导航到一个新页面时，Turbo Drive 就查找在新页面的`<head>`中的任何`<script>`元素，且其未出现于当前页面上。然后，Turbo Drive 把它们 append 到当前的`<head>`，浏览器对其进行加载和执行。你可以由此来按需加载额外的 JavaScript 文件。

Turbo Drive 在每次渲染页面时执行该页面`<body>`中的`<script>`元素。你可以使用 inline body script 来建立每个页面的 JavaScript 状态或者启动客户端的 model。要建立某些行为，或在页面变更时执行更复杂的操作，避免使用 script 元素，使用`turbo:load`事件来代替。

如果你不想 Turbo 在页面渲染后执行`<script>`元素，就使用`data-turbo-eval="false"`对其进行注解。注意，这种注解不会防止浏览器在初始页面加载时执行这些 scripts。

### Loading Your Application’s JavaScript Bundle

要总是确保在`<head>`中使用`<script>`元素来加载你应用的 JavaScript 打包文件。否则，Turbo Drive 将会在每次页面变更时都重载它。

```html
<head>
  ...
  <script src="/application-cbd3cd4.js" defer></script>
</head>
```

你也应该考虑把 asset 打包系统配置成给每个 script 加上指纹，这样当其内容变动时就会是一个新的 URL。然后，你可以使用`data-turbo-track`属性来强制当部署了新 JavaScript 打包文件之后做一次全页面重载。参看 [Assets 变更后重载](https://turbo.hotwire.dev/handbook/drive#reloading-when-assets-change) 可获得更多信息。

## Understanding Caching

Turbo Drive 维护着近期访问页面的一个缓存。该缓存有两个目的：在 restoration 访问期间展示页面无需访问网络，和在 application 访问期间通过显示临时性的预览来提升可感知的性能。

当通过 history 导航（以 [Restoration 访问](https://turbo.hotwire.dev/handbook/drive#restoration-visits)），只要可能，Turbo Drive 将从缓存恢复页面而无需从网络加载一个全新的拷贝。

否则，在标准导航期间（以 [Application 访问](https://turbo.hotwire.dev/handbook/drive#application-visits)），Turbo Drive 将从缓存中立即恢复页面作为一个预览，并同时从网络加载一个全新拷贝。这就给经常访问的位置带来了瞬时页面加载的错觉。

Turbo Drive 在渲染新页面之前，把当前页面的一个拷贝保存到其缓存中。注意，Turbo Drive 使用了[`cloneNode(true)`](https://developer.mozilla.org/en-US/docs/Web/API/Node/cloneNode) 来拷贝页面，这意味着任何 attach 的事件监听及关联数据都被丢弃掉。

### Preparing the Page to be Cached

如果你需要在 Turbo Drive 缓存对其之前准备 document，可以监听`turbo-cache`事件。使用该事件来重置表单、收起所展开的 UI 元素、或清理任何第三方的 widgets，以便准备好重新显示该页面。

```javascript
document.addEventListener("turbo:before-cache", function() {
  // ...
})
```

### Detecting When a Preview is Visible

当 Turbo Drive 从缓存中展示一个预览时，它向`<html>`元素上添加了一个`turbo-preview`属性。当一个预览可见的时候，你就可以检查该属性的存在而有选择地启用或禁用行为。

```javascript
if (document.documentElement.hasAttribute("data-turbo-preview")) {
  // Turbo Drive is displaying a preview
}
```

### Opting Out of Caching

您可以通过在页面的`<head>`中包含`<meta name ="turbo-cache-control">`元素并声明一个缓存指令来控制每个页面的缓存行为。

使用`no-preview`指令来指定在 application 访问期间，页面的一个缓存版本不作为预览被显示。被标注了 no-preview 的页面将只被用于 restoration 访问。

要指定一个页面完全不应该被缓存，使用`no-cache`指令。被标注了 no-cache 的页面将总是通过网络获取，包括在 restoration 访问期间。

```html
<head>
  ...
  <meta name="turbo-cache-control" content="no-cache">
</head>
```

要完全禁用应用中的缓存，就要确保每个页面都包含 no-cache 指令。

## Installing JavaScript Behavior

你可能习惯于加入 JavaScript 行为来响应`window.onload`，`DOMContentLoaded`，或者 JQuery 的`ready`事件。使用 Turbo 时，这些事件将只在初始页面加载时被触发，之后的任何后续页面变更都不会触发。我们来比较下把 JavaScript 行为连接到 DOM 的两种策略。

### Observing Navigation Events

Turbo Drive 在导航期间触发一系列事件。其中最重要的是`turbo:load`事件，其只在初始页面加载时触发一次，并在每次 Turbo Drive 访问时触发一次。

你可以在`DOMContentLoaded`内监听`turbo:load`事件来在每次页面变更时建立 JavaScript 行为：

```javascript
document.addEventListener("turbo:load", function() {
  // ...
})
```

记住，当该事件被触发时，你的应用不会总是在一个崭新的状态，而你就可能需要清理前一个页面所建立的行为。

也要注意，Turbo Drive 的导航可能不是你应用中的页面更新的唯一源头，所以你可能期望把你的初始化代码移到一个单独的函数内，你可以从`turbo:load`和任何其他可能变更 DOM 的地方来调用它

可能的话，避免使用`turbo:load`事件来把其他事件监听器直接添加到页面 body 的元素上。相反，考虑使用[事件委托](https://learn.jquery.com/events/event-delegation/)来把事件监听器注册到`document`或`window`仅一次。

参看[全部事件列表](https://turbo.hotwire.dev/reference/events)获取更多信息。

### Attaching Behavior With Stimulus

新 DOM 元素可以在任何时刻呈现在页面上，通过 frame 导航、stream 信息、或客户端渲染操作等方式，而这些元素经常需要如同出现于一个全新页面加载那样被初始化。

对于所有这些更新，包括从 Turbo Drive 页面加载的更新，你可以借助于 Turbo 的兄弟框架 [Stimulus](https://stimulus.hotwire.dev/) 所提供的约定和回调生命周期，在一个单独的地方来处理它们。

Stimulus 让你使用 controller、action 和 target 属性对 HTML 进行注释：

```html
<div data-controller="hello">
  <input data-hello-target="name" type="text">
  <button data-action="click->hello#greet">Greet</button>
</div>
```

实现其相应的 controller 并由 Stimulus 自动连接到它：

```javascript
// hello_controller.js
import { Controller } from "stimulus"

export default class extends Controller {
  greet() {
    console.log(`Hello, ${this.name}!`)
  }

  get name() {
    return this.targets.find("name").value
  }
}
```

Stimulus 使用 [MutationObserver](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver) API，只要 document 发生变更，这些 controllers 和它们相关联的事件处理器就会被连接及断开连接。结果就是，它会处理 Turbo Drive 页面变更、Turbo Frames 导航、以及 Turbo Streams 信息，以它处理其他类型 DOM 更新完全同样的方式。

## Making Transformations Idempotent

你经常会想要在客户端对接收自服务端的 HTML 执行变换。例如，你可能想利用浏览器对用户当前时区的了解来按日期对元素集合进行分组。

假设你已经对一组元素注释以`data-timestamp`属性来指示其 UTC 创建时间。你有一个 JavaScript 函数来查询 document 中所有这样的元素，把时间戳转换为本地时间，并在每个发生于新的一天的元素之前插入日期表头。

考虑下如果你已经配置好该函数在`turbo:load`上执行的话会发生什么。当你导航到该页面，你的函数插入了日期表头。再离开该页面，则 Turbo Drive 把一个变换后页面的拷贝存入缓存。现在按下浏览器回退按钮——Turbo Drive 恢复页面，再次触发`turbo:load`，则你的函数插入第二个日期表头。

为了避免这个问题，就要让你的转换函数是*幂等的*。幂等转换能安全地执行多次而不会改变其最初应用的结果。

使转换幂等的一种技术是通过在每个处理的元素上设置一个`data`属性来跟踪是否已经执行了变换。当 Turbo Drive 从缓存中恢复页面时，这些属性会仍然存在。在你的函数中检测这些属性以确定哪个元素已经被处理过了。

更健壮的一种技术是简单地检测转换自身。在上面日期分组的示例中，这意味着在插入一个新日期分割线之前检查其存在与否。这个方案优雅地处理了未被初始转换所处理的新插入元素。

## Persisting Elements Across Page Loads

Turbo Drive 允许你把某些元素标注为 *permanent*。Permanent 元素在页面加载之间都存留着，所以你对这些元素的任何变更都不需要在页面导航之后再次赋予。

考虑下一个带购物车的 Turbo Drive 应用。在每个页面顶部都是一个图标，有当前在购物车内的商品数量。这个计数器是借助 JavaScript 动态更新的，当商品被添加和移除时。

现在想象一下，一个用户在该应用中已经导航到过多个页面。她添加一个商品到购物车，然后按下浏览器回退按钮。Turbo Drive 从缓存中恢复了前一个页面的状态，而购物车的商品计数被错误地从 1 变为 0。

你可以通过使计数器元素 permanent 来避免这个问题。要制定元素为 permanent，赋予它们一个 HTML `id`，并以`data-turbo-permanent`来注释它们。

```html
<div id="cart-counter" data-turbo-permanent>1 item</div>
```

每次渲染之前，Turbo Drive 通过 ID 匹配到所有的 permanent 元素，并把它们从初始页面转换到新页面，保留其数据和事件监听器。

