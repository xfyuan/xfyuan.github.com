---
layout: post
title: Tailwindcss底层基石的理念
author: xfyuan
categories: [ Programming ]
tags: [css, tailwindcss]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210220_115551.jpg"
---

Tailwindcss 从 2019 年开始逐渐在国外的 Web 开发圈子内盛行起来。国内倒是至今仍然不温不火。2020 年的 Ruby China 上***过纯中***做过一次在项目上使用 tailwindcss 体验的有关演讲。我在 2020 年也写过一篇有关的博客“[在 Rails 6 中整合 Stimulus 和 Tailwind CSS](http://xfyuan.github.io/2020/07/integrate-stimulus-and-tailwindcss-with-rails6/)”（被前者在演讲中所引用^_^）。

这篇文章来聊一下有关 Tailwindcss 底层理念的东西。了解了这个，再来看它就不觉得毫无头绪而畏惧了。

在 Tailwindcss 中，**“工具类为一等公民（utility classes are king）”**。这种工具类在 Bootstrap 中早已为人熟知，并非什么新鲜事物，比如`text-muted`,`bg-success`。但 Tailwindcss 又有所不同，正是这些不同使得它更“Tailwind”。

大部分时间内，在使用 Tailwindcss 时都面对两类对象。一个是 theme，通用性配置。另一个是一大堆的 property 列表，可把它们用在 theme 上。theme 有一系列的细粒度对象，提供了超多的可配置项。

比如说，在开始一个 theme 的设计时，会从这三种配置开始：screen、color、spacing。首先来看 color 和 spacing：

- Color 从 0 开始，一直到 900。越接近 900，color 就越暗，反之则越亮。
- Spacing 是 space 之数字，或对象之大小，在 0 - 96 之间。

还有上面所提到的那些 property，比如`margin`,`width`,`padding`等。

只要有了这两种“变量”，你就可以把它们如此组合起来：`{property}-{color/spacing}`。如果想要一个暗红色的背景，就写`bg-red-900`，而如果想要 6 个像素的 padding，就写`p-6`。

再看 screen。Screen 用于响应式的 breakpoint，如 desktop / tablet / mobile 的设计上（`sm`,`md`,`lg`,`xl`）。有了 screen 之后，上面的公式就变为`{screen}:{property}-{color/spacing}`。

用一个完整的示例来演示。

我想要一个有暗红色背景，白色文字，以及 padding 为 6 的 DIV：

```html
<div class="bg-red-900 text-white p-6">Messi</div>
```

接下来可以再添加一些别的工具类。想要把这个 DIV 在浏览器内居中，可用`mx-auto`。想要让其宽度自动扩展，可用`w-auto`。最后，想要让其文字居中，显然，用`text-center`即可：

```html
<div class="bg-red-900 p-6 mx-auto w-auto 
            text-white text-center ">Messi</div>
```

这样，在 desktop 上看起来已经很好了。不过，我想在 mobile 上 padding 要更小一点。此时，就是 screen 发挥作用的时候了。适配不同的 breakpoint 和 property 能带来很多好处。假设默认 padding 为 3，而从 phone 过渡到 tablet 的尺寸，则使其 padding 变为 6：

```html
<div class="bg-red-900 p-3 md:p-6 mx-auto 
            w-auto text-white text-center">Messi</div>
```

最后，再针对各 breakpoint 分别适配以适当的文字：

```html
<div class="bg-red-900 text-center p-3 
            mx-auto w-auto text-white text-center 
            text-md md:text-lg lg:text-2xl ">Messi</div>
```

Tailwindcss 还有很多其他类似的工具类， 它的官方文档中都有详细讲述。

这一切看起来是“过度设计”了，然而 Tailwindcss 的闪光之处，就是“组件驱动设计（component driven design）”。把这些工具类用于组件之上，然后组件用于系统各处。多个组件则可构成组件库。组件库即类似于 Bootstrap 里的 modal 之类。

#### 一些相关的 Tailwindcss component 链接

- https://tailwindui.com/ Tailwindcss 官方的 UI kit 站点
- https://tailwindcomponents.com/ 一个社区类 components 集合站点
- https://tailwind.build/editor 一个 Tailwindcss component builder

