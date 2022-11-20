---
layout: post
title: 纯粹的Rails便已足够
author: Mr.Z
categories: [ Translation, Programming ]
tags: [ruby, rails]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20221117.jpeg"
rating: 5
---

*本文已获得原作者（**Jorge Manrubia**）和 [37signals](https://37signals.com/) 授权许可进行翻译。原文讲述了在 37signals 公司中如何使用纯粹 Rails应用架构方案，及其怎样在另一个层面对 DDD（领域驱动设计） 原则做出最佳体现的故事。*

- 原文链接：[Vanilla Rails is plenty](https://dev.37signals.com/vanilla-rails-is-plenty)
- 作者：Jorge Manrubia（[Github](https://github.com/jorgemanrubia)、[Twitter](https://twitter.com/jorgemanru/)），居住于西班牙瓦伦西亚，目前工作于 37signals，诸多 Ruby、Rails 的 Gem/Library 的作者，比如：[Active Record Encryption](https://github.com/rails/rails/pull/41659)（已被纳入 Rails 7 成为默认特性）、[mass_encryption](https://github.com/basecamp/mass_encryption)、[console1984](https://github.com/basecamp/console1984)、[audits1984](https://github.com/basecamp/audits1984)、[ib_ruby_proxy](https://github.com/jorgemanrubia/ib_ruby_proxy)、[impersonator](https://github.com/jorgemanrubia/impersonator)、[turbolinks_render](https://github.com/jorgemanrubia/turbolinks_render) 等
- 站点：37signals 以创建了 [Basecamp](https://basecamp.com/) 和 [HEY](https://www.hey.com/) 而举世闻名，也撰写了很多商业和软件相关的书籍（[Getting Real](https://www.amazon.com/Getting-Real-Smarter-Successful-Application/dp/0578012812), [REWORK](https://bookshop.org/books/rework-9780307463746/9780307463746), [REMOTE](https://bookshop.org/books/remote-office-not-required/9780804137508), [It Doesn’t Have to Be Crazy at Work](https://bookshop.org/books/it-doesn-t-have-to-be-crazy-at-work/9780062874788), 以及 [Shape Up](https://basecamp.com/shapeup)），更创造了著名的 [Ruby on Rails](https://rubyonrails.org/)  框架。

*【正文如下】*

## 引言

对 Rails 一个常见的指责就是它鼓励了对关注点做很少的分离。这样当事态变得严重时，你就需要一个替代方案来弥补缺失的拼图。但我们不同意这点。

我经常听到这样的话：纯粹的 Rails 只能把你带到这里了，某种角度上，应用已经变得难以维护了，你需要一个不同的方案来弥补缺失的拼图，因为 Rails 在架构层面鼓励的是对关注点做很少的分离。

开创性的[领域驱动设计（DDD）书](https://www.oreilly.com/library/view/domain-driven-design-tackling/0321125215/)中讨论了这四种概念上的层级：presentation（呈现层）、application（应用层）、domain（领域层）、和 infrastructure（基础设施层）。应用层与领域层协调工作一起实现业务需求。但 Rails 只提供了 *controllers* 和 *models*：models 通过 Active Record 包含了持久化，而且 Rails 鼓励从 controllers 中直接访问它们。批评者指责道，应用层、领域层和基础设施层就不可避免地合并到一起，形成了 fat models（胖 model）的混乱局面。事实上，替代方案总是会包含进额外的东西，例如在应用层上包含进 services 或 use case interactors，以及在基础设施层上包含进 repositories。

我发现这种讨论具有迷惑性，因为在 [37signals](https://37signals.com/) 这儿，我们既推崇纯粹的 Rails，也推崇领域驱动设计。我们并未在发展进化自己的应用时陷入上述的维护性问题，所以这里我想讨论下我们是如何组织自己的应用的代码。

## We don’t distinguish application and domain layers

我们不区分应用层和领域层的。相反，我们有一套领域模型（Active Record 和 POROs【译者注：指 Plain Old Ruby Object】），它们暴露出公共接口，可以从系统边界去调用，典型的是 controllers 或 jobs。从架构上讲，我们不把 API 从 领域模型上进行分离。

我们关心很多的是如何设计这些模型和其所暴露的 API，我们发现在额外的层上去协调对它们的访问并没有太多价值。

换句话说，我们默认并不会去创建 services、actions、commands、或 interactors 以实现 controllers 的行为。

## Controllers access domain models directly

对于简单场景，我们觉得从 controllers 进行 CRUD 访问的做法很好。例如，下面是我们在 Basecamp 中如何为 messages 和 comments 创建 boosts 的：

```ruby
class BoostsController < ApplicationController
  def create
    @boost = @boostable.boosts.create!(content: params[:boost][:content])
  end
```

但更常见的是，我们通过领域模型所暴露出的方法来进行这些访问。例如，下面是 HEY 中的 controller 对一个给定联系人来选择所期望的 box：

```ruby
class Boxes::DesignationsController < ApplicationController
  include BoxScoped

  before_action :set_contact, only: :create

  def create
    @contact.designate_to(@box)

    respond_to do |format|
      format.html { refresh_or_redirect_back_or_to @contact, notice: "Changes saved. This might take a few minutes to complete." }
      format.json { head :created }
    end
  end
```

我们的大多数 controllers 都使用这种做法来直接访问 models：一个 model 暴露出一个方法，然后 controller 执行它。

## Rich domain models

与贫血领域模型相反，我们的方案是鼓励构建富（rich）领域模型。我们把领域模型视为应用的 API且，作为一个指导性设计原则，我们希望它尽可能合乎自然。

因为我们喜欢通过领域模型来访问业务逻辑，所以一些核心领域实体最终提供了许多功能。那么我们如何避免那些跟可怕的胖模型问题相关的问题呢？有两种策略：

- 使用 concerns 来组织 model 的代码
- 把功能委托到额外的对象系统上（使用单纯的面向对象编程）

我会用一个范例来说明这点。在 Basecamp 中有一个核心领域实体叫`Recording`。而 Basecamp 里一个用户管理的大部分元素都是 recordings——其初始的用例场景，推动促进了 [Rails 的委托类型](https://api.rubyonrails.org/classes/ActiveRecord/DelegatedType.html)。

你可以使用 recordings 做很多事，包括把它们拷贝到其他地方，或者焚毁它们。“焚毁”是我们对于“好的数据删除方式”所使用的术语。对于调用者——比如 controller 或 job——我们期望提供合乎自然的 API：

```ruby
recording.incinerate
recording.copy_to(destination_bucket)
```

但是，在其内部，焚毁数据和拷贝则是完全不同的职责，所以我们使用 concerns 来捕获各自：

```ruby
class Recording < ApplicationRecord
  include Incineratable, Copyable
end

module Recording::Incineratable
  def incinerate
    # ...
  end
end

module Recording::Copyable
  extend ActiveSupport::Concern

  included do
    has_many :copies, foreign_key: :source_recording_id
  end

  def copy_to(bucket, parent: nil)
    # ...
  end
end
```

如果你感兴趣的话，我曾经写过一篇关于[如何使用 concerns 的文章在这里](https://world.hey.com/jorge/code-i-like-iii-good-concerns-5a1b391c)。

现在，焚毁和拷贝都是所涉及的操作。`Recording`并非是一个实现它们的好地方。相反，它把这工作委托给额外的对象系统。

对于焚毁，`Recording::Incineratable`创建并执行`Recording::Incineration`，后者包含了焚毁一条 recording 的业务逻辑：

```ruby
module Recording::Incineratable
  def incinerate
    Incineration.new(self).run
  end
end
```

对于拷贝，`Recording::Copyable`创建一条新的`Copy`记录：

```ruby
module Recording::Copyable
  extend ActiveSupport::Concern

  included do
    has_many :copies, foreign_key: :source_recording_id
  end

  def copy_to(bucket, parent: nil)
    copies.create! destination_bucket: bucket, destination_parent: parent
  end
end
```

这里，事情更复杂一些了：`Copy`是`Filing`的 child。`Filing`是一个对 *copy* 和 *move* 操作而言两者共有的父类。当一个 filing 被创建时，它把一个 job 排入队列，并最终执行其`#process`方法。这个方法又执行`file_recording`，一个[模板方法](https://en.wikipedia.org/wiki/Template_method_pattern)，由其子类所实现。当实现那个方法时，`Copy`创建一个`Recording::Copier`实例以实施拷贝。

```ruby
module Recording::Copyable
  extend ActiveSupport::Concern

  included do
    has_many :copies, foreign_key: :source_recording_id
  end

  def copy_to(bucket, parent: nil)
    copies.create! destination_bucket: bucket, destination_parent: parent
  end
end

class Copy < Filing
  private
    def file_recording
      Current.set(person: creator) do
        Recording::Copier.new(
          source_recording: source_recording,
          destination_bucket: destination_bucket,
          destination_parent: destination_parent,
          filing: self
        ).copy
      end
    end
end

class Filing < ApplicationRecord
  after_create_commit :process_later, unless: :completed?

  def process_later
    FilingJob.perform_later self
  end

  def process
    # ...
    file_recording
    # ...
  end
end
```

这个例子不像焚毁操作那样简单，但其原则是相同的：富内部对象模型隐藏于更高层级的领域模型 API 之后。这并不意味着我们总是创建额外的类来实现 concerns，绝非如此，但当复杂性证明了这一点值得时我们就会这样做。

利用 concerns，使得拥有大型 API 表层的类的方案是有效可行的。如果你在考虑单一职责原则（SRP），就像 Michael Feathers 在 [Working effectively with Legacy code](https://www.oreilly.com/library/view/working-effectively-with/0131177052/) 中说的那样，你必须区分是在接口层还是在实现层违反 SRP：

> *The SRP violation we care more about is violation at the implementation level. Plainly put, we care whether the class really does all of that stuff or whether it just delegates to a couple of other classes. If it delegates, we don’t have a large monolithic class; we just have a class that is a facade, a front end for a bunch of little classes and that can be easier to manage.*

在上面的示例中，并没有胖模型去负责做太多的事情。`Recording::Incineration` 或者 `Recording::Copier` 都是只做一件事的内聚式的类。`Recording::Copyabl` 加入了一个高级别的`#copy_to` 方法到 `Recording` 的公共 API，并保持其相关的代码和数据定义跟其他`Recording`的职责相分离。还有，注意下它是如何使用 Ruby 实现良好的、老派的面向对象：继承，对象组合，以及简单的设计模式。

最后要提醒的是，有人可能会争论说这三者是相等的：

```ruby
recording.incinerate
Recording::Incineration.new(recording).run
Recording::IncinerationService.execute(recording)
```

我们不认为如此：我们强烈推荐选择第一种形式。一方面，它在隐藏复杂性方面做得更好，因为它不会将组合的负担转移到代码的调用方，另一方面，它感觉更合乎自然，就像单纯的英语，这更“Ruby”。

## What about services?

DDD 的构筑砖石之一是 *services*，它旨在“捕获在领域实体或价值对象中找不到自然归属的重要领域操作”。

我们并不把 services 作为 DDD 意义上的架构构件的一等公民（无状态，以动词命名），但我们有许多用于封装操作的类。我们把它们不叫做 services，而它们也并无特殊待遇。我们通常更喜欢将它们作为领域模型来展示，这些模型暴露所需的功能，而不是使用单纯的程序语法来执行操作。

例如，下面是 Basecamp 中通过邀请 tokens 来注册一个新用户的代码：

```ruby
class Projects::InvitationTokens::SignupsController < Projects::InvitationTokens::BaseController
  def create
    @signup = Project::InvitationToken::Signup.new(signup_params)

    if @signup.valid?
      claim_invitation @signup.create_identity!
    else
      redirect_to invitation_token_join_url(@invitation_token), alert: @signup.errors.first.message
    end
  end
end

class Project::InvitationToken::Signup
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :name, :email_address, :password, :time_zone_name, :account

  validate :validate_email_address, :validate_identity, :validate_account_within_user_limits

  def create_identity!
    # ...
  end
end
```

所以我们不是用`SigningUpService`来负责“注册”的领域操作，而是用`Signup` 类让你来校验和创建一个应用中的身份（identity）。有人会争论说这只是一点点的语法糖而不是 service，甚至只是一个表单对象。但我所看到的是，它只是一个单纯的 Ruby 面向对象，在代码层面赋予了领域概念而给以适当的描述而已。

还有，我们并不太注意区分领域模型是否持久化（Active Record 或 PORO）。从业务逻辑消费者的角度看，这是无关紧要的，所以我们在代码上不去紧抠领域实体和价值对象的差别。于我们而言，它们都是领域模型。你可以在我们的`app/models`目录中找到很多 POROs。

## The dangers of isolating the application layer

我关于隔离应用层的思想的主要疑问是，人们经常走得太远了。

最早的 DDD 书中对滥用 services 提出了警告：

> *Now, the more common mistake is to give up too easily on fitting the behavior into an appropriate object, gradually slipping towards procedural programming.*

而你也可以在  [Implementing Domain Driven Design](https://www.amazon.com/Implementing-Domain-Driven-Design-Vaughn-Vernon/dp/0321834577/ref=sr_1_1?keywords=implementing+domain+driven+design&qid=1667229833&qu=eyJxc2MiOiIxLjM4IiwicXNhIjoiMC45OCIsInFzcCI6IjAuOTcifQ%3D%3D&sr=8-1&ufe=app_do%3Aamzn1.fos.006c50ae-5d4c-4777-9bc0-4513d670b6bc) 中找到同样的建议：

> *Don’t lean too heavily toward modeling a domain concept as a Service. Do so only if the circumstances fit. If we aren’t careful, we might start to treat Services as our modeling “silver bullet.” Using Services overzealously will usually result in the negative consequences of creating an Anemic Domain Model, where all the domain logic resides in Services rather than mostly spread across Entities and Value Objects.*

两本书中都讨论了隔离应用层所面临的挑战，其均始于区分领域和应用 services 的细微差别。此外，它们承认大多数分层 DDD 架构都是*宽松的*，有时表现层直接访问领域层。最早的 DDD 书中讲述说让 DDD 得以可用的是*领域层* 的*关键性分离*，注意到了一些项目*没有在用户界面和应用层之间做出明确区分*。

然而，在 Rails 世界里，你经常会看到教条主义的观点，即坚决反对 controllers 直接与 models 对话，将之视为罪大恶极。而是应该有一个中间人在两者之间进行衔接——比如，DDD 概念里的应用 service，或者 [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) 概念中的 interactor。我认为，这些并无细微差别的建议会助长以下两种情况的出现：

- 大量的样板代码，因为很多应用层元素都仅仅是把操作委托给领域实体。别忘了，应用层不应该包含业务规则，它只是协作并把工作委托给该层之下的领域对象。
- [贫血领域模型](https://martinfowler.com/bliki/AnemicDomainModel.html)，其中的应用层元素去实现业务规则，而领域模型变成了携带数据的空壳。

这些方案通常被视为解决一个异常复杂的问题——如何正确设计软件——的[难以权衡的答案](https://world.hey.com/jorge/no-silver-buckets-84d249d5)。它们通常暗示，好的架构是使用了一整套分离原型的结果，这不仅非常幼稚，而且对缺乏经验的观众来说也非常有误导性。我希望，我在本文提出的替代方案能引起人们的共鸣，让他们寻找更务实的替代方案。

## Conclusions

在我们的经验里，这种利用纯粹 Rails 的方案得到的是具有可维护性的大型 Rails 应用。最近的一个范例，我们刚刚在 Basecamp 3 基础上所构建的 [Basecamp 4](https://basecamp.com/new)，其代码库有将近 9年了，包含 400 个 controllers、500 个 models，每天为上百万的用户服务。我不知道我们的方案是否适用于 Shopify，但我确信对大多数使用 Rails 的企业来说都是适用的。

我们的方案反映了 Rails 宗旨的其中一个支柱：[*没有范式*](https://rubyonrails.org/doctrine#no-one-paradigm)。我喜爱架构模式，但我们业界的一个反复出现的问题就是把其应用于代码中时太过教条了。我想这原因在于在处理像软件开发这样复杂的问题时，简单而严格的“菜谱”就非常有吸引力。37signals 的代码是我的职业生涯中所见过最好的，我是作为一名观众来这么说，因为其中大部分代码都不是我写的。特别是，它是我见过的 DDD 原则的最佳体现，即使它并没有用到其中大部分构筑的砖石。

所以，如果你曾经放弃了纯粹的 Rails 路线，而现在想知道在处理一些屏幕交互时，自己是否真的需要那些额外的样板类，请确信是有一种替代方案的，它不会损害你的应用的可维护性。它不会阻止你了解如何编写软件——并非别无选择——但它可能会让你再次回到快乐之地。

感谢 *[Jeffrey Hardy](http://quotedprintable.com/)* 在我撰写此文时给出了极有价值的建议。他是纯粹 Rails应用架构方案（我仍在学习并极为喜爱）的主要贡献者之一

