---
layout: post
title: 一万年太久，只争朝夕
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, rspec, evil martians]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20250421.jpg"
rating: 4
---

_本文已获得原作者（**Vitalii Yulieff**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了如何通过实战工具和高超技术让一个企业级 Rails 项目的测试速度提高了 5 倍。_

- 原文链接：[Railing against time: tools and techniques that got us 5X faster tests](https://evilmartians.com/chronicles/railing-against-time-tools-and-techniques-that-got-us-5x-faster-results)
- 作者：**Vitalii Yulieff**、**Travis Turner**
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发者博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

_【正文如下】_

## 引言

缓慢的测试对任何项目来说都是一个拖累，而对于大规模运行的企业级项目来说尤其痛苦。这可能会导致 CI 滞后、部署时间变长，以及非常无聊的开发人员体验。

Evil Martians 最近帮助一位客户优化了他们的 CI pipeline 和测试，让他们的代码变的更快，最终获得了**五倍提速的结果** ！在这篇文章中，我们将讨论一些实现这一目标的技术和工具——也许你会受到启发来做到同样的事情！

首先，我们客户的一些背景：[Power Home Remodeling](https://powerhrg.com/) （“POWER”） 是美国最大的外部住宅改造商，专门从事外部改造——包括窗户、壁板、屋顶、门、阁楼绝缘和太阳能屋顶板。无论内外，很明显公司都有很高的标准，因此我们着手满足这些标准。

从技术上讲，该项目基于 Ruby on Rails 构建，并遵循基于组件的架构设计（又叫*模块化单体* ），具有数十个组件。

## A bird’s eye view of our optimization

为实现这种性能提升，我们结合使用了 [RSpec](http://rspec.info/) 和测试分析的高级技术（例如，通过 [Stackprof](https://github.com/tmm1/stackprof)），当然，还使用了我们自己的 [TestProf](https://evilmartians.com/opensource/testprof) 工具箱。

首先，我们使用 Stackprof 对整个测试套件进行了初步检查。这有助于我们确定一些需要改进的常规内容：factories、日志、API 调用等。然后，在常规优化之后，我们切换到*本地*测试优化，例如，分析和重构特定的测试文件。

总的来说，我们提交（并合并）了三个 PR，每个 PR 都带来了不同级别的测试套件改进。在本文中，我们将带你了解这三个优化里程碑。

## The three pillars of the testing optimization mindset

稍安勿躁。在优化测试之前，先了解获得重大改进所需的理念非常重要。这种理念依赖于以下三个支柱。

首先， **搜索最有价值的内容进行优化**。例如，优化所有测试中使用的 user factory 将比优化单个 `monthly_report_spec.rb` 文件（很少更改或使用）提供更多的价值。

其次， **找到唾手可得的果实，不要过度优化** 。使用某些方法很容易卡住，如果需要 4 小时才能获得 1 秒的测试性能提升，那你应该在这里重新考虑优先级。

第三， **衡量时间消耗，** 始终比较优化前和优化后的时间。可能会有令人惊讶的增长，这并不是我们真正想要的。

## Understanding the situation

首先，我们必须查看不同类型的指标，以获得清晰的概览并查明任何瓶颈。简而言之，这些指标是：总测试时间、调用堆栈中最慢的方法、以及最常用（也是最慢）的 factories。

### Setting up the tools

开始之前，我们安装并配置了 Stackprof 和 [TestProf](https://evilmartians.com/opensource_projects/testprof)。Stackprof 是 Ruby 的调用堆栈分析器，而 TestProf 是用于分析和优化测试的高级工具箱（同样，它是由 Evil Martians 创造的！）

请记住：我们需要记录自己的测量结果。对我们来说，起始测试套件运行时间为 **53 分钟** 。你认为我们可以将这个数字降低到多低？试着猜猜，然后继续往下看以找到答案（警告：你可能会感到惊讶）！

让我们通过查看基于 Stackprof 收集的调用堆栈来大致了解“为什么它这么慢”——顺便说一句，**这是你处理慢测试套件时要做的第一件事**。

### Learning from the call stacks

读取应用程序的调用堆栈的最佳方法是将它们绘制为*火焰图* 。为此，我们可以将 `TEST_STACK_PROF=1 SAMPLE=1000 bin/rspec` 命令的结果加载到 [Speedscope 中，Speedscope](https://www.speedscope.app/) 是一个支持 Stackprof 和其他分析器（即不仅仅是 Ruby 分析器）的火焰图查看器。

虽然实际上掌握火焰图需要一些时间，但 Speedscope 中的“三明治”视图可以立即为你提供一些线索。在我们的例子中，我们发现了几个可疑的 Active Record 回调：

```ruby
History#auto_add_history
NitroSearch::Elastic::Indexing
```

![](https://evilmartians.com/static/d3f723a9c7d287507d45bd88789f365f/492b8/speedscope.webp)

我们还可以看到很多低级的 Active Record 调用（`#exec_prepare` 等）和 factory 相关的调用（`FactoryBot#create`）。让我们使用 TestProf 的 [FactoryProf 分析器](https://test-prof.evilmartians.io/profilers/factory_prof)来仔细看看这些 factory。

### Analyzing factories with FactoryProf

FactoryProf 允许你查看哪些 factory 最常用和最耗时（在我们的例子中，` project` 和 `estimate` factory 对测试时间的“贡献”最大）。

还有一个非常有用的类似火焰图的 factory 分析器 （`FPROF=flamegraph bin/rspec`），可以高亮显示 **factory cascades**：

![](https://evilmartians.com/static/dcc0c34d6e01ca8d6c74cbbfb4d5bb91/642ce/factory_flame_before.webp)

在上图中，你可以注意到其中一个级联：每次调用 `create(:candidate_interview)` 时，都会创建大量依赖记录。

而且我们也可以看到，这些 cascades 都是由于重复创建 `project` 和 `estimate` factories 造成的。

有了这些分析信息，我们就可以开始逐个应用优化*补丁*。

## PR #1: General optimizations

我们发现，在整个测试运行过程中，多个 Active Record 回调（例如 `History#auto_add_history`）被频繁调用。然而，在所有测试中，只有 ~1% 需要其相应的*边际作用* 。因此，为了缩短测试时间，我们可以在测试中默认禁用它们，并且仅在需要时启用它们。

为此，我们应用了 _testability_ pattern：为该功能添加一个特殊的 `Testing` module，以控制测试中此回调的调用：

```ruby
# models/history.rb
module Testing
  class << self
    def fake? = @fake
    def fake! = @fake = true
    def real! = @fake = false
  end

  # ...
  def auto_add_history
    return if History::Testing.fake?
    # ...
  end
end
```

在这里，我们遵循许多 Ruby 开发者所熟知的 `Sidekiq::Testing` 接口。现在，在我们的 `rails_helper.rb` 中，我们可以执行以下行为：

```ruby
# spec/rails_helper.rb

# ...
History::Testing.fake!

RSpec.configure do |config|
 config.before(:each) do |example|
   if example.metadata[:auto_history] == true
     History::Testing.real!
   else
     History::Testing.fake!
   end
 end
end
```

在这里，我们使用 RSpec 的标记功能来有条件地切换回调行为。每当我们需要测试一些依赖于 auto-history 的功能时，我们都会将 `:auto_history` 添加到相应的测试用例中：

```ruby
# spec/models/history_spec.rb
describe History do
  let(:fp) { create(:finance_project) }

  it "automatically record history on creation", :auto_history do
    h = fp.histories.last
    expect(h.owner_changes["roofing_sold"]).to eq([nil, true])
    expect(h.activity).to eq("Created the Finance Project")
  end

  # ...
end
```

在我们对 `NitroSearch::Elastic::Indexing` 模块应用类似的技术后，我们将总测试时间**从 53 分钟缩短到 33 分钟** 。而这仅仅是个开始！

## PR #2: Optimizing factories

我们发现 `project` 和 `estimate` 两个 factory 是最慢的（根据 FactoryProf 报告）。我们查看了他们的源码，发现它们有一个共同点 —— 默认情况下，他们都创建了 `home` 和 `owner` 关联：

```ruby
factory :estimate do
  # ...
  home
  association :owner, factory: :user
end
```

如果你看到类似的东西怎么办？尝试注释掉关联，看看有多少测试失败了！

在我们的例子中，这个数字并不大（数千个测试中有 ~50 个），因此我们继续将关联创建移动到相应的 trait 中，并在需要时才使用它们：

```ruby
factory :estimate do
  # ...
  trait :with_home do
    home
  end
  trait :with_owner do
    association :owner, factory: :user
  end
end
```

如下就是 factory 火焰图在我们删除了不必要的关联后的样子——堆栈变得更低了（总体测试时间又减少了 ~15%）：

![](https://evilmartians.com/static/c0912159aa54a627398d48b661c769be/7ad1f/factory_flame_after.webp)

### Fixturizing `nitro_user`

我们还注意到，几乎每个测试都会创建一个默认用户（`User.current`）。我们在测试中发现的常见用法是 `User.current || create(:nitro_user)` 。创建用户还涉及创建一些其他 factory，因此一直重新创建它的开销非常明显。

我们决定使用 TestProf 的 [AnyFixture](https://test-prof.evilmartians.io/recipes/any_fixture) 工具将默认用户的创建移动到 Fixture 中：

```ruby
# spec/nitro_user.rb

require "test_prof/recipes/rspec/any_fixture"
using TestProf::AnyFixture::DSL

RSpec.shared_context "fixture:nitro_user" do
  let(:nitro_user) { fixture(:nitro_user) }
end

RSpec.configure do |config|
  # Create a Nitro user for the whole test run
  config.before(:suite) do
    fixture(:nitro_user) { FactoryBot.create(:nitro_user) }
  end

  config.include_context "fixture:nitro_user"
end
```

在引入 fixture 之后，我们删除了测试中所有显式 `User.current` 的创建，以再次获得性能提升。

### On the database state and its cleanness

当我们在进行上述 `nitro_user` fixture 的工作时，发现即使使用了事务性的 fixtures，数据库在测试运行后也没有完全保持原始状态。

快速搜索后，我们发现有一些 `before(:all)` 在测试中的用法，然后将其替换为 [`before_all`](https://test-prof.evilmartians.io/recipes/before_all) —— 原始 RSpec hook 的事务性版本。

我们还引入了一个方便（且条件性）的 hook 来重置数据库状态，因此在任何其他尚未修复的分支中工作的开发者可以轻松修复全局状态问题：

```ruby
RSpec.configure do |config|
  config.prepend_before(:suite) do
    # Truncate all tables to make sure we start with a clean slate
    ActiveRecord::Tasks::DatabaseTasks.truncate_all if ENV["CLEAN_DB"]
  end
end
```

还要注意下，我们使用的是纯粹的 Active Record，不涉及第三方数据库清理器。

最后，我们的第二个 PR 让时间进一步减少到了 **21 分钟** （提醒一下，在第一步之后，我们是 33 分钟，而最初是 53 分钟！）

但我们并没有就此止步......我们继续进行更精细的优化。

## PR #3: Optimizing specific test files

在上一节中，我们已经介绍了 TestProf 的杀手级功能之一 `before_all`，但真正的*强大*之处在于它的兄弟 [`let_it_be`](https://test-prof.evilmartians.io/recipes/let_it_be)。`let_it_be` helper 的工作方式与 `let！` 类似（从使用的角度来看），但性能差异很大 —— 数据创建一次，然后由文件（或在 RSpec context 中）的所有测试用例重用。因此，我们可以将 `let_it_be` 视为*local fixture* 。

迁移到 `let_it_be` 必须逐个文件完成。如何确定从何处开始此迁移，以及首先选择哪个文件？

为此，TestProf 提供了一个名为 [RSpecDissect](https://test-prof.evilmartians.io/profilers/rspec_dissect) 的特定分析器。它显示了测试在 `let`/`let！` 和 `before(:each)` 声明中花费了多少时间：

```bash
Top 10 slowest suites (by `let` time):


HiringRequisition (./spec/models/hiring_requisition_spec.rb:5) – 00:04.126 (378 / 59) of 00:05.019 (82.21%)

...
```

下面的测试报告显示，`let` 表达式占用了 `spec/models/hiring_requisition_spec.rb` 文件大约一半的运行时间。来看看我们是如何重构它的！

…不过，在进行任何重构之前，我们通过 FactoryProf 捕获其 factory 分析来记录测试文件的当前状态。我们捕获的初始统计数据如下：

```bash
$ FPROF=1 rspec spec/models/hiring_requisition_spec.rb

Total time: 00:03.368 (out of 00:07.064)

  name                    total   top-level     total time

  user                      237         109        3.8929s
  office_location            86          41        2.3305s

  ...
```

现在，无需深入讨论这些信息告诉了什么，看看我们如何重构测试：

```diff
- let(:office_location) { create(:office_location, territory: create(:territory)) }
+ let_it_be(:default_user) { create_default(:user) }
+ let_it_be(:office_location) { create(:office_location, territory: create(:territory)) }
```

发生了什么变化？首先，我们将 `let` 替换为 `let_it_be`，以确保在整个测试文件中只创建 `office_location` 记录一次。此外，我们还应用了 [`create_default` 优化 ](https://test-prof.evilmartians.io/recipes/factory_default)，这使我们能够在所有需要 `user` 关联的 factory 生成的对象中重用 user 记录。

为了衡量更改的效果，我们再次运行 FactoryProf 并得到以下结果：

```bash
FPROF=1 rspec spec/models/hiring_requisition_spec.rb

Total time: 00:01.039 (out of 00:04.341)

  name                    total   top-level     total time

  office_location            11          11        0.1609s
  ...
```

如你所见，总时间减少了 3 秒 （~50%），factory 时间从 3 秒减少到 1 秒——对于单个文件更改来说还不错！

我们继续将 `let_it_be` / `create_default` 重构方式应用于其他文件，在接近几十个文件（数百个文件中）的调整后，我们达到了令人满意的 **11 分钟** 。

总而言之，我们的三个优化步骤帮助我们在两周内将测试速度提高了 **~5 倍** （从 53 分钟到 11 分钟）。你觉得怎么样？如果你在慢测试方面需要帮助，请随时与我们联系！
