---
layout: post
title: Ruby慢测试的“良医圣手”
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, rspec, evil martians]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/20200721IMG_20200717_170501.jpg"
rating: 4
---

*本文已获得原作者（Vladimir Dementyev）和 Evil Martians 授权许可进行翻译。原文介绍了 TestProf 这个 Evil Martians 出品的强大 Gem。作者通过详细的范例场景和代码演示，说明了 TestProf 怎样对 Ruby 测试进行性能分析，找出慢测试的痛点，以及如何使用其提供的工具箱对慢测试改进，缩短测试运行时间，进行令人愉悦的 Ruby 开发。*

- 原文链接：[TestProf: a good doctor for slow Ruby tests — Martian Chronicles, Evil Martians’ team blog](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【下面是正文】*

## 概述

**编写测试是开发过程的重要部分，尤其是在 Ruby 和 Rails 社区。我们平常不会关注测试用例套件的性能，直到发现自己在对测试“绿点”的等待中已经耗费了太多时间为止。**

## 前言

我已经花费了许多时间用在分析测试套件的性能上，也开发了一些很有用的技术和工具来让测试跑得更快。我把所有这些集合到了一个称为 [TestProf](https://github.com/palkan/test-prof) 的 Gem 中，这是一个 Ruby 测试的分析工具箱。

## The Motivation

**慢测试浪费你的时间，降低你的效率。**

你可能在扪心自问：“为什么测试性能很重要？”。在给出任何建议之前，让我向你展示一些统计数据吧。

今年早些时候我做过一个小调查，询问了 Ruby 开发者关于其测试偏好的内容。

首先——各位，好消息是——事实证明大多数 Ruby 开发者都确实会编写测试（坦率地说，我并不感到惊讶）。顺便说一句，这就是我之所以如此喜欢 Ruby 社区的原因。

![https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/writetests-c0e3731.svg](https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/writetests-c0e3731.svg)

根据这个调查，所有测试套件只有四分之一其运行时间超过 10 分钟——同时只有一半是运行少于 5 分钟。

![https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/howlong-e6897ac.svg](https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/howlong-e6897ac.svg)

看起来情况还不坏，对吧？那让我们只来看拥有超过 1000 个测试用例的情况。

![https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/howlong1000-b37bf3e.svg](https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/howlong1000-b37bf3e.svg)

现在看起来就差多了：将近一半的测试套件运行都超过了 10 分钟，而几乎 30%——更是超过了 20 分钟。

顺便说一句，我一直工作着的一个典型 Rails 应用有着 6000 ～ 10000 个测试用例。

当然，你不是每次进行一个改动后都必须运行整个测试套件。通常，当我做一个中等大小的功能时，每次提交之前会运行大约 100 个测试用例，而这只花费一分钟左右。但即使这样的“一分钟”也影响到了我的*反馈环*（参看 Justin Searls 的[演讲](https://www.youtube.com/watch?v=VD51AkG8EZw)）从而浪费了我的时间。

尽管如此，在部署周期之内，我们还是必须在使用 CI 服务时运行所有测试。你是否愿意等待好几十分钟（如果队列中有大量的构建，甚至要数小时）来部署一个 hotfix？ 我很怀疑。

并发地构建会有所帮助，但它们是有代价的。看看下面的柱状图：

![https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/howmanyci-82f3d21.svg](https://cdn.evilmartians.com/front/posts/testprof-a-good-doctor-for-slow-ruby-tests/howmanyci-82f3d21.svg)

例如，我[当前的项目](https://onboardiq.com/)上，我们有 5 个并行构建，而平均（每个 job）RSpec 耗时是 2 分 30 秒于 1250 个测试用例上。这意味着我们的 EPM（examples per minute）等于 500.

在未优化之前，800 个测试用例耗时 4 分钟——这仅仅 200 EPM！现在每次构建我们节省了 3～4 分钟。

所以，毫无疑问，慢测试浪费你的时间，拉低你的工作效率。

## The Toolbox

好，你已经认识到了自己的测试套件很慢。如何找出它们慢的原因？

让我略过[这个介绍视频](https://www.youtube.com/watch?v=q52n4p0wkIs)的所有说辞直接向你介绍 [TestProf](https://github.com/palkan/test-prof)——一个 Ruby 测试分析工具箱。

TestProf 旨在帮你识别测试套件的瓶颈，并为你提供修复它们的“配方”。

我来给你展示下自己是如何使用它来分析并且改进测试的。

### General Profiling

在深入挖掘整个测试套件之前，收集一些常规信息通常很有用。

尝试回答如下问题：

- 在哪些地方你的测试花费了更多的时间：controllers、models、services 或者 jobs？
- 最耗时间的 module/method 是什么？

并非那么容易，对吧？

要回答第一个问题，你可以使用 TestProf 的 [*Tag Profiler*](https://test-prof.evilmartians.io/#/tag_prof.md)，它让你可以收集到根据特别的 RSpec tag 值进行分组的统计信息。RSpec 为测试用例[自动添加](https://relishapp.com/rspec/rspec-rails/v/3-6/docs/directory-structure)了`type`的 tag，所以我们可以这样使用它：

```bash
TAG_PROF=type rspec

[TEST PROF INFO] TagProf report for type

          type          time   total  %total   %time           avg

    controller     08:02.721    2822   39.04   34.29     00:00.171
       service     05:56.686    1363   18.86   25.34     00:00.261
         model     04:26.176    1711   23.67   18.91     00:00.155
           job     01:58.766     327    4.52    8.44     00:00.363
       request     01:06.716     227    3.14    4.74     00:00.293
          form     00:37.212     218    3.02    2.64     00:00.170
         query     00:19.186      75    1.04    1.36     00:00.255
        facade     00:18.415      95    1.31    1.31     00:00.193
    serializer     00:10.201      19    0.26    0.72     00:00.536
        policy     00:06.023      65    0.90    0.43     00:00.092
     presenter     00:05.593      42    0.58    0.40     00:00.133
        mailer     00:04.974      41    0.57    0.35     00:00.121
        ...
```

现在要查找瓶颈即可只关注某些测试类型就够了。

你可能已经了解了常规的 Ruby 分析器，例如 [RubyProf](https://github.com/ruby-prof/ruby-prof) 和 [StackProf](https://github.com/tmm1/stackprof)。

TestProf 帮助你在测试套件上无需任何调整就能运行它们：

```bash
TEST_RUBY_PROF=1 bundle exec rake test

# or

TEST_STACK_PROF=1 rspec
```

这些分析器生成的报告可以帮你识别最热的堆栈路径，从而回答第二个问题。

不幸的是，这种类型的分析需要大量资源，让你本来就不那么快的测试套件愈加迟缓。你不得不在测试的一小部分上来运行它，但如何选择是哪一小部分？好吧，只能随机了！

TestProf 包含一个[特别的补丁](https://test-prof.evilmartians.io/#/tests_sampling.md)，让你可以运行随机的 RSpec 用例组（或 Minitest 的）：

```bash
SAMPLE=10 bundle exec rspec
```

现在尝试在你 controller 测试的一个样例上运行 StackProf（因为根据上面 TestProf 它们是最慢的）看看输出结果。当我在自己的一个项目上这样做之后，看到了如下内容：

```bash
%self     calls  name
20.85       721   <Class::BCrypt::Engine>#__bc_crypt
 2.31      4690  *ActiveSupport::Notifications::Instrumenter#instrument
 1.12     47489   Arel::Visitors::Visitor#dispatch
 1.04    205208   String#to_s
 0.87    531377   Module#===
 0.87    117109  *Class#new
```

事实证明我们 [Sorcery](https://github.com/Sorcery/sorcery) 的 encryption 配置在测试环境跟在生产环境中一样严格。

一个典型的 Rails 应用中，关于时间你会在报告内看到类似这样的一些内容：

```bash
TOTAL    (pct)     SAMPLES    (pct)     FRAME
   205  (48.6%)          96  (22.7%)     ActiveRecord::PostgreSQLAdapter#exec_no_cache
    41   (9.7%)          22   (5.2%)     ActiveModel::AttributeMethods::#define_proxy_call
    20   (4.7%)          14   (3.3%)     ActiveRecord::LazyAttributeHash#[]
```

大量`ActiveRecord`的东西——意味着大量的数据库操作。想知道如何处理？继续往下看。

### Database Interactions

知道你的测试套件在数据库上花费了多少时间吗？先猜猜看，然后使用 TestProf 来计算一下。

我们[已经扩展了](https://evilmartians.com/chronicles/fighting-the-hydra-of-n-plus-one-queries) Rails 中的 instrumentation（ActiveSupport 的 [Notification](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) 和 [Instrumentation](http://guides.rubyonrails.org/active_support_instrumentation.html) 功能），所以让我们略过基础来介绍 [*Event Profiler*](https://test-prof.evilmartians.io/#/event_prof.md)。

EventProf 在你的测试套件运行中收集检测指标，并提供包含常规信息的报告以及与指定指标有关的前 N 个最慢的组和用例。目前，它自带的仅支持`ActiveSupport::Notifications`，但其[很容易跟你自己的解决方案集成](https://test-prof.evilmartians.io/#/event_prof.md#custom-instrumentation)。

要获取有关数据库使用情况的信息，我们可以用`sql.active_record`事件。然后报告看起来会是这样（很类似于`rspec --profile`）：

```bash
EVENT_PROF=sql.active_record rspec ...

[TEST PROF INFO] EventProf results for sql.active_record

Total time: 00:05.045
Total events: 6322

Top 5 slowest suites (by time):

MessagesController (./spec/controllers/messages_controller_spec.rb:3)–00:03.253 (4058 / 100)
UsersController (./spec/controllers/users_controller_spec.rb:3)–00:01.508 (1574 / 58)
Confirm (./spec/services/confirm_spec.rb:3)–00:01.255 (1530 / 8)
RequestJob (./spec/jobs/request_job_spec.rb:3)–00:00.311 (437 / 3)
ApplyForm (./spec/forms/apply_form_spec.rb:3)–00:00.118 (153 / 5)
```

对于我目前的项目，耗费在 DB 上的时间量大约是 20%——而这已经是在对其进行了大量优化之后！起初，其耗费时间超过了 30%。

这个指标对于每个项目没有一个单一的最优数字。它高度依赖于你的测试风格：编写更多的单元测试还是集成测试。

我们主要编写集成测试，顺便说一句——20%并不差（但还能更好）。

什么是数据库耗时偏高的典型原因呢？一言难尽，我来捋一捋其中的部分：

- 无用的数据生成
- 过重的测试准备（`before`/`setup` hooks）
- Factory cascades

第一个是著名的`Model.new` vs. `Model.create`问题（或者`build_stubbed` vs. `create`在 [FactoryBot 中的区别](https://robots.thoughtbot.com/use-factory-girls-build-stubbed-for-a-faster-test)）——你在对 model 的单元测试中可能不需要写入数据库。所以别那样做，好吧？

但如果已经那样做了怎么办？如何找出哪些测试不需要持久化数据？这就该 [*Factory Doctor*](https://test-prof.evilmartians.io/#/factory_doctor.md) 登场了。

当你创建不必要的数据时，FactoryDoctor 会通知你：

```bash
FDOC=1 rspec

[TEST PROF INFO] FactoryDoctor report

Total (potentially) bad examples: 2
Total wasted time: 00:13.165

User (./spec/models/user_spec.rb:3)
  validates name (./spec/user_spec.rb:8)–1 record created, 00:00.114
  validates email (./spec/user_spec.rb:8)–2 records created, 00:00.514
```

不幸的是，FactoryDoctor 不是魔术师（它还在学习中），有时它也会发生“误诊”的事情。

第二个问题比较棘手。考虑这个例子：

```ruby
describe BeatleSearchQuery do
  # We want to test our searching feature,
  # so we need some data for every example
  let!(:paul) { create(:beatle, name: 'Paul') }
  let!(:ringo) { create(:beatle, name: 'Ringo') }
  let!(:george) { create(:beatle, name: 'George') }
  let!(:john) { create(:beatle, name: 'John') }

  # and about 15 examples here
end
```

你可能会想：“这里用 fixture 就行了呗”。这貌似个好主意，不过当你正在做一个每天都要更改数十个 model 的大型项目时，就不是那么回事儿了。

另外一个考虑是用`before(:all)` hook 仅生成数据一次。但这里要提请注意——我们不得不手动清理数据库，因为`before(:all)`是在事务外运行的。

或者，我们可以把整个组都手动包在一个事务里！这正是 TestProf 的 [`before_all`](https://test-prof.evilmartians.io/#/before_all.md) helper 所做的：

```ruby
describe BeatleSearchQuery do
  before_all do
    @paul = create(:beatle, name: 'Paul')
    @ringo = create(:beatle, name: 'Ringo')
    @george = create(:beatle, name: 'George')
    @john = create(:beatle, name: 'John')
  end

  # and about 15 examples here
end
```

如果你想要在不同的组（文件）之间共享 context，考虑使用 [*Any Fixture*](https://test-prof.evilmartians.io/#/any_fixture.md)，其让你能从代码生成 fixture（比如，使用 factories）。

### Factory Cascades

*Factory cascade* 是一个非常普遍但很少解决的问题，它会让你的整个测试套件陷入困境。

简而言之，它是通过嵌套 factory 调用而生成过度数据的不可控进程。TestProf 知道如何处理它，我们已经写了一篇专栏文章来单独讨论这个主题——[你值得看一下](https://evilmartians.com/chronicles/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest)。

### Background Jobs

除去数据库瓶颈之外，当然还有很多其他瓶颈。我们来说说其中一个。

在测试中有一个 *inline* 后台任务的普遍做法（例如，[`Sidekiq::Testing.inline!`](https://github.com/mperham/sidekiq/issues/3495)）。

通常，我们把一些繁重的事情丢进后台任务中，因此无条件地运行所有任务会拖慢运行时间。

TestProf 支持对后台任务耗费时间的分析（目前，仅对 Sidekiq）。只需告诉它要分析`sidekiq.inline`：

```bash
EVENT_PROF=sidekiq.inline bundle exec rspec
```

现在当你知道了所耗费的准确时间之后，接下来要做什么？简单地关闭 inline 模式很可能会破坏很多测试用例——太多太多以至于无法快速修复。

解决方案就是全局关闭 inline 模式，仅在必要时才使用它。如果你在用 RSpec，则可以这样做：

```ruby
# Add a shared context
shared_context "sidekiq:inline", sidekiq: :inline do
  around(:each) { |ex| Sidekiq::Testing.inline!(&ex) }
end

# And use it when necessary
it "do some bg", sidekiq: :inline do
  # ...
end
```

那还是得必须把这些 tag 添加到每个失败的用例上，不是么？抱歉，有 TestProf 在，你确实不必。

在 TestProf 的工具箱中，有一个称为 [*RSpec Stamp*](https://test-prof.evilmartians.io/#/rspec_stamp.md) 的特殊工具。它可以*自动地*添加指定的 tag：

```bash
RSTAMP=sidekiq:inline rspec
```

顺便说一句，RSpec Stamp 在其之下是用了 [Ripper](https://ruby-doc.org/stdlib-2.4.0/libdoc/ripper/rdoc/Ripper.html) 来解析源文件并准确插入 tag 的。

在[我们的指南](https://test-prof.evilmartians.io/#/rspec_stamp.md)里可以阅读到关于如何从`inline!`迁移到`fake!`的完整说明。

## 附记

TestProf 已经发布在 [GitHub](https://github.com/palkan/test-prof) 和 [rubygems.org](https://rubygems.org/gems/test-prof)，可随时用在你的应用中，帮助你提升测试套件的性能。

本文只是一个 TestProf 的简介，并未涵盖其所有特性。可以跳转到该系列的下一篇：[TestProf II: Factory therapy for your Ruby tests](https://evilmartians.com/chronicles/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest) 来学习更多关于 TestProf “医生”的工具包，它们能使你的测试更加漂亮优雅，你的 TDD 反馈环更短更快，从而让你成为一个*快乐的* Ruby 开发者。

这里是一些额外的资源列表：

- TestProf [文档](https://test-prof.evilmartians.io/)
- 2017 年 [RailsClub Moscow](http://railsclub.ru/) 的“Faster Tests” 演讲（[视频](https://www.youtube.com/watch?v=8S7oHjEiVzs)[俄语]，[slides](https://speakerdeck.com/palkan/railsclub-moscow-2017-faster-tests)）
- 2017 年 [RubyConfBy](http://rubyconference.by/) 的“Run Test Run” 演讲（[视频](https://www.youtube.com/watch?v=q52n4p0wkIs)，[slides](https://speakerdeck.com/palkan/rubyconfby-minsk-2017-run-test-run)）
- [Benoit Tigeot](https://github.com/benoittgt) 发表的 [“Tips to improve speed of your test suite”](https://medium.com/appaloosa-store-engineering/tips-to-improve-speed-of-your-test-suite-8418b485205c)
