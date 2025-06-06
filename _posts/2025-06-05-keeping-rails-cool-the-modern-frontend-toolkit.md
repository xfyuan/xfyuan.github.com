---
layout: post
title: 让Rails酷如既往
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, frontend, evil martians]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20240606.jpg"
rating: 4
---

_本文已获得原作者（**Irina Nazarova**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了2020年代的现代前端工具箱如何让 Rails 继续保持引领潮流的那种技术范。_

- 原文链接：[Keeping Rails cool: the modern frontend toolkit](https://evilmartians.com/chronicles/keeping-rails-cool-the-modern-frontend-toolkit)
- 作者：**Irina Nazarova、**Travis Turner\*\*
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发者博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

_【正文如下】_

## 引言

在 Evil Martians，我们倡导和构建 Rails 上的初创公司，我们也知道 Ruby 和 Rails 可以提高团队的生产力和竞争优势。然而，我们还知道这些初创公司最苦苦挣扎的是什么：**前端** 。在这篇文章中，我们分享了对付它们的“白银工具包”！

Rails 的总体前端故事感觉就像经典的 [一千零一夜，](https://en.wikipedia.org/wiki/One_Thousand_and_One_Nights) 一个历时数百年的史诗故事（换句话说，它不是一个简短的故事）。

但只需 6 个字就可以讲述 2025 年 Rails 的前端故事。哪 6 个字？**“Cooling down Hot Wires with Inertia”**。这个小的故事为那些既精干又严谨的创业团队提供了一个更好的交汇点。

在 Evil Martians，我们倡导并为 Rails 上的初创公司构建——这些小团队通过构建卓越的产品产生巨大影响——并与他们一起赢得市场。[我们确切地知道初创公司选择 Rails 的原因（参见我的主题演讲）](https://evilmartians.com/chronicles/startups-on-rails-in-2024-my-keynote-at-railsconf)——尽管缺乏关注。但我们了解 Ruby 和 Rails 如何为团队带来生产力提升和竞争优势。

而我们也知道这些初创公司最苦恼的是什么：**前端** 。

因此， **我们在过去 2 年里一直在寻找 Rails 前端生产力的下一个前沿领域** ：试用各种工具、gem、模式，与数十家客户合作，构建开源并做出贡献。

今天，我们终于准备好展示这个解决方案了！

## Diverting from the mainstream?

对于外部观察者来说，我们提出与 [rubyonrails.org](https://rubyonrails.org/) 上官方内容不同的东西似乎很奇怪，但对于一家已经深度融入 Ruby 社区 18 年的公司来说，这个提议实际上很合理。

重要的是，它与 Rails 原则是一致的。毕竟，**Rails 的设计独特，可以将替代解决方案集成到框架的几乎每个关键部分，而且是以完美的方式**。

这种设计原则，以及官方和替代方案之间持续的竞争（还记得 MySQL 与 Postgres 吗？），是 Rails 适应性及其成功的主要来源！

话虽如此，选择替代路径确实需要我们做一些事情：信任替代维护者的愿景。

现在，这就是我们可以抛开谦虚的地方了，如果你是一个快节奏的小团队，希望征服世界，你可以相信我们的判断：[我们已经帮助来自最佳团队的客户](https://evilmartians.com/clients)解决了[一些最困难的问题 ](https://evilmartians.com/services)，做了几周或几年的项目，将他们从种子阶段带到后期阶段并进行 IPO。从我们的失误中吸取教训，构建广泛使用的开源解决方案，并以最可维护的方式扩展 Rails。

（事实上，我们写了一本关于它的书（“Layered Design for Rails applications”），这本书在 [2024 年 Rails 社区调查](https://railsdeveloper.com/survey/2024/)中排名前 3 位！

现在让我们切入正题。

## A silver toolbox

这里有一个小问题：我们没有灵丹妙药！ **但我们确实有一个银色工具箱** 。前端任务本质上是如此多样化，以至于达到更优化的生产力，即下一个前沿领域，不仅仅是通过一种工具来实现的，而是通过多种工具的组合来实现的。让我们谈谈它们，以及如何做出适当的选择。

## Tool #1: Hotwire/Turbo frontend for simple/CRUD pages

由 [View Component](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends) （Phlex） 提供支持的新主流 HTML-over-the-wire 前端是构建具有两个特征的页面的最高效方法：

1. 它们可以将状态管理委托给服务端。这些包括简单的 CRUD 页面、大多数管理面板、向导以及用户行为与页面上多个元素的状态之间几乎没有纠缠的任何屏幕。
2. 它们看起来不像是 React/Svelte/Vue 生态系统中已经存在的复杂组件。这是因为构建已经存在的东西是次优的。（稍后会详细介绍。

下面是一个 Hotwire 前端的示例：一个名为 [Turbo Music Drive](https://github.com/palkan/turbo-music-drive/) 的音乐应用程序。花点时间观看实际作：

<video class="MarkdownVideo-module--root--b01ad" height="982" width="900" muted="" autoplay="" loop="" playsinline="">
	<source type="video/mp4; codecs=avc1.4D401E,mp4a.40.2" src="https://evilmartians.com/static/13cded9923d6082d862c25d6374d4541/hotwire-vs-turbo-mount.av1.mp4">
</video>

我们构建它是为了探索 Hotwire 的极限：了解在保持工作效率的同时，我们可以在相互依赖的行为和更新方面走多远。

现在，这大约是你想要使用 Hotwire 的极限，因为我们可以通过使用下一个工具来简化它。我们可以在 wires（Turbo 中的以及我们大脑中的）过热之前应用冷却【译者注：原文的 cool 一语双关，既是“冷却”也是“酷”的意思，“冷却”是针对“Hotwire”的“Hot”而言】解决方案。

## Tool #2: Turbo Mount for a standalone React/Svelte/Vue component

矛盾的是，使用 Hotwire 保持高效所需的只是在需要时优雅地摆脱它的能力！即使在完美布线的 Turbo 应用程序中，一些组件也可能开始过热，并具有更复杂的交互要求。

这时最好通过在 React、Vue 或 Svelte 中构建特定部分，并使用我们的开源工具 [Turbo Mount](https://evilmartians.com/chronicles/the-art-of-turbo-mount-hotwire-meets-modern-js-frameworks) 将其安装到你的 Turbo 驱动的视图中来冷却。

Turbo Mount 允许在非常细化的组件级别上引入所选的前端框架。Turbo Mount 在 Rails 视图和现代 JavaScript 组件之间架起了一座干净的桥梁。

它会自动处理所有 prop 传递和生命周期事件，让你可以将 React/Vue/Svelte 组件无缝嵌入到 Hotwire 驱动的页面中。

这里是[一个示例，我们使用 Turbo Mount 将 Turbo Music Drive 中的播放器替换为现有的 React 组件 ](https://github.com/palkan/turbo-music-drive/tree/demo/turbo-mount)。这种方法的主要优点是：

- 我们使用现有的库组件
- 我们最终的自定义 JS 代码要少得多（比较 [player_controller.js](https://github.com/palkan/turbo-music-drive/blob/main/app/javascript/controllers/player_controller.js) 和 [Player.tsx](https://github.com/palkan/turbo-music-drive/blob/demo/turbo-mount/app/javascript/components/Player.tsx)）
- 组件的代码现在完全隔离在一个位置（而不是 \_player.html.erb 和 player_controller.js）
- 多亏了 Turbo Mount，我们只有 50 行 React 和 TS

这种方法的局限性显然是 UX 的响应性受组件的限制。 **但是，一旦我们觉得需要一个完整的页面反应式 SPA，就可以使用我们的下一个工具** 。

## Tool #3 Inertia for React/Svelte/Vue SPA where you need it

**当你看到温度上升**时 — 多个组件纠缠在复杂的状态管理中，并且整个页面需要响应性 — **就是时候让 Inertia.js 来掌控**了。它允许你使用 Rails 和自己最喜欢的前端框架（React、Vue 或 Svelte）构建单页面应用（SPA），所有这些都无需单独的 API 开销。

**使用 Inertia on Rails 的主要好处是与现有的 Rails 应用程序无缝集成** 。使用 Inertia 时，不需要单独的 API 层，你可以使用熟悉的路由模式和控制器。唯一更改的组件是视图。

无论何时构建具有多个相互依赖小部件的复杂仪表盘、实时更新和复杂的状态管理或类似功能，**Inertia 都可以让你利用现代前端框架的全部功能，同时保持 Rails 的简洁和惯例。**

你可以[在此处找到 Turbo Music Library 的 Inertia 版本 ](https://github.com/vankiru/turbo-music-drive/tree/demo/inertia)。可以看到后端逻辑和代码几乎保持不变。同时，我们的 UI 现在由 React 及其响应性提供支持。

我们按照 React 的用途来使用 React：作为一个视图层库（而不是一个带有路由、API、复杂存储等的多功能巨无霸）。

**这种方法让我们有机会利用丰富的前端生态系统和工具，将 UI/UX 工作委托给前端团队（或 AI，如 Bolt），并让 Rails 专注于它最擅长的事情——应用程序的业务逻辑** 。从技术上讲，我们可以消除很大一部分 HTTP 往返请求，并在可能的情况下依赖本地状态。例如，在我们的音乐播放器中，不需要发出 HTTP 请求来更新播放器的状态（播放另一首歌时）：

<video class="MarkdownVideo-module--root--b01ad" height="982" width="900" muted="" autoplay="" loop="" playsinline="">
	<source type="video/mp4; codecs=avc1.4D401E,mp4a.40.2" src="https://evilmartians.com/static/a46408465bdf96a938beb1f006d11214/turbo-mount-vs-inertia.av1.mp4">
</video>

我们可以更进一步，通过 [Typelizer](https://github.com/skryukov/typelizer) 引入类型系统拼接（很难想象现代前端工程师会编写除 TypeScript 之外的任何内容）来使这种共生关系更加牢固。

最后，Inertia 通过服务端渲染支持为 HTML-over-the-wire 留下了空间，尽管这需要引入另一个工具 - 让我们开始吧！

## Tool #4 Vite Ruby: our secret ingredient

我们今天展示的工具箱非常有效，这要归功于一种秘密成分 [Vite Ruby](https://vite-ruby.netlify.app/)。[Vite](https://evilmartians.com/events/using-vite-ruby-vite-conf) 从应用程序级别抽象出特定的构建工具（它依赖于 esbuild 和 Rollup，即将推出 Rolldown），并通过其插件系统提供快速构建、出色的 DX 和灵活性，以适应未来的任何情况。

它 “就是好用”，与 #nobuild 不同的是，它不会将你锁定在一堆需要构建工具的 gem 之外。**Vite 是使我们整个前端战略成为可能的基础，提供快如闪电的开发体验和可靠的生产构建** 。

此过程中，虽然工具是必不可少的，但只有在长期维护和发展的支持下，它们才有价值。这就是我们的承诺所在。

## Our commitment

在 Evil Martians，我们并非只是出于自己有能力这么做才去构建 Turbo Mount，[ 为 Inertia 做出贡献 ](https://github.com/skryukov/inertia_rails-contrib)，并在任何地方推广 Vite Ruby**，——恰恰相反，我们构建、维护并积极为这些工具做出贡献，是因为我们与客户一起使用它们。因此，我们投资于他们的成功和发展** 。

如果你正在使用这些工具并遇到任何问题，或者觉得缺少某些内容，请告诉我们！联系我们 - 我们随时为您提供帮助。

## Moving forward

在 2025 年，Rails 的前端前景不再是选择单一的解决方案，而是为每项工作提供合适的工具。本着这种精神，我们的 Silver Toolbox 解决方案为你提供以下所有功能：

- 用于快速开发标准 CRUD 接口的 Hotwire
- Turbo Mount 可在需要时无缝集成反应性组件
- 在不牺牲 Rails 约定的情况下构建完整 SPA 的惯性内容

这种组合使初创公司团队能够在提供卓越的用户体验的同时保持精简。 **借助这些工具，你可以专注于最重要的事情 - 构建令用户满意并发展业务的功能**。

不要让事情变得太热——让这个夏天保持凉爽——当有什么事情让你放慢脚步时，请联系我们以提高生产力！
