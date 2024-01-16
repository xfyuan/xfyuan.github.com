---
layout: post
title: TestProf III：引导式及自动化的Ruby测试分析
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, rspec, evil martians]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20240115.jpg"
rating: 4
---

*本文已获得原作者（Vladimir Dementyev）和 Evil Martians 授权许可进行翻译。原文是 TestProf 这个 Evil Martians 出品的 Gem 介绍文章系列的第三篇。作者介绍了 TestProf 最新的 Playbook 和 Autopilot 功能。特别是后者，非常值得一试。*

- 原文链接：[TestProf III: guided and automated Ruby test profiling](https://evilmartians.com/chronicles/test-prof-3-guided-and-automated-ruby-test-profiling)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula), Travis Turner
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 概述

让开发人员（及开发工具）有更好体验的趋势正在增加。工程师渴望更智能的工具和更快的反馈循环，以最大限度地提高生产力。在 Ruby on Rails 社区中，由于测试速度慢，后者通常意味着长时间运行的 CI/CD 构建。六年前 TestProf 的出现使 Ruby 开发者的生活更轻松，他们的测试速度也更快。尽管该项目已证明了其有效性并且可以被认为是完善的，但它从未停止过发展。

今天，我们想分享更新的测试分析手册和新的 TestProf 工具及功能！

## 前言

我们在六年多前就开始了这个系列，但是我们讨论的关于 Ruby/Rails 慢测试的问题——以及我们提出的解决方案——今天仍然适用。你能想象吗？

自 2018 年来，我们已经经历了两个 Rails 版本和一个 Ruby 版本，但保持测试速度的最佳方法仍然是使用 `let_it_be` ，而不是 `let / let!` ；以及 `before_all` ，而不是 `before(:each)` 。所以，我们不会重复自己。相反，我们想谈谈 TestProf 及其使用模式是如何随着时间的推移而演变的。

在本文中，我们将介绍以下主题：

- TestProf playbook
- TestProf Autopilot
- More features and futures

## Introducing the TestProf playbook

这些年来，我们（Evil Martians）已经开发了数十个 Rails 应用程序，对于每个应用程序，测试套件都至少得到了一些关注（我们甚至有只专注于测试性能的）。不出所料，速度慢的原因和我们处理这些测试套件的方式非常相似，因此我们提出了以下框架（或手册）：

- 我们从一些目之所及的分析开始：检查应用程序的配置，查看 Gemfile 以查找已知的肇事者。
- 我们继续使用 [Speedscope](https://www.speedscope.app/) 分析 StackProf 样品。
- 然后，我们开始使用 TestProf 自己的分析器：TagProf、EventProf、FactoryProf等。

TestProf playbook 的完整版本可在此处获得：test-prof.evilmartians.io/playbook 【译者注：中文文档也已上线】

我们的 playbook 有助于开始测试分析。尽管如此，它仍然需要开发者进行大量手动操作。鉴于我们处理的是慢测试，分析自然会导致较长的反馈循环。

因此，我们开始研究尽量减少人际互动的方法，并提出了“自动驾驶”的想法。

## Automating profiling with TestProf Autopilot

将某些东西描述为正式流程是迈向自动化的第一步。因此，在正式确定“剧本”后，我们准备迈出这一步。TestProf Autopilot 就是这样诞生的。

TestProf Autopilot 是一个 CLI 工具（也是一个 gem），可帮助执行复杂的 TestProf 场景。你用 Ruby 编写一个脚本，然后针对你的代码库执行它。例如，你可以通过以下方式自动生成和合并 StackProf 报告以查看汇总结果：

```ruby
# spec/.test-prof/stack_prof_scenario.rb

# First, profile the boot time
run :stack_prof, boot: true, sample: 10

save report, file_name: "stack_prof_boot"

# Then, generate multiple sampled profiles and aggregate the results
aggregate(3) { run :stack_prof, sample: 100 }

save report, file_name: "stack_prof_sample"
```

然后，通过以下 `auto-test-prof` 命令运行脚本：

```sh
bundle exec auto-test-prof -i spec/.test-prof/stack_prof_scenario.rb
```

Autopilot 执行四次运行，并将报告保存到指定位置——所有这些都不会分散你对其他任务的注意力，你可能已经转而知道分析需要一些时间。

由于场景是 Ruby 脚本，因此你可以自由地使用该语言的所有功能和表现力来满足分析需求。让我分享另一个现实中的场景——选择负责给定组在 factories 中花费大雨 50% 时间的文件：

```ruby
# spec/.test-prof/event_prof_scenario.rb

run :event_prof, event: "factory.create", top_count: 1000

total_run_time = report.raw_report["absolute_run_time"]
total_event_time = report.raw_report["total_time"]

threshold = 0.5 * total_run_time

sum = 0.0
sum_event = 0.0

top_groups = report.raw_report["groups"].take_while do |group|
  next false unless sum < threshold

  sum += group["run_time"]
  sum_event += group["time"]
  true
end

msg = <<~TXT
  Total groups: #{report.raw_report["groups"].size}
  Total times: #{total_event_time} / #{total_run_time}
  Selected groups: #{top_groups.size}
  Selected times: #{sum_event} / #{sum}

  Paths:

TXT

paths = top_groups.map { _1["location"] }

puts msg
puts paths.join("\n")
```

下面是你运行它的方式：

```sh
$ bundle exec auto-test-prof -i spec/.test-prof/event_prof_scenario.rb \
  -c "bundle exec rspec spec/models"

Total groups: 497
Total time: 2210.41 / 2394.49
Selected groups: 26
Selected time: 1118.15 / 1199.34

Paths:

./spec/models/appointment_spec.rb:4
./spec/models/user_spec.rb:3
./spec/models/assessment_spec.rb:3
...
```

你可以看到，该场景帮助我们将优化工作范围缩小到 497 个文件中的 26 个——仅 ~5% 的文件就占用了所有运行时间的 50%！

虽然它不是最初计划之一，但 Autopilot 对于处理较大的代码库特别有用，这些代码库使用单个进程运行整个测试套件需要耗费数小时。

如果你查看手册，可能会注意到某些步骤需要完整的测试套件运行，例如 TagProf 分析。

我们已经具备了以 JSON 格式保存报告并合并它们的功能（请参阅上面的 `aggregate` 示例），因此我们只需要向 CLI 暴露这些功能。于是，添加了 `--merge` 选项：

```sh
$ auto-test-prof --merge tag_prof --reports tag_prof_*.json

Merging tag_prof reports at tag_prof_1.json, tag_prof_2.json, tag_prof_3.json

[TEST PROF] TagProf report for type

       type          time   factory.create    total  %total   %time           avg

      model     28:08.654        19:58.371     1730   56.44   46.23     00:00.976
    service     20:56.071        16:14.435      808   29.18   28.35     00:01.554
        api     04:48.179        03:54.178      214    7.32    4.78     00:01.346
        ...
```

但是我们如何收集报告呢？只需在 CI 上运行 TestProf Autopilot 并将报告存储为工件【译者注：artifacts】即可！下面是一个示例场景：

```sh
run :tag_prof, events: ["factory.create"]

save report, file_name: "tag_prof_#{ENV["CI_NODE_INDEX"]}"
```

你可能仍然需要手动下载所有文件，这并不理想。我们正在考虑在未来版本中添加的可能解决方法之一是将报告存储在云上，使用 `#upload` 这样的方法（也许，甚至是 TestProf Cloud 😉 ）。

TestProf Autopilot 作为一个内部项目已经很长一段时间了，在测试优化任务方面已成为我们值得信赖的伙伴。

它仍处于（不那么）积极的开发中，但依然足以以向公众展示了——所以，请试一试并分享您的想法（和问题）！

说到展示，来看看我们在这个新的 TestProf 版本中还为你准备了什么。

## More features and futures

TestProf 在大约三年前发布了 v1.0，这是一款稳定成熟的软件。但成熟并不意味着我们没有任何新的东西可以向你展现。以下是最新版本 TestProf v1.3.0的亮点。

我们引入了一个全新的分析器 —— MemoryProf。它可以帮助你识别导致 RSS 使用高峰或大量对象分配的测试用例和组。你可能会问，“我们为什么要关心测试中的内存使用情况？”

首先，这能优化你的 CI 基础架构（无论是否自托管——并不重要，因为你都需要为此付费）。其次，这种分析也可以帮助你识别生产环境的内存问题。试一试，看看它揭示了什么见解！

另一个令我们兴奋的新功能是[Vernier](https://github.com/jhawthorn/vernier)集成。Vernier 是下一代 Ruby 采样分析器，具有更好的多线程、GVL 和 GC 事件支持。我们还不知道它在测试分析的上下文中是否具有一定优势，但它与 Firefox Profiler UI 的兼容性看起来很有吸引力。以下是我试图找到测试套件中突然变慢的原因（剧透：它是 `Sentry.capture_message` ）：

![vernier-demo](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/vernier-demo.gif)

那么，TestProf 的下一步是什么？我们对 v2 没有太大的计划（好吧，我有，但还没有时间表）。相反，我们专注于扩展 TestProf 的世界，并带来新的面向测试的工具。一年前，我们还发布了 Mock Suey，这是一个工具包，可使模拟更可靠并避免误报。

接下来是一个代号为“Flakon”的项目，旨在帮助你处理不稳定的测试。

最后，我们计划进一步自动化 TestProf playbook，并提供类似 `test-prof-audit` 的东西——一个用于分析配置和依赖关系并提出优化建议的工具（参见 playbook 中的日志记录和 Wisper 示例）。

请继续关注并加入更快的测试运动！（你可以随时支持我们！）
