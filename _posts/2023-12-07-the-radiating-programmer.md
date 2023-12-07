---
layout: post
title: 辐射式开发者
author: xfyuan
categories: [Translation, Programming, Life]
tags: [life, 37signals]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_2023120702.jpg"
rating: 4
---

_本文已获得原作者（**Jorge Manrubia**）和 [37signals](https://37signals.com/) 授权许可进行翻译。原文分享了在 37signals 内部开发者之间的一种高效工作沟通决策的模式，很有启发。遂以记之_

- 原文链接：[The radiating programmer](https://dev.37signals.com/the-radiating-programmer)
- 作者：Jorge Manrubia（[Github](https://github.com/jorgemanrubia)、[Twitter](https://twitter.com/jorgemanru/)），居住于西班牙瓦伦西亚，目前工作于 37signals，诸多 Ruby、Rails 的 Gem/Library 的作者，比如：[Active Record Encryption](https://github.com/rails/rails/pull/41659)（已被纳入 Rails 7 成为默认特性）、[mass_encryption](https://github.com/basecamp/mass_encryption)、[console1984](https://github.com/basecamp/console1984)、[audits1984](https://github.com/basecamp/audits1984)、[ib_ruby_proxy](https://github.com/jorgemanrubia/ib_ruby_proxy)、[impersonator](https://github.com/jorgemanrubia/impersonator)、[turbolinks_render](https://github.com/jorgemanrubia/turbolinks_render) 等
- 站点：37signals 以创建了 [Basecamp](https://basecamp.com/) 和 [HEY](https://www.hey.com/) 而举世闻名，也撰写了很多商业和软件相关的书籍（[Getting Real](https://www.amazon.com/Getting-Real-Smarter-Successful-Application/dp/0578012812), [REWORK](https://bookshop.org/books/rework-9780307463746/9780307463746), [REMOTE](https://bookshop.org/books/remote-office-not-required/9780804137508), [It Doesn’t Have to Be Crazy at Work](https://bookshop.org/books/it-doesn-t-have-to-be-crazy-at-work/9780062874788), 以及 [Shape Up](https://basecamp.com/shapeup)），更创造了著名的 [Ruby on Rails](https://rubyonrails.org/) 框架。

_【正文如下】_

## 引言

正确的仪式可以把你从错误的仪式中拯救出来。

**【译者提醒：下文里“辐射信息”这个词中的“辐射”都应当做动词来看待。】**

## 正文

你本质上是一位个人贡献者。你喜欢编写代码和解决技术问题。你不喜欢会议和仪式。你可以做些什么来尽量最大化你喜欢的东西，减少你不喜欢的东西？***辐射信息***。

Scrum 推广的每日站会有负面新闻是有原因的。每天这种周期性太频繁了。使用回顾会议让人们有机会赶上进度是破坏性的，而且效率低下。【译者注：“每日站会、回顾会议”都是 Scrum 这种敏捷开发模式的专门术语，顾名思义】。

但问题本身是有道理的：你过去做了什么？你打算接下来做什么？有什么阻碍性的问题吗？您应该定期传达这些信息，而不是在会议上。

在构建软件时，每个参与其中的人都必须在了解问题时调整他们的工作。而这种学习在很大程度上是通过从事这项工作的人来实现的。如果他们只提供自己的输出，其他人需要从中吸取经验来做出调整。这时，不好的仪式——侵入性的、破坏性的、极其糟糕的——就会渗入这个过程。

相比之下，*辐射信息*的做法就会大放异彩：你不是让别人从你那里获取信息，而是把信息推送给每个人。它可能看起来很微妙，但有一个显着的区别：控制权仍然在你这边，而不是其他人。

有人可能会争辩说，每当你交流时，你都会散发出信息。但我在这里谈论的是更有意味的东西。在我的日常工作中，我发现有三个反复出现的场景：

- 定期沟通你的工作。
- 沟通项目进度。
- 在做决定时，给别人一个干预而不会被阻止的机会。

接下来，我将展示我们自己 [Basecamp](https://basecamp.com/) 的例子。其基本思想与任何工具无关，但如果你熟悉  [37signals 的沟通哲学](https://37signals.com/how-we-communicate/)，对 Basecamp 为其提供一流的支持也就不足为奇了。

## What have you worked on (你做了什么)?

这是核心问题。我们使用 [check-in](https://basecamp.com/features/automatic-check-ins) 以便每个人都可以每周至少回答两次“你做了什么？”。[我前段时间写过这个问题](https://world.hey.com/jorge/what-did-you-work-on-today-b153fba3)。你可以随时以自己喜欢的风格和详细程度，异步回答这些问题，而公司中的每个人都可以阅读其他人的回答。

这是我写的最近一个：

![](https://dev.37signals.com/assets/images/the-radiating-programmer/what-have-you-worked-on.webp)

> **回答“你做了什么？**
>
> 这是 Basecamp 4 的屏幕截图，显示了以下内容。请注意，这些链接已被删除。文中突出显示了三个部分，稍后将在文章中引用。
>
> 最后两个：
>
> **Turbo 8**
>
> On Thursday, when I was doing the last testing round of Turbo 8 with HEY before shipping it, I found an issue I hadn’t noticed before: when paginating new periods and creating events in those, the page wasn’t refreshing fine. There were two issues there.
> 周四，当我在发布前使用 HEY 对 Turbo 8 进行最后一轮测试时，发现了一个以前没有注意到的问题：在对新周期进行分页并在其中创建事件时，页面无法刷新。那里有两个问题。
>
>
>
> One was easy to spot: we were deleting the pagination frames. Using data-turbo-permanent with those created other issues in the Day screen, so this wasn’t easy to solve.
> 一个很容易发现：我们在删除分页帧时，将 data-turbo-permanent 与那些在 Day 屏幕中产生的其他问题一起使用，因此这并不容易解决。
>
>
>
> That was the nth reason to recover the original idea of flagging such frames with an attribute, so after talking to Alberto, we recovered that here (this was actually part of the API that we originally presented in Rails World, but at some point we thought we could simplify things further).
> 这是恢复使用属性标记此类帧的原始想法的第 n 个原因，因此在与 Alberto 交谈后，我们在这里恢复了它（这实际上是我们最初在 Rails World 中提供的 API 的一部分，但在某些时候我们认为我们可以进一步简化事情）。
>
>
>
> **Section 1:** But the second problem took me most of my Thursday to troubleshoot: idiomorph was failing to match the paginated turbo-frames properly. It took me a long debugging session within idiomorph to understand what was going on there, as the error didn’t make sense at all.
> 第 1 部分：但第二个问题花了我周四的大部分时间进行故障排除：idiomorph 无法正确匹配分页的 turbo-frames。我在 idiomorph 中花了很长时间的调试会话来了解那里发生了什么，因为错误根本没有意义。
>
>
>
> There were two issues there: one, idiomorph creates a map of nodes and children ids first; this wasn’t playing well with a pagination trick we were doing with JS, where we were moving a turbo frame outside of its container.
> 这里有两个问题：第一，idiomorph 首先创建节点和子 ID 的映射；这与我们在 JS 上所做的分页技巧并不相符，我们在 JS 中将 turbo frame 移出了其容器。
>
>
>
> And second, we had some duplicated “ids” inside our markup that was confusing idiomorph’s heuristics, which are also based on that map.
> 其次，我们在标记中有一些重复的“id”，这混淆了 idiomorph 的启发式方法，这些启发式方法也基于该映射。
>
>
>
> I fixed the problem by reworking the pagination approach. I am happy with the change as the new system is simpler than the previous one. With that, I could finally wrap up the pull request and ship 🥳.
> 我通过重新设计分页方法解决了这个问题。我对这个变化感到满意，因为新系统比以前的系统更简单。有了这个，我终于可以结束拉取请求并发布🥳.
>
>
>
> Also, discussion about an issue that Jay found: we shouldn’t use morphing in regular page visits. Until we fix for good, I enabled morphing only for the two main views, to prevent the issue from happening with the mobile app.
> 此外，关于Jay发现的一个问题的讨论：我们不应该在常规页面访问中使用变形。在我们永久修复之前，我只为两个主要视图启用了变形，以防止移动应用程序发生问题。
>
>
>
> **Mobile API 移动 API**
>
> - **Section 2:** Addressed feedback in the PR and shipped support for repeating events. Thanks to a question by Jeffrey I found a tricky issue with database precision and URL serialization I fixed here.
>   第 2 部分：解决了 PR 中的反馈，并提供了对重复事件的支持。多亏了 Jeffrey 的一个问题，我发现了一个棘手的问题，即我在这里修复了数据库精度和 URL 序列化。
> - Chat about including modified records in responses. I should complete the short list of requests we need to support this Monday.
>   讨论在响应中包含修改后的记录。我应该完成本周一我们需要支持的请求的简短清单。
>
> **Other 其他**
>
> - Weighted in on:
>   - Control to jump to specific days.
>     控制跳转到特定日期。
>   - **Section 3:** Will you still be able to move calendars between accounts after creation? We’re not supporting that for launch 🪓.
>     第 3 部分：创建后，您仍然可以在帐户之间移动日历吗？我们不支持发布🪓。
> - Some chatting about bugs and organizing those. Next week I’ll dedicate a good amount of time to clear some serious bugs we have.
>   一些人谈论错误并组织这些错误。下周，我将花大量时间来清除我们遇到的一些严重错误。
> - Some thinking about next projects for the web team. Alberto has already started with support for multiple home accounts, and control to jump to specific days will be next.
>   一些人正在考虑 Web 团队的下一个项目。阿尔贝托已经开始支持多个家庭帐户，接下来将控制跳转到特定日期。
> - PR reviews:
>   - For Matt who built a nice foundation for supporting the rich iCal invitations workflow and integrate it with HEY.
>     对于 Matt，他为支持丰富的 iCal 邀请工作流程奠定了良好的基础，并将其与 HEY 集成。
>   - For Alberto: one, two
>     阿尔贝托：一，二
> - Wrote some hill chart updates for the projects I worked on this week:
>   为我本周从事的项目写了一些山图更新：
>   - Mobile API 移动 API
>   - Open source: Upstream turbo-morph
>     开源：上游 turbo-morph
>   - Performance 性能

我重点介绍了三个部分，以说明其他人如何从我分享的信息中受益：

1. 一个意想不到的问题影响了我本周可以完成的工作。
2. 我学到的东西，其他程序员可能会觉得有用。
3. 一些领域锤击【37signals 专门术语：[scope hammering](https://basecamp.com/shapeup/3.5-chapter-14#scope-hammering)】，对于进行产品调用的人来说可能会很有趣。

## Communicating progress on projects (沟通项目进度)

工具可以提供帮助，但除非另一个人（最好是做这项工作的人）提供帮助，否则很难从高层次上了解项目的进展情况。不，我不认为人工智能会很快改变这一点。

我们在 Basecamp 中显示进度的首选方式是通过[山峰图](https://basecamp.com/features/hill-charts)更新。它们将高级完成量表与文本描述相结合。这是我写的最近一篇：

![](https://dev.37signals.com/assets/images/the-radiating-programmer/hill-chart.webp)

> **“山峰图更新”的答案**
>
> 来自 Basecamp 4 Hill Chart 更新的屏幕截图，包含以下内容，并突出显示了 3 个部分：
>
> **Section 1:** This week Alberto cleared all the remaining issues with the Card Table, and Jorge all the remaining ones in HEY. Both translated into tweaks to the upstreamed library.
> 第 1 部分：本周 Alberto 清除了 Card Table 的所有剩余问题，而 Jorge 则清除了 HEY 中所有剩余的问题。两者都转化为对上游库的调整。
>
>
>
> HEY is now using Turbo 8 in production, and the Calendar, finally, is using the upstreamed version with idiomorph.
> HEY 现在在生产环境中使用 Turbo 8，而 Calendar 最后使用带有 idiomorph 的上游版本。
>
>
>
> **Section 2:** Today we recovered a setting we had nixed: the one to flag turbo-frames that you want to reload during page refreshes. At the end, removing the option created a ton of frictions in different scenarios.
> 第 2 部分：今天我们恢复了之前取消的设置：用于标记要在页面刷新期间重新加载的 turbo-frames 的设置。最后，删除该选项在不同情况下会产生大量冲突。
>
>
>
> **Section 3:** To launch Turbo 8 we still need to document the library, and also to solve this problem that Jay detected: we should not be using morphing during regular page navigations.
> 第 3 节：要加载 Turbo 8，我们仍然需要记录库，并解决 Jay 检测到的这个问题：我们不应该在常规页面导航中使用变形。
>
>
>
> We also need to complete some changes to the adapters that Jay and Alberto already cooked (that aren’t strictly beneficial to morphing, but without which morphing doesn’t make much sense in mobile apps).
> 我们还需要对 Jay 和 Alberto 已经做好的适配器进行一些更改（严格来说，这些更改对变形没有好处，但如果没有这些更改，变形在移动应用程序中就没有多大意义）。
>
>
>
> So not much to do to think of a release here. We should probably release a beta first.
> 因此，在这里考虑发布内容没什么可做的。我们可能应该先发布一个测试版。
>
>
>
> **Section 4:** And the good news is that this is totally decoupled from the calendar launch now.
> 第 4 节：好消息是，这与现在的 Calendar 发布完全脱钩。

同样，公司中的不同人员可以从更新中获得不同的东西：

1. 自上次更新以来的进度。
2. 导致恢复我们之前删除的某些 API 的问题。
3. 我们发现了一些意味着额外工作的东西。
4. 这对 Calendar 的发布有何影响？

## Non-blocking decisions 非阻塞决策

我已经写过关于[远程工作时应该如何避免阻塞自己的文章](https://world.hey.com/jorge/don-t-block-yourself-a-remote-worker-super-power-7322c679)。当你需要他人的意见来做出决定时，通常可以在告知的同时自己做出决定。其他人可以根据需要进行干预，而如果他们不干预的话，你可以继续前进。

这儿有一个上周的例子。我有一个关于移动端 API 的问题，想与团队核实。我根据自己的最佳判断来了次沟通，把他们拉了进来。

而后我很高兴根据讨论的答案改变方案，但我并没有让自己处于自我封闭的境地来等待它。

![](https://dev.37signals.com/assets/images/the-radiating-programmer/non-blocking-decisions.webp)

> **在不妨碍自己的情况下进行协作**
>
> 豪尔赫在 Basecamp 4 中的评论：
>
> > Hey folks,
> >
> > For the API responses, I’m seeing that, in general in HEY and BC4, we rely on response codes (e.g: 201 for created, 204 for updated/deleted). We don’t render the response body.
> > 对于 API 响应，我看到，通常在 HEY 和 BC4 中，我们依赖于响应代码（例如：201 表示创建，204 表示更新/删除）。我们不呈现响应正文。
> >
> >
> >
> > For the Calendar API, I’m thinking that it might be interesting to return the created/updated resource in the JSON body? For example: if you create an event, you need to grab the id for the future. I’m going with that if you don’t tell me otherwise.
> > 对于日历 API，我认为在 JSON 正文中返回创建/更新的资源可能会很有趣？例如：如果你创建一个事件，你需要为将来获取 ID。如果你们不回答的话，我就会这样做了。
>
> A reply from Milan:
> 来自米兰的回复：
>
> > Hey Jorge 👋
> >
> > Generally, I don’t think we’ll need the newly created/updated resources in the responses right now because we’ll just hit the incremental sync endpoint to get the fresh data right after.
> > 通常，我认为我们现在不需要响应中新创建/更新的资源，因为我们只需点击增量同步终结点即可立即获取新数据。
> >
> >
> >
> > On the other hand, there will probably be situations where we’ll want to reference the newly created object — as you mentioned, at least know what ID it received from the backend.
> > 另一方面，在某些情况下，我们可能想要引用新创建的对象——正如您提到的，至少知道它从后端接收了什么 ID。
> >
> >
> >
> > So I don’t think there’s any harm in sending the resources back in responses even if we don’t use them right now.
> > 因此，我认为即使我们现在不使用资源，在响应中发送资源也没有任何害处。

## Conclusion 结论

信息辐射表面上看起来像是一种官僚主义的做法，但实际上它是一种保护措施。想想我引用例子的替代方案：

- 参加会议，看看加载 Turbo 8 还剩下什么。
- 与移动团队中的某个人聊天，以同步方式讨论 API 响应格式。
- 与 Manager 进行 1-1 沟通，了解我们在 Turbo 中发现的内容如何影响日历的发布。
- 与设计师快速通话，以决定是否实现我们决定 nix 的功能。

夸张吗？这正是很多地方的工作方式。如果你需要开会，确保它不是你本可以通过辐射信息来避免的。想想看，*这次会议本来可以是一封电子邮件*，且是通过设计让电子邮件主动流动的过程。

**作为一名开发者，你可以通过总结你的工作来增加很多价值。你可以分享经验、教训、挣扎、意想不到的转折、动机，以及更广泛地说，事情是如何向前发展的。任何工具或自动报告都无法做到这一点。**

许多人可以从中受益；而你可以帮助别人也接受帮助。你喜欢根据现实的样子做出决策，这是任何不可预测的工作（如软件开发）的基本特征。

最终，它使你所做的事情变得清晰，从而抵消了你花时间写代码的内在不透明性。

辐射信息不是免费的，这需要时间。你需要找到一个有意义的平衡点。我估计自己每周花一两个小时写我所做的事情或项目更新。我通常会把它留到一天的最后一部分。

它不会打断我的主要工作，也不会每天都发生。这就像一块需要训练的肌肉。你做的越多，它就越容易。

每当感觉像是件苦差事时，我就会提醒自己：这确实是苦差事，但它让我把大部分时间都花在了做自己喜欢的事情上。
