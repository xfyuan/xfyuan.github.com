---
layout: post
title: 为什么我偏爱 Ember.js 胜过 Angular 和 React.js
author: xfyuan
categories: [ Frontend ]
tags: [ember]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a006.jpg"
---

前几天看到了这篇文章：[Why I prefer Ember.js over Angular & React.js](http://voidcanvas.com/prefer-ember-js-angular-react-js/)，觉得对于国内期望了解 Ember.js 的开发者来说是一个不错的介绍。于是和该文的作者 [Paul Shan](http://voidcanvas.com/author/paulshan/) 联系取得翻译的授权，翻译了过来。译文如下：

从我开始写 JavaScript 已经有5年了。无论是开发项目，指导别人，还是发布文章，JavaScript 都给了我极大的满足感。感谢 JavaScript！

在过去5年里我使用过很多 JavaScript 框架，不管做后端还是前端。但 Ember 从2015年中期就从我的开发世界中消失了。幸运的是1个月前机缘凑巧我又参加了一个用 Ember 做的前端项目。起初我并不太在意这点，只把它当作不过又一个日常开发而已。但随着项目的深入我开始思考自己关于这三个前端框架的体验，并在今天把它记录下来。

## 声明

* 该文并非是要抨击 Angular 或 React。
* 该文并非要很深入探讨技术层面的部分，而是作为一个开发人员对其真实使用体验的吐露。
* 标题中我使用了“偏爱”而非“推荐”的字眼，因为“推荐”往往要和具体项目具体场景相关，而“偏爱”则是一种更普适性的描述。

## Ember 令人满意之所在

### 原生感受

说实话，最近几年来我对 JavaScript 越来越不满。我不喜欢有人试图用工程的模式来对待 JavaScript。我喜爱 JavaScript 就仅仅是 JavaScript 而已。这也是我为什么不喜欢 TypeScript，以及 Angular 2。我看不到任何用处来多学习另一门语言，只为了试图引入一些丑陋的类（我知道是可选的）和语法。React 至少在这一点上做的比 Angular 2 好一些，但你依旧要面对 jsx 的问题。

相反，Ember 使用了纯 JavaScript。你只用写 JavaScript。Ember 提供了很多 api，却没有额外的语法。这让我作为 JavaScript 开发者而言感觉很棒。

### 约定大于配置

相信我，尽可能地减少配置相关代码对你的项目将有巨大的好处。首先，代码会变得少而清爽。其次，约定将是通用的，任何新加入的开发者都能了解发生了什么。对于那些之前从没有使用过 Ember 的人来说，只要你遵循了约定来命名文件和变量，Ember 就能自己处理好剩下的事情。

### 所见过的最好文档

[Ember guides](https://guides.emberjs.com/) 和 [Ember API](http://emberjs.com/api/) 的文档可能是我开发生涯中见过的最好技术文档。即使是一个初学者都能很容易理解并上手。Ember 的[官方论坛](https://discuss.emberjs.com/)对于解决疑问也很有帮助。

### 最好的构建体验

[Ember-CLI](https://ember-cli.com) 是 Ember 的一大杀器。即使 Angular 都试图借鉴 Ember 的这一工具来开发自己的 CLI。使用 ember-cli 你可以快速构建一个预定义好目录文件架构的项目，而这样的架构是经过社区的讨论和实践所验证过的。当项目开始构建时，无论团队是否对此有经验，都完全不用担心有没有遵循最佳实践的问题。对于 React 而言这里就可能存在风险，因为它[只是一个库并非是一个框架](http://voidcanvas.com/framework-vs-library-one-better/)。

### 强制性的最佳实践

即使你的团队中有很棒的开发者，有时候迫于上线的压力他们也会写出坏的代码。而 Ember 会至少在某些层面上强制性地让你采取最佳实践的方式。举个例子，你不应该把业务逻辑写到模版中。Ember 的模版里只可以使用迭代 iteration 和带布尔参数的 helper 帮助方法，这样你就根本别考虑在模版里写业务逻辑的事儿了。

### 开发效率的提升

我知道，在三个框架里 Ember 可能是学习曲线最陡也最难学的那一个。但是一旦你掌握了它，你就能开发一个项目超快，远胜过 Angular 或 React。“约定大于配置”和 ember-cli 就是最主要的两个原因。

### 团队工作

如果你公司的所有团队（甚至即使有人不在公司办公）是在开发多个 Ember 项目，使用 ember-cli 构建工具，那么他们每个人的项目目录文件架构会非常相似，而且可以几乎不花费什么时间成本就进行项目的切换，并立刻投入开发和提交代码。这实际变相提高了公司实际上的开发效率。

### 不属于公司只属于社区

Angular 属于 Google，React 属于 Facebook。而 Ember 来自于社区，也只为了社区。**Ember 核心开发团队的开发者们都来自于各自公司实际 Ember 项目的成员，这恰好是 Ember 的最大不同之处：他们不仅是框架的开发者，更是框架的使用者。这让他们能始终贴近现实，紧接地气。**

### 友好的版本发布

我幸运地在 Angular 2 发布时已经离开了之前的 Angular 项目，但我的朋友要为项目升级到 Angular 2 头疼和抓狂了。与此相反，Ember 2 发布时没有任何变化。是的，你没听错。它没有任何变化。Ember 1.13.0 和 2.0 在使用上完全相同，因为 Ember 是采取渐进式的策略来对 1.x 开放新功能，以便让使用 Ember 的实际项目能进行完全无痛地升级。这正是 Ember 核心团队成员“不仅是框架的开发者，更是框架的使用者”的最好体现。

## Ember 没有缺点了吗？

任何事物都有两面性，Ember 也不例外。Ember 也有自己的缺点，诸如陡峭的学习曲线，稍慢的页面渲染，框架体积较大等。已经有很多的技术文章对这些框架进行过比较了。但本文更多的是在开发实践体验上我个人的一些感受。我相信这些框架中不管选用哪一个，就技术而言都能帮你完成项目。但还有一些除此之外的因素影响到你项目的实施和进展。在考虑了各种实际情况、业务、场景之后，你就可以做出最佳的决策来启动项目了。

## 相关文章

1. [Is React.js tougher and confusing than Ember or Angular?](http://voidcanvas.com/react-js-tougher-confusing-ember-angular/)
2. [A complete guide to Ember – Ember.js Tutorial](http://voidcanvas.com/complete-guide-ember-ember-js-tutorial/)
3. [What’s new in Angular 2.0? Why it’s rewritten – addressing few confusions](http://voidcanvas.com/angular-2-introduction/)
4. [Plus minus kind of calculation and comparison in Ember.js template, handlebars?](http://voidcanvas.com/plus-minus-kind-calculation-comparison-ember-js-template-handlebars/)
5. [MVC vs Flux – which one is better?](http://voidcanvas.com/flux-vs-mvc/)
6. [Scaffolding and understanding an ember application – Ember.js Tutorial part 2](http://voidcanvas.com/scaffolding-understanding-ember-application-ember-js-tutorial-part-2/)
