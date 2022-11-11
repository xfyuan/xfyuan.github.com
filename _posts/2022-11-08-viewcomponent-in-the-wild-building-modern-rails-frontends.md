---
layout: post
title: "野生的ViewComponent（上）: 构建现代Rails前端"
author: Mr.Z
categories: [ Translation, Programming ]
tags: [ruby, rails, view_component]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20221110-01.jpeg"
rating: 5
---

*本文已获得原作者（**Alexander Baygeldin**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了在单体式模块架构下，使用 ViewComponent 来构建组件化的现代 Rails 前端的故事。（本文是上篇）*

- 原文链接：[ViewComponent in the Wild I: building modern Rails frontends](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends)
- 作者：**Alexander Baygeldin**、**Travis Turner**
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

GitHub 的 ViewComponent 已经诞生有好一段时间了，帮助开发者们在构建 Ruby on Rails 应用的视图层时保持明智的做法。它越来越受到欢迎——但并未如期望的那样快速流行。在这个分为上下两篇的系列文章里，我将阐述为什么你需要去尝试一下它。我们将讨论一些最佳实践，并展示在 Evil Martians 中使用了 ViewComponent 的项目上所积累的相当多的经验和技巧。

在上篇这一部分，我们将把脚尖探入荒野，聚焦在现代 Rails 应用内构建视图层时在更高层面的角度使用 component 方案。你会学习到为什么这种方案是一个很棒的替代品来构建 SPA 应用——尽管它相对新奇并且表面上看采用率不那么高。也会提到，至关重要的是，你如何正确地应用这种方案——而不是把自己逼疯。

本文将只有很少的代码，因为我们这里更关注宏观大局。如果你要寻找那些细节的代码部分，请别错过本文的下篇，在那里你能找到自己想要的！😉

本文目录：

1、Redeeming the ‘V’ in MVC（拯救 MVC 中的“V”）

2、Components with benefits（组件的收益）

3、How to ✨component✨（如何组件化）

## Redeeming the ‘V’ in MVC 🌱

但是首先让我们回退一步，解决一个合理的问题，它可能已经在你脑海里了：“为什么？”。这都 2022 年了，为什么我们还需要用这种传统的 MVC 应用的视图构建方式来干扰自己的头脑，看起来已经没什么人在这么干了啊？🤔

确实如此，当前，几乎每个你遇到的新项目都有一个单独的前端应用，由单独的前端工程师来维护。并且有着很好的理由：近年来前端开发者不断增长和成熟，如今我们可以构建比之前更复杂的应用了。然而，代价是什么？

如你所猜想的那样，这个问题的答案基于一个简单的事实：我们现在不得不维护两个单独的应用（一个后端，一个前端）。这很容易造成双倍的开发成本：更多的代码需要写，这意味着要聘用更多的工程师，最终要花掉更多的钱。（我还没有提到那些隐形的成本：这包含那些显著的事实比如更复杂的架构，和那些不那么显著的比如设立恰当的团队流程和沟通的困难）。

**分开的工程师 --> 更大的团队 --> 更多的开发成本（时间上和金钱上）**。

![https://evilmartians.com/static/7dd40a49329610188f2ed11e71f48d5f/a8aea/lightbulb_comic.avif](https://evilmartians.com/static/7dd40a49329610188f2ed11e71f48d5f/a8aea/lightbulb_comic.avif)

因此，我认为要问的问题不是“为什么我要使用传统的 MVC 方案？”，而是“我为什么不应该使用？”😉

考虑下你的实际情况：你的项目真的需要做成一个 SPA 应用么？还是说这被过分设计了？

**应该要问的更好的问题是这样：为什么我们不使用传统的、服务端驱动的 MVC？**

React/Vue.js/Svelte/等就是唯一的方式来构建现代、响应式的 Web 应用么？当然不是！我们都不用去寻找别的例子，看看 GitHub 就行。是的，今天支撑着最多的开源项目的应用是一个多页面 Rails 应用，而且它仍然使用 ERB 模板来渲染大部分视图。我不知道你怎么看，就我而言，它就是当今最可靠、最易于使用的 Web 应用之一——看看它的复杂度，和它仍然在持续增长和改进的事实吧。

**如果传统的、服务端驱动的 MVC 方案对于像 GitHub 如此大型规模的应用都能很好工作的话，那么，它一定也能适合你的应用！**

> 想了解更多，请参考我们的另一篇博客：["Hotwire: Reactive Rails with no JavaScript?"](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript)（[中文译文：“Hotwire: 没有JavaScript的Reactive Rails”](https://xfyuan.github.io/2021/04/hotwire-reactive-rails-with-no-javascript/)）

实际上，跟 GitHub 比较你更加有利，因为你能从一开始就用上一些新的工具。例如，近来在开发社区内开始受到欢迎的新方案：HTML over-the-wire。它由 Phoenix LiveView 引领先锋，然后在 Rails 世界内以 [Hotwire](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript) 掀起风暴，承诺以一种简单的方式来构建响应式 Web 界面，而无需写一行 JavaScript 代码。当然，它并非银弹，但它确实是一个构建 SPA 的可行替代方案，以及我在上面所概述的给项目带来的明显优势。

**我强烈建议你去看看由 Vladimir Dementyev 所做的 [Frontendless Rails Frontend](https://noti.st/palkan/eVl0xO/frontendless-rails-frontend) 演讲的幻灯片，如果你想了解更多的话。**

无论如何，当争论一个特定项目到底是做成 SPA 还是传统的多页面应用，有一件事都是肯定的：两种方案都需要一种明智且可维护的方式来组织构建其代码。这就最终把我们带到了接下来的主题：✨**components**✨

## Components with benefits 🌿

前端开发已经“组件化”有很长时间了，没有人再质疑这种方案。原因很清楚：组件就是那种好代码应该成为的化身——隔离，易于测试，可重用，以及可组合。比较于我们过去 10 年中所写的 jQuery 驱动的意大利面条式代码，就像是骑了多年的马之后换成了驾驶[德罗宁跑车](https://zh.m.wikipedia.org/zh-my/%E5%BE%B7%E7%BE%85%E5%AF%A7%E6%B1%BD%E8%BB%8A%E5%85%AC%E5%8F%B8)一般。难怪该方法的开创性解决方案（即 React 和 Vue.js）如此迅速而广泛地被行业所采用。

然而，当你敲下`rails new`创建一个新项目时，看到了什么呢？partials 和 view helpers——跟 2005 年一样。不止一次说过，这种方案已经过时了，因为它甚至违背了最基本的代码品质的标准。并且，就像 jQuery 意面代码，这种方案的所有缺陷都依然如故：紧密耦合的代码，隐晦不明的参数，不可预测的数据流，魔法般的常量——甚至都不能让我从测试开始！

> 想了解更多，请参考 Joel Hawksley 在 RailsConf 上超棒的演讲：[Rethinking the View Layer with Components](https://www.youtube.com/watch?v=y5Z5a6QdA-M).

![https://evilmartians.com/static/79cbc78b6b40eff12c5b193d7a3a4728/42705/unit_tests_comic.avif](https://evilmartians.com/static/79cbc78b6b40eff12c5b193d7a3a4728/42705/unit_tests_comic.avif)

现在，如果这听起来完全像是前端行业当时所遭受的问题——那是因为它们正是如此。唯一的区别在于，直到最近，我们后端开发者都由于我们工作的特殊性而忽略了它们（同时也因为前端开发已经接手了这一部分工作的缘故）。但是说真的，对于传统的服务端渲染 HTML 的方案，其并没有什么内在的错误（这实际上是一件有趣的事情，因为 HTTP 实际上代表超文本传输协议）。

**Rails 的视图层绝非是注定失败的：它需要的只是更好的工具。**

而这正是 [ViewComponent](https://viewcomponent.org/) 大显身手的地方了！它是我们一直缺失的组件模式的一个 Ruby 原生实现库，100% 解决了我们上述的全部问题。它的核心基于一个看似简单的构想，然而却有深远的影响：一个视图组件（view component）就是一个带有相关联模版（ERB/Slim/etc.）的 Ruby 对象。

渲染一个组件时所有需要做的就是把它实例化，跟任何其他 Ruby 对象一样，通过把所需的依赖以参数传给 constructor，然后对其调用 Rails 的 `#render`方法——就是这样简单。

这听起来跟使用 partials 没有不同，是吧？感觉我们几乎只是在底层来手工处理 partials 所做的事。然而，通过选择使用 Ruby 对象并把以前的隐式转为显式，我们得到了许多。最重要的是——我们获得了可预测性（其实质上转化成了可维护性）。我们把 Ruby 最强大的特性——OOP——的全部能力带进了视图。

慢着，这还不是全部！例如，我们来看看它是如何影响测试的。考虑下上面的定义，我打赌你会惊讶于测试组件就跟测试 POROs 一样容易（如果你不相信，可以[看看这里](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends#test-the-actual-behavior-not-the-helpers)）。使用 ViewComponent，你可以最终让你的视图层代码优雅起来，不用再试图修复测试套件中的黑洞，包含许多请求和/或系统测试用例——众所周知，它们又慢又脆弱，而且看起来永远都不够（因为[整合测试就是一个骗局](https://www.youtube.com/watch?v=VDfX44fZoMc)）。因此，一个健康的测试金字塔不再听起来像是一个神话概念仅仅存在于理论之中，而是我们能够在现实之中所触摸得到的东西了。

哦对了，我提到组件测试跑起来异乎寻常的快了吗？使用 ViewComponent 来测试 DOM 简直就是自由飞翔。所以，如果这样你仍然坚持使用 partials，好吧……我只能说，在测试条件分支沿着视图链向下深入的地方，祝你好运（愿力量与你同在）！

> 在 GitHub 的代码库中，ViewComponent 的单元测试比类似的 controller 测试要快 100 倍以上。

当然了，在后端使用组件还有些别的（不那么明显的）收益，而我相信其中一个应该值得我们的关注。

**使用 ViewComponent 最大的收益是在后端和前端的团队之间取得了平衡。**

前端开发者习惯于“在组件中思考”。并且，从经验上讲，在后端应用相同的方案，当需要深入后端代码去修复一些视图问题时，极大地减少了他们的学习曲线（而且，说实话，这种必要性迟早会出现）。

> 想了解更多，请参考我们的另一篇博客：“[Vite-lizing Rails: get live reload and hot replacement with Vite Ruby](https://evilmartians.com/chronicles/vite-lizing-rails-get-live-reload-and-hot-replacement-with-vite-ruby)”

总而言之，Rails 的 asset pipeline 后来已经改进了许多（使用诸如 Propshaft、esbuild、Vite 等等），这不是秘密了。可以肯定地说，在功能和可用性方面，它已经赶上了前端工具。与前端开发者在同一领域中相比，唯一缺失的是正确的设计模式，而我相信 ViewComponent 最终填补了这个缺口。所以，我满怀期望已经能够说服你，后端的视图组件（View Component）完全值得一试！

## How to ✨component✨ 🌲

现在我已经（希望如此）把通用性的思想告诉了你，该是面对苦药的时候了：不幸的是，只是简单使用组件并不能魔法般地解决你的所有问题。我们不能仅仅将它们拍在现有的视图代码之上，就期望立即使其变得更好。要遵循一些原则。

![https://evilmartians.com/static/69c3b5e39ba05ffe5944bd54362fa14f/04598/unicorn_comic.avif](https://evilmartians.com/static/69c3b5e39ba05ffe5944bd54362fa14f/04598/unicorn_comic.avif)

与任何架构模式一样，组件的方案都需要在该方案中如何操作（或如何不操作）的一定知识以使其受益。否则，你可能会得到同样的遗留代码，但这一次是“聪明的”遗留代码（最糟糕的情形）。

好消息是这种所需的知识对于我们后端工程师已经大量可用了！这要归功于我们的前端工程师朋友们的勤奋努力，他们精心制作了最佳实践列表，同时在过去 10 年中在许多生产环境上对该列表进行搏斗测试。我们所要做的就是把它们应用到现实中。换句话说，轮子已经被制造出来了，我们要做的就是让它跑起来。

现在，显然会有一些差异（这也是为什么我写这篇文章的原因，而不是让你去看 React 的文档），但这里每个最佳实践背后的核心思想将都会保持相同。因此，我强烈建议你在阅读代码片段时退后一步，从细节上略过，而专注于总体的思想。

> 尽管并非必须，我仍然建议先去概览一下 [ViewComponent 官方文档](https://viewcomponent.org/guide/)。这会让你对后面的代码更适应。

这会帮你更好地理解组件方案背后的原则，却也将使你有所困惑，因为一些代码片段使用了一些“非正统”功能，这些功能在 ViewComponent 文档中你找不到。别担心！在本文的下篇中一切都将揭晓，不过目前，让我们把目光放到大局上。

### Test the actual behavior, not the helpers

我们在前面已经谈到了测试这个主题，也证实了组件测试是一个🍰，但要怎样正确地测试它们呢？或者说，我们要测试什么东西呢？简单，跟任何其他 Ruby 对象一样，我们测试公共接口——对于组件而言就是它的模板（惊不惊喜）。

你会被诱惑去测试那些定义在组件 Ruby class 中的方法，因为它们看起来很容易也很熟悉，但是，如果你这样想的话，从根本上讲，就跟给私有方法编写测试是一回事了（千万别这么做）。把那些方法跟 helpers 一样对待就好，这样你就不会想错了。

“好吧，但是我们要怎样来测试一个模板？”——我很高兴你这么问！

来看看如下示例：

```erb
<!-- app/views/components/menu/component.html.erb -->
<% if current_user %>
  <div class="greeting">Hello, <%= current_user.name %>!</div>
  <%= button_to t(".sign_out"), users_sessions_path, method: :delete %>
<% else %>
  <%= button_to t(".sign_in"), users_sessions_path %>
<% end %>
```

你看到了什么？对于我，看到的是带有条件逻辑的命令式代码，它们需要用测试来覆盖。可能命名有些困惑，因为模板应该是声明式的（某种程度上），但从本质上讲，它与我们编写的常规代码没有区别，因此，它们必须以类似的方式进行测试。

下面是这个组件的测试大概的样子：

```ruby
# spec/views/components/menu_spec.rb

describe Menu::Component do
  subject { page }

  let(:component) { described_class.new }

  before do
    with_current_user(user) { render_inline(component) }
  end

  context "when current_user is present" do
    let(:user) { build(:user, name: "Handsome") }

    it "renders sign out button" do
      is_expected.to have_link "Sign out"
    end

    it "has greeting text" do
      is_expected.to have_content "Hello, Handsome!"
    end
  end

  context "when current_user is absent" do
    let(:user) { nil }

    it "renders sign in button" do
      is_expected.to have_link "Sign in"
    end
  end
end
```

注意：我们不为确切的标记做测试断言——这是没有意义的。相反，我们感兴趣的是跟编写其他单元测试同样的事情：条件逻辑和计算（简单来说，这里就是字符串插入）。这就是你如何为视图层获得良好测试覆盖率的方式。

**ViewComponent 为我们提供了简单直观的方式来对组件进行隔离测试，所以我们最终就能编写自己完全信赖的视图代码。**

去看看这些测试会快得多么耀眼吧。完全是因为我们测试的是静态输出，没有任何 HTTP 请求或浏览器设置……等等，静态？那动态 JS 行为怎么办？当然，我们希望在某个时候用 JS 来点缀自己的组件！

> 想了解更多，请参考我们的另一篇博客：“[System of a test: Proper browser testing in Ruby on Rails”](https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing)（[中文译文：2020时代的Rails系统测试](https://xfyuan.github.io/2020/07/proper-browser-testing-in-rails/)）

虽然 ViewComponent 的维护者们希望合并一个 [PR](https://github.com/github/view_component/pull/1061)，以便我们在真正的浏览器中工作时轻松地隔离测试视图组件的动态行为，但你可以通过[预览](https://viewcomponent.org/guide/previews.html)和传统的系统测试来做到同样的事。你只需要测试中加载预览页面就好：

```ruby
# spec/system/components/my_component_spec.rb

it "does some dynamic stuff" do
  visit("/rails/view_components/my_component/default")
  click_on("JavaScript-infused button")

  expect(page).to have_content("dynamic stuff")
end
```

### Use context to pass global state

组件需要数据来渲染，但数据从哪儿来？如果我们排除了诸如麻烦的 post 或全局变量之类的深奥选项，那么只剩下一种方式来把数据传给组件了：参数。然而，由于数据是从上到下传递的，这会让“通用”数据（比如 current user）的使用变得异常笨拙，因为我们必须把它向下传递到组件树的每一层，以使其到达最终所需的组件。

噢！如何修复这个问题？如果你熟悉前端开发，就已经知道答案了：[context](https://reactjs.org/docs/context.html)。

**代替显式依赖注入的做法，我们可以把这些依赖通过 context 显式注入——一个能够被组件树中的任何组件所共享的对象。**

一种实现 context 的方式是使用 [dry-effects](https://dry-rb.org/gems/dry-effects/)，它是一个 Ruby 代数效应的实现。别管那些烧脑的词汇，它不过是让你能够在调用堆栈的某个位置设置一个值，并从行的任何位置访问它（比如，在 controller 中设置`current_user`并在视图组件中访问它）。

在本文的下篇里，我会展示具体如何做。目前，只要知道有这种技术并切记不要滥用它就好。你通过 context 显式传递的东西越多，要追踪数据从何而来和编写对应测试就越难。

### Avoid deeply nested component trees

俄罗斯套娃很有趣，因为你总想知道他们到底会有多少个。类似地，当处理过深的嵌套组件树时，你也想知道具体有多深（直到你完全丧失理智为止）。所以，为了避免不必要的伤害，我们来揭示为何及如何避免这种情形。

我们已经知道如何使用 context 把频繁使用的数据沿着组件树向下传递，但很明显并非所有数据都用这种方式传递。实际上，大多时候都是从参数传递的，所以我们已经在前一章中指出的问题依然存在。

**在那些通过 context 传递数据不适用的场合，解决“参数下钻”问题的办法就是把组件而非数据向下传递。**

ViewComponent 提供了两种方式来处理这个麻烦：`context`存取器（accessor）和[slots](https://viewcomponent.org/guide/slots.html)。我们来看一个组件使用 slots 的例子：

```ruby
# app/views/components/feed/component.rb

class Feed::Component < ApplicationViewComponent
  renders_one :pinned

  renders_many :posts
end
```

```erb
<!-- app/views/components/feed/component.html.erb -->

<div class="pinned">
  <%= pinned %>
</div>

<% posts.each do |post| %>
  <%= post %>
<% end %>
```

下面是如何渲染它：

```erb
<%= render(Feed::Component.new) do |c| %>
  <% c.with_pinned do %>
    <%= render(Post::Component.new(@pinned_post)) %>
  <% end %>

  <% @posts.each do |post| %>
    <% c.with_post do %>
      <%= render(Post::Component.new(post)) %>
    <% end %>
  <% end %>
<% end %>
```

噢，这么多代码！如果你将其与我们通过参数传递数据的代码相比，可能会得出结论：这并不值得：

```erb
<%= render(Feed::Component.new(pinned: @pinned_post, posts: @posts)) %>
```

但考虑下这个：如果我们的应用中有两个 feeds（一个是个人的，一个是全局的），并且想要这两者中的`post`组件的视觉样式有些许差别，你怎么做（例如，在个人 feed 中隐藏 post 作者）？当然，我们可以添加一个新的选项到`post`组件上（`show_author`或其他什么），但是`feed`组件在渲染`post`组件时是无法知道如何去设置它的，除非我们在`feed`组件上也添加同样的选项。想象一下你将不得不在组件树的每个组件上都要做一遍同样的事——这足以让大部分理智的人都疯掉。

**无论何时，当一个子组件有不同于其父组件的数据需求时，几乎总是意味着它应该被作为组件向下传递，而不是在父组件的模板中来硬编码实现。**

这种技术方案会把你从许多烦恼中解脱出来，但不止如此：它还能让你的组件更易于重用。如果我们想在`pinned` slot 中显示不同的组件，怎么做？或者把`feed`换成另一个有相同 slots 的组件呢（比如一个`board`或其他什么）？而使用这种方案，你基本上都能应付自如。

### Extract general-purpose components

如果你在前端圈子里已经呆过一段时间了，那应该听说过“Smart”和“Dumb”组件（或近似的， [*Presentational* 和 *Container* 组件](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0)）。你也可以把它们叫做“通用目的”和“应用专属”组件。不管名称怎样称呼，前者都应该充当你的应用的“调色板”（同时对应用的数据模型一无所知），而后者是使用此调色板实际绘制视图的角色。Presentational 组件关心的是视觉上看起来怎样，Container 组件关心的是事物如何工作——这样想你就清晰了。如果你把一个`ActiveRecord`对象传递给一个组件，那它显然是应用专属的。

把组件拆分为“通用目的”和”应用专属“，将使你有更大的机会能够贯穿整个应用来重用视图代码，从而在开发过程中贯彻“DRY”原则。

![https://evilmartians.com/static/b9e7207c6615510f3c76f93050327e92/e2dc3/reusable_components_comic.avif](https://evilmartians.com/static/b9e7207c6615510f3c76f93050327e92/e2dc3/reusable_components_comic.avif)

虽然坚决地坚持这种分离可能不值得，但我仍然认为重要的是要考虑应用的核心组件是什么，因为这将帮助你保持 UI 的一致性。可能有一天，你甚至会开源它（就像 GitHub 对待他们的 [Primer ViewComponents](https://primer.style/view-components/) 一样）。

### Stick to the single-responsibility principle

就像有上千行的神奇 model 是一种代码味道（code smell）一样，对于有上千行长度的视图模板也是如此。实际上，对于模板的场景，即使是上百行长度，其味道就已经很难闻了，因为（与 class 中的方法相反）模板内的一切都是有联系的——至少是通过父子关系，但它很少在那里结束。

你可能已经听过“低耦合，高聚合”（基本上归结为“分治”原则），当涉及到单体式模块架构时，它总会出现。好吧，你猜怎么着？视图组件并无不同。Modules、blocks、components：随你怎么叫，其核心方式都是一样的。

**请记住，首先，我们使用组件是为了在代码库中促进良好的代码质量标准。**

这意味着坚持我们总是坚持（或至少尝试去坚持）的相同原则。这尤其适用于单一职责原则。

![https://evilmartians.com/static/15b0f3f23cf1fd588c0528772436aefe/aaed8/good_practice_comic.avif](https://evilmartians.com/static/15b0f3f23cf1fd588c0528772436aefe/aaed8/good_practice_comic.avif)

严肃地说，在前端社区中忽视了大型组件树。对此有很好的理由：它们难以理解和重构，也几乎不可能被重用。随着时间的推移，它们的实现会由于邻近的组件逻辑而逐渐纠缠到一起以至于更加耦合，相对而言，把整个组件子树完全丢弃掉并从头开始重写它会更容易一些。

**组件应该具有原子性，只关心单一职责。**

分解大型组件树要耗费时间和精力，但如果你的目标是控制其复杂性，那么💯%是值得的。

### Avoid making database queries inside components

这一点对后端开发来说很特殊。

**视图是为了渲染数据，而不是获取数据。**

在 controller 而不是视图中获取数据。就好比，你不应该在床上吃东西，对吧？什么，你不是这样？好吧，我也是——但这不是重点！我的意思是，什么事该在什么地方做，需要划分清晰，才能让我们的生活更方便。就像每次我在床上吃快餐，总会把难以清理的残渣在自己四周弄得到处都是。而就像床上的食物碎屑令人烦恼一样，当你认为在视图中进行数据库查询是一个好主意时，N + 1问题就也会随之而来。试着尽可能避免这种做法并预加载数据。

P.S. 尽管吃饼干会洒落大量碎屑，冰淇淋却不会。（这并非什么有关组件的隐喻，只是一个在床上吃东西的小技巧而已）

> 想了解更多，请参考我们的另一篇博客：“[Squash N+1 queries early with n_plus_one_control test matchers for Ruby and Rails](https://evilmartians.com/chronicles/squash-n-plus-one-queries-early-with-n-plus-one-control-test-matchers-for-ruby-and-rails)”（[中文译文：在Rails中尽早碾碎N+1查询](https://xfyuan.github.io/2020/10/squash-n-plus-one-queries-in-rails/)）

实际上，作为主动措施，你可以更进一步，在开发中完全禁止组件进行任何数据库查询。我会在下篇中向你展示如何设置这个，敬请期待！😉

## 结语

哇哦！我想，我们已经涵盖了那些决定走上采用组件方案之路的人所将面临的大多数严重隐患了。记住，不要教条主义（每个场景都是不同的！），但一般而言，如果你坚持上述指导的话，将会得到一个更好的结果：更令人愉悦，且更易于维护的代码。

现在，下一步终于要踏上荒野了—— ViewComponent 在生产环境上的使用，让它成为我们自己的！

下周见！🌲🌳🌲🌳🌲
