---
layout: post
title: 宝石符文，好梦成真
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, evil martians]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img-20250318.jpeg"
rating: 4
---

_本文已获得原作者（**Vladimir Dementyev**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了 Evil Martians 公司用来构建 Rails 应用的 常用/必备 Gem。这就是我们梦想的那个 Gemfile！_

- 原文链接：[Gemfile of dreams: the libraries we use to build Rails apps](https://evilmartians.com/chronicles/gemfile-of-dreams-libraries-we-use-to-build-rails-apps#beyound-tools)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula)、**Travis Turner**
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发者博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

_【序】_

今天恰好是炉石传说最新一个扩展包“漫游翡翠梦境”发布的日子。

原文标题的 dreams 含义跟炉石的宣传“好梦成真”再吻合不过了。而 Gemfile 由 “Gem”（宝石） 和 “file”（文件）两个词构成，我把它意译为“宝石符文”，跟“好梦成真”押韵，感觉很不错！

![hearthstone-dreams](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/hearthstone-dreams.jpg)

<iframe src="https://hs.v.netease.com/2025/0218/f76935e7f3603498fe762de251e02966qt.mp4" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" width="560" height="315"></iframe>

**谨以此文为炉石贺！**❤️

_【正文如下】_

## 引言

自创建以来，Evil Martians 团队每年都会在数十个 Ruby on Rails 项目上工作。

自然，这个过程涉及很多 Ruby gems。有些反映了我们渴望使用前沿且现代的工具（或构建我们自己的工具！），而其他 gem 则非常灵活，它们都已经在我们的大多数项目中使用。

我们的开发理念、编程习惯和灵魂都在这个火星（Martian）宝石的宇宙中。那么，如果它们能够以某种方式收敛成一个 Gemfile——理想的 Martian Gemfile，外星的 Rails 工程师的工具箱那会是什么样子呢？

Rails 生态系统非常庞大。对于（几乎）每个典型任务，都有许多库等着帮助你。我们如何为这项工作作出合适的选择？我们可以依赖一些特定的指标，比如 GitHub 星标或下载量（参见[ The Ruby Toolbox](https://www.ruby-toolbox.com/) 获得有价值的见解）。或者，我们可以借鉴过去的经验：这种方法效果很好，但可能会导致极端保守主义。

在 Evil Martians，我们在选择 gem 或决定创造新 gem 时押注于我们的*集体经验*和*外星人的本能*。这种集体经验的好处是，它跨越了几十个头脑和年龄：我们知道哪些成功该重复，哪些失败要避免。虽然我们还不能将这些知识转化为*超级智能的对话* AI，但我们可以在这篇文章中分享它的惊鸿一瞥。

本文的下述部分结构类似于 Rails 应用的 Gemfile，它包含以下章节：

- Rails fundamentals
- Background jobs
- Active Record extensions
- Authentication and authorization
- HTML views
- Asset management
- Crafting APIs (and GraphQL)
- Logging and instrumentation
- Development tools
- Testing tools
- Everything else
- Beyound tools

## Rails fundamentals

首先，我们需要配置 Rails Web 应用的基本元素：Web server 和数据库。

对于我们的数据库，我们将押注 [PostgreSQL，](https://www.postgresql.org/)而 [Puma](https://github.com/puma/puma) 将是我们首选的 Web server。所以，我们的 Gemfile 的开头看起来像这样：

```ruby
gem 'rails', '~> 7.2'
gem 'pg'
gem 'puma'
```

这里没有太多要添加的内容，所以让我们继续讨论 Ruby on Rails 应用的第三个支柱：后台作业引擎。

## Background jobs

Web 应用性能的重要特征是**吞吐量**（在给定时间内可以处理多少个请求）。由于 Ruby （MRI） 并发限制，更准确地说是全局虚拟机锁定 （GVL），可以并行提供的请求数量是有上限的。

为了提高吞吐量，我们尽最大限度地减少请求时间。实现此目的之最佳方法是将尽可能多的工作卸载到后台执行。这就是后台作业处理引擎发挥作用的地方。

Rails 提供了一个抽象层 Active Job 来定义后台作业。但由用户来选择特定的处理器实现。这里没有奇怪的地方 — 我们使用 [Sidekiq](https://github.com/mperham/sidekiq)：

```ruby
gem 'sidekiq'
```

有很多 Sidekiq 附加组件（包括官方的 Pro 和 Enterprise 版本），可让你更好地控制后台作业执行逻辑。让我分享一下 Martian 项目中最常用的两个：

```ruby
gem 'sidekiq-grouping'
gem 'sidekiq-limit_fetch'
```

[sidekiq-grouping](https://evilmartians.com/opensource/sidekiq-grouping) Gem 允许你缓冲排队的作业并批量处理它们。这在排队率较高时非常有用，但你不需要立即处理作业。一个典型的用例是重新索引 models，或向 models 播发实时更新。

为了控制 hard-working（和 RAM 膨胀）的作业，我们使用 [sidekiq-limit_fetch](https://evilmartians.com/opensource/sidekiq-limit-fetch)。例如，为了避免一次生成多个大型 XSLX 导出，我们为队列配置了一个限制：

```yaml
# sidekiq.yml
---
:queues:
  - default
  # ...
  - exports
:process_limits:
  exports: 1
```

你当然可以选择 Sidekiq Pro 或 Enterprise，并获得第三方解决方案提供的所有功能和开箱即用的改进与稳定性——这肯定会使你的 gem 列表更瘦身（以及钱包也如此。但是，嗯，值得）。

但是，无论是否付费，Sidekiq 仍然需要一些权衡。首先，它要求你拥有 Redis，这是一个额外的基础设施组件需要维护（或付费）。

其次，使用 Redis 进行作业存储容易出现事务完整性错误（我们将在下面讨论这个问题和解决方案，请继续阅读）。

因此，近年来，事务感知和无依赖性的后台作业引擎的发展已经获得了很大的普及。现在，在 Gemfile 中可以看到以下 Gem 很常见：

```ruby
gem 'good_job'

# or
gem 'solid_queue'
```

[GoodJob](https://github.com/bensheldon/good_job) 使用 PostgreSQL 作为后端，因此它可以轻松集成到已经使用此数据库的任何应用（即我们的大多数应用）中。它提供了一组不错的功能，对于典型的 Rails 应用来说已经足够*好*了，并且已经被使用了相当长的时间，足以让我们认真考虑。它的精神继任者 [SolidQueue](https://github.com/rails/solid_queue)，一个与数据库无关（仍然依赖于 SQL）的解决方案，旨在成为 Rails 8 起的后台作业的默认答案。但我们更愿意等待它变得更好更成熟些。

使用 GoodJob 或 SolidQueue 的另一个好处是内置了对循环作业（类似 cron）的支持。对于非 Enterpise Sidekiq，您必须使用一些第三方工具来实现。以下是可以在我们的一些 Gemfile 中找到的内容：

```ruby
gem 'schked'
```

对于循环作业，我们使用一个名为 [Schked](https://evilmartians.com/opensource/schked) 的轻量级解决方案。它是著名的 [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler) 的包装器，具有一些有用的附加功能，例如测试支持和 Rails 引擎感知。

让我们用一些有点像 Rails 的东西来结束本节：

```ruby
gem 'faktory_worker_ruby'
```

在多编程语言的项目（群）中，我们使用 [Faktory](https://contribsys.com/faktory) 来排队和处理来自不同服务的作业。例如，用 Python 编写的 ML 服务可以将分析结果*发送到* Rails 应用，反之亦然：Rails 应用可以向 Python 应用发送分析请求。

## Active Record extensions

从章节标题中可以看出，我们并没有从 Rails Way “脱轨”：我们使用 Active Record 来建模业务逻辑并与数据库通信。

Active Record 是功能最丰富的 Rails 子框架，它的 API 随着每个 Rails 版本的发布而增长（我们甚至在 Rails 7.1 中获得了 [Common Table Expressions 支持](https://github.com/rails/rails/pull/37944)！但是，还有更多功能的空间，因此我们将添加一堆插件来实现这一目标。

由于我们专注于 PostgreSQL，因此我们大量使用其特定功能。我个人最喜欢的是 JSONB。

如果使用得当，它可以极大地提高你的工作效率（无需担心架构、迁移等）。默认情况下，Rails 将 JSONB 值转换为普通的 Ruby hash，这在建模业务逻辑方面并不那么强大。

这就是为什么我们通常使用以下库之一来支持我们的非结构化字段：

```ruby
gem 'store_attribute'
gem 'store_model'
```

[store_attribute](https://evilmartians.com/opensource/store-attribute) Gem 扩展了内置的 Active Record `store_accessor`功能，并添加了类型转换支持。因此，可以将 JSONB 值视为常规属性。

[Store Model](https://evilmartians.com/opensource/store-model) 更进一步，允许你定义由 JSON 属性支持的 model class。

我们的 Top-N 列表中的其他数据库功能（不是 PostgreSQL，而是特定于 SQL）是视图、触发器和全文搜索。以下是相应的 gems：

```ruby
gem 'pg_search'
gem 'postgresql_cursor'

gem 'fx'
gem 'scenic'
# or
gem 'pg_trunk'
```

说到功能类扩展，我只想提其中的几个：

```ruby
# Soft-deletion
gem 'discard'
# Helpers to group by time periods
gem 'groupdate'
```

[Discard](https://github.com/jhawthorn/discard) 提供极简的软删除功能（不附加`任何default_scope`）。简约风格可以轻松满足你的需求，这就是为什么我们*软*删除数据的大多数应用中都存在此 gem 的原因。

如果你处理时间聚合报告（并且仍未迁移到时间序列数据库，例如 [TimescaleDB](https://evilmartians.com/chronicles/time-series-data-using-timescaledb-with-ruby-on-rails)），则 [Groupdate](https://github.com/ankane/groupdate) 是必不可少的。

## Authentication and authorization

在过去五年中，我参与的大多数应用在其 Gemfile 中都有这行代码：

```ruby
gem 'devise'
```

我敢打赌，十之八九的读者也在他们的 bundle 中拥有 Devise。这就是当前的现实。

（但尽管如此，我还是想梦想一下）在不太常见的情况下，当从头开始构建 Rails 应用时，我们总是首先考虑替代身份验证库。而领导者是...<鼓声>...Rails 本身！你可以用 `has_secure_password` 功能走得很远。Rails 8 [计划附带一个花哨的生成器](https://github.com/rails/rails/issues/50446)，以使其更容易实现！

在放弃并退回到 Devise 之前，还有其他几个候选者：

```ruby
gem 'sorcery'
gem 'jwt_sessions'
```

[Sorcery](https://github.com/Sorcery/sorcery) 已经存在多年了。它不如 Devise _神奇_（尽管在其 README 中陈述相反）【译者注：Sorcery 已经停止维护了】，并且具有可插拔架构（因此你可以轻松选择所需的部分）

[JWT Sessions](https://github.com/tuwukee/jwt_sessions) 库提供了构建基于令牌的身份验证所需的一切。它非常适合使用移动或 SPA 前端构建纯 API 的 Rails 应用程序。

让我们跳过整个 OAuth 驱动的身份验证解决方案类别（这个问题值得单独讨论），切换到**授权**。

等等，什么？这不就是一回事吗？一点也不。根本区别在于我们要回答的问题。身份验证回答“谁在那里？”，而授权回答”我能够这样做吗？“因此，授权处理角色和权限。

授权本身可以分为两个组件：*授权模型*和*授权（实施）层*。前者表示权限背后的业务逻辑（无论你使用角色、精细权限还是其他权限）。后者授权层，用于定义如何应用授权规则。

授权模型特定于应用程序，而对于实现授权层，我们可以使用通用技术（包装到 gem 中）。过去，我们使用 [Pundit](https://github.com/varvet/pundit) 来实现授权执行，但现在我们有一个更好的选择：

```ruby
gem 'action_policy'
```

[Action Policy](https://actionpolicy.evilmartians.io/) 是 Pundit on steroids。它使用相同的概念（策略），但提供了更多开箱即用的功能（性能更佳，和更好的面向开发人员的体验）。

## HTML views

经典的 Rails Way 采用 HTML 优先的方案。服务端负责“模型-视图-控制器”范式的每个部分：即“M”、“V”和“C”。

在纯 API 的 Rails 应用的黑暗时代之后，我们最近见证了 HTML-over-the-wire 方案在 Rails 社区的复兴。所以，我们又回来了，再次构建视图模板吧！

然而，在 2020 年代，做到这一点的方式和工具箱已然不同：

```ruby
gem 'view_component'
gem 'view_component-contrib'
gem 'lookbook', require: false

gem 'turbo-rails'
```

[Hotwire](https://hotwire.dev/) 使我们基于 HTML 的应用具有交互性和响应性，而 **View Component** 则帮助我们组织模板及其逻辑。

## Asset management

自从 Rails 5 中引入 Webpacker 以来，处理 Rails 中的 assets 就变得很棘手。今天，在 Rails 7 中，我们有多种官方解决方案（Import Maps, JS/CSS bundling gems）。然而，在我们这儿，走的是另一条路：

```ruby
gem 'vite_rails'
```

使用 [Vite](https://vitejs.dev/) 是面向后端和面向前端的 assets 管理之道的中庸之选。它对 Hotwire 应用和 React SPA 都很简单（我们经常有混合设置）。此外，[vite_ruby](https://github.com/ElMassimo/vite_ruby) Gem 还提供了五星级的开发人员体验。

以下是一些与 assets 相关的好东西，可以添加到我们的文件中：

```ruby
gem 'imgproxy-rails'
gem 'premailer-rails'
```

你是否必须处理大量用户生成的内容？不要将 Ruby 服务器资源浪费在图像转换上，让专用代理服务端来完成这种艰苦的工作。显然，我们使用自己的 [imgproxy](https://imgproxy.net/)，而对于[配套的 gem](https://github.com/imgproxy/imgproxy-rails)，在 Rails 应用中使用它是小菜一碟。

在设置电子邮件样式时，[premailer-rails](https://github.com/fphilipe/premailer-rails) gem 确实是 gem 中的*宝石*。自由使用你的 CSS 类，并让 Premailer 在电子邮件模板渲染期间将它们解包到样式属性中。

## Crafting APIs (and GraphQL)

尽管 HTML-over-the-wire 方案正在重新流行起来，但多年来 JS 的统治地位不会那么容易被撤销。因此，API 优先的 Rails 应用似乎不会太快消失。

在构建 JSON API 时，我们通常会使用以下工具：

```ruby
gem 'alba'
# or
gem 'panko_serializer'
```

[Alba](https://github.com/okuramasafumi/alba) 和 [Panko](https://github.com/panko-serializer/panko_serializer) 都专注于数据序列化性能，并提供熟悉的 （类似 Active Model Serializer） 的接口。Panko 是当前维护的[最快的序列化库](https://github.com/okuramasafumi/alba/tree/main/benchmark)（因为它使用了 C 扩展），并且更类似于 `active_model_serializers` 的 API（因此它非常适合迁移）。另一方面，Alba 功能更丰富，速度也更快（当使用 Oj 作为 JSON 序列化驱动程序时）。

处理 REST API 文档及其与前端对应产物的同步是 Rails 开发人员面临的另一个常见挑战。

我们发现文档优先的方案效果非常好：手动或在 AI 帮助下（现在是 2024 🤖 年）制作你的 OpenAPI 模式，并确保你的实现与模式一致：

```ruby
gem "skooma", group: :test
```

如果你使用 GraphQL（在 Rails 社区中仍然很流行），则不需要额外的修饰来保持文档同步和类型同步：

```ruby
gem 'graphql', '~> 2.3'

# Cursor-based pagination for connections
gem 'graphql-connections'
# Caching for GraphQL done right
gem 'graphql-fragment_cache'
# Support for Apollo persisted queries
gem 'graphql-persisted_queries'

# Yes, Action Policy comes with the official GraphQL integration!
gem 'action_policy-graphql'

gem 'graphql-schema_comparator', group: :development

# Solving N+1 queries problem like a (lazy) pro!
gem 'ar_lazy_preload'
```

我们使用的大多数 GraphQL 库都是面向性能的（并且是 Evil Martians 构建的。...巧合？）`graphql-schema_comparator` gem 与 [Danger](https://evilmartians.com/chronicles/danger-on-rails-make-robots-do-some-code-review-for-you) 一起使用，以警告拉取请求审阅者有关架构修改的信息（以便他们可以适当注意更改）。

你可能会问为什么我们将 [ar_lazy_preload](https://evilmartians.com/opensource/ar-lazy-preload) Gem 添加到 GraphQL 组。尽管是一个 Active Record 扩展，但这个库与 GraphQL API 结合使用时特别方便，而像 `#preload` 和 `#eager_load` 这样的经典 N+1 破坏者效率不高。通过延迟预加载，我们可以避免性能恶化，以及使用 data loaders 或 batch loaders 的任何复杂性开销（当然，尽管不完全是）。

## Logging and instrumentation

_我们神话般的_ Gemfile 的 production 组包含日志记录和监控工具：

```ruby
group :production do
  gem 'yabeda-sidekiq', require: false
  gem 'yabeda-puma-plugin', require: false

  gem 'lograge'
end
```

[Yabeda](https://evilmartians.com/opensource/yabeda) 是 Ruby 和 Rails 应用的测量框架。它带有适用于流行库（如 Sidekiq 和 Puma）和监控后端（Prometheus、DataDog 等）的插件。

[Lograge](https://github.com/roidrage/lograge) 将冗长的 Rails 输出转换为简洁的结构化日志，日志收集系统可以解析这些日志并转换为可查询的数据源。

在 default 组中，我们还有这个（反）日志记录 gem：

```ruby
gem 'silencer', require: ['silencer/rails/logger']
```

自从 Rails 添加了默认的 health 检查端点后，我们的日志里就充斥着无用的 `GET /up` 行。为了关闭它们，我们添加了 [silencer](https://github.com/stve/silencer) gem 并按如下方式对其进行配置：

```ruby
# config/initializers/silencer.rb
Rails.application.configure do
  config.middleware.swap(
    Rails::Rack::Logger,
    Silencer::Logger,
    config.log_tags,
    silence: ["/up"]
  )
end
```

## Development tools

让我们从 production 转向 development——我们作为工程师的现实工作。Ruby 是为开发人员的快乐而设计的，但为了让使用 Ruby 开发应用遵循这一原则，我们需要稍微调整一下自己的开发工具。是什么让 Rails 开发人员真正开心？

开发环境零烦扰🙂。Docker 很好地解决了这个问题。还有什么？少做无聊的工作。因此，我们将添加 _robot_ 来帮助我们，这样我们就可以专注于很酷的事。或者，添加 Gem 以使我们的开发体验更加愉快，并帮助我们编写更好的代码。

下面列出了 Rails 项目中 Martians 使用的常见开发工具。

```ruby

gem 'bootsnap', require: false
```

Bootsnap 是 Rails 默认包的一部分，因此无需介绍。用就对了！

```ruby
gem 'database_validations'
gem 'database_consistency'
```

这对 Gem [database_validations](https://github.com/toptal/database_validations) 和 [database_consistency](https://github.com/djezzzl/database_consistency) 可帮你强制执行 model 层与数据库 schema 之间的一致性。如果为 `null： false`，则它必须具有 `validates :foo, presence: true` 。如果是这样 `validates :bar, uniqueness: true` ，则应为数据表的 column 定义唯一索引。

```ruby
gem 'isolator'
gem 'after_commit_everywhere'
```

由于我们通常在事务数据库上运行，因此应该始终记住 [ACID。](https://en.wikipedia.org/wiki/ACID)数据库事务与*逻辑事务*不同，与数据库无关的边际功能效果不受数据库保护，我们应该自己处理它们。例如，从数据库事务中发送“Post published”电子邮件可能会导致事务提交失败时出现*误报*通知。同样，在事务回滚的情况下，执行 API 请求可能会导致第三方系统（例如支付网关）不一致。[Isolator](https://evilmartians.com/opensource/isolator) 有助于识别此类问题。[after_commit_everywhere](https://evilmartians.com/opensource/after-commit-everywhere) 提供了一个方便的 API 来在成功 `COMMIT` 后执行（上述）边际功能。Rails 7.2 附带了一个类似功能，[ `ActiveRecord::Transaction#after_commit` ](https://github.com/rails/rails/pull/51474)也是个[在提交时自动将 Active Job 作业排队的选项](https://github.com/rails/rails/pull/51426)，因此你可能不再需要 `after_commit_everywhere` gem。

下面是更多与数据库相关的好东西，带有简短的注释：

```ruby
# Make sure your migrations do not cause downtimes
gem 'strong_migrations'
# Get useful insights on your database health
gem 'rails-pg-extras'

# Create partial anonymized dump of your production database to perform
# profiling and benchmarking locally
gem 'evil-seed'
```

基准测试和性能分析是开发过程的一部分。以下是一些有助于实现它们的 Gems：

```ruby
# Speaking of profiling, here are some must-have tools
gem 'derailed_benchmarks'
gem 'rack-mini-profiler'
gem 'stackprof'
gem 'vernier'
```

说到 Stackprof，我们不得不提到一个很棒的堆栈分析报告查看器 — [Speedscope](https://www.speedscope.app/)。对于在 Ruby 3.2+ 上运行的项目，我们建议使用 [Vernier](https://github.com/jhawthorn/vernier)，这是下一代 Ruby 采样分析器，内置了对 Rails instrumentation events 及更多功能的支持。

```ruby
gem 'bundler-audit', require: false
gem 'brakeman', require: false
```

安全性当然是必须的。通过运行 [`bundle audit`](https://github.com/rubysec/bundler-audit) 检查依赖项中的任何已知 CVE，并使用 [Brakeman](https://brakemanscanner.org/) 定期扫描你的代码库以查找安全漏洞。如今，CI 服务提供了自己的安全分析工具，可供用户使用。

```ruby
gem 'danger', require: false
```

[Danger](https://danger.systems/ruby/) 可以通过自动执行日常任务和突出显示重要更改来提升你的代码审查体验：自动附加标签、警告缺少测试或不需要的 `structure.sql` 更改——将你想要的几乎任何内容委托给自动化脚本吧。

```ruby
gem 'next_rails'
```

要升级 Rails？[next_rails](https://github.com/fastruby/next_rails) Gem 可以指导你完成整个过程。

```ruby
gem 'attractor'
gem 'coverband'
```

要使代码库保持健康状态，我们需要定期检查并监控代码中*受伤害*最大的部分。你可以使用静态分析（例如，著名的 churn/complexity 技术）来识别值得重构的组件。有很多工具可以做到这一点，但我们选择 [Attractor](https://github.com/julianrubisch/attractor)。Production 下的覆盖率（通过 [Coverband](https://github.com/danmayer/coverband)）提供了关于哪些代码更重要的不同视角（因此在重构过程中需要更多关注）。它还可识别要消除的任何已死代码。

下面是这首小交响乐的最后一个和弦：

```ruby
eval_gemfile 'gemfiles/rubocop.gemfile'

# gemfiles/rubocop.gemfile
gem 'standard'
gem 'rubocop-rspec'
gem 'rubocop-rails'
```

你可以在这篇相关的文章中了解有关我们的 RuboCop-ing 方案的更多信息：[RuboCoping with legacy：使你的 Ruby 代码达到标准](https://evilmartians.com/chronicles/rubocoping-with-legacy-bring-your-ruby-code-up-to-standard)。

## Testing tools

编写和运行测试也是日常开发的一部分，但仍然应该以个人风格对待。高度先进卓越的测试文化是使用 Ruby 和 Rails 构建应用的最重要好处之一。

让我们从基础开始：

```ruby
gem 'rspec-rails'
gem 'factory_bot_rails'
```

是的，我们是 [RSpec](https://rspec.info/) 粉丝，我们更喜欢 factory（通过 [FactoryBot](https://github.com/thoughtbot/factory_bot)）而不是 fixture（但不局限于此）。让我们把关于 Minitest 与 RSpec 和 Factories 与 fixtures 的激烈讨论留到另一天，继续讨论与范式无关的库。

```ruby
gem 'cuprite'
gem 'site_prism'

gem 'capybara-thruster'
```

构建快速而健壮的系统测试（或浏览器测试）是一个组合工作：控制浏览器的现代工具（[Cuprite](https://github.com/rubycdp/cuprite)） ，和描述场景的面向对象方案（通过 [site_prism](https://github.com/site-prism/site_prism) 的页面对象）。

[Capybara Thruster](https://github.com/evilmartians/capybara-thruster) 是一个微型 gem，它允许你将 [Thruster](https://github.com/basecamp/thruster) 用作系统测试的 Web 服务器。虽然我们还没有完全接受 Thruster 作为 production 服务器（甚至作为开发服务器），但我们发现它对于基于浏览器的测试非常有用。

这主要是因为它能够以极快的速度提供 assets，从而缩短页面加载时间。对于使用 AnyCable 的项目，这是必须的，因为可以通过我们特殊的 [AnyCable Thruster](https://github.com/anycable/thruster) 发行版运行 AnyCable 服务器，而无需任何额外工作。

```ruby
gem 'with_model'
```

[with_model](https://github.com/Casecommons/with_model) gem 是我们最喜欢的宝石之一。我第一次发现它是在很多年前，当时我正在寻找一种更好的方法来测试 Rails model concerns。

这个库允许你创建由临时数据库表支持的临时 model，以测试 modules、Rails concerns 和任何实现共享行为的代码。

```ruby
gem 'n_plus_one_control'
```

*N+1 查询*问题是 Rails 应用最常见的问题之一：引入它很容易，并且有一些工具可以检测它，但不能阻止它（除了最近的 `.strict_loading` Active Record 功能）。使用 [n_plus_one_control](https://evilmartians.com/opensource/n-plus-one-control) Gem，你可以编写测试以保护自己将来不会引入 N+1 查询。

```ruby
gem 'webmock'
gem 'vcr'
```

测试永远不应该访问外部世界。我的经验法则很简单：只有当我可以在飞机上运行测试用例并且能通过时，它才是好的。只需将 `WebMock.disable_net_connect！` 拖放到 `rails_helper.rb` 或 `test_helper.rb` 中，即可帮你避免对实际网络调用的依赖。

网络调用（以及耗时）也可能导致你的测试出现*不稳定*：

```ruby
gem 'zonebie'
```

防止依赖于时间的测试的一种优雅方法是在随机时区运行它们。[zonebie](https://github.com/alindeman/zonebie) gem 只需包含在 bundle 中即可实现此目的。

注意，我们没有包含著名的 Timecop gem 来控制时间：那是因为它对于 Rails 应用来说是多余的。相反，你可以使用[内置的时间帮助方法](https://andycroll.com/ruby/replace-timecop-with-rails-time-helpers-in-rspec/)。

```ruby
gem 'rspec-instafail', require: false
gem 'fuubar', require: false
```

对 RSpec 用户的几个好玩意：[Fuubar](https://github.com/thekompanee/fuubar) 是一个进度条格式化工具（为什么它不是默认的!？），并且在 CI 上运行测试时，[rspec-instafail](https://github.com/grosser/rspec-instafail) 格式化工具很有用（因此你可以立即看到任何错误，并在全部测试用例完成之前开始修复它们）。

最后也最重要的，我们对 Gemfile test group 的最后一个组成部分是：

```ruby
gem 'test-prof'
```

[TestProf](https://evilmartians.com/opensource/testprof) 是“Rails 慢测试的良医圣手”。无论你有数百或数十万个测试，让它们运行得更快总是值得的。借助 TestProf，可以毫不费力地大幅缩短测试运行时间。

## Everything else

基本上不可能在一篇文章中描述完我们用过的所有很棒的库。因此，我们挑选了一些*额外的*库在这里分享：

```ruby
gem 'anycable-rails'

gem 'feature_toggles'

gem 'redlock'

gem 'anyway_config'

gem 'retriable'

gem 'nanoid'

gem 'dry-initializer'
gem 'dry-monads'
gem 'dry-effects'
```

以上每一项都是一个特定问题的答案：

- 想要构建一些**实时功能**？[AnyCable](https://anycable.io/) 就是钥匙。
- 需要快速引入**功能切换**？有一个极简的解决方案：[feature_toggles](https://evilmartians.com/opensource/feature-toggles)。
- 正在寻找**分布式锁定**机制？Redis 非常适合此目的，而 [redlock](https://github.com/leandromoreira/redlock-rb) 是你要走的那条路。
- 想要控制**应用程序的配置**？考虑通过 [Anyway Config](https://evilmartians.com/opensource/anyway-config) 使用配置类。
- 厌倦了手动编写重试逻辑？看看 [retriable](https://github.com/kamui/retriable)。
- 需要一种快速可控的方式来生成唯一标识符吗？查看 [nanoid](https://github.com/radeno/nanoid.rb)（火星人 Andrey Sitnik 的 [nanoid JS](https://github.com/ai/nanoid) 的移植版）。
- Service objects 一团糟？考虑用一点 [dry-rb](https://dry-rb.org/) 来标准化它们。例如，来自 `dry-initializer` 的声明性参数，和/或 来自 `dry-monad` 的 [Result objects](https://dry-rb.org/gems/dry-monads/1.3/result/)（它们[特别适用于模式匹配](https://dry-rb.org/gems/dry-monads/1.3/pattern-matching/)）。
- 想要以更安全、更可预测的方式在抽象层周围移动 context？通过 `dry-effects` 库尝试 algebraic effects。

我可以继续提出这样的问题和答案，但我不想太咄咄逼人。每个工程师都有自己理想的工具箱。尝试构建自己的应用吧！使用我们的工具箱作为参考，而不是作为真理的来源。

## Only in dreams

到此处止，是一个回到现实的好位置。希望你此时对“理想中”的火星 Gemfile 有一定的概念了，如果运气好的话，你也有一些灵感可以为自己编织一个梦想。

如果你正在寻找一本好的睡前书，以确保你的梦想充满宝石和光环，那么可以考虑一下[ “Layered Design for Ruby on Rails applications”（Ruby on Rails 应用的分层设计），](https://www.amazon.com/Layered-Design-Ruby-Rails-Applications/dp/1801813787/ref=tmm_pap_swatch_0?link_from_packtlink=yes)（当你在里面看到这篇文章中的大部分宝石时，不要感到惊讶）。
