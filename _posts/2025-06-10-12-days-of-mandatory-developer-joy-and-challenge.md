---
layout: post
title: Rails开发者的黄道十二宫
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, rspec, vite, frontend, evil martians]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20250610.jpg"
rating: 4
---

_本文已获得原作者（**Svyatoslav Kryukov**、**Artur Petrov**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了圣诞节 Rails 开发者为期 12 天的挑战及欢乐。内容非常长，这个漫长的 12 天就像星矢挑战黄道十二宫那样充满艰难险阻，也正因如此，最终达到的目标才那样物有所值——让你的 Rails 应用程序如宝石般光芒璀璨！_

- 原文链接：[Railsmas on Mars: 12 Days of Mandatory Developer Joy and Challenge](https://evilmartians.com/chronicles/railsmas-on-mars-12-days-of-mandatory-developer-joy-and-challenge)
- 作者：**Svyatoslav Kryukov**、**Artur Petrov**、**Travis Turner**
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发者博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

_【正文如下】_

## 引言

随着假期的临近，是时候给自己（和你的团队）一份更快乐的开发体验了！因此，在 12 天的时间里，我们将展示 12 种小而强大的方法，旨在提升你的 Rails 应用水平。我们将先进行讨论，然后给出动手实践的建议。

这些小任务要求每天在一个小时内完成。如果我们要说服圣诞老人从 “Sleighs” 切换到 Rails，就得快点——他可是个大忙人！

- Day 1: a renewing, anti-aging treatment
- Day 2: faster rails boot time
- Day 3: better yourself and better your environment
- Day 4: flaky flakes
- Day 5: the nutcracker suite of system testing
- Day 6: a test suite so fast, Santa’s elves are jealous
- Day 7: better database migrations
- Day 8: silent night, secure night
- Day 9: Dashing through the …queries
- Day 10: deck the docs with lines of clarity
- Day 11: Jemlocking around the Christmas tree
- Day 12: Silent night, stable night

## Day 1: a renewing, anti-aging treatment

**[libyear](https://libyear.com/)** 是显示应用程序 “新鲜度” 的简单指标。换句话说，它向你展示了你的依赖项在几年内已经过时多久了。

让我们为你当前的一个应用程序生成一个 libyear 报告：

```bash
# Install libyear
$ gem install libyear-bundler

# Generate libyear report
$ libyear-bundler
         aasm          5.2.0     2021-05-02          5.5.0     2023-02-05       1.8
  actioncable        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
actionmailbox        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
 actionmailer        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
   actionpack        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
   actiontext        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
   actionview        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
    activejob        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
  activemodel        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
 activerecord        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
activestorage        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
activesupport        7.0.8.5     2024-10-15          8.0.0     2024-11-07       0.1
 acts_as_list          1.1.0     2023-01-31          1.2.4     2024-11-19       1.8
...
System is 663.4 libyears behind
```

> 嘘...你的 JavaScript 和 Python 朋友也应该得到依赖项跟踪的礼物：[libyear](https://libyear.com/) 已经满足了他们！

好吧，我们落后了 663.4 lib 年 – 这还不错！实际上，对于较大的应用程序，达到世纪大关非常容易。但不要惊慌：这里没有什么是过时的......那只是“复古”！

（是的，“复古”就像那瓶令人作呕的过期蛋奶酒。但是，嘿，蛋奶酒总是充满节日色彩的，这篇文章有一个节日主题，所以请记住这一点！🎄)

无论如何， **乍一看，“libyears” 似乎是一个新奇的指标，而不是一个有用的指标，但它实际上非常适合比较不同的子项目和确定升级的优先级** 。

> 做出了升级 Rails **的坚定**决定？以下是一些有用的工具：使用 [RailsDiff](https://railsdiff.org/) 检查 Rails 默认配置，使用 [RailsBump](https://www.railsbump.org/) 检查你的依赖项。

此外，定期运行这个 gem 可以鼓励开发人员更新那些小的、被遗忘的 gem（或寻找现代的替代方案），而不是只关注像 Rails 这样大而有趣的 gem。

此外，libyear 唤醒治疗的另一个好处是，新版本通常会免费提供错误修复和速度提升——只需要一点爱和关注！

### Don’t let libyears catch up with you

**今天的假期挑战是掸掉旧应用程序的灰尘，其中的 libyears 开始看起来更像光年。**

注意：在上面，“光年”的意图当然是用“非常古老”的氛围来表达，使用“光年”作为时间的度量，而不是一些读者会认为的距离。

其次，更相关的说明：一个常见的疏忽是那些带有自定义 GitHub 链接或固定版本的 gem 造成 bug。开发人员经常忘记在它们的补丁被应用后更新其上游版本。

错过开发人员提供的那些宝贵更新简直不要太容易！

那么，让我们更新其中的一些 gems！但是等等——不要只是贸然运行 bundle update ——对于假期来说，这太过分了！相反，让我们通过一次更新几个 gem 来保持快乐和光明。

> 对一些高级[虎胆龙威](https://en.wikipedia.org/wiki/Die_Hard)风格的节日活动想进行冒险？伟大！尝试在你的测试套件中运行[我们的 Gem 跟踪器代码段](https://github.com/evilmartians/terraforming-rails/tree/master/tools/gem_tracker)。找到未使用的 Gems 从未如此简单，整理你的 Gemfile。

但是，你如何决定更新什么呢？虽然像 libyear 这样的工具可以提供指导，但让我们从圣诞老人的袋子里拆开另一份礼物，添加到你的节日工具箱中：[bundle_update_interactive](https://github.com/mattbrictson/bundle_update_interactive)。

这个 gem 不仅使更新过程更具交互性和复杂性，还允许快速查看更改日志——只需点击一下！

在那些花哨、鲁莽的升级派对之后，不再有宿醉的遗憾（同样，大概是通过蛋酒这种最喜庆的饮料来促进的）。

**第 1 天节日的行动计划** ：

1. 生成 [libyear](https://github.com/jaredbeck/libyear-bundler) 指标并保存结果，然后再进行改进。
2. 检查具有固定版本或 GitHub 源的所有 Gem。
3. 运行 [bundle_update_interactive](https://github.com/mattbrictson/bundle_update_interactive) 并更新你的一些 Gem。
4. 对结果满意后，再次生成 libyear 指标，计算差异，并在 #railsmas 下分享你的成就！

很高兴看到用你的结果挑战 Rails 社区——让我们看看最新、最老或最有活力的应用各是谁的！

## Day 2: faster rails boot time

大多数人不敢承认假期中最糟糕的部分之一：**等待礼物** （最好的部分？礼物）。“我能得到什么？”这几乎是你一整年等待时所能想到的。

…但你知道那种更糟糕的等待吗？ **等待 Rails 应用程序加载** 。

所以，今天，我们将专注于加快启动时间！这是一份不断给予的礼物，无论是用于开发环境中的代码重新加载还是生产环境中的部署。

### Santa also does the whole “boot” thing

在深入研究细节之前，让我们试着更好地了解你的个人启动时间。现在就来看看你的申请吧。为此，请使用这个闪亮的新 CRuby 分析器：[Vernier](https://vernier.prof/)。

> 今年有点调皮？跳过更新并让你的应用程序卡在 Ruby < 3.2.1 上？好吧，不要噘嘴，亲爱的开发人员！🎅 在这种情况下，（尽管他在这个领域提供建议并不特别出名），圣诞老人建议尝试 [rbspy](https://rbspy.github.io/)。

首先，让我们安装 Vernier 并分析我们的启动过程：

```bash
# Install Vernier sampling profiler
$ gem install vernier

# Capture a profile of the application's full boot process.
$ DISABLE_SPRING=1 vernier run -- bundle exec rails runner 'puts "Railsmas is here!"'

Railsmas is here!
#<Vernier::Result 2.821947994 seconds, 7 threads, 3943 samples, 3103 unique>
written to /tmp/profile20241126-134618-4btew9.vernier.json.gz
```

每个应用程序都是独一无二的（哦，比方说）雪花，根据启动过程的持续时间，你将获得非常清晰或非常混乱的图表。

不要忘记生成第二个报表，并在内部 `config/environments/development.rb` 启用了 eager loading，因为它提供了更多数据，可以得出有价值的见解：

```ruby
config.eager_load = true
```

现在在 [Vernier UI](https://vernier.prof/) 中打开生成的配置文件：

![](https://evilmartians.com/static/0c6c01f353ec21aa860b8007acc5982d/9362f/vernier.webp)

使用调用树时，请始终记下每个子树在引导期间花费的报告百分比。

注意：先深入研究占比最大的部分会更有效。请注意在加载期间花费最高百分比的 boot runtime 里较大的初始化器 span。

应该永远记住，在加载过程中，我们运行的是所有初始化和类级代码。一些示例：读取巨大的 JSON 文件，预加载所有时区信息，尝试在预加载所有翻译的类级别上使用 i18n，等等。

广泛的 DSL 也经常是常见的罪魁祸首：Active Admin、Grape、GraphQL、RSwag 以及许多其他问题。我们可能会尝试在生产环境中将应用程序的这些大部分加载到单独的实例中，或者在我们不处理这些部分时在本地跳过它们。

> 对于像我们这样喜欢宝石狩猎的精灵来说，[Bumbler](https://github.com/nevir/Bumbler) 可能是更好的雪橇之旅——它让事情变得美好而简单。

外部依赖项也可能包含所有这些问题，因此这里的关键是审核你的 Gemfile。你真的需要所有这些 gem 吗？ **未使用的 Gem 会增加不必要的启动时间并增加复杂性**。精简内容，为你的应用程序提供简单的礼物！

你还可以将一些 Gem 移动到单独的组中，以便有条件地加载它们。

### Santa’s gift

现在的主要行为，圣诞老人，一个拥有神秘而难以辨认的力量的神奇生物，带来了节日利他主义的象征：Devise 配置的一行更改可以显著缩短你的启动时间。

默认情况下，Devise 会强制重新加载所有应用程序路由，从而有效地加载它们两次。但是，我们可以轻松地在 `config/initializers/devise.rb` 中禁用此默认行为：

```ruby
# When false, Devise will not attempt to reload routes on eager load.
# This can reduce the time taken to boot the app but if your application
# requires the Devise mappings to be loaded during boot time the application
# won't boot properly.
config.reload_routes = false
```

当然，此更改的影响与应用程序中的路由数量成正比，但它应该会显著改善加载时间。

> 听说过 Rails 核心团队的节日礼物吗？Rails 8 于 2024 年 11 月 7 日发布，现在为新应用提供全局懒加载路由！

**第 2 天节日的行动计划** ：

**安装 [Vernier](https://vernier.prof/) 或 [rbspy](https://rbspy.github.io/)** （Ruby < 3.2.1） 并为你的应用程序创建两个配置文件：一个启用了预加载;一个没有预加载。

**在 [Vernier UI](https://vernier.prof/) 中分析生成的配置文件**：

- 探索调用树以获取最耗时的子树和方法。
- 密切注意每个子树在引导期间花费的报表百分比。

**找到违规者并对其进行优化**：

- 考虑将应用程序的大部分移动到生产中的单独实例中，或者在本地跳过它们。
- 从 Gemfile 中删除未使用的 Gem。
- 将一些 Gem 移动到单独的组中，以便有条件地加载它们。
- 禁用 Devise 的路由重新加载（如果适用的话）。

通过在进行更改后测试你的应用程序并在 #railsmas 下分享你的第 2 天见解， **确保应用程序加载保持正常运行**！

## Day 3: better yourself and better your environment

新的一年，新的氛围！昨天，我们给应用程序带来了一些能量提升，所以今天，让我们专注于改进我们的开发设置！突然间，DHHanish Santa [建议](https://world.hey.com/dhh/imperfections-create-connections-bc87d630)我们应该迁移到一个全新的 Linux 认可的笔记本 — 这很诱人，但我们现在还不去那里。

今天，我们很高兴地揭开了一份特殊的礼物，它实际上是由 Shopify 在两年前准备的。请放心，这颗翻新的宝石确实是宝藏 - [Ruby LSP](https://shopify.github.io/ruby-lsp)！

**是什么让它如此特别** ？毕竟，我们多年来一直拥有像 RubyMine 和 Solargraph 这样的工具，谁还需要 Ruby 的其他语言服务器协议 （LSP） 实现呢？

答案在于一个非常强大的功能：[ 用 Ruby 编写的插件系统 ](https://shopify.github.io/ruby-lsp/add-ons)。虽然 `ruby-lsp` 包括跳转到定义、内联文档和代码导航等高级主打功能，但插件系统更进一步，允许任何人轻松扩展其功能。

> 经验丰富的 IDE 用户可能会对内置功能不屑一顾，例如从 controller 跳转到其 view或从其 action 打开路由。但是一位作者（我们有没有提到他使用 Arch Linux？）对这种程度的便利性**感到震惊** ......并且可能需要到下一个假期才能恢复。

然而，真正的强大之处在于分发这些插件——你甚至不需要手动安装插件——当它们被放置在 `gem 的 ./lib/ruby_lsp/**/addon.rb` 中时，它们会自动加载（就像 Railties 一样）。这意味着 Ruby LSP 和你的 Gem 的每个用户都可以享受增强的编辑器体验，而无需任何额外的工作！

试想一下：所有约定优于配置的魔法都被揭开了——ActiveModelSerializer、CanCanCan、ActiveAdmin 背后的黑魔法变成了一群穿着奇怪服装的人。

记住，LSP API 提醒 RuboCop cops — 当然，多亏了 Ruby，创建插件变得简单明了。

你甚至可以开发一个自定义应用程序 LSP 插件，以便在除夕夜午夜之前突出显示应用程序的独特 DSL！

这里有一个小奇迹 — 我们[心爱的 Action Policy gem 的插件](https://gist.github.com/skryukov/35539d57b51f38235faaace2c1a2c1a1)先睹为快，为其 DSL 提供简单的跳转定义支持。现在我们可以毫不费力地从 controller 跳转到相关 policy 并返回：

<video class="MarkdownVideo-module--root--b01ad" height="982" width="900" muted="" autoplay="" loop="" playsinline="">
	<source type="video/mp4; codecs=avc1.4D401E,mp4a.40.2" src="https://evilmartians.com/static/7d34cdb61861a7f17c1067b75a409a72/ruby-lsp-plugin.av1.mp4">
</video>
哇哦，它奏效了！更好的是，如果我们将新代码贡献给上游 gem，这个插件将适用于每个 Ruby LSP 用户。

**第 3 天节日的行动计划** ：

- 在你选择的编辑器中设置 [Ruby LSP](https://shopify.github.io/ruby-lsp)。
- 探索开箱即用的新高级功能，包括所有标准但更强大的主打功能，例如，轻松导航到 Rails 的“convention over configuration”座右铭中的隐藏元素，等等。
- 考虑为你的应用程序（或心爱的 gem）的自定义 DSL 创建一个简单的插件，以帮助同事节省使用代码的时间。

顺便说一句，请在 #railsmas 下分享你的 Ruby LSP 想法 — 你的建议可能会启发其他人！毕竟，假期都是为了团聚。（当然，还有礼物。）

## Day 4: flaky flakes

每年，我们都会听到（并且绝对喜欢）同样疲惫的节日叮当声。我们简直爱不释手！

有些很吸引人，我们发现自己在脑海中循环浏览它们。我们需要一些东西来对抗这种重复性，就像我们今天的礼物一样：处理不稳定的测试，它迫使你一次又一次地重复运行测试套件。

我们都讨厌这种重复，就像任何邪恶的节日跳蚤一样。

首先，我们应该从适当的测试配置开始，以便尽早发现问题。检查你是否按随机顺序运行测试：

```ruby
RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed
end
```

> Minitest 用户？很棒！默认情况下你已经是如此了，但请检查在代码库中的某个地方没有 `my_tests_are_order_dependent！`（或者[其他奇怪的地方 ](https://docs.seattlerb.org/minitest/Minitest/Test.html)）。

这可以防止你依赖细微的全局状态清理序列（有时可以在应用程序的测试套件中找到）。如果你有一个没有此选项的中等测试套件，则预计会出现许多意外故障。 **拥抱节日的混乱，起初令人不快，后来就以礼物呈现。**

顺便说一句，全局状态泄漏有什么大惊小怪的呢？基本上，测试期间更改的任何内容，除了数据库交互（默认情况下使用[事务测试](https://guides.rubyonrails.org/testing.html#transactions)或老式 [database_cleaner](https://github.com/DatabaseCleaner/database_cleaner) 保护）都存在保留挥之不去的状态并泄漏到其他测试上下文中的风险。

冗长的常见罪魁祸首名单包括：

- ActiveRecord models 是在事务外部创建的（比如在 `before(:all)` 内部创建的）
- ENV 更改
- 各种设置的配置（应用程序的参数设定、路由、日志、I18n 等）
- 全局的类或单例级别变量
- 文件系统修改
- 其他数据存储，如 Redis、Elasticsearch、RabbitMQ 等（如果你在测试中使用真正的集成）
- 缓存 / 内存的存储
- 不同的队列，例如作业、邮件程序等（总是更喜欢 fake 模式以获得性能优势）
- 用于系统测试的浏览器存储
- 数据库主键计数器

> 从上述列表中找到了什么？可通过这个 [Fight the flakiness Guide](https://bit.ly/flaky-fight) 和里面的链接开始解开混乱。

好，全局状态已得到控制，但仍然遇到不稳定的情况？就像残酷的假期航班延误一样 - 有人搞砸了他们的`时间 `！

如果在测试中我们与时间交互，它应该在特定的时间点[被冻结 ](https://api.rubyonrails.org/classes/ActiveSupport/Testing/TimeHelpers.html)（如果它是与时间相关的断言，则始终如此）。

另一个常见的疏忽是依赖于外部系统或服务的测试，因为它不稳定且缓慢。评估应用中风险的位置：

- 对外部 API（包括具有隐藏 HTTP 外部服务的 Gem）的 HTTP 请求
- 远程文件存储访问
- SMTP 邮件
- DNS 解析
- 原始 sockets 使用情况

尝试通过将 [WebMock](https://github.com/bblimke/webmock) 引入测试套件来完全禁用外部请求。请记住：好的测试就像圣诞老人的工作室——自成一体，不依赖于外界！（免责声明：这是未经证实的传说。）

最后但很重要的一点是，订单！下面是一个不言自明的代码段：

```ruby
RSpec.describe 'Delivery order' do
  it 'is a naughty test!' do
    expect(Gift.all).to eq([gift1, gift2]) # Ho-ho-NO! Order undefined!
  end

  it 'is a nice one!' do
    expect(Gift.order(:id)).to eq([gift1, gift2]) # Santa approved!
  end

  it 'is an extra nice test!' do
    expect(Gift.all).to match_array([gift1, gift2]) # Santa’s secret method
  end
end
```

**出现了一个随机的尾注** ！随机性并不总是好的，它也可能会造成严重破坏。有时需要使用稳定的值，例如在使用 [VCR cassettes](https://github.com/vcr/vcr)时。

**第 4 天节日的行动计划** ：

1. 确保是以随机顺序运行测试。
2. 如果你知道自己的测试结果不正常，请选择一个并尝试使用我们的常见问题列表进行修复。
3. 没有？我们不相信你的甜蜜谎言！在测试中搜索 `Date` 和 `Time` 用法，并检查它们是否使用了时间冻结。
4. 尝试通过安装 [WebMock](https://github.com/bblimke/webmock) gem 将你的测试套件从 Internet 上切断。
5. 通过使用 `match_array` 或在适当的位置创建订单来强化你的测试套件。

## Day 5: the nutcracker suite of system testing

除了成堆的礼物外，假期还为大型测试派对*提供了*合适的场所，节日聚会的主要活动总是......失败（因为，嗯，涉及系统测试）。但别担心，帮助就在圣诞树下！

拯救派对的计划由几个部分组成。

第一部分：准备好接受平均来说不可避免的系统测试断言会带来更多的 expectations，涵盖应用程序各个部分，在实时浏览器环境中运行，那么自然容易出现测试漏洞。

因此，关键步骤是最大限度地减少开发人员等待整个套件重新运行所花费的时间。

> Flakiness 并不是唯一的相关问题;系统测试偶尔会冻结，就像雪花在无风的天空中毫无意义地瘫痪一样。在这种情况下，请考虑使用 [sigdump](https://github.com/fluent/sigdump) 来诊断问题。

这里最简单的技巧是重试单个测试，而不是整个测试重新运行。我们有 [rspec-retry](https://github.com/NoRedInk/rspec-retry) 和 [Minitest::Retry](https://github.com/y-yagi/minitest-retry) 用于相应的测试框架。这是解决该问题的双面利刃，因此我们建议谨慎行事，并且仅将其包含在系统测试中，以避免在单元测试中隐藏真正的问题。

（另外，不要忘记限制重试次数，这样我们就不会用马马虎虎的测试运行让整个测试套件膨胀。）

### Simple trick: the day after

由于我们已经通过跳过手动测试套件重试而节省了大量时间，因此我们现在可以继续进行第二部分：实际修复受影响系统测试的不稳定问题。

就像那些不尊重人的孩子试图在圣诞节晚上偷走难以捉摸的圣诞老人的高峰一样，我们可以尝试使用 [Rails 自动截图](https://guides.rubyonrails.org/testing.html#screenshot-helper)来捕捉我们的失败。（专业提示：不要忘记将失败的屏幕截图也保留在 CI 上。）

> Rails 7.2 及更高版本中的 `rails new` 命令会自动生成 GitHub Actions 工作流程文件，并完成[上传屏幕截图的步骤 ](https://github.com/railsdiff/rails-new-output/blob/v8.0.1/.github/workflows/ci.yml#L78-L90)。

### One Viewport size fits all

说到屏幕截图，设置适当的 viewport 大小很重要。此配置取决于特定的驱动程序 - 有关现在热门的 [Cubrite](https://github.com/rubycdp/cuprite) 的示例，请查看[我们的博客文章 ](https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing#annotated-configuration-example)。作为奖励，它还提供了更稳定的测试，因为每个人都会在滚动页面中收到相同的行为。

> 速度问题？可以通过设置来禁用 CSS 动画全局加载： `Capybara.disable_animation = true` .

### Capybara matchers: the good, the bad, and the flaky

拥有坚如磐石的配置是不够的 - 你需要小心测试代码。Capybara matchers 很聪明，但我们必须小心，不要错过选择器中的所有条件：

> 使用 Minitest？用 [Capybara::SlowFinderErrors](https://github.com/ngauthier/capybara-slow_finder_errors) 防止偶尔的缓慢 - 让你的测试像圣诞老人的雪橇一样快速！

```ruby
# Naughty developers use RSpec matchers that flake like artificial snow ❄️
# This matcher may find a Santa list before it’s filled by the elves.
text_field = find('.santa_list)
expect(text_field['value']).to match /Nice list/

# Nice developers make Santa happy with synchronized Capybara matchers 🎅
# This matcher retries until the elves finish updating the list!
expect(page).to have_field('.santa_list, with: /Nice list/)
```

### Sleepless nights with Capybara Lockstep

虽然 Capybara 可以重试一些失败的行为（如元素 expectations），但它对 JavaScript 或 AJAX 一无所知，因此 UI 交互，如 modal 表单或动态更新，其中可能在元素准备就绪之前就去尝试行为（并且网络请求仍在进行中）从而容易失败，具体取决于时间和机器性能。

通常，开发人员会尝试使用显式的零星`sleep`来解决这个问题。但有一个更好的选择：[capybara-lockstep](https://github.com/makandra/capybara-lockstep)。

配置 Gem 后，Capybara 的新行为意味着它会等待所有 JS 异步交互完成，然后再执行下一个 matcher。因此，我们可以保证页面已准备好，这意味着我们在测试步骤之间不需要任何不可靠的 `sleep`。Capybara-LockStep 还通过智能跳过不必要的等待来提高测试性能，消除了对低效固定延迟的需求。 **这是一次如此关键的体验，我们认为它应该默认包含在每个系统测试套件中** ！

> 不要忘记启用 Gem 提供的[中间件 ](https://github.com/makandra/capybara-lockstep?tab=readme-ov-file#including-the-middleware-optional)- 它涵盖了更罕见的情况，例如在测试清理钩子期间防止恶意请求。

**第 5 天节日的行动计划**：

- 安装 [rspec-retry](https://github.com/NoRedInk/rspec-retry) 或 [Minitest::Retry](https://github.com/y-yagi/minitest-retry) 以重试单个测试，而不是整个套件重新运行。
- 确保系统测试失败时的屏幕截图可用。
- 设置适当的浏览器 viewport 配置以获得更稳定的测试。
- 验证系统测试 matchers，以确保它们不包含不完整的条件。
- 安装 [capybara-lockstep](https://github.com/makandra/capybara-lockstep) 以消除显式不可靠又慢的 `sleep` 调用的必要性。

与 #railsmas 分享有关系统测试失败的其他提示和警示故事！

## Day 6: a test suite so fast, Santa’s elves are jealous

随着假期的临近，对于所有兴奋的年轻人来说，时间似乎变慢了，因为他们热切等待着撕开将他们与甜蜜礼物分开的纸张的快感。这种等待可能是令人毛骨悚然的残酷。

也许这种现象与开发人员在等待测试套件的最后一部分完成后才能按下合并按钮时所经历的体验十分相似。

因此，为了避免圣诞不耐烦之灵（狄更斯留在剪辑室地板上的角色）的访问，今天**我们将解开加快测试**速度的策略。毕竟为什么不让开发过程像冬日的微风一样轻快宜人呢？

首先，让我们确定瓶颈。精确定位慢速测试是获得更明亮、更快速套件的第一步。先启用分析器让我们了解一下那些缓慢的 specs：

```bash
# For RSpec:
bin/rails spec --profile
# Or for Minitest enjoyers (Rails 7.1+):
bin/rails test --profile
```

这将向你展示你的套件中最慢的测试，但是，仅从这一点来看，我们真的不知道为什么它们很慢（除非你放置了 `sleep christmas.from_now` 代码）。 **要更深入地了解测试的工作原理，请使用 TestProf**。它就像测试套件的奇迹工具包，不仅揭示了特定测试的问题，还揭示了整个测试套件的系统性低效问题，可以为你节省大量时间。

> 查看我们的 TestProf 文章系列，了解各种工具和技术来分析你的测试套件并进行有针对性的优化。

一旦你确定了拖慢测试套件速度的罪魁祸首，就该进行优化了。我们来探讨一些关键领域，在这些领域中，一些微调和微小的更改都可能会对你的测试节奏产生重大影响。

首先，啊，**Devise** — 我们用户数据的可靠守护者。它在测试中的加密可能有点像那个过分热心的亲戚，他坚持用三层胶带包裹每一份礼物。考虑在测试环境中使用加速哈希算法：

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # Use a lower cost factor in tests
  config.stretches = Rails.env.test? ? 1 : 12
end
```

Devise 的算法需要花费大量时间 - 感到惊讶吗？日志是另一个“Grinch”，无情地窃取我们宝贵的测试套件时间。虽然它们在测试期间很有用，但也可能是多余的。 **为了加快速度，请考虑降低日志的详细程度，或完全禁用它们** 。

```ruby
# config/environments/test.rb
unless ENV['WITH_LOGS']
  config.logger = Logger.new(nil)
  config.log_level = :fatal
end
```

不要低估这个小的变化，因为它可能会使测试套件的总运行时间减少多达 10%。

**覆盖率工具属于同一类别。有选择地运行它们** ，也许只在 CI 中运行，以保持本地测试快速运行：

```ruby
if ENV['COVERAGE']
  require 'simplecov'
end
```

另一个罪魁祸首是**隐藏在回调中的逻辑** 。一个常见的疏忽是 [PaperTrail](https://github.com/paper-trail-gem/paper_trail)，它非常适合跟踪变化，但在测试期间，它可能会感觉像是在暴风雪中跟踪每一片雪花，而不仅仅是一些更传统的天气预报方式。**[关闭 PaperTrail](https://github.com/paper-trail-gem/paper_trail?tab=readme-ov-file#2d-turning-papertrail-off) 以简化你的测试运行** 。

> 我们很快就会对此进行更多讨论，但如果你希望使用类似 PaperTrail 的功能来加快生产速度，请查看 [Logidze](https://github.com/palkan/logidze) 将跟踪逻辑从慢速回调移动到高性能数据库。

**后台作业**也可能带来偷偷摸摸的时间消耗。确保你使用的是 [`Sidekiq::Testing.fake！`](https://github.com/sidekiq/sidekiq/wiki/Testing#testing-worker-queueing-fake) 模式来跳过作业处理，而不会产生实际执行的开销，从而保持测试的重点和速度。

> 将数据库事务与 HTTP 请求、后台作业或其他非回滚行为混合可能会导致状态不一致。Santa 使用 [Isolator](https://github.com/palkan/isolator) 在测试中尽早自动检测这些问题。

**外部 HTTP 请求**也会减慢一切速度！使用 [VCR](https://github.com/vcr/vcr) 记录和重放 HTTP 交互，确保你的测试无需等待网络即可顺利运行。VCR cassettes 还可以增强测试，防止间歇性测试失败。

**第 6 天节日的行动计划**：

- 打开 test profile 并尝试优化最慢的那个
- 安装 [TestProf](https://github.com/test-prof/test-prof) 并查看你的套件的配置文件，首先尝试修复全局问题。

提醒一下，以下是常见问题列表：

- Devise hashing cost factor
- 日志和覆盖率
- 回调中的逻辑（如 PaperTrail）
- Disabled Sidekiq fake mode
- 外部请求

完成后，在 #railsmass 分享自己加快测试速度的技巧和发现。我们想看到你的结果！

## Day 7: better database migrations

随着我们继续 Railsmas，是时候对我们的数据库工具集进行改造了。没有让你的数据库井井有条可能会导致连锁反应，就像看着纸牌屋无助地崩塌。

或者，为了保持主题，更像是看着姜饼屋因为你没有做对什么而可悲地崩溃。

无论如何，让我们从 migrations 开始，因为如果不小心处理，它们可能会带来风险。例如，在大型表上运行某些 migration 可能会锁定你的数据库，从而导致停机。

从这个意义上说，[`strong_migrations`](https://github.com/ankane/strong_migrations) gem 是你可以送给团队的最佳礼物。这个 gem 充当一个安全网，在潜在危险的 migrations 对生产环境造成严重破坏之前捕获它们：

```bash
bundle add strong_migrations

bin/rails g strong_migrations:install
```

接下来，让我们解决数据库一致性问题。[`database_consistency`](https://github.com/djezzzl/database_consistency) Gem 就像你的假期清单，你可以确保数据库约束和 models 校验是一致的，这可以防止可能导致错误的差异，从而使你的应用程序变得更好。

```bash
bundle add database_consistency --group development --require false

bundle exec database_consistency
NullConstraintChecker fail User code column is required in the database but does not have a validator disallowing nil values
NullConstraintChecker fail User company_id column is required in the database but do not have presence validator for association (company)
...
```

随着时间推移，你的 migration 文件会像阁楼上的装饰品一样堆积起来，两者都很难管理。这就是 [squasher](https://github.com/jalkoby/squasher) gem 派上用场的地方。它允许你将旧 migration 合并到一个文件中，从而简化 migration 历史记录。

```bash
gem install squasher

# Squash all migrations prior to 1st January 2024
squasher 2024 -m 8.0 # for Rails 8.0
```

最后，让我们介绍一个“小精灵”，它将使你的数据库像圣诞老人的工作室一样井井有条！[`actual_db_schema`](https://github.com/widefix/actual_db_schema) Gem 可在分支切换时自动迁移。此 Gem 通过自动回滚 WIP migrations 来确保数据库 schema 在分支之间保持一致;它使你在切换分支时免于手动管理 Schema 差异的麻烦。

**第 7 天 节日的行动计划**：

- 首先，将 [`strong_migrations`](https://github.com/ankane/strong_migrations) 引入你的工作流程。
- 将数据库检查和 model 验证同步，使用 [`database_consistency`](https://github.com/djezzzl/database_consistency)。
- 考虑使用 [squasher](https://github.com/jalkoby/squasher) 压缩旧的 ActiveRecord migrations。
- 使用 [`actual_db_schema`](https://github.com/widefix/actual_db_schema) 简化本地多个分支的处理。

然后，在 #railsmas 分享你进行数据库维护的最佳实践！

## Day 8: silent night, secure night

在 Railsmas 的第八天，我们将应用程序包裹在温暖舒适的安全罩中，因为没有什么比数据泄露更能破坏庆祝气氛的了。因此，让我们用一些安全最佳实践和工具来 “装饰大厅”。

### Audit all the way

[`bundler-audit`](https://github.com/rubysec/bundler-audit) 和 [`ruby_audit`](https://github.com/civisanalytics/ruby_audit) 扫描你的依赖项以查找已知漏洞，确保应用程序不依赖于非安全版本的库。确保你定期在 CI 上运行它们：

```bash
gem install bundler-audit ruby_audit

bundle-audit check --update

ruby-audit check
```

（想感受额外的喜庆？让 [Dependabot](https://docs.github.com/en/code-security/getting-started/dependabot-quickstart-guide) 为你检查和处理依赖项更新。）

### Brakeman: let it scan, let it scan, let it scan

[Brakeman](https://github.com/presidentbeef/brakeman) 是 Rails 应用程序的终极安全扫描程序，多年来它一直是值得信赖的工具。它会扫描你的代码库以查找 SQL 注入、跨站攻击脚本 （XSS） 和其他常见漏洞，帮助你在问题变得严重之前识别和修复问题。

```bash
gem install brakeman

brakeman
```

（顺便说一句：从 Rails 8 开始，`rails new` 命令会自动将 Brakeman 添加到你的 CI 流水线中。因此，如果你正在启动一个新应用程序，Brakeman 已经在保护你的应用程序安全了。）

### Outdated configurations: the ghosts of Rails past

随着时间推移，最佳实践会不断发展，旧设置很容易在你的应用程序中徘徊，从而悄悄地破坏安全性。

[Rails 安全指南](https://guides.rubyonrails.org/security.html)是识别过时或不安全配置的首选资源。花一些时间检查应用的设置，并确保它们符合当前的最佳实践。

别忘了你的依赖项！例如，如果使用 Devise 进行身份验证，请根据最新的默认值检查你的 `config.stretches` 设置，在撰写本文时，建议的 stretch 数为 **12**。任何更低的值，该更新了：

```ruby
# config/initializers/devise.rb
config.stretches = Rails.env.test? ? 1 : 12
```

请注意，它只会影响更改后生成的新密码。现有用户将继续使用其原始 stretch 计数，直到他们更改密码。

**第 8 天节日的行动计划**：

- 将 [`bundler-audit`](https://github.com/rubysec/bundler-audit) 和 [`ruby_audit`](https://github.com/civisanalytics/ruby_audit) 添加到你的 CI 中（或使用 [Dependabot](https://docs.github.com/en/code-security/getting-started/dependabot-quickstart-guide)）。
- 运行 [Brakeman](https://github.com/presidentbeef/brakeman) 来扫描你的应用程序以查找漏洞。

然后，检查你的应用程序是否有过时的配置：

- 根据 [Rails 安全指南](https://guides.rubyonrails.org/security.html)检查你的应用程序。
- 检查与安全相关的依赖项（如 Devise、Lockbox 等）的配置。

别忘了用 #railsmas 标签分享你的发现——但前提是你修补了它们，因为圣诞老人在看着！

## Day 9: Dashing through the …queries

在 Railsmas 的第九天，是时候让我们的数据库比圣诞老人更快了（圣诞老人必须非常非常快，因为他必须在[一夜之间走得比从地球到太阳的距离更远 ](https://www.sciencefocus.com/science/how-fast-would-father-christmas-have-to-fly-to-visit-every-child-in-the-world)）。这一次：优化数据库性能的工具、提示和技巧，以便你的应用程序可以毫不费力地应对假期高峰（或任何高峰）。

### PgHero: your friendly neighborhood database tool

在数据库优化方面，你的配置是最好的起点。

PostgreSQL 因开箱即用配置为使用保守的默认值运行而恶名昭著——也许非常适合在圣诞老人的古老计算机上对表现好或不好的列表进行排序，但它并不能完全满足现代速度需求。我们认为 [PgHero](https://github.com/ankane/pghero) 是必备工具。它提供了一个控制面板，可深入了解数据库的运行状况，包括配置建议、未使用的索引、查询统计信息等。

> 更喜欢纯数据库解决方案，例如核心 DBA？打开 [`log_min_duration_statement`配置](https://www.postgresql.org/docs/current/runtime-config-logging.html#GUC-LOG-MIN-DURATION-STATEMENT)以将慢查询记录到日志文件中。

为了更深入地了解慢查询，请考虑自动向它们添加注释，以便更轻松地追溯到生成它们的代码：

```ruby
# config/environments/development.rb
config.active_record.query_log_tags_enabled = true
```

这将导致你的查询使用有用的上下文进行注释，使调试变得轻而易举！

### N+1 issues: a silent performance killer

N+1 查询悄无声息地潜入，并对你的应用程序的性能造成严重破坏（有点像某种痴迷于技术的反圣诞老人，他们做恶事而非好事，......一种赛博朋克反英雄，他可能是也可能不是本文作者之一的待定电影剧本的主题！)

要捕获这些讨厌的 N+1 查询问题，我们建议使用 [Prosopite](https://github.com/charkost/prosopite) gem。与 Bullet 不同，Prosopite 会监视日志和堆栈跟踪以检测 N+1，这使得它不太容易出现假阴性/阳性报告。请注意，这样做也有缺点 — 收集堆栈跟踪并非不占用资源，因此我们不建议在生产环境中启用此功能：

```ruby
# config/initializers/prosopite.rb
unless Rails.env.production?
  require 'prosopite/middleware/rack'

  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)
end
```

请注意，此代码段仅启用对前台应用程序代码的跟踪 - 后台作业、ActionCable Channel 和其他异步部分需要单独设置。相同的注意事项也适用于非集成级别的测试。

### Use the database when possible

有时，我们最终会依赖外部工具来完成任务，而实际上，数据库本身可以更有效地处理这些任务。因此，让我们将一些功能带回本该数据库闪耀的地方：

**PaperTrail → Logidze：** 与其使用 Papertrail 进行版本控制，不如考虑使用 [Logidze](https://github.com/palkan/logidze)，它直接在数据库中存储和管理版本历史记录。它更快、更精简，并将所有内容集中在一个地方。

**Model 校验→数据库约束：** 复杂的验证可能会导致显著的性能负载。尽可能尝试利用数据库来加快速度。[DatabaseValidations](https://github.com/toptal/database_validations) 提供了额外的验证帮助程序来确保数据完整性，而不必仅仅依赖 Rails 验证。

**第 9 天 节日的行动计划**：

- 安装 [PgHero](https://github.com/ankane/pghero) 以检查你的数据库配置。
- 启用 Rails Annotated Query 日志以查找慢查询。
- 使用 [Prosopite](https://github.com/charkost/prosopite) 检查你的应用程序是否存在 N+1 问题。

并尽可能使用数据库：

- 考虑将 PaperTrail 替换为 [Logidze](https://github.com/palkan/logidze)。
- 尝试通过 [DatabaseValidations](https://github.com/toptal/database_validations) 在数据库级别使用验证。

像完美优化的查询一样将其包装，并使用 #railsmas 与我们分享你的菜谱！

## Day 10: deck the docs with lines of clarity

在 Railsmas 的第十天，我们将处理文档问题。是的，考虑假期期间的记录......听起来很有趣？

相信我们，当你不疯狂地试图记住你为什么在 3 月份做出那个奇怪的设计决定时，未来的你（和你的团队）会感谢你的。

### Check Your README for outdated documentation

你的 README 是项目的大门，因此请尝试花点时间戴着新手帽子查看你的 README，并检查所有说明是否仍然准确。

注意：需要追踪所有这些 TODO、FIXME 和 “I'll fix this later” 等承诺吗？运行 [`bin/rails notes`](https://guides.rubyonrails.org/command_line.html#bin-rails-notes) 以获取隐藏在代码中这些注释的整洁列表。

### Start documenting your API

如果你的应用程序有 API，那么假期后的淡季是开始记录它（或更新你一直忽略的那些文档）的最佳时机。 **我们强烈建议你采用 “文档优先” 的方法：在写代码之前编写文档** 。这不仅可以确保你的 API 有据可查，还可以迫使你在实施之前仔细考虑其设计。

继续，即使是最好的 API 文档也可能存在不一致、拼写错误或缺少字段的情况。这就是 [Spectral](https://github.com/stoplightio/spectral) 的用武之地;它是 API 文档的 Linter，可帮助你在问题成为问题之前发现问题。

如果你使用的是 GraphQL，那么是时候为你的文档增添一点爱意了。缺失或过时的描述和示例可能会导致混淆和挫败感，因此请确保它们准确无误并反映架构的当前状态。[RuboCop::GraphQL](https://github.com/DmitryTsepelev/rubocop-graphql) Gem 可以帮助你实施一致的文档标准。

请记住，如果编写 API 感觉工作量太大，那么总还有[Inertia Rails](https://evilmartians.com/chronicles/inertiajs-in-rails-a-new-era-of-effortless-integration)—— **因为有时最好的 API 就是根本没有 API**。

**第 10 天 节日的行动计划**：

- 检查你的 README，就像你是该项目的新手一样。
- 如果尚未完成，请利用文档优先的方法记录至少一个 API 的终端节点。
- 使用 [Spectral](https://github.com/stoplightio/spectral) 整理你的 API 文档。
- 对于 GraphQL，请添加 [RuboCop::GraphQL。](https://github.com/DmitryTsepelev/rubocop-graphql)

终于对所有这些 API 厌倦了？下次考虑 [Inertia Rails](https://evilmartians.com/chronicles/inertiajs-in-rails-a-new-era-of-effortless-integration) 吧！

同时，分享你使用文档记录不佳的 API 的经验，并展示你自己的最佳实践到 #railsmas 。

## Day 11: Jemalocking around the Christmas tree

Railsmas 的第 11 天：性能调优和优化的世界！因为没有什么比减少宝贵的启动时间更能体现“节日欢乐”的了。

### Memory management magic

让我们面对现实吧，Rails “崇拜” 内存，这种热爱肯定不仅影响了资源的消耗，而且还带来了性能损失。（不幸的是，内存管理不是免费的，它是在 Ruby 之外处理的。）

值得庆幸的是，Rails 社区几年前就提出了[一种优化内存分配的方法 ](https://www.speedshop.co/2017/12/04/malloc-doubles-ruby-memory.html)：要么设置一个神奇的` MALLOC_ARENA_MAX` 环境值，要么用 [Jemalloc](https://brandonhilkert.com/blog/reducing-sidekiq-memory-usage-with-jemalloc) 完全替换系统分配器。

对于那些想要方便的预打包解决方案的人，我们保证 Fullstaq 也把 Ruby < 3.3 的 [`malloc_trim` 补丁](https://evilmartians.com/chronicles/cables-vs-malloc_trim-or-yet-another-ruby-memory-usage-benchmark)反向移植到 [Docker 镜像](https://github.com/evilmartians/fullstaq-ruby-docker)中了。

> 对大型玩家如何在 Ruby 内存膨胀中生存感兴趣？查看 [GC 度量值自动调谐器 ](https://github.com/Shopify/autotuner)。

这些调整对于多线程应用程序特别有用。也就是说，虽然这些技巧很普遍，但默认情况下它们并未用在 Ruby 上。Ruby 并不只是给 Rails 专用，也并非每个程序都受益于自定义内存分配策略。

## A Docker & Bootsnap BFF story

Rails 开发人员使用 Bootsnap（缓存那些昂贵的应用程序加载计算）来加快开发过程中的启动时间。**...但是，如果我们告诉你 Bootsnap 也可以加快你的生产环境启动时间呢？**

要在生产环境中获得加载速度，你可能需要预编译缓存：

```bash
bundle exec bootsnap precompile --gemfile app/ lib/
```

不要忘记包含所有相关目录和要正确缓存的代码（即 `config`、`engines`、`packs` 和其他自定义顶级目录）。要验证它，你可以使用简单的检测：

```ruby
# config/boot.rb

# put this at the bottom of the file:
Bootsnap.instrumentation = ->(event, path) { puts "#{event} #{path}" }
```

现在，清除及预编译缓存并检查 Bootsnap instrumentation 是否未显示任何未命中：

```bash
rm -rf tmp/cache/bootsnap/*
bundle exec bootsnap precompile --gemfile app/ lib/
bundle exec rails r 'puts :ok' | grep 'miss'
```

（使用 Docker 映像层时要格外小心 — 通常将预编译的引导程序缓存留在后面，因为它位于 `tmp` 目录中。）

有点乏味，但乏味是圣诞老人的做事方式; 364 天的准备，迎接一个盛大的执行之夜！

### The Notorious YJIT

还记得所有那些使用 JIT 的实验吗？很诡异，对吧？事实上，从去年开始，Rails 默认开启了 YJIT，没有任何特殊标志。你运行的是 Rails 7.2 和 Ruby 3.3？

你可能已经在使用 YJIT，但有一个警告：开发人员经常忘记更新 `load_defaults` 方法，如果是这样，你可以打开 YJIT：

```ruby
# config/application.rb

# Development and test environment tend to reload code and
# redefine methods (e.g. mocking), hence YJIT isn't generally
# faster in these environments.
config.yjit = !Rails.env.local?
```

这是更新 `load_defaults` 值的一种更无用的方法的安全替代方案，应该适当注意每个更新的配置值。

> 对 YJIT 背后的魔力感到好奇吗？阅读这篇关于[优化 Ruby 以进行 Just-in-Time 编译的](https://railsatscale.com/2023-08-29-ruby-outperforms-c)文章。

密切关注性能指标，看看 YJIT 是否对你的应用产生了明显的影响。请记住，并非所有工作负载都会从 JIT 编译中受益，因此请在代码提交之前进行测试！

### Sidetrack with frontend and Vite

如果你正在优化，则不能忘记 Asset Pipeline。特别是，如果你仍然依赖基于 Webpacker 的 pipeline，那么可能是时候将旧雪橇换成涡轮增压雪地摩托了：[Vite Ruby](https://vite-ruby.netlify.app/)。

Vite Ruby 是一个现代的前端工具链，它为 Rails 带来了更快的构建、实时重载和热模块替换。这就像为你的前端工作流程打开一份闪亮的新礼物 — 不再需要永远等待 assets 编译。

如果你特别大胆，可以看看 [`rolldown-vite`](https://github.com/rolldown/vite)，这是一个临时的 Vite 分支，由 Rust 编写的实验性 [Rolldown](https://rolldown.rs/) 打包器提供支持。它[比 Turbo 模式下的圣诞老人的雪橇更快 ](https://github.com/rolldown/benchmarks)：

```json
// package.json
"vite": "npm:rolldown-vite@0.1.0"
```

虽然它还不支持 Ruby Vite 所需的所有配置选项，但它让我们看到了更快的 assets pipeline 的未来; 你的前端构建可能比圣诞老人大口喝两品脱全脂牛奶更快。

而且，根据记录，他能够魔术般快速做到这一点。

**第 11 天 节日的行动计划**：

- 通过设置 `MALLOC_ARENA_MAX` 来优化 Rails 内存消耗
- …或者更好的是，通过使用 [Jemalloc](https://brandonhilkert.com/blog/reducing-sidekiq-memory-usage-with-jemalloc)
- 确保在生产环境中预编译 Bootsnap 缓存，且没有缓存未命中
- 试用 YJIT（在使用前测试一下结果）
- 考虑使用 [Vite](https://vite-ruby.netlify.app/) 加速你的 asset pipeline。

然后，在 #railsmas 分享你的加速技巧，因为没有什么比应用程序速度优化更能体现“节日精神”了。

## Day 12: Silent night, stable night

在 Railsmas 的第 12 天，也是最后一天，我们将为你的应用带来终极礼物：稳定性。因为如果一个快速、安全且文档齐全的应用程序在用户打开它那一刻崩溃，那它又有什么用呢？

所以，带上你最温暖的毯子，一杯可可，让我们确保你的应用程序经久耐用。

### Set timeouts: don’t let requests roast on an open fire

时间宝贵，尤其是在假期期间。为你的应用程序设置适当的超时可确保缓慢或卡住的请求不会占用资源并使一切停止。

如果没有超时设置，无响应的服务可能会无限期地消耗关键资源，从而导致系统范围的减速或崩溃。

害怕错过潜在的故障点？别担心！

[Ruby 超时终极指南](https://github.com/ankane/the-ultimate-guide-to-ruby-timeouts)为 Ruby 应用程序中超时至关重要的每种情况提供了完整的代码片段列表。

你的 Rails 应用程序至少必然有一个超时设置： **数据库超时** ：

```yaml
production:
  adapter: postgresql
  variables:
    statement_timeout: 30s
```

**警告：** 你为超时设置的值至关重要，应根据应用程序的需要进行定制。虽然 30 秒可能适用于许多应用程序，但具有大量长时间查询的其他应用程序可能需要更高的值，以避免过早终止合法的查询。

### **Sidekiq: the engine driving your winter wonderland**

Sidekiq 是后台作业的主力，但即使是主力也需要一点 TLC 才能保持可靠。让我们分享一些技巧，以保持你的 Sidekiq 队列平稳运行。

最常见的疏忽是没有意识到 Sidekiq 可能会在片段错误或其他严重崩溃期间丢失作业。Sidekiq 从 Redis 队列中弹出作业条目，默认情况下是没有确认机制的。

虽然 Sidekiq Pro 带有 [`super_fetch`](https://github.com/mperham/sidekiq/wiki/Reliability) 功能以确保在 worker 崩溃时作业不会丢失，但 GitLab 有一个 OSS 替代方案：[sidekiq-reliable-fetch](https://gitlab.com/gitlab-org/ruby/gems/sidekiq-reliable-fetch)。此 Gem 将作业获取包装在一个更健壮的进程中，确保即使你的工作程序在任务中途崩溃，该作业也会重新排队以供其他工作程序接收。这就像让圣诞老人的精灵仔细检查顽皮和善良的名单——什么都不会丢弃。

Sidekiq 相当灵活，但是当涉及到公平分配作业时，一个 “贪婪” 的客户端可以吃掉整个后台处理。要解决这个问题，我们需要 Robin Hoo...循环调度算法。

[Sidekiq::FairTenant](https://github.com/Envek/sidekiq-fair_tenant) Gem 通过限制来自资源密集型客户端的作业来提供解决方案。它添加了加权队列功能，用于将超过定义阈值的作业重新路由到优先级较低的队列。这可确保这些作业不会阻止其他作业，同时仍保持整体吞吐量。

### ActionCable to AnyCable: no more messages lost in a blizzard!

如果你正在使用 ActionCable for WebSockets，那么可能是时候考虑切换到 [AnyCable](https://anycable.io/) 了。

AnyCable 可以将 WebSocket 连接卸载到单独的 Go 服务端，从而减少 Rails 应用程序的负载并提高可扩展性。

它还附带一个特殊礼物：[Action Cable Extended 协议 ](https://docs.anycable.io/misc/action_cable_protocol?id=action-cable-extended-protocol)，该协议提供了多项稳定性改进，包括更好地处理连接生命周期事件，以及支持更强大的重连接策略。

### Threads and databases

找到正确数量的服务器进程和线程是一种平衡行为。这里越多并不总是意味着更好，例如，最近 Rails 核心团队[将默认的 Puma 线程数从 5 个降低到 3](https://github.com/rails/rails/issues/50450) 个，因为这会让表现良好的 Rails 应用程序有更好的响应时间和资源利用率（没有长时间运行的查询和同步第三方调用）。

> 在后台作业中寻找更好的延迟优化导致了 [Thread Priority 的有趣实验 ](https://github.com/bensheldon/good_job/issues/1554)。

要为你的应用程序找到最适合的 worker 和线程的数值，请使用经典的[将 Ruby 应用程序扩展到每分钟 1000 个请求 - 初学者指南](https://www.speedshop.co/2015/07/29/scaling-ruby-apps-to-1000-rpm.html)和全新的 [Tuning Performance for Deployment](https://edgeguides.rubyonrails.org/tuning_performance_for_deployment.html) Rails 指南。

检查你的应用程序是否有合理的配置值，以消除峰值负载上的错误，或者如果你提前配置的话就可以为明年节省资金。

如果在正确更新配置后仍然遇到连接超时错误，最好检查一下应用程序的所有与数据库相关的部分是否都使用了 [Rails Executor / Reloader](https://guides.rubyonrails.org/threading_and_code_execution.html) 封装。

如果你使用的 Gem 利用线程机制，请确保它们利用 Rails 锁定机制来防止数据库访问超时错误，例如：[Karafka](https://github.com/karafka/karafka/blob/master/lib/karafka/railtie.rb#L98-L107)、[Sidekiq](https://github.com/sidekiq/sidekiq/blob/main/lib/sidekiq/rails.rb#L13-L18)、[AnyCable](https://github.com/anycable/anycable-rails/blob/main/lib/anycable/rails/railtie.rb#L67-L87) 等。一些 Gem 希望用户手动管理线程安全：[Sucker Punch](https://github.com/brandonhilkert/sucker_punch)、[Kicks （ex-Sneakers）](https://github.com/ruby-amqp/kicks) 等。

**第 12 天 节日的行动计划**：

- 配置好超时设置 （数据库、HTTP 等） 。
- 使用 [sidekiq-reliable-fetch](https://gitlab.com/gitlab-org/ruby/gems/sidekiq-reliable-fetch) 优化 Sidekiq，并使用 [Sidekiq::FairTenant](https://github.com/Envek/sidekiq-fair_tenant) 优化公平队列。
- 考虑从 ActionCable 切换到 [AnyCable](https://anycable.io/) 以提高连接稳定性。
- 调整 worker 和线程的数量以获得最佳性能。
- 使用 Rails Executor/Reloader 修复数据库连接超时。

在 #railsmas 分享你实现稳定的方法，因为没什么比一款足够稳定的应用程序更能体现节日气氛了，这样即使在最疯狂的假期流量高峰也能生存下来。

## Twas’ the heading at the end of the post

好吧，好吧！12 天终于过去了！现在，到新年开始时，你已经将你的代码库变成了真正值得庆祝的东西。新年快乐，迎接 2025！
