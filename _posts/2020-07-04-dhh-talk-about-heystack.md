---
layout: post
title: 对 Hey.com 技术栈的期待
author: Mr.Z
categories: [ Programming ]
tags: [ruby, rails, stimulus]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a016.jpg"
---

近一周来，著名的 Basecamp 公司发布了新式的 Hey.com 的邮件服务，号称是针对当前诸如 GMail 等邮件服务的一次“革命”，在 Twitter 上引发了巨大的议论风暴。而作为公司创始人、Rails 创建者的 DHH 大神，在 Twitter 上也发了多个推，来说明 Hey.com 的卓越不凡。[其中一篇](https://twitter.com/dhh/status/1275901955995385856)更是列举了 Hey.com 当前使用的技术栈，他称之为**“Heystack”**（甚至分享了所用到的 [Gemfile](https://gist.github.com/dhh/782fb925b57450da28c1e15656779556)），如下：

```markdown
- Vanilla Ruby on Rails on the backend, running on edge
- Stimulus, Turbolinks, Trix + NEW MAGIC on the front end
- MySQL for DB (Vitess for sharding)
- Redis for short-lived data + caching
- ElasticSearch for indexing
- AWS/K8S
```

由于 Hey.com 的（网页端）使用体验相当流畅顺滑（提供 7 天免费试用，有兴趣的同学可以去感受下。但正式使用的话则是按 $99/年 收费^_^），这个列表中的一项引发了诸多人的强烈兴趣：

```txt
Stimulus, Turbolinks, Trix + NEW MAGIC on the front end
```

这一项明显是指 Hey.com 当前所用到的前端技术，而所谓的“NEW MAGIC”到底是什么，在 DHH 本条推特下有很多人猜测，甚至直接询问他。DHH 则热情洋溢地回复说不久之后 Basecamp 会开源发布有关代码。我个人猜测有可能是 Stimulus 2.0 + WebSocket 等技术实现，类似于 Elixir 语言的 Phoenix 框架中的 LiveView。不管怎样，DHH 的技术品味和 Basecamp 的名头，都相当值得给以期盼。让我们拭目以待吧。

