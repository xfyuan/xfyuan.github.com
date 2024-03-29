---
layout: post
title: 《Programming Elixir >= 1.6》第一章(节选)
author: xfyuan
categories: [ Translation, Programming ]
tags: [elixir]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a010.jpg"
---

《Programming Elixir >= 1.6》的第一章标题为“Take the Red Pill”。毫无疑问，这个说法的出处源自《黑客帝国1》中的红蓝小药片背景。不言而喻，Dave Thomas 老爷子明显是想表示如果你选择了 Elixir，就意味着选择了编程的“真相”。懂这个梗的人看到这里自然会会心一笑，有了想探究一下这个“真相”到底是什么的兴趣。

让我们来看看 Dave Thomas 在这里是怎么说的吧。

【下面是正文】

## 1. Take the Red Pill

Elixir 以小巧而现代的语法封装了函数式编程，包括不可变状态和基于 Actor 模式的并发。并且它运行在以工业化强度、高性能以及分布式著称的 Erlang VM 上。那么这一切意味着什么？

这意味着你可以不用再担心目前困扰你的那些难题了。你不再需要苦苦思索多线程环境下确保数据一致性的事儿，也不用再想太多应用切分的事儿，同时最重要的是，你可以享受以一种不同的方式来编写代码。

### Programming Should Be About Transforming Data

如果你来自面向对象编程的世界，那你会习惯于用类和实例来思考问题。类定义行为，对象控制状态。开发者花费时间在复杂的类继承关系上，并尝试针对问题来建模，就好比维多利亚时期的科学家创建庞杂的蝴蝶分类学一样。

当我们围绕对象编写代码时，我们要考虑的是状态。大部分时间都花在调用对象的方法和把它们传给其他对象上。基于此，对象更新它们的状态，或其他对象的状态。这个世界中，类就是国王般的存在——它定义每个实例能做什么，它掌控着实例数据的状态。我们的目标是把数据隐藏起来。

但这并不是真实的世界。在真实的世界里，我们不想建模抽象等级（因为现实中并没有这么多真实的级别）。我们只想把事情完成，不想维护什么状态。

现在，比如，我有一些空的文件，把它们转换成一些包含文本的文件。然后我把它们转换成你可以阅读的格式。还有，某个地方的 web 服务器会把你的下载请求转换为一个包含请求下载内容的 HTTP 响应。

我不想隐藏数据，我只想转换它。

### Combine Transformations with Pipelines

Unix 用户都习惯于小而精的命令行工具哲学，用不同的方式来随意组合。每个这样的工具都有内容输入、转换并以下一个工具所需要的格式来输出。

这种哲学极其灵活，使得工具复用度极高。这些工具甚至能以其作者做梦都想不到的方式来组合使用。因此极大地倍增了工具相互间作用的潜能。

这也是极为可靠的——每个小的工具只做好一件事，意味着其很容易测试。

还有另外的好处。命令管道能同时运行。如果我写：

```bash
$ grep Elixir *.pml | wc -l
```

那么单词计数程序，wc，会跟 grep 命令同时运行。因为 wc 程序会消费 grep 的输出，只要 grep 有输出内容产生出来。一旦 grep 结束，几乎没有任何延迟就能得到单词计数的结果。

为给你一点感觉，这里有一个 Elixir 的函数，名为 pmap。它输入一个 collection 和 function，返回一个把 collection 每个元素都调用 function 后的结果作为元素的列表。但……它是把每个元素转换都放到单独的进程中。先不要关心那些细节。

```elixir
defmodule Parallel do
  def pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
end
```

我们可以运行这个函数来得到从 1 到 1000 的平方数。

```elixir
result = Parallel.pmap 1..1000, &(&1 * &1)
```

当然，我刚刚启动了 1000 个后台进程，完全充分利用了自己电脑的全部多核处理器。

这段代码你可能还很不习惯，没关系，等你读到本书的一半之后，就能自己写出这样风格的代码了。

### Functions Are Data Transformers

Elixir 让我们用和上述 Unix 同样的方式来解决问题。而除了命令行工具外，我们更拥有了函数。我们能把它们按照自己的意愿尽情使用。这些函数越小（更专注），我们越能灵活地组合使用它们。

只要想，我们可以让这些函数并行地运行——Elixir 拥有简单而又强大的机制在它们之间通信。这可不是从你爸爸那个时候起就令人头疼的进程或线程——我们这里要谈论的是仅仅在一台电脑上就运行上百万个任务的潜力，以及在上百台电脑上的运行。Bruce Tate 对此的想法是这样的：“大多数开发者把线程和进程看作地狱一般；Elixir 开发者却把它们当作一种重要的简洁方案”。当我们跟随着此书的深入讲解，你会开始明白他这话的意思。

这种转换理念是函数式编程的核心：函数将其输入转换为输出。三角函数 sin 就是一个例子——给它 π⁄4，返回 0.7071。一个 HTML 模版系统是一个函数，当它接收一个包含占位符和相应键值对的模版时，就生成一个完整的 HTML 文档。

但这种强大是有代价的。你将不得不抛弃很多之前已有的编程理念。很多原有的直觉都将变成错的。这会成为一种阻力，因为你会感到自己完全变成了一个“新”手。

从我个人角度看，这恰恰是乐趣所在。你并非在一夜之间就学会面向对象的编程，当然也不可能一顿早饭的时间就成为函数式编程的专家。

不过某种角度看，你将开始以不同的方式来思考问题，并且会发现自己用很少的代码就能完成令人惊讶的事情。你会发现自己编写的小段代码能够被反复使用，而且通常以意想不到的方式（就象上面的 wc 和 grep）。

你看待世界的视角甚至也开始改变，因为你不再考虑责任而开始考虑完成任务。每个人都会同意这是有趣的。



**……（关于如何配置 Elixir 环境的一些步骤说明，略过）……**



### Think Different(ly)

这是一本不同凡"想"的书——接受一些对于编程的看法并非其全部：

- 面向对象并不是代码设计的唯一方法
- 函数式编程并不需要非常复杂或精确
- 编程的基础并不是赋值、if 语句和循环
- 并发不需要锁，信号量，监视器，以及类似的东西
- 进程并不是代价昂贵的资源
- 元编程并不是随便添加到语言上的东西
- 即使它是工作，编程也能很有趣

当然，我并非要说 Elixir 就是那种灵丹妙药（好吧，技术确实是，你懂我的意思）。它不是编写代码的唯一方式。但它跟主流是如此不同，学习它会为你提供更多的视角，能让你拓展思维而看到新的思考编程的方式。

那么，让我们开始吧。
