---
layout: post
title: Good concerns
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, ddd, 37signals]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img2023061601.jpeg"
rating: 4
---

_本文已获得原作者（**Jorge Manrubia**）和 [37signals](https://37signals.com/) 授权许可进行翻译。原文描述了在大型代码库中使用 Concern的一些设计原则。_

- 原文链接：[Domain driven boldness](https://dev.37signals.com/domain-driven-boldness/)
- 作者：Jorge Manrubia（[Github](https://github.com/jorgemanrubia)、[Twitter](https://twitter.com/jorgemanru/)），居住于西班牙瓦伦西亚，目前工作于 37signals，诸多 Ruby、Rails 的 Gem/Library 的作者，比如：[Active Record Encryption](https://github.com/rails/rails/pull/41659)（已被纳入 Rails 7 成为默认特性）、[mass_encryption](https://github.com/basecamp/mass_encryption)、[console1984](https://github.com/basecamp/console1984)、[audits1984](https://github.com/basecamp/audits1984)、[ib_ruby_proxy](https://github.com/jorgemanrubia/ib_ruby_proxy)、[impersonator](https://github.com/jorgemanrubia/impersonator)、[turbolinks_render](https://github.com/jorgemanrubia/turbolinks_render) 等
- 站点：37signals 以创建了 [Basecamp](https://basecamp.com/) 和 [HEY](https://www.hey.com/) 而举世闻名，也撰写了很多商业和软件相关的书籍（[Getting Real](https://www.amazon.com/Getting-Real-Smarter-Successful-Application/dp/0578012812), [REWORK](https://bookshop.org/books/rework-9780307463746/9780307463746), [REMOTE](https://bookshop.org/books/remote-office-not-required/9780804137508), [It Doesn’t Have to Be Crazy at Work](https://bookshop.org/books/it-doesn-t-have-to-be-crazy-at-work/9780062874788), 以及 [Shape Up](https://basecamp.com/shapeup)），更创造了著名的 [Ruby on Rails](https://rubyonrails.org/) 框架。

_【全文如下】_

### 引言

我们喜欢 Conern，并且多年来一直在大型代码库中使用它们。这里分享下我们使用它们的一些设计原则。

### 正文

多年来，Rails Concern 受到了很多批评。它们是所有问题的解决方案，还是要不惜一切代价避免的东西？我认为 Concern 的一个问题是你可以随心所欲地使用它，所以毫不奇怪，你在这样做时会搬起石头砸自己的脚。

毕竟，Concern 只是 Ruby mixins：以一些语法糖来删除常见的样板代码。

37signals 在大型 Rails 代码库中使用它们有多年的经验，所以我想在这篇文章中聊聊一些设计原则。

## Where to put concerns

Ruby mixins 通常作为多重继承的替代方案呈现：跨类的代码重用机制。我们以这种方式使用一些 Concern，但我们使用它们的最常见情况是在单个 Model 中组织代码。我们对每种情况使用不同的约定：

- 对常见的 Model Concern：我们将它们放在 `app/models/concerns` 中。
- 对于特定于 Model 的 Concern：我们将它们放在与 model 名称匹配的文件夹中： `app/models/<model_name>` 。

例如，下面是来自 Basecamp 的特定于 Model 的 Concern 的示例：

```ruby
# app/models/recording.rb
class Recording < ApplicationRecord
  include Completable
end

# app/models/recording/completable.rb
module Recording::Completable
  extend ActiveSupport::Concern
end
```

这个约定消除了在包含 Concern 时重复命名空间的需要。

对于 Controller，情况是相反的。我们将大多数 Concern 放在 `controllers/concerns` 文件夹中，有些 Concern 仅适用于放置在以该文件夹命名的子目录中的某个子系统： `controller/concerns/<subsystem>` . 我想在另一篇文章中探讨我们如何处理 Controller。

## Improve readability

对 Concern 的常见批评是[它们会降低可读性](https://www.cloudbees.com/blog/when-to-be-concerned-about-concerns)。我认为情况正好相反。如果使用得当，它们会以两种方式提高可读性：

首先，它们有助于管理复杂性。处理复杂系统的本质是[一遍又一遍地将它们分成更小的部分，这样我们就可以一次专注于一件事](https://world.hey.com/jorge/code-i-like-ii-fractal-journeys-b7688f93)。Concern 是你工具箱中实现这一目标的一个工具。

这里的关键是，每个 Concern 都应该是一个内聚单元，用于捕获宿主模型的特征。换句话说，它们应该只包含归属到一起的东西。

不应将 Concern 视为行为和结构的任意容器，以将大型模型拆分为较小的部分。它们需要含有真正的具备特征或充当语义来工作，就像类继承需要一种关系一样。否则，它们弊大于利。

看看[我过去谈到](https://world.hey.com/jorge/code-i-like-i-domain-driven-boldness-71456476)的 HEY 筛选器中的这个示例。HEY 中的用户充当其他联系人的清理请愿书的审查员，这些联系人希望向他们发送电子邮件：

```ruby
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

  def has_approved?(contact)
    …
  end

  def has_denied?(contact)
    …
  end

  …
end
```

Concern 与许可申请审查员的领域角色相匹配，并且仅包含与该角色相关的代码。这增强了可维护性：任何时候需要管理的概念越少，事情就越容易理解。

其次，Concern 提供了一个额外的抽象来反映领域概念。

下面是 HEY 中 `Topic` 模型包含的 Concern。就像审查员示例一样，请注意大多数名称如何捕获易于掌握的领域概念。它们提供了类似于领域的额外机遇，这对于可读性来说是积极的。

```ruby
class Topic < ApplicationRecord
  include Accessible, Breakoutable, Deletable, Entries, Incineratable, Indexed, Involvable, Journal, Mergeable, Named, Nettable, Notifiable, Postable, Publishable, Preapproved, Collectionable, Recycled, Redeliverable, Replyable, Restorable, Sortable, Spam, Spanning
```

## Enhance, but not replace, rich object models

对 Rails Concern 的一个常见误解是，它们代表了传统面向对象技术的替代方案，例如类继承或组合。看看[这个](https://medium.com/@carlescliment/about-rails-concerns-a6b2f1776d7d)：

> *Business logic is better modeled as abstractions (classes), rather than concerns. Value objects, services, repositories, aggregates or whatever artifact that fits better.*
> 业务逻辑最好建模为抽象（类），而不是 Concern。Value objects, services, repositories, aggregates 或任何更适合的东西。

或者[这个](https://www.cloudbees.com/blog/when-to-be-concerned-about-concerns)：

> *Favor composition 偏爱组合

> I’m not saying you HAVE to put everything in one file. Please, by all means, extract some logic into a custom class and call it.
> 我并不是说你必须把所有东西都放在一个文件中。请务必将一些逻辑提取到自定义类中并调用它。

我认为这是一个错误的二分法。使用 Concern 不会限制或取代正确设计系统的需要。

特别是，你不应使用 Concern 来使 fat 和 flat 的 Active Record models 井井有条，而不去使用具有良好职责分配的适当对象系统。

我知道这是一个关于 Concern 的真正风险，因为我在第一次与它们打交道时就制造了这样的混乱。

37signals 对好且传统的面向对象设计，继承和组合，设计和实现模式等方面很看重，我们的 models 文件夹中到处都是 PORO。 Concern 实际上在这种方案中发挥了巨大作用。让我用一个简单的例子来说明这一点。

在 HEY 中，付费客户会永久保留他们的电子邮件地址，即使他们取消订阅也是如此。

因此，当系统终止帐户时，它会选择完全删除所有数据（焚毁）或仅保留最小集，例如出站转发（清除）。让我展示代码的一些相关部分：

```ruby
class Account < ApplicationRecord
  include Closable
end

module Account::Closable
  def terminate
    purge_or_incinerate if terminable?
  end

  private
    def purge_or_incinerate
      eligible_for_purge? ? purge : incinerate
    end

    def purge
      Account::Closing::Purging.new(self).run
    end

    def incinerate
      Account::Closing::Incineration.new(self).run
    end
end
```

焚毁和清除是共享一些通用代码的复杂操作。所以猜猜我们如何解决这个问题？使用封装操作的额外类和重用公共位的好而传统的继承：

![](https://dev.37signals.com/assets/images/good-concerns/account-closing.webp)

我喜欢这种使用 Concern 在 Model 上提供一个很好的面向领域的 API，从调用者的角度来看隐藏了一个复杂的子系统。如果我们想终止一个帐户，我们可以说：

```ruby
account.terminate
```

而不是更冗长、更不流畅的写法，例如：

```ruby
AccountTerminationService.new(account).run
```

请注意，我们没有一个 fat `Account` 模型负责处理焚毁或清除帐户的所有逻辑。有一个由三个类组成的子系统负责它，而`Account`模型只提供了使用它的大门。

Concern 使这些 API 更简洁、更好看，同时保持 Model 代码井然有序，并且不会牺牲你对系统的设计。

## Conclusions

Concern 是一种工具。我不确定它们是否属于 Rails Doctrine 中的 [sharp](https://rubyonrails.org/doctrine#provide-sharp-knives)，或者它们是否太开放，但如果滥用它们可能会造成麻烦。然而，通过一些简单的指导原则，我认为如果你是 Rails 开发者，它们是一个很好的资源。

Concern 与良好的面向对象设计结合起来是一个甜蜜的组合。当然，Concern 不会消除必须知道如何设计软件的需要。尽管如此，它们仍然是改进代码组织的实用机制，使其更易于理解和维护。

你经常听说普通的 Rails 只能带你走这么远了，所以你需要额外的结构、挽具和约定【才能走得更远】。如果这有用的话，那么去瞅瞅 [Basecamp](https://basecamp.com/) 和 [HEY](https://www.hey.com/) 吧，它们是纯粹的 Rails 应用，使用传统的面向对象和模式，而它们大量使用了 Concern。
