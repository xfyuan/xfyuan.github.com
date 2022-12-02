---
layout: post
title: 在Rails中尽早碾碎N+1查询
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, rspec, minitest]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20201027_125936.jpg"
---

*本文已获得原作者（Vladimir Dementyev）和 Evil Martians 授权许可进行翻译。原文介绍了 对于 Rails 中经典的 N+1 问题，我们通常使用的 Bullet 的局限性，以及如何运用 [n_plus_one_control](https://github.com/palkan/n_plus_one_control) 以测试的方式来尽早发现 N+1 查询。*

- 原文链接：[Squash N+1 queries early with n_plus_one_control test matchers for Ruby and Rails](https://evilmartians.com/chronicles/squash-n-plus-one-queries-early-with-n-plus-one-control-test-matchers-for-ruby-and-rails)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

**发现一种面向测试的替代方案，在开发中的冗余数据库调用之前，就检测你的 Rails 和纯 Ruby 应用程序中的 N+1 查询问题。[n_plus_one_control](https://github.com/palkan/n_plus_one_control) gem 的工作方式与 Bullet 等众所周知的工具不同，能确保额外的 SQL 查询永远不被忽略，且与你对 ORM 工具的选择无关。**

*我假定本文读者是了解 N+1 查询问题的。如果不是，可从我们的一篇[介绍文章](https://evilmartians.com/chronicles/fighting-the-hydra-of-n-plus-one-queries)开始，该文展示了 Evil Martians 更早开发的另一个测试工具。*

每个使用 ORM（如 Active Record）与数据库进行工作的后端 Ruby 开发者都知道：需要小心你的数据库查询，以免生成太多 Query。即使 N+1 问题众所周知，但我们仍然不可能每次都比 ORM 聪明：即我们需要一种自动化方式来指明问题。

在过去三年，我一直使用自己的小工具尽可能在更早的场合下就检测到 N+1 问题：在运行 RSpec 或 Minitest 的时候。我的 [n_plus_one_control](https://github.com/palkan/n_plus_one_control) gem 一直在缓慢地逐步完善，最近来到了 [0.5.0](https://github.com/palkan/n_plus_one_control/releases/tag/v0.5.0) 版本，因此我觉得是时候向各位展示它，以及我的解决方案与其他常见工具的不同之处了。

## Biting the bullet

你可能想知道已经有了 [Bullet](https://github.com/flyerhzm/bullet) gem 为什么我还要创建另一个库来检测 N+1 问题呢？让我来分享一个小故事。

我已使用 Bullet 许多年了：首先，是在开发环境和 staging 环境中，像我们大多数人一样。但在某个时候，我意识到测试环境更适合用来检测和防止 N+1 问题。通过一些小修小补，让 Bullet 在测试环境下工作起来是可行的。如下代码示例创建了一个可用于 spec 的`bulletify`帮助方法。

```ruby
# spec/shared_contexts/bulletify.rb
RSpec.shared_context "bullet" do
  before(:each) do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.raise = true # raise an error if N+1 query occurs
    Bullet.start_request
  end

  after(:each) do
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
    Bullet.enable = false
    Bullet.bullet_logger = false
    Bullet.raise = false
  end
end

RSpec.configure do |config|
  config.include_context "bullet", bullet: true
  config.alias_example_to :bulletify, bullet: true
end

# spec/controllers/my_controller_spec.rb
context "N+1" do
  bulletify { get :index }
end
```

然而在多个成熟的 Rails 应用程序的工作中，我发现当数据库交互超越 Active Record 及其关联关系时，Bullet 并不能发现问题。[False positives](https://github.com/flyerhzm/bullet/issues?q=is%3Aissue+is%3Aopen+false+positive) 也是相当的常见。

这有一个范例，使用了上面的`bulletify`方法：

```ruby
# user.rb
class User < ApplicationRecord
  has_many :teams

  def supports?(team_name)
    teams.where(name: team_name).exists?
  end
end
```

```erb
<!-- users/index.html.erb -->
<% @users.each do |user| %>
  <li class="<%= user.supports?("FC Spartak Moscow") && "red-white" %>">
    <%= user.name %>
  </li>
<% end %>
```

```ruby
# users_controller_spec.rb
describe "GET #index" do
  render_views

  let!(:users) { create_pair(:user, :with_teams) }

  bulletify { get :index }
end
```

即使我们在这儿明显有了 N+1 查询（来自于`#supports?`方法），测试却仍然是绿色通过的。

## Running and counting

我就开始考虑一种检测 N+1 查询的更健壮的方式，与 Active Record 内部无关的方式。

**而最终我找到了这样的思路：如果我们运行同样的代码两次，以不同数量的数据库记录，并比较所执行 SQL 查询的次数呢？**

如果这个数字不依赖于测试集的大小，我们便没有（N+1）问题。否则，看起来就是有一个 *XN+Y* 了。

这个想法在 [n_plus_one_control](https://github.com/palkan/n_plus_one_control) gem 中得以实现，它为你所选择的 Ruby 测试框架添加 N+1 检测的 DSL。下面是 RSpec 的示例：

```ruby
context "N+1", :n_plus_one do
  # Populate block is called multiple times
  # with different values of n (2 and 3 by default)
  populate { |n| create_list(:user, n, :with_teams) }

  specify do
    # The example body is executed
    #after each `populate` call
    expect { get :index }.to perform_constant_number_of_queries
  end
end
```

而测试将以如下消息报失败：

```bash
Expected to make the same number of queries, but got:
  3 for N=2
  4 for N=3
```

## Search and destroy N+1 violations

[最新版本](https://github.com/palkan/n_plus_one_control/releases/tag/v0.5.0)中，我把重点放在了开发体验上，帮助开发者不仅检测 N+1 问题，还能方便地在大型应用程序中找到惹出问题的“元凶”。

当处理优化工作时，我认识到仅仅拥有测试因 N+1 而报失败是不够的（能知道这问题的存在要感谢性能监测系统）。所以，我已经开始为这个 gem 添加新的特性，即以如下计划发现 N+1 问题：

### Step 1: Write a test that fails

创建一个好的性能测试可不容易。我们需要所涉及的数据，各种设置，来覆盖多数代码路径，这样才不会遗失任何不期望的数据库交互。比如：

```ruby
# This example uses Minitest
class PerformanceTest < ApplicationIntegrationTestCase
  def populate(scale_factor)
    scale_factor.times do
      # Here, I'm not using create_list but introducing some
      # randomness instead.
      # That would make our setup less deterministic
      # (and, thus, test more valuable)
      create(:resource, :with_tags, tags_num: [0, 1, 2].sample)
    end
    create_list(:document, scale_factor)
  end

  test "should not produce N+1 queries" do
    assert_perform_constant_number_of_queries do
      get :index
    end
  end
end
```

输出看起来会是这样：

```bash
Expected to make the same number of queries, but got:
  10 for N=2
  11 for N=3
Unmatched query numbers by tables:
  resources (SELECT): 2 != 3
  permissions (SELECT): 4 != 6
```

**注意：**即使我们没有看到上面的*`documents`* 列表，也不要移除设置中的这个部分：N+1 问题可能会在将来遇到，所以我们应该做好准备。

### Step 2: Localize the problem

根据上面的错误信息，我们可以看到有两个影响到的表。让我们通过使用查询筛选的特性，来对每个测试单独重新运行。我们也可启用明细输出模式以获得所收集到的查询列表及其来自哪里：

```bash
$ NPLUSONE_VERBOSE=1 \
  NPLUSONE_FILTER=resources \
  bundle exec rails test

Expected to make the same number of queries, but got:
  2 for N=2
  3 for N=3
Unmatched query numbers by tables:
  resources (SELECT): 2 != 3
Queries for N=2
   SELECT "resources".* FROM "resources" WHERE "resources"."deleted_at" IS NULL
   ↳ app/controllers/resources_controller.rb:32:in `index'
   ...
Queries for N=3
   ...
```

再重复第二个表的：

```bash
$ NPLUSONE_VERBOSE=1 \
  NPLUSONE_FILTER=permissions \
  bundle exec rails test

Expected to make the same number of queries, but got:
  4 for N=2
  6 for N=3
Unmatched query numbers by tables:
  permissions (SELECT): 4 != 6
Queries for N=2
  SELECT "permissions".* FROM "permissions" WHERE "permissions.user_id" = 42 AND "permissions.resource_id" = 15 AND "permissions.grants" @> '{manage}'
  ↳ app/policies/resource_policy.rb:41:in `update?'
  SELECT "permissions".* FROM "permissions" WHERE "permissions.user_id" = 42 AND "permissions.resource_id" = 15 AND "permissions.grants" @> '{invite}'
  ↳ app/policies/resource_policy.rb:56:in `invite?'
  ...
Queries for N=3
  ...
```

有时，查询会太长，让我们的输出难以阅读。那么我们可以通过设置`NPLUSONE_TRUNCATE`环境变量只显示查询的前 N 个字符。

还有，仅显示堆栈的单独一行可能没那么有用。不用担心！你可以通过`NPLUSONE_BACKTRACE`变量来增加堆栈行数显示的数量。

因此，最终的命令看起来会是这样：

```bash
NPLUSONE_VERBOSE=1 \
NPLUSONE_FILTER=permissions \
NPLUSONE_TRUNCATE=100 \
NPLUSONE_BACKTRACE=5 \
bundle exec rails test
```

总结一下，通过[n_plus_one_control](https://github.com/palkan/n_plus_one_control)，你可以通过编写测试并以不同参数运行多次来快速识别出任何一种 N+1 查询的根源。而在你修复所有这些问题后，这种检测就成为一种回归测试——阻止你的代码在将来再出问题的测试！

