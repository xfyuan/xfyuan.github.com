---
layout: post
title: 领域驱动，必有勇夫
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, ddd, 37signals]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20230404.jpeg"
rating: 4
---

_本文已获得原作者（**Jorge Manrubia**）和 [37signals](https://37signals.com/) 授权许可进行翻译。原文描述了在领域驱动设计中，对于如何选择代码“遣词造句”的思考。_

- 原文链接：[Domain driven boldness](https://dev.37signals.com/domain-driven-boldness/)
- 作者：Jorge Manrubia（[Github](https://github.com/jorgemanrubia)、[Twitter](https://twitter.com/jorgemanru/)），居住于西班牙瓦伦西亚，目前工作于 37signals，诸多 Ruby、Rails 的 Gem/Library 的作者，比如：[Active Record Encryption](https://github.com/rails/rails/pull/41659)（已被纳入 Rails 7 成为默认特性）、[mass_encryption](https://github.com/basecamp/mass_encryption)、[console1984](https://github.com/basecamp/console1984)、[audits1984](https://github.com/basecamp/audits1984)、[ib_ruby_proxy](https://github.com/jorgemanrubia/ib_ruby_proxy)、[impersonator](https://github.com/jorgemanrubia/impersonator)、[turbolinks_render](https://github.com/jorgemanrubia/turbolinks_render) 等
- 站点：37signals 以创建了 [Basecamp](https://basecamp.com/) 和 [HEY](https://www.hey.com/) 而举世闻名，也撰写了很多商业和软件相关的书籍（[Getting Real](https://www.amazon.com/Getting-Real-Smarter-Successful-Application/dp/0578012812), [REWORK](https://bookshop.org/books/rework-9780307463746/9780307463746), [REMOTE](https://bookshop.org/books/remote-office-not-required/9780804137508), [It Doesn’t Have to Be Crazy at Work](https://bookshop.org/books/it-doesn-t-have-to-be-crazy-at-work/9780062874788), 以及 [Shape Up](https://basecamp.com/shapeup)），更创造了著名的 [Ruby on Rails](https://rubyonrails.org/) 框架。

_【全文如下】_

### 引言

如何创建一个好的领域模型是许多书籍的主题，但我从 37signals 学到的是：不要保守，加倍大胆。

### 正文

当我三年前在 37signals 开始工作的时候，最先做的事情里，其中一件是把 [Basecamp](https://basecamp.com/) 的 git 代码库 clone 下来。我探索了一下，最后看到了这个方法：

```ruby
module Person::Tombstonable
  …
  def decease
    case
    when deceasable?
      erect_tombstone
      remove_administratorships
      remove_accesses_later
      self
    when deceased?
      nil
    else
      raise ArgumentError, "an account owner cannot be removed. You must transfer ownership first"
    end
  end
end
```

这表示在 Basecamp 的一个 person 有一个 [delegate type attribute](https://github.com/rails/rails/pull/39341)，代表它的特定类型（比如，User 或 Client）。当你从给定 account 移除一个 person，Basecamp 就用一个占位符替换它，这样它所关联的数据就保持不动且功能不受影响。

那时我很熟悉 [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html) 和代码重构领域概念的重要性，但还从未见过其理论如此有意地被用于实际。我本来预计的写法是在移除时用一个占位符来替换一个 person 之类的东西，但在一个 person “死亡”时“竖起墓碑”的用词显然要好得多。

从客观的角度，这种用语更传神、清晰和简洁。从主观的角度看：它有了一个大胆的构成，犹如有了个性或者说灵魂。代码也可以有这样的东西吗？它可以，而且，如果做得好的话，这会是一个相当大的提升。对我而言，这是一个顿悟的时刻。

让我来展示另一个例子，[HEY screening system](https://dev.37signals.com/domain-driven-boldness/__www.hey.com_features_the-screener_)。在内部，系统看起来类似于这样：_users_ 检查发送邮件的联系人所请求的 _clearance petitions_【许可申请】。

![img](https://dev.37signals.com/assets/images/domain-driven-boldness/clearance-petitions.png)

再一次，我发现了大胆的构成。一个 _petition_ 跟一个 _request_ 是有区别的，因为它暗示了其正式性。HEY 中的 Screening 在设计上是很正式的：没有你的允许，别人不能获取你邮箱中的邮件。_petitioner_【申请人】的 _clearance petition_【许可申请】必须得到 _examiner_【审查员】的批准，这是一种向另一个人解释系统正在做什么的清晰方式，而这正是代码所映射的：

```ruby
class Contact < ApplicationRecord
  include Petitioner
   …
end

module Contact::Petitioner
  extend ActiveSupport::Concern

  included do
    has_many :clearance_petitions, foreign_key: "petitioner_id", class_name: "Clearance", dependent: :destroy
  end
   …
end

class User < ApplicationRecord
  include Examiner
end

module User::Examiner
  extend ActiveSupport::Concern

  included do
    has_many :clearances, foreign_key: "examiner_id", class_name: "Clearance", dependent: :destroy
  end

  def approve(contacts)
    …
  end

  …
end
```

这种 concerns 的用法让我想起了 [DCI architectural pattern](https://en.wikipedia.org/wiki/Data,_context_and_interaction) 中的角色。DCI 是那些充满有趣想法的提案之一，这些想法往往不能很好地转化为代码。这种 concerns 的使用是一种非常实用的角色实现。

在构建一个非一般的模型时，我最喜欢的工具是写一个纯文本的描述。当我为 HEY 改进邮件分析系统时，给自己写了写了一篇关于新领域模型看起来怎样的笔记。如下所示，你可以看到这篇笔记（上）和我在系统构建完成的 PR 中所包含的描述（下）。笔记的内容与其准确性并不相关——对我来说，书写是一种思考工具——在思考复杂系统时，纯文本是一个绝好的起点。一本字典是做这种事情的好伴侣。

![img](https://dev.37signals.com/assets/images/domain-driven-boldness/domain-model-1.png)

![img](https://dev.37signals.com/assets/images/domain-driven-boldness/domain-model-2.png)

从第一个代码提交以来，HEY 和 Basecamp 都在领域驱动设计上下了很大的功夫。当然，这并不意味其每个角落都耀眼和完美，但总的来说，阅读它们的代码是一种乐趣。如何创建一个好的领域模型是许多书籍的主题，而我在这里学到的是：不要保守，加倍大胆。
