---
layout: post
title: Ruby测试的“工厂疗法”
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, rspec]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200723IMG_20200717_185642.jpg"
rating: 4
---

*本文已获得原作者（Vladimir Dementyev）和 Evil Martians 授权许可进行翻译。原文是 TestProf 这个 Evil Martians 出品的 Gem 介绍文章系列的第二篇。作者介绍了造成 Ruby 慢测试的一个主要元凶——Factory Cascade，以及如何使用 TestProf 来消灭这个元凶。文中也提到了众所周知的 Factories vs. Fixtures 问题，而 TestProf 可以做到让你鱼和熊掌兼得。*

- 原文链接：[TestProf II: Factory therapy for your Ruby tests — Martian Chronicles, Evil Martians’ team blog](https://evilmartians.com/chronicles/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【下面是正文】*

## 概述

**学习如何把你的 Ruby 测试套件带回到健康满满、速度满满的路上，通过使用 [TestProf](https://test-prof.evilmartians.io/)——一个强大的工具包来诊断所有跟测试有关的问题。这一次，我们来聊聊 factories：它们如何拖慢你的测试，如何来估量那些负面影响，如何避免，以及如何让你的 factories 跟 fixtures 一样快。**

## 前言

[TestProf](https://test-prof.evilmartians.io/)，用于很多 Evil Martians 的项目，以缩短 [TDD](https://en.wikipedia.org/wiki/Test-driven_development) 的反馈环，对任何其测试运行时间超过一分钟的 Rails（或其他基于 Ruby 的）应用而言都是一个必备工具。它通过扩展有关功能而对 [RSpec](http://rspec.info/) 和 [minitest](https://github.com/seattlerb/minitest) 均可适用。

在我们展示该开源项目的[介绍文章](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests)里，当时承诺会有一篇专门文章来讲述在测试 Ruby Web 应用时被经常忽视的一个问题：*factory cascades*。本文就是我们所承诺的东西。

通过在你的实际测试中运行一下 [TestProf](https://test-prof.evilmartians.io/) 有个概览是比较好的。所以如果你手边恰好有一个 RSpec 覆盖的 Rails 项目，且使用了 factory_bot（之前闻名的名字叫 factory_girl）的 factories——我们建议你阅读下去之前安装该 gem，那么这将会是一个互动式演练！

[安装 TestProf](https://test-prof.evilmartians.io/#/getting_started) 很简单，把下面这行添加到你`Gemfile`的`:test`组：

```ruby
group :test do
  gem 'test-prof'
end
```

## Crumbling factories

无论何时要测试自己的应用时，我们都需要生成测试数据——两种常见的方式就是 *factories* 和 *fixtures*。

factory 是一个可以根据预定义 schema 生成其他对象（可以被持久化，也可以不）并*动态*实现的对象。

Fixtures 相当于一个不同的方案：它们声明数据的静态状态，其会被立即加载到测试数据库中，且通常在测试运行之间保持不变。

在 Rails 世界中，我们有[内置 fixtures](http://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures) 和广受欢迎的第三方 factory 工具（比如 [factory_bot](https://github.com/thoughtbot/factory_bot), [Fabrication](http://www.fabricationgem.org/), 及[其他](https://www.ruby-toolbox.com/categories/rails_fixture_replacement)）。

尽管关于 [“factories vs. fixtures”](https://evilmartians.com/chronicles/factories-or-fixtures) 的辩论看起来永远不会停止，不过我们仍然把 factories 视为一种更加灵活也更易于维护的方式来处理测试数据。

**然而，能力越大责任越大：factories 更容易让你搬起石头砸自己的脚，让你的测试陷入困境。**

那么，我们如何判断自己是否滥用了这种能力并且该怎么办？首先，让我们来看看测试套件耗费在 factories 上的时间有多少。

对此，我们应该使用这个“良医”：[TestProf](https://test-prof.evilmartians.io/)。该 gem 是个完整的诊断工具包，[EventProf](https://test-prof.evilmartians.io/#/event_prof) 为其中工具之一。顾名思义：它是一个事件分析器，可以让它追踪`factory.create`[事件](https://test-prof.evilmartians.io/#/event_prof?id=quotfactorycreatequot)，它会在你每次调用`FactoryBot.create()`时被触发，同时一个 factory 生成的对象被保存到数据库中。

EventProf 对 [RSpec](http://rspec.info/) 和 [minitest](https://github.com/seattlerb/minitest) 都支持，有一个命令行界面，所以在任何 Rails 项目目录下启动终端（当然，它必须得有测试和 factories，且本文中所有测试用例都假设用的是 RSpec）并运行如下命令：

```bash
$ EVENT_PROF="factory.create" bundle exec rspec
```

在输出中，你可以看到从 factories 创建数据所花费的总时间，以及前五个最慢的测试：

```bash
[TEST PROF INFO] EventProf results for factory.create

Total time: 03:07.353
Total events: 7459

Top 5 slowest suites (by time):

UsersController (users_controller_spec.rb:3) – 00:10.119 (581 / 248)
DocumentsController (documents_controller_spec.rb:3) – 00:07.494 (71 / 24)
RolesController (roles_controller_spec.rb:3) – 00:04.972 (181 / 76)

Finished in 6 minutes 36 seconds (files took 32.79 seconds to load)
3158 examples, 0 failures, 7 pending
```

从我们项目之一取出的一个真实范例中（重构之前），在六分半的测试运行时间里，超过三分钟是用于生成测试数据，其几乎占据了 50%。这并不令人惊讶：我曾经工作过的一些代码库上，从 factories 生成数据花费了多达 80% 的测试时间。

平静一下，请继续阅读，我们明白如何修复这个问题。

## The name of the game is “cascade”

根据多年以来的观测和对 [TestProf](https://test-prof.evilmartians.io/) 的开发，以及对所有与测试有关东西的分析，慢测试的原因里最大的一个是——*factory cascade*。

让我们来做一个演示：

```ruby
factory :comment do
  sequence(:body) { |n| "Awesome comment ##{n}" }
  author
  answer
end

factory :answer do
  sequence(:body) { |n| "Awesome answer ##{n}" }
  author
  question
end

factory :question do
  sequence(:title) { |n| "Awesome question ##{n}" }
  author
  account # suppose it's our tenant in SaaS application
end

factory :author do
  sequence(:name) { |n| "Awesome author ##{n}" }
  account
end

factory :account do
  sequence(:name) { |n| "Awesome account ##{n}" }
end
```

现在，试着猜一下，一旦你调用`create(:comment)`，会有多少条记录被创建到数据库中？如果你已经有了答案，请继续往下看。

- 首先，我们对于`comment`生成了一个`body`。但还没有记录被创建，所以这时总数是 0。
- 接下来，对于`comment`我们需要一个`author`。`author`应该属于`account`，因此我们创建了两条记录。总数：2。
- 每个 comment 需要一个可注释的对象，对吧？我们这里是`answer`。`answer`自身需要一个`author`跟`account`。这就多了三条记录。总数：2 + 2 = 4。【*译者注：原文这里有点描述不清晰。前面说“三条记录”，是把 answer、author、account 一起算上的，后面总数计算的数字又按 2 来加，应该没计入 answer。结合后文看，answer 是在最后一步才计入的，所以这里按 2 算是对的。*】
- `answer`也需要一个`question`，其有自己的`author`跟后者自身的`account`。而且，我们的`:question` factory 也包含一个`account`关联。总数：4 + 4 = 8
- 现在我们可以创建`answer`以及`comment`本身了。总数： 8 + 2 = 10。

就是如此！使用`create(:comment)`创建一个 comment 产生了十条数据库记录。

我们需要多个 account 和不同的 author 来测试一个单独的 comment 吗？不太可能吧。

你可以想象出当我们创建多个 comment 时，比如`create_list(:comment, 10)`，会发生什么。休斯敦，我们碰上麻烦了。【*译者注：电影《阿波罗13》的经典台词*】

**遭遇 factory cascade——一个通过嵌套 factory 调用生成过量数据的无法控制的过程。**

我们可以把 cascade 用一颗树来描绘：

```bash
comment
|
|-- author
|    |
|    |-- account
|
|-- answer
     |
     |-- author
     |    |
     |    |-- account
     |
     |-- question
     |    |
     |    |-- author
     |    |    |
     |    |    |-- account
     |    |
     |    |--account
```

让我们把这种呈现形式称为 *factory 树*。稍后会用在我们的分析中。

## Fire walk with me

[EventProf](https://test-prof.evilmartians.io/#/event_prof) 仅为我们展示了花费在 factories 上的总时间，也因此能够识别出某些东西不对。然而，我们仍然不知道它们在哪儿，除非去挖掘代码做猜谜游戏。使用 TestProf 医疗包中的另一个工具，就不用这么麻烦了。

第二个分析器登场：[FactoryProf](https://test-prof.evilmartians.io/#/factory_prof)。你可以这样来运行它：

```bash
$ FPROF=1 bundle exec rspec
```

报告结果列出了所有 factories 及其使用情况统计：

```bash
[TEST PROF INFO] Factories usage

 total      top-level                            name
  1298              2                         account
  1275             69                            city
   524            516                            room
   551            549                            user
   396            117                      membership

524 examples, 0 failures
```

这里的`total`和`top-level`结果有什么区别？`total`值是一个 factory 被使用生成数据记录的次数，不管显式使用（通过`create`调用），还是在另一个 factory 内的隐式使用（通过关联关系和回调）；而`top-level`值仅考虑显式调用。

因此，`top-level`值和`total`值之间的明显不同就可能指示了 factory cascade：告知我们一个 factory 更经常从其他 factories 被引用，而非直接调用其自身。

如何准确找出这个“其他 factories”？就用前面讨论过的 factory 树来帮忙！我们来把这颗树平铺展开（使用 [pre-order traversal](https://en.wikipedia.org/wiki/Tree_traversal#Pre-order_(NLR))）并把结果列表称为 *factory 堆栈*：

```bash
// factory stack built from the factory tree above
[:comment, :author, :account, :answer, :author, :account, :question, :author, :account, :account]
```

下面是如何以编程方法构建 factory 堆栈的方式：

- 每次`FactoryBot.create(:thing)`被调用时，一个新堆栈就被初始化（使用`:smth`作为首元素）。
- 每次另一个 factory 在一个`:thing`内被使用时，我们把其压入堆栈。

为什么堆栈很棒？正如跟堆栈调用那样，我们可以绘制火焰图！而有什么比火焰图更酷的呢？

[FactoryProf](https://test-prof.evilmartians.io/#/factory_prof) 了解如何生成交互的 HTML 火焰图报告，开箱即用。下面是另一个命令行调用：

```bash
$ FPROF=flamegraph bundle exec rspec
```

输出结果包含一个 HTML 报告的路径：

```bash
[TEST PROF INFO] FactoryFlame report generated: tmp/test_prof/factory-flame.html
```

在你浏览器中打开，可以看到类似这样：

![https://cdn.evilmartians.com/front/posts/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest/flame1-fe0a939.gif](https://cdn.evilmartians.com/front/posts/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest/flame1-fe0a939.gif)

我们怎样来阅读它？

每一栏代表一个 factory 堆栈。该栏越宽，该堆栈在测试中耗费的时间越多。`root`那栏展示了 top-level `create`调用的总数。

如果你的 FactoryFlame 报告看起来象纽约的大厦轮廓线那样参差不齐，这就是有很多 factory cascade 了（每个“摩天大楼”代表一个 cascade）：

![](https://cdn.evilmartians.com/front/posts/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest/flame2-7303761.png)

尽管看起来景色很美，但这并非你理想的无 cascade 报告应有的模样。相反，你的目标应该是象荷兰乡村那样平坦的东西：

![](https://cdn.evilmartians.com/front/posts/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest/flame3-7377b3b.png)

## Doctor, am I going to live?

知道如何发现 cascade 是不够的——我们还需要消灭它们。让我们来考虑有关的几种技术吧。

### Explicit associations

涌上心头的第一个做法就是从我们的 factories 移除所有（或几乎所有）关联关系：

```ruby
factory :comment do
  sequence(:body) { |n| "Awesome comment ##{n}" }
  # do not declare associations
  # author
  # answer
end
```

采用这个方案，你在使用一个 factory 时必须明确指定所有需要的关联关系：

```ruby
create(:comment, author: user, answer: answer)

# But!
create(:comment) # => raises ActiveRecord::InvalidRecord
```

有人可能会问：我们使用 factories 不就是为了每次避免指定所需的参数么？对，没错。用这个方案，factories 变快了，但也更没用了。

### Association inference

有时候（通常是在处理 [denormalization](https://en.wikipedia.org/wiki/Denormalization)时）是可能从其他关系推断出关联关系的：

```ruby
factory :question do
  sequence(:title) { |n| "Awesome question ##{n}" }
  author
  account do
    # infer account from author
    author&.account
  end
end
```

现在，我们可以编写`create(:question)`或`create(:question, author: user)`而不创建一个单独的 account。

我们也能够使用生命周期回调：

```ruby
factory :question do
  sequence(:title) { |n| "Awesome question ##{n}" }

  transient do
    author :undef
    account :undef
  end

  after(:build) do |question, _evaluator|
    # if only author is specified, set account to author's account
    question.account ||= author.account unless author == :undef
    # if only account is specified, set author to account's owner
    question.author ||= account.owner unless account == :undef
  end
end
```

这个方案会很有效，但需要很多重构（而且，坦率地讲，让 factories 更难阅读）。

### Factory default

而 TestProf 提供了另一种方式来消除 cascade——[FactoryDefault](https://test-prof.evilmartians.io/#/factory_default)。它是一个 [factory_bot](https://github.com/thoughtbot/factory_bot) 的扩展，通过允许你隐式重用 factory 内的记录，来启用更简洁和更不易出错的 DSL，以创建有关联关系的默认值。考虑如下示例：

```ruby
describe 'PATCH #update' do
  let!(:account) { create_default(:account) }
  let!(:author) { create_deafult(:author) } # implicitly uses account defined above
  let!(:question) { create_default(:question) } # implicitly uses account and author defined above
  let(:answer) { create(:answer) } # implicitly uses question and author defined above

  let(:another_question) { create(:question) } # uses the same account and author
  let(:another_answer) { create(:answer) } # uses the same question and author

  # ...
end
```

这个方案的主要优势在于你不必修改自己的 factories。你所有需要做的就是把测试中的一些`create(…)`调用替换为`create_default(…)`。

另一方面，这个特性也为你的测试带来了一些魔法，所以请谨慎使用，因为测试应该尽可能保持可读性。仅针对 top-level 的实体（比如多租户 App 中的租户）使用是个不错的主意。

## Bonus: AnyFixture

到目前为止我们只讨论了 factory cascade。从 TestProf 报告中我们还能看出其他什么呢？

让我们再来看一眼 FactoryProf 报告：

```bash
[TEST PROF INFO] Factories usage

 total      top-level                            name
  1298              2                         account
  1275             69                            city
   524            516                            room
   551            549                            user

524 examples, 0 failures
```

注意到`room`和`user` factories 被使用了跟测试用例总数大约相同的次数。因此，在每个用例中两者可能都需要。对于所有用例一次性创建这些记录呢？那么，我们可以使用 fixtures。

由于我们已经有了 factories，重用它们来生成 fixtures 会是很棒的。有请 [AnyFixture](https://test-prof.evilmartians.io/#/any_fixture) 登场。

你可以为数据生成使用任何代码块，而 AnyFixture 会在运行结束时负责清理数据库。

AnyFixture 可以很好地跟 RSpec 的 [shared contexts](https://relishapp.com/rspec/rspec-core/docs/example-groups/shared-context) 一起工作：

```ruby
# Activate AnyFixture DSL (fixture) through refinements
using TestProf::AnyFixture::DSL

shared_context "shared user", user: true do
  # You should call AnyFixture outside of transaction to re-use the same
  # data between examples
  before(:all) do
    fixture(:user) { create(:user, room: room) }
  end

  let(:user) { fixture(:user) }
end
```

然后激活该 shared context：

```ruby
describe CitiesController, :user do
  before { sign_in user }
  # ...
end
```

随着 AnyFixture 的启用，FactoryProf 报告会看起来这样：

```bash
total      top-level                            name
 1298              2                         account
 1275             69                            city
  8                1                            room
  2                1                            user

524 examples, 0 failures
```

看起来完美，不是么？

**小孩子才对 factories 和 fixtures 做选择，我们全都要！**

## 附记

感谢阅读！

Factories 为你的测试数据生成带来了简单和灵活，但它们非常*脆弱*——cascade 如幽灵般出现，而重复地数据创建会消费大量的时间。

照顾好你的 factories 吧，定期带它们去看看医生（[TestProf](https://test-prof.evilmartians.io/)）。让测试更快速，开发者就更快乐！

请阅读 [TestProf 介绍文章](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests) 以了解更多该项目和其他使用场景背后的初衷。

