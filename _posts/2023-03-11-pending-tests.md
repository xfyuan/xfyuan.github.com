---
layout: post
title: 等待测试之际
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, testing, ddd, 37signals]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image2023-0311.jpeg"
rating: 4
---

_本文已获得原作者（**Jorge Manrubia**）和 [37signals](https://37signals.com/) 授权许可进行翻译。原文分享了一个关于 TDD 测试的观点。_

- 原文链接：[Pending tests](https://dev.37signals.com/pending-tests/)
- 作者：Jorge Manrubia（[Github](https://github.com/jorgemanrubia)、[Twitter](https://twitter.com/jorgemanru/)），居住于西班牙瓦伦西亚，目前工作于 37signals，诸多 Ruby、Rails 的 Gem/Library 的作者，比如：[Active Record Encryption](https://github.com/rails/rails/pull/41659)（已被纳入 Rails 7 成为默认特性）、[mass_encryption](https://github.com/basecamp/mass_encryption)、[console1984](https://github.com/basecamp/console1984)、[audits1984](https://github.com/basecamp/audits1984)、[ib_ruby_proxy](https://github.com/jorgemanrubia/ib_ruby_proxy)、[impersonator](https://github.com/jorgemanrubia/impersonator)、[turbolinks_render](https://github.com/jorgemanrubia/turbolinks_render) 等
- 站点：37signals 以创建了 [Basecamp](https://basecamp.com/) 和 [HEY](https://www.hey.com/) 而举世闻名，也撰写了很多商业和软件相关的书籍（[Getting Real](https://www.amazon.com/Getting-Real-Smarter-Successful-Application/dp/0578012812), [REWORK](https://bookshop.org/books/rework-9780307463746/9780307463746), [REMOTE](https://bookshop.org/books/remote-office-not-required/9780804137508), [It Doesn’t Have to Be Crazy at Work](https://bookshop.org/books/it-doesn-t-have-to-be-crazy-at-work/9780062874788), 以及 [Shape Up](https://basecamp.com/shapeup)），更创造了著名的 [Ruby on Rails](https://rubyonrails.org/) 框架。

_【正文如下】_

## 引言

我现在很少先写测试或利用它们来设计代码了。

## 正文

我最近在 37signals 开始忙于一个新项目上。我们面前一片白纸，空无一物，这意味着我们能快速前进。我发现自己每天都能创建许多 PR。而我想要尽早开启它们以验证讨论时，它们都含有下面这个东西：

![img](https://dev.37signals.com/assets/images/pending-tests/pending-tests.png)

这只是反映出我常在最后才写测试的工作方式。一个例外是，当测试为我提供了最短的反馈循环时，就我的经验而言，这在基础设施中比在产品环境中更频繁地发生。但即便如此，我也不寻求利用测试来帮我设计系统。我并不践行 TDD（Test-Driven Development）。

我对于 TDD 及其所能带来的都非常了解。我曾完全拥抱这种范式，当它在某时某刻被引爆时，我停止了对它的使用，首先会有一种内疚感，然后则是[感到一种解脱](https://dhh.dk/2014/tdd-is-dead-long-live-testing.html)。

关于 TDD 有这些方面我都很喜欢：它鼓励从外部观察系统，就像一个隐藏了复杂性的黑匣子，提供了一个易于理解的界面。正如我在过去所写的那样，我认为[这是一个关键性的设计原则](https://dev.37signals.com/fractal-journeys)，你需要把它应用在每一个抽象层面上，从 app 的边界之外直到其包含的最后一个内部方法。我认为你根本不需要 TDD 来做到这一点，但从用户的角度考虑接口是积极的。

而从负面的一侧来看，TDD 鼓励一种我对其抱以警惕的测试风格：通过 mock 慢的依赖性来构建非常小而快的测试。在我的经验中，这种测试方案有着糟糕的成本/收益：在[达到给定的信心水平](https://stackoverflow.com/questions/153234/how-deep-are-your-unit-tests/153565#153565)之时，它既昂贵又低效。多年以前，我写下了[一些关于测试偏好的思考](https://www.jorgemanrubia.com/2018/05/19/on-rails-testing/)。我可以把其总结为*尽最大可能地测试真实的东西*。

TDD 的另一个危险在于，伴随而来的信念是强调可以独立测试的构建代码块能产生设计良好的系统。我可以相信，一个设计良好的系统在某种程度上必须是可测试的，但我不认为反之亦然或者说每个单独的部分都必须是可单独测试的。你可以构建出一个糟糕的设计，却有着完美的单元测试且上千个用例在不到一秒钟内就跑完。然后，还有一个问题，就是让每个模块都可以在没有依赖性的情况下可测试，这就需要为这些模块的可注入性和间接性付出代价。我相信你可以构建出好或者不好的设计，用或者不用 TDD 均可。我看不出许多人为之辩护的那种坚实因果关系。

但最重要的是，我最不喜欢 TDD 的是你经常看到它缺乏实用主义。它很少作为一种工具在某些情况下使用，而是作为一种设计技术来驱动你如何构建软件。这种介绍，加上 TDD 带来的仪式感，吸引了教条主义者和随之而来的所有负面事物。

TDD 是一个引起从业者和批评者强烈反应的话题。我不做 TDD，但我知道它对很多人都工作良好。只要它没有教条的味道，或者被用作攻击他人专业素养的武器，我就没有问题。我只是把它看作是一个自己不用的工具，仅此而已。
