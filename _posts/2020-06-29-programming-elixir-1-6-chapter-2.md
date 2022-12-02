---
layout: post
title: 《Programming Elixir >= 1.6》第二章：模式匹配
author: xfyuan
categories: [ Translation, Programming ]
tags: [elixir]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a011.jpg"
---

《Programming Elixir >= 1.6》的结构形式与一般的编程语言入门书完全不同。常规的编程语言书一般都会从基本语法开始讲起，无非数字、字符串、函数、变量等等。但这本书不是。Dave Thomas 意识到 Elixir 拥有如此与众不同的语法特性，他认为让读者首先接触并理解这种特殊性才是更好学习该语言的方式，所以在第一步就首先介绍了 Elixir 最为特殊也最为重要的**模式匹配（Pattern Matching）**。

而我认为这也是本书极为卓越的一点。因为**模式匹配（Pattern Matching）**对熟悉了其他语言的开发者而言，极有可能是一个巨大的观念冲击。同时，它也是 Elixir 语法最重要的一块基石。如果你不能接受它，后面的内容就根本没有再看下去的必要了。所谓提纲挈领，纲举目张，**模式匹配（Pattern Matching）**就是这个**“纲”**，理解了它，其他 Elixir 的语法就能很容易理解了。而 Dave Thomas 敏锐地认识到了这一点，不再按部就班地进行常规语法介绍，而是把**模式匹配（Pattern Matching）**提到了本书正式内容的最前面，正显示了其卓越的语言嗅觉。

由于**模式匹配（Pattern Matching）**是如此重要，所以我想在这里放出本章的全文翻译是值得的。

让我们来看看 Dave Thomas 在这里是怎么介绍的吧。

【下面是正文】

## 2. Pattern Matching（模式匹配）

我们从前一章开始说 Elixir 产生了一种不同的方式来思考编程。

为了说明这一点，并且为后续的 Elixir 编程奠定基础，让我们来打量所有编程语言的一个基石——赋值。

### Assignment: I Do Not Think It Means What You Think It Means.

用 Elixir 命令行，IEx，来看一段简单的代码（记住，在命令行使用`iex`命令来开始 IEx，在`iex>`后输入 Elixir 代码来运行显示结果）。

```elixir
iex> a = 1
1
iex> a + 3
4
```

大部分程序员看到上面代码都会说，"好吧，我们把 1 赋值给变量 a，下一行再把 3 加到 a 上，最后得到 4"。

但是当我们来到 Elixir 的世界，这是错的。在 Elixir 中，等号不表示赋值，而更像是断言（assertion）。当 Elixir 能找到一种方式让等号左边等于右边时，该表达式即成立。Elixir 把等号`=`称作匹配（match）操作符。

上面的示例中，左边是一个变量，右边是一个整数字面量，所以 Elixir 能通过把变量 a 绑定到值 1 来使得匹配成功。你可能会争辩这不还是赋值么。但让我们接着往下看：

```elixir
iex> a = 1
1
iex> 1 = a
1
iex> 2 = a
** (MatchError) no match of right hand side value: 1
```

看下第 2 行代码，`1 = a`。这是另一个匹配，且通过了。变量 a 已经有了一个值 1（第 1 行代码中被设定的），所以等号左边和右边是相同的，匹配成功。

但是在第 3 行代码时，`2 = a`，抛出了错误。你可能会期望把 2 赋值给 a 来让匹配成功，然而 Elixir 只会改变等号左边变量的值——右边的变量会直接使用它的值。这行代码相当于`2 = 1`，因此报错了。

### More Complex Matches

首先，介绍一个小的语法。Elixir 的列表（list）可以通过使用方括号包含以逗号分隔的值来创建。一些例子如下：

```elixir
[ "Humperdinck", "Buttercup", "Fezzik" ]
[ "milk", "butter", [ "iocane", 12 ] ]
```

回到匹配操作符：

```elixir
iex> list = [ 1, 2, 3 ]
[1, 2, 3]
```

为使匹配成功，Elixir 把变量 list 绑定为列表`[1, 2, 3]`。

再看看别的：

```elixir
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [a, b, c ] = list
[1, 2, 3]
iex> a
1
iex> b
2
iex> c
3
```

Elixir 会尽力寻找一种方式来使等号左右两边的值相同。左边是一个包含三个变量的列表，右边是一个有三个值的列表，所以可以通过依次设置三个变量为对应位置的值来做到这一点。

Elixir 把这个过程称作**模式匹配（*pattern matching*）**。对于等号左边（称作"模式"（pattern）），如果等号右边和其有相同的结构，且左边的每个元素都能和右边对应位置的元素匹配，那么这个模式就和右边是匹配的。值和值匹配，变量通过设置为对应位置的值来匹配。

下面是更多的范例：

```elixir
iex> list = [1, 2, [ 3, 4, 5 ] ]
[1, 2, [3, 4, 5]]
iex> [a, b, c ] = list
[1, 2, [3, 4, 5]]
iex> a
1
iex> b
2
iex> c
[3, 4, 5]
```

右边相应位置和左边元素 c 对应的是子列表`[3, 4, 5]`，所以 c 被设置为这个值而使得匹配成功。

再看下模式包含值和变量的情况：

```elixir
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [a, 2, b ] = list
[1, 2, 3]
iex> a
1
iex> b
3
```

模式中的字面量 2 和右边对应位置是匹配的，所以可让变量 a，b 分别被设为 1，3 来使得匹配成功。但是……

```elixir
iex> list = [1, 2, 3]
[1, 2, 3]
iex> [a, 1, b ] = list
** (MatchError) no match of right hand side value: [1, 2, 3]
```

这里的 1（list 第二个元素）无法和右边相应位置元素匹配，因此没有任何变量被设置，匹配失败。可以看出这里定义了列表的一个匹配标准——要包含 3 个元素，且第二个元素为 1。

### Ignoring a Value with _ (Underscore)

如果在匹配时不需要获取某一个值，我们可以使用特殊变量，`_`（下划线）。它在运行时会象一个变量一样，但会丢弃任何在匹配中设置给它的值。它象一个宣称"我能接受任何值"的通配符。下面是一个匹配任何有三个元素的列表，且第一个元素为 1 的例子。

```elixir
iex> [1, _, _] = [1, 2, 3]
[1, 2, 3]
iex> [1, _, _] = [1, "cat", "dog"]
[1, "cat", "dog"]
```

### Variables Bind Once (per Match)

一旦一个变量在匹配过程中被绑定到一个值了，它就会在接下来的匹配过程中一直保持这个值。

```elixir
iex> [a, a] = [1, 1]
[1, 1]
iex> a
1
iex> [b, b] = [1, 2]
** (MatchError) no match of right hand side value: [1, 2]
```

第一个表达式成功是因为 a 首先匹配了 1，这个值然后保持用在第二个匹配中，也是 1，成功。

下一个表达式中，首先 b 匹配了 1，但到第二个匹配时，b 和相应位置的 2 去匹配，b 不能有两个不同的值，所以失败了。

然而，一个变量可以在后续的匹配中绑定到新的值，其当前的值不会用在新的匹配中。

```elixir
iex> a = 1
1
iex> [1, a, 3] = [1, 2, 3]
[1, 2, 3]
iex> a
2
```

那么如果你想要 Elixir 在匹配中强制使用变量的当前值要怎么办呢？给它加上前缀`^`（脱字符）。Elixir 中把这个称作`pin`操作符。

```elixir
iex> a = 1
1
iex> a = 2
2
iex> ^a = 1
** (MatchError) no match of right hand side value: 1
This also works if the variable is a component of a pattern:
iex> a = 1
1
iex> [^a, 2, 3 ] = [ 1, 2, 3 ]
[1, 2, 3]
iex> a = 2
2
iex> [ ^a, 2 ] = [ 1, 2 ]
** (MatchError) no match of right hand side value: [1, 2]
```

关于模式匹配，另外有一个重要的部分。我们将在后面的章节 ***Lists and Recursion*** 中介绍。

### Another Way of Looking at the Equals Sign

Elixir 的模式匹配和 Erlang 的很相近（主要的区别在于 Elixir 允许在匹配中把之前已有绑定值的变量重新设置新的值，Erlang 则只允许对变量设置一次值）。

Joe Armstrong，Erlang 的创建者，把 Erlang 中的等号和代数中的进行了类比。当你写下方程`x = a + 1`时，并不是把`a + 1`的值赋给`x`，而是在断言（asserting）表达式`x`和`a + 1`有相同的值而已。当你知道了`x`的值，就能计算出`a`的值，反之亦然。

他的观点是，当你第一次遇到命令式编程语言时是不得不抛弃等号`=`的代数含义，现在是重新捡回它们的时候了。

这就是我之所以把**模式匹配**作为本书第一章的原因。它是 Elixir 的核心之一——被广泛用于条件语句、函数调用和执行中。

说真的，我期望让你对编程语言有些不同的想法，并且也向你展示了一些现有预设在 Elixir 中并不起作用。

说到现有的预设……下一章会打破另一个不容置疑的东西。你现有的编程语言可能被设计为很容易修改数据。毕竟，那就是程序要干的事，对吧？Elixir 不是。让我们来看看一门所有数据都不可变的语言。
