---
layout: post
title: 分形之旅
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, ddd, 37signals]
comments: true
image: "https://dev.37signals.com/assets/images/fractal-journeys/cover.jpg"
rating: 4
---

_本文已获得原作者（**Jorge Manrubia**）和 [37signals](https://37signals.com/) 授权许可进行翻译。原文提出了一个对于好代码应该具备哪些品质的思考。_

- 原文链接：[Fractal journeys](https://dev.37signals.com/fractal-journeys/)
- 作者：Jorge Manrubia（[Github](https://github.com/jorgemanrubia)、[Twitter](https://twitter.com/jorgemanru/)），居住于西班牙瓦伦西亚，目前工作于 37signals，诸多 Ruby、Rails 的 Gem/Library 的作者，比如：[Active Record Encryption](https://github.com/rails/rails/pull/41659)（已被纳入 Rails 7 成为默认特性）、[mass_encryption](https://github.com/basecamp/mass_encryption)、[console1984](https://github.com/basecamp/console1984)、[audits1984](https://github.com/basecamp/audits1984)、[ib_ruby_proxy](https://github.com/jorgemanrubia/ib_ruby_proxy)、[impersonator](https://github.com/jorgemanrubia/impersonator)、[turbolinks_render](https://github.com/jorgemanrubia/turbolinks_render) 等
- 站点：37signals 以创建了 [Basecamp](https://basecamp.com/) 和 [HEY](https://www.hey.com/) 而举世闻名，也撰写了很多商业和软件相关的书籍（[Getting Real](https://www.amazon.com/Getting-Real-Smarter-Successful-Application/dp/0578012812), [REWORK](https://bookshop.org/books/rework-9780307463746/9780307463746), [REMOTE](https://bookshop.org/books/remote-office-not-required/9780804137508), [It Doesn’t Have to Be Crazy at Work](https://bookshop.org/books/it-doesn-t-have-to-be-crazy-at-work/9780062874788), 以及 [Shape Up](https://basecamp.com/shapeup)），更创造了著名的 [Ruby on Rails](https://rubyonrails.org/) 框架。

_【全文如下】_

### 引言

好的代码就是一种分形：你观察到同样的品质在不同的抽象层面不断重复着。

### 正文

分形是在逐渐缩小的尺度上反复出现相似的模式。对我而言，好的代码就是一种分形：你观察到同样的品质在不同的抽象层面不断重复着。

这并不令人惊讶。好的代码是易于理解的，而我们处理复杂性的最佳机制是构建抽象。这把复杂性替换为我们人类易于理解的界面。但我们仍然需要处理他们所带来的复杂性；要做到这一点，我们始终遵循相同的过程：构建隐藏细节的新抽象，并提供更高层级的机制来处理它们。

我使用*抽象*这个词来指代一切：从大型子系统到某些内部类的最后一个私有方法。但你如何构建这些抽象呢？好吧，这是一个价值千金的问题，是无数本书籍的主题。本文中，我想重点专注于四个品质，它们在使代码易于理解方面至关重要：

- 领域驱动：说出问题的领域。
- 封装性：暴露的接口如水晶般清晰，隐藏细节。
- 内聚性：从调用者的视角来看，仅做一件事。
- 对称性：在相同的抽象层级上操作。

因为本文也是，抱歉，抽象的，所以我将以来自 [Basecamp](https://basecamp.com/) 的真实代码进行说明。在好些地方，该产品提供了 [activity](https://3.basecamp-help.com/article/92-the-latest-activity) 和 [timeline](https://3.basecamp-help.com/article/92-the-latest-activity)。这个 timeline 会动态刷新：当你查看它时，如果有人做了某些事，它将会实时更新。

在领域层面，当你在 Basecamp 执行操作时，比如完成待办事项、创建文档、或者发表评论，系统都会创建 *events*，且这些 events 会被*转播*【译注：relay】到好些目的地，比如 activity timeline 或者 webhooks。我们来看看代码。

首先，我们有`Event` model，它包含一个`Relaying` concern（我仅展示相关的部分）：

```ruby
class Event < ApplicationRecord
  include Relaying
end
```

而这个 concern 添加了关联的`relays`和一个 hook 来异步转播 events，当它们被创建的时候：

```ruby
module Event::Relaying
  extend ActiveSupport::Concern

  included do
    after_create_commit :relay_later, if: :relaying?
    has_many :relays
  end

  def relay_later
    Event::RelayJob.perform_later(self)
  end

  def relay_now
    …
  end
end

class Event::RelayJob < ApplicationJob
  def perform(event)
    event.relay_now
  end
end
```

所以`Event#relay_now`就是我们感兴趣的方法了。注意到，它说出了领域语言；从执行它的任务的视角，它只做了一件事；而且在转播一个 event 所需的一切都在这里被隐藏起来。让我们来深入研究下这个方法：

```ruby
module Event::Relaying
    def relay_now
        relay_to_or_revoke_from_timeline

        relay_to_webhooks_later
        relay_to_customer_tracking_later

        if recording
          relay_to_readers
          relay_to_appearants
          relay_to_recipients
          relay_to_schedule
        end
      end
end
```

这个方法协调了对一组较低级别方法的调用。它们都是有关转播的，所以调用仍然保留着；它们具有基于领域的转播目的地的清晰命名；细节仍然隐藏着；而且它们是对称的：你不必跨越抽象层来理解这个方法的作用。

这个方法`#relay_to_or_revoke_from_timeline`看起来正是我们要找的那个：

```ruby
module Event::Relaying
  private
    def relay_to_or_revoke_from_timeline
      if bucket.timelined?
        ::Timeline::Relayer.new(self).relay
        ::Timeline::Revoker.new(self).revoke
      end
    end
end
```

再次看到，很好的基于领域的命名：它检查一个 *bucket* 是否是 timelined 并创建一个`Timeline::Relayer`对象来把 events 转播到一个 timeline；注意其对称性：有一个*revoke* events 的对应 class；方法是内聚的，它专注于转播和 timeline，并且实现的细节保持隐藏。再来看看这个 class：

```ruby
class Timeline::Relayer
  def initialize(event)
    @event = event
  end

  def relay
    if relaying?
      record
      broadcast
    end
  end

  private
    attr_reader :event
    delegate :bucket, to: :event

    def record
      bucket.record Relay.new(event: event), parent: timeline_recording, visible_to_clients: visible_to_clients?
    end

    def broadcast
      TimelineChannel.broadcast_event(event, to: recipients)
    end
end
```

这次的抽象层是一个纯 Ruby 类，不是方法，但我们能观察到同样的特点。它暴露出一个公共方法`#relay`，隐藏了其实现细节。往里看，我们看到它做了两个操作：把 relay 记录在数据库，和把它通过 Action Cable 播发出去（这段代码是在 [Hotwire](https://hotwired.dev/) 出现好多年前写的了）。注意其对称性：即使这两个操作都是单行调用，它们也会被提取为更高层级的方法。

最后，我们来到了底层的细节。`#record`方法把 relay 存储于数据库中——relays 是记录中的可存储对象，这源于 [Rails 的可委托类型](https://github.com/rails/rails/pull/39341)。而`#broadcast`是把事件播发给接收者的方法，也是我们一开头感兴趣的方法。

在这个示例中，我们可以很容易理解到转播的业务逻辑，从一个事件被创建的时刻，到它被通过 action cable 频道推送出去。我们能做到如此是因为在每一步前进时只需要专注一件事：一个职责对应一个抽象层，而名称映射出其正处理的问题。当然，好代码的构成是很主观的，涉及许多许多的概念，但在正式的系统上能轻松完成如上旅程的能力，就是我所喜欢的代码的首要品质。
