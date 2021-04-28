---
layout: post
title: "Hotwire: 没有JavaScript的Reactive Rails"
author: Mr.Z
categories: [ Translation, Programming ]
tags: [ruby, rails, hotwire, turbo, stimulus]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210220_121324.jpg"
rating: 5
---

*本文已获得原作者（Vladimir Dementyev）和 Evil Martians 授权许可进行翻译。原文介绍了 Rails 的最新“魔法”：**Hotwire**。这也是 Vladimir Dementyev 在 RailsConf 2021 上的演讲内容。*

- 原文链接：[Hotwire: Reactive Rails with no JavaScript?](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

到传播 DHH 及其公司久经考验的[新魔法](https://twitter.com/dhh/status/1275901955995385856)的时候了，并且在超过 5 分钟的教学中学习使用 [Hotwire](https://hotwire.dev/)。自从今年揭开其面纱以来，这个用于构建现代 Web 界面而似乎无需任何 JavaScript 的技术的名字就备受欢迎。这个 **HTML-over-the-wire** 的方案正在 Rails 世界里激发起层层涟漪：不计其数的博客文章、reddit 社区帖子、录屏视频，以及[今年 RailsConf 的五个演讲](https://railsconf.com/program)，而其中会包含你所期望的内容。本文中，我想要对 Hotwire 进行彻底地解释——借助代码示例和测试策略。就像我最爱的摇滚乐队说的那样，让我们 Hotwired 来……~~self destruct~~ 学习新技巧吧！【译者注：摇滚乐队 Metallica 2016 年发行了专辑《Hardwired ... To Self-Destruct》，作者在这儿使用了名称的谐音】

## Life is short

**要概览 Hotwire 在 Rails 6 中进行使用的全貌，毋需再费其他功夫，看[这个 PR](https://github.com/anycable/anycable_rails_demo/pull/16) 就足够了。**

接下来的文章会解释上述 PR 代码——在很多细节上。它是我的 [RailsConf 2021](https://railsconf.com/) 演讲：[“Frontendless Rails frontend”](https://railsconf.com/program/sessions#session-1118) 的一个改编和扩展版本，所有 RailsConf 的参会者都已能够在线观看。如果你没有大会门票也不用担心：可以在[这里](https://noti.st/palkan/eVl0xO/frontendless-rails-frontend)看到其简报，而且该页面会更新演讲视频，一旦演讲可以公开发布的话。

## “This is the way”

过去五年中，我一直主要在做纯后端的开发：REST 和 GraphQL APIs、WebSocket、gRPC、数据库、缓存等。

整个前端的进化像巨浪一样席卷了我：我仍然不理解为什么我们需要为每个 Web 应用都使用 *reacts* 和 *webpacks*。传统的 HTML-first 的 **Rails 方式** 才是我的方式（或者说捷径😉）。还记得那些 JavaScript 在你的应用中无需什么 MVC（或 MVVM）的日子吗？我怀念那种日子。而这些日子正在悄悄地卷土重来。

今天，我们目睹了 *HTML-over-the-wire* 的崛起（是的，现在它是一个实际名词了）。由 [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) 率先提出，[StimulusReflex](https://stimulusreflex.com/) 系列 gems 对其发扬光大，这种基于后端通过 WebSocket 把渲染的模板推送到所有所连接的客户端的方案，在 Rails 社区获得了极大的吸引力。最终，DHH 本人于今年初把 [Hotwire](https://hotwire.dev/) 呈现于世界面前。

我们是否正站在 Web 开发的另一个全球范式转变的边缘？回到服务端渲染模板的简单思维模型，这一次花费很少的精力就可实现各种花里胡哨的反应式界面吗？绞尽脑汁后，我认识到这是一厢情愿的想法：技术领域已经有太多的投资在客户端渲染的应用上而很难回头了。2020 时代的前端开发已经是一种独立的**资质**和有其自身需求的独立行业，我们将没办法再成为“全栈”了。

然而，HOTWire（看到那个首字母缩写吗？Basecamp 这方面很聪明，是吧？），为复杂的，或者我们应该说“错综复杂的”，航天科学一般针对浏览器的现代客户端编程，提供了一种急需的替代方案。

**对于厌倦了只做 API 应用而无法掌控其呈现，以及怀念创建卓越用户体验而摆脱每周 40 小时充斥着 SQL 和 JSON 的一名 Rails 开发者而言，Hotwire 就如他所渴望能带来新鲜气息的呼吸一般，让 Web 开发重拾乐趣。**

本文中，我会演示如何把 HTML-over-the-wire 哲学通过 Hotwire 用到现有的 Rails 应用上。就像我最近的大多数文章一样，我会使用 [AnyCable demo 应用](https://github.com/anycable/anycable_rails_demo)作为小白鼠。

这个应用很应景：交互和反应，Turbolinks 驱动，以及少量自定义 JavaScripts，还有相当好的系统测试覆盖率（这意味着我们可以进行安全地重构）。我们的 *Hotwire 化* 将会按照如下步骤进行：

- [From Turbolinks to Turbo Drive](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript#from-turbolinks-to-turbo-drive)
- [Framing with Turbo Frames](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript#framing-with-turbo-frames)
- [Streaming with Turbo Streams](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript#streaming-with-turbo-streams)
- [Beyond Turbo, or using Stimulus and custom elements](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript#beyond-turbo-or-using-stimulus-and-custom-elements)

## From Turbolinks to Turbo Drive

[Turbolinks](https://github.com/turbolinks/turbolinks) 在 Rails 世界里很长时间久负盛名；其[第一个主要版本](https://github.com/turbolinks/turbolinks-classic/commit/41dd321407f837d9705de9d893f2847537676904)在 2013 年早期发布。然而，在我的开发生涯初期，Rails 开发者有一个经验之谈：*如果你的前端出毛病了，尝试一下禁用Turbolinks*。让第三方 JS 库的代码跟 Turbolinks 的伪导航（参考：`pushState` + AJAX）兼容可不像在公园里散步那样容易。

当 [StimulusJS](https://stimulus.hotwire.dev/) 出来以后，我就不再躲避 Turbolinks 了。它通过依靠现代的 [DOM mutation APIs](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver) 而从根本上解决了“连接”和“断开连接” JavaScript 的问题。Turbolinks 与 Stimulus 的代码组合，DOM 操作仅以 React-Angular 几分之一的开发成本就轻而易举产生了“SPA”般的体验。

昔日诸般好处的 Turbolinks 现在更名为 *Turbo Drive*，就如字面上那样它驱动了 [Turbo](https://turbo.hotwire.dev/) —— Hotwire 包的核心。

**如果你的应用已经使用了 Turbolinks（如我一般），切换到 Turbo Drive 不费吹灰之力。不过是一些重命名的事儿罢了。**

所有你需要做的就是把`package.json`中的`turbolinks`替换为`@hotwired/turbo-rails`，以及把`Gemfile`中的`turbolinks`替换为`turbo-rails`。

初始化代码稍有差异，现在的更简洁了：

```diff
- import Turbolinks from 'turbolinks';

- Turbolinks.start();
+ import "@hotwired/turbo"
```

注意，我们现在不需要手动启动 Turbo Drive 了（当然你可以[不这么做](https://github.com/hotwired/turbo/issues/198)）。

还有些“查找 & 替换”工作要做：把所有 HTML 的 data 属性的`data-turbolinks`更新为`data-turbo`。

这些变更中唯一花费了我一点时间而值得一提的是处理 **forms 和 redirects**。之前使用 Turbolinks 时，我使用的是 remote forms（`remote: true`）和 [Redirection concern](https://github.com/turbolinks/turbolinks-rails/blob/master/lib/turbolinks/redirection.rb) 来响应以 JavaScript 模板。Turbo Drive 已经内置了对表单拦截的支持，所以`remote: true`就不再需要了。然而，事实证明 redirection 代码必须进行更新，或者更精确地说，是 redirection **status code**：

```diff
- redirect_to workspace
+ redirect_to workspace, status: :see_other
```

使用有些晦涩的 *See Other* HTTP response code (303) 是一个聪明的选择：它允许 Turbo 依赖原生 Fetch API 的 `redirect: "follow" ` 选项，这样在表单提交后你就不必明确发起另一个请求以获取新内容。根据[其规范](https://fetch.spec.whatwg.org/#concept-http-redirect-fetch)，“*if status is 303 and request’s method is not `GET` or `HEAD`*”，GET 请求必须被自动执行。把这个跟 “*if status is 301 or 302 and request’s method is `POST`*” 比较一下——看到区别了吗？

其他的 3xx 状态仅适用于 POST 请求，而 Rails 中我们通常使用 POST, PATCH, PUT, 和 DELETE。

## Framing with Turbo Frames

该来看一些真正的新东西了：Turbo Frames。

Turbo Frames 带来了页面在局部上的无缝更新（不像 Turbo Drive 是在整个页面上）。我们可以说它非常类似于`<iframe>`所做的，但却不用创建单独的 windows、DOM 树以及与之俱来的那些安全噩梦。

我们来看看实际的例子。

AnyCable demo 应用（称为 *AnyWork*）允许你创建 dashboards，其带多个 ToDo 列表和一个聊天室。用户可以与不同列表中的条目进行交互：添加、删除以及把其标注为已完成。

![turbo_frames.av1-d92b50b](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/turbo_frames.av1-d92b50b.gif)

起初，完成和删除这些条目是通过 AJAX 请求和[一个自定义 Stimulus controller](https://github.com/anycable/anycable_rails_demo/blob/fdb1353b3fa4aae2598b5eaceba838b73d09254e/frontend/controllers/list_controller.js) 来做到的。我决定使用 Turbo Frames 来重写这部分功能以全部使用 HTML。

我们如何来解构这些 ToDo 列表项以处理单个条目的更新呢？把每个条目都转化为一个 frame！

```erb
<!-- _item.html.rb -->
<%= turbo_frame_tag dom_id(item) do %>
  <div class="any-list--item<%= item.completed? ? " checked" : ""%>">
    <%= form_for item do |f| %>
      <!-- ... -->
    <% end %>
    <%= button_to item_path(item), method: :delete %>
      <!-- ... -->
    <% end %>
  </div>
<% end %>
```

这里我们做了三个重要的事情：

- 通过 helper 传递一个唯一识别符（来自`ActionView`的可爱的 [dom_id](https://api.rubyonrails.org/classes/ActionView/RecordIdentifier.html#method-i-dom_id) 方法），把单个条目包裹在一个`<turbo-frame>` tag 之内；
- 添加一个 HTML form，使得 Turbo 拦截表单提交并更新该 frame 的内容；以及
- 使用`button_to` helper 并带 `method: :delete` 参数，在该代码处也创建了一个 HTML form。

现在，任何时候该 frame 内有表单提交，Turbo 都会拦截该提交，执行 AJAX 请求，从响应返回的 HTML 中提取出有相同 ID 的 frame，把其内容替换到该 frame 上。

**所有上述工作没有一行自己手写的 JavaScript！**

来看一下更新过后的 controller 代码：

```ruby
class ItemsController < ApplicationController
  def update
    item.update!(item_params)

    render partial: "item", locals: { item }
  end

  def destroy
    item.destroy!

    render partial: "item", locals: { item }
  end
end
```

注意，当我们删除条目时，以同样的 partial 进行了响应。但我们需要移除该条目的 HTML 节点而非更新它。要如何做呢？我们可以用一个空 frame 来响应！更新 partial 为如下：

```erb
<!-- _item.html.rb -->
<%= turbo_frame_tag dom_id(item) do %>
  <% unless item.destroyed? %>
    <div class="any-list--item<%= item.completed? ? " checked" : ""%>">
      <!-- ... -->
    </div>
  <% end %>
<% end %>
```

 你可能会问自己一个问题：“当标注一个条目为完成时如何触发表单提交呢？”换句话说，如何让 checkbox 的状态变更来触发提交表单？我们可以通过定义一个*行内事件监听器*做到：

```erb
<%= f.check_box :completed, onchange: "this.form.requestSubmit();" %>
```

**提醒：**使用 *`requestSubmit()`* 而非 *`submit()`* 很重要：前者触发的“submit”事件能够被 Turbo 所拦截，而后者不能。

总结一下，我们可以放弃所有专门为此功能定制的 JS 了，只需一点 HTML 模板的更改和 controller 代码的简化。非常令人兴奋，不是么？

我们可以更进一步，把列表也转化为 frames。这会让我们在添加一个新条目时，从 Turbo Drive 的整个页面更新切换为仅特殊页面节点的更新。你大可自己尝试一下！

假设你也期望在一个条目被完成或删除的任何时候都为用户展示一个 flash 提醒（比如，“条目已被成功删除”）。我们能借助于 Turbo Frames 做到吗？听起来我们需要把 flash 消息容器包裹在一个 frame 内，并将更新后的 HTML 跟标记一起推送给该条目。这是我初始的思路，但其并不能正常工作：frame 的更新是在所创建的 frame 定义域内的。因此，我们无法更新在其外部的任何东西。

经过一番探索之后，我发现 [Turbo Streams](https://turbo.hotwire.dev/handbook/streams) 能帮我们做到这点。

## Streaming with Turbo Streams

较之于 Drive 和 Frames，[Turbo Streams](https://turbo.hotwire.dev/handbook/streams) 完全是一项新技术。跟前两者不同，Streams 含义明确，易于理解。没有什么会自动发生，你得负责页面上何时更新何种内容。要做到这点，你需要使用特殊的`<trubo-stream>`元素。

来看一个 stream 元素的示例：

```erb
<turbo-stream action="replace" target="flash-alerts">
  <template>
    <div class="flash-alerts--container" id="flash-alerts">
      <!--  -->
    </div>
  </template>
</turbo-stream>
```

该元素负责以`<template>` tag 内所传输过来的新 HTML 内容替换（`action="replace"`）DOM ID 为`flash-alerts`其下的节点。不管什么时候你把这样的`<turbo-stream>`元素下发到页面上，它都会立刻执行其 action 并销毁其自身。而在底层，它使用了 HTML 的 [Custom Elements API](https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_custom_elements) —— 又一个为了开发乐趣（比如，更少的 JavaScript 😄）而使用现代 Web APIs 的范例。

我得说，Turbo Streams 是老式的 JavaScript 模板的一个声明式替代方案。在 2010 年代，我们写的代码类似这样：

```erb
// destroy.js.erb
$("#<%= dom_id(item) %>").remove();
```

而现在，我们这样写：

```erb
<!--  destroy.html.erb -->
<%= turbo_stream.remove dom_id(item) %>
```

目前，仅有五种可用的 actions：*append、prepend、replace、remove 和 update*（仅替换节点的文本内容）。我们将在下面谈论其局限性和如何克服它。

回到我们的初始问题：为 ToDo 条目的完成或删除，展示响应结果中的 flash 提醒。

我们想要一次响应结果就带有`<turbo-frame>`和`<turbo-stream>`两种更新。如何来做？为其添加一个新的 partial 模板：

```erb
<!-- _item_update.html.erb -->
<%= render item %>

<%= turbo_stream.replace "flash-alerts" do %>
  <%= render "shared/alerts" %>
<% end %>
```

对`ItemsController`添加一点小的改动：

```diff
+    flash.now[:notice] = "Item has been updated"

-    render partial: "item", locals: { item }
+    render partial: "item_update", locals: { item }
```

不幸地是，上述代码并未如预期那样正常工作：我们没有看到任何 flash 提醒。

深入研究[文档](https://turbo.hotwire.dev/handbook/streams#streaming-from-http-responses)之后，我发现是 Turbo 期望 HTTP 响应具有`text/vnd.turbo-stream.html` content type 才可激活 stream 元素。好吧，加上它：

```diff
-    render partial: "item_update", locals: { item }
+    render partial: "item_update", locals: { item }, content_type: "text/vnd.turbo-stream.html"
```

现在我们得到了相反的情况：flash 消息正常工作，但条目的内容不能更新了😞。是我对 Hotwire 要求太高了么？阅读了下 Turbo 的源码，我发现类似这样把 streams 和 frames 进行混合是[不行的](https://github.com/hotwired/turbo/blob/8bce5f17cd697716600d3b34836365ebcdc04b3f/src/observers/stream_observer.ts#L50-L55)。

这说明，有两种方式来实现该功能：

- 把 streams 用在所有东西上。
- 把`<turbo-stream>`置于`<turbo-frame>`内部。

第二个选项，对我而言，与在常规页面上重用 HTML partials 并以 Turbo 进行更新的想法背道而驰。所以，我选择第一个：

```erb
<!-- _item_update.html.erb -->
<%= turbo_stream.replace dom_id(item) do %>
  <%= render item %>
<% end %>

<%= turbo_stream.replace "flash-alerts" do %>
  <%= render "shared/alerts" %>
<% end %>
```

任务完成。但付出了什么代价呢？我们不得不为这种用例添加一个新的模板。并且我担心在现实中的应用程序里，这种 partials 的数量会随着应用的进化而增长。

**更新（2021-04-13）**：Alex Takitani [建议](https://twitter.com/alex_takitani/status/1381706025875730435?s=20)了一种更加优雅的解决方案：使用 layout 来更新 flash 内容。我们可以如下面这样把 application layout 定义为 Turbo Stream 响应：

```erb
<!-- layouts/application.turbo_stream.erb -->
<%= turbo_stream.replace "flash-alerts" do %>
  <%= render "shared/alerts" %>
<% end %>

<%= yield %>
```

然后，我们需要从 controller 移除相应的渲染（因为要不然 [layout 就不会被用上了](https://github.com/hotwired/turbo-rails/issues/25)）：

```diff
def update
     item.update!(item_params)

     flash.now[:notice] = "Item has been updated"
-
-    render partial: "item_update", locals: { item }, content_type: "text/vnd.turbo-stream.html"
   end
```

**注意：**别忘了把*`format: :turbo_stream`*添加到 controller/request specs 测试相应的请求上，以便使得 render 能正常工作。

并且把我们的`_item_update` partial 转换为`update`的 Turbo Stream 模板：

```erb
<!-- update.turbo_stream.erb -->
<%= turbo_stream.replace dom_id(item) do %>
  <%= render item %>
<% end %>
```

很酷，对吧？这正是 Rails 的方式！

现在，让我们转到一些实时的流广播上。

Turbo Streams 经常在实时更新的语境中被提到（且常常被用来跟 [StimulusReflex](https://stimulusreflex.com/) 比较）。

来看看我们能够如何在 Turbo Streams 之上构建列表的同步化：

![turbo_streams.av1-17e20a6](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/turbo_streams.av1-17e20a6.gif)

在有 Turbo 之前，我不得不添加一个自定义的 Action Cable channel 和一个 Stimulus controller 来处理广播的事情。我也需要处理消息的格式，因为必须区分对条目的删除和完成。换句话说，有不少代码要维护。

而 Turbo Streams 已经照顾好了几乎一切：`turbo-rails` gem 自带一个通用的`Turbo::StreamChannel`和一个 helper（`#turbo_stream_from`），用来从 HTML 中创建一个 subscription：

```erb
<!-- worspaces/show.html.erb -->
<div>
  <%= turbo_stream_from workspace %>
  <!-- ... -->
</div>
```

在 controller 中，我们已经有了`#broadcast_new_item`和`#broadcast_changes`这样的“after action” callback 负责对更新进行播发。现在我们所有需要做的就是切换到`Turbo::StreamChannel`：

```diff
def broadcast_changes
   return if item.errors.any?
   if item.destroyed?
-    ListChannel.broadcast_to list, type: "deleted", id: item.id
+    Turbo::StreamsChannel.broadcast_remove_to workspace, target: item
   else
-    ListChannel.broadcast_to list, type: "updated", id: item.id, desc: item.desc, completed: item.completed
+    Turbo::StreamsChannel.broadcast_replace_to workspace, target: item, partial: "items/item", locals: { item }
   end
 end
```

这次迁移很顺畅，几乎——因为所有检验播发（`#have_broadcasted_to`）的 controller 单元测试都失败了。

不幸的是，Turbo Rails 没有提供任何测试工具（?），所以我不得不自己写一个，以[自己熟悉的方式](https://github.com/rails/rails/pull/33659)：

```ruby
module Turbo::HaveBroadcastedToTurboMatcher
  include Turbo::Streams::StreamName

  def have_broadcasted_turbo_stream_to(*streamables, action:, target:) # rubocop:disable Naming/PredicateName
    target = target.respond_to?(:to_key) ? ActionView::RecordIdentifier.dom_id(target) : target
    have_broadcasted_to(stream_name_from(streamables))
      .with(a_string_matching(%(turbo-stream action="#{action}" target="#{target}")))
  end
end

RSpec.configure do |config|
  config.include Turbo::HaveBroadcastedToTurboMatcher
end
```

下面是我如何把这个新的匹配器用在测试上：

```diff
it "broadcasts a deleted message" do
-  expect { subject }.to have_broadcasted_to(ListChannel.broadcasting_for(list))
-    .with(type: "deleted", id: item.id)
+  expect { subject }.to have_broadcasted_turbo_stream_to(
+    workspace, action: :remove, target: item
+  )
 end
```

到目前为止，使用 Turbo 的实时处理进展顺利！一大堆代码都被移除了。

**而我们仍然还是一行 JavaScript 代码都没有写。这也太不真实了吧？**

不过是个幻梦吗？何时我会醒来？好吧，就是现在。

## Beyond Turbo, or using Stimulus and custom elements

在向 Turbo 迁移的过程中，我碰到了好几个场景，使用已有的 API 是不够的，所以我最终不得不编写一些 JavaScript 代码！

场景一：向 dashboard 实时添加新的列表。这跟前面提到的列表中条目的示例有何不同？在于标记。来看一下 dashboard layout：

```html
<div id="workspace_1">
  <div id="list_1">...</div>
  <div id="list_2">...</div>
  <div id="new_list">
    <form>...</form>
  </div>
</div>
```

最后一个元素总是新列表的 form 容器。不管我们何时添加新列表，它都会被插入到`#new_list`节点之前。还记得 Turbo Streams 仅仅支持五种 actions 不？明白问题所在了吗？下面是我起初使用的代码：

```js
handleUpdate(data) {
  this.formTarget.insertAdjacentHTML("beforebegin", data.html);
}
```

要使用 Turbo Streams 实现类似的行为，我们需要添加一个 hack，在列表被通过 stream 添加之后立即把其移动到正确的位置。所以，来添加我们自己的 JavaScript 代码吧。

首先来给我们的任务一个正式的定义：“当一个新列表被 append 到 workspace 容器时，它应该出现在那个 new form 元素之前的正确位置上。”。这里的“当”意味着我们需要观察 DOM 并对变更作出反应。是不是听起来很熟悉？没错，我们已经提到过与 Stimulus 有关的 MutationObserver API！用它就对了。

幸运的是，我们不是必须编写高阶的 JavaScript 才能使用该特性；我们可以使用 [stimulus-use](https://github.com/stimulus-use/stimulus-use)（抱歉使用这种重言式语法。【译者注：原文是 use stimulus-use，所以作者这么说】）。Stimulus Use 是一个 Stimulus controllers 很有用的行为的集合，以简单的代码片段解决复杂的问题。我们这儿，需要 [useMutation](https://github.com/stimulus-use/stimulus-use/blob/master/docs/use-mutation.md) 行为。

如下的 controller 代码相当简洁，含义不言自明：

```js
import { Controller } from "stimulus";
import { useMutation } from "stimulus-use";

export default class extends Controller {
  static targets = ["lists", "newForm"];

  connect() {
    [this.observeLists, this.unobserveLists] = useMutation(this, {
      element: this.listsTarget,
      childList: true,
    });
  }

  mutate(entries) {
    // There should be only one entry in case of adding a new list via streams
    const entry = entries[0];

    if (!entry.addedNodes.length) return;

    // Disable observer while we modify the childList
    this.unobserveLists();
    // Move newForm to the end of the childList
    this.listsTarget.append(this.newFormTarget);
    this.observeLists();
  }
}
```

问题就这样解决了。

来讨论下第二个边界场景：实现聊天室功能。

我们有一个非常简单的聊天室附在每个 dashboard 上：用户可以发送临时消息（不会被存储到任何地方）和实时接收它们。消息具有依赖于上下文的不同外观：自己的消息有绿色边框，靠左；其他消息则是灰色，靠右。而我们是向每个所连接的客户端播发相同的 HTML。要如何使得用户看到这种区别呢？这对于聊天室类的应用是一个很常见的问题，且一般而言，它通过要么向每个用户 channel 发送个性化的 HTML，要么增强所收到的 HTML 在客户端来解决。我更喜欢第二种，所以来实现它吧。

要把当前用户的信息传递给 JavaScript，我使用 meta tags：

```erb
<!-- layouts/application.html.erb -->
<head>
  <% if logged_in? %>
    <meta name="current-user-name" content="<%= current_user.name %>" data-turbo-track="reload">
    <meta name="current-user-id" content="<%= current_user.id %>" data-turbo-track="reload">
  <% end %>
  <!-- ... -->
</head>
```

和一个小的 JS helper 来获取这些 values：

```js
let user;

export const currentUser = () => {
  if (user) return user;

  const id = getMeta("id");
  const name = getMeta("name");

  user = { id, name };
  return user;
};

function getMeta(name) {
  const element = document.head.querySelector(
    `meta[name='current-user-${name}']`
  );
  if (element) {
    return element.getAttribute("content");
  }
}
```

要播发聊天室消息，我们将会使用`Turbo::StreamChannel`：

```ruby
def create
  Turbo::StreamsChannel.broadcast_append_to(
    workspace,
    target: ActionView::RecordIdentifier.dom_id(workspace, :chat_messages),
    partial: "chats/message",
    locals: { message: params[:message], name: current_user.name, user_id: current_user.id }
  )
  # ...
end
```

下面是初始的`chat/message`模板：

```erb
<div class="chat--msg">
  <%= message %>
  <span data-role="author" class="chat--msg--author"><%= name %></span>
</div>
```

以及前述根据当前用户赋予不同样式的 JS 代码，这些代码我们很快就要去掉：

```js
// Don't get attached to it
appendMessage(html, mine) {
  this.messagesTarget.insertAdjacentHTML("beforeend", html);
  const el = this.messagesTarget.lastElementChild;
  el.classList.add(mine ? "mine" : "theirs");

  if (mine) {
    const authorElement = el.querySelector('[data-role="author"]');
    if (authorElement) authorElement.innerText = "You";
  }
}
```

现在，当 Turbo 负责更新 HTML 时，我们需要做点不同的事。当然，`useMutaion`也会在这里被用到。并且这有可能是我将用在*现实*项目上的。然而，我今天的目标是演示以不同的方式来解决问题。

还记得我们一直在谈论 Custom Elements（哦，那是好几页之前了，抱歉，这说明我们阅读太久了）？它正是令 Turbo 之所以强大的 Web API。我们干嘛不用呢！

让我先分享一个*更新后的* HTML 模板：

```erb
<any-chat-message class="chat--msg" data-author-id="<%= user_id %>>
  <%= message %>
  <span data-role="author" class="chat--msg--author"><%= name %></span>
</any-chat-message>
```

我们只添加了`data-author-id`属性，并把`<div>`替换为自定义 tag ——`<any-chat-message>`。

现在来对 custom element 进行注册：

```js
import { currentUser } from "../utils/current_user";

// This is how you create custom HTML elements with a modern API
export class ChatMessageElement extends HTMLElement {
  connectedCallback() {
    const mine = currentUser().id == this.dataset.authorId;

    this.classList.add(mine ? "mine" : "theirs");

    const authorElement = this.querySelector('[data-role="author"]');

    if (authorElement && mine) authorElement.innerText = "You";
  }
}

customElements.define("any-chat-message", ChatMessageElement);
```

大功告成！现在当一个新的`<any-chat-message>`元素被添加到页面时，如果它来自于当前用户就自动更新自己。而且甚至我们为此都不再需要 Stimulus 了！

你可以在[这个 PR](https://github.com/anycable/anycable_rails_demo/pull/16) 中找到本文有关的全部源代码。

所以，那么零 JavaScript 的 Reactive Rails 到底存在吗？并不。我们移除了很多 JS 代码，但最后不得不用一些新东西来替代。这些新东西跟之前的有所区别：它更加，我得说，***实用主义***。它也更加高阶，需要对 JavaScript 以及最新浏览器 APIs 有很好的了解，这肯定是要权衡考虑的。

附：我对 CableReady 和 StimulusReflex 也有一个[类似的 PR](https://github.com/anycable/anycable_rails_demo/pull/12)。你可以把它跟 Hotwire 的这个 PR 进行比较，在 [Twitter](https://twitter.com/evilmartians) 上与我们分享你的观点。


