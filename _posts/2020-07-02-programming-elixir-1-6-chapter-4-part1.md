---
layout: post
title: 《Programming Elixir >= 1.6》第四章：基本语法（节选一）
author: Mr.Z
categories: [ Translation, Programming ]
tags: [elixir]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a014.jpg"
---

其他编程语言中的常规语法介绍在《Programming Elixir >= 1.6》里直到第四章才终于姗姗来迟。这一章介绍的是 Elixir 中全部的各种内置类型。函数在 Elixir 中也是一种类型，但会用单独的一章来专门介绍而不在本章之内。出人意料的是，字符串和结构体也不在本章里，因为它们不是 Elixir 的基本类型，而是由基本类型构成的高级类型。

由于本章涵盖内容太多，因此跟其他语言类似的一些类型就不发出来了，比如数字、正则表达式等，而只节选了一些 Elixir 特有的类型，比如元组等几种集合类型等。想要了解 Elixir 所有这些基本类型的知识，可以在去查阅官方文档或者本书该章节的原文。

即使经过上述节选之后，本章的内容还是显得太长了，所以我不得不把其分成两部分发出。这是节选的第一部分。

【下面是正文】

## 4. Elixir Basics

这一章我们将看看 Elixir 中的类型，以及开始时需要了解的其他一些内容。本章特意写得不长——作为一名开发者你当然知道什么是整数，所以我不会在这些小事上侮辱大家的智商。相反，我会聊一些 Elixir 中特别的东西。

### Built-in Types

Elixir 的内置类型有：

- Value types:
  - Arbitrary-sized integers【整数】
  - Floating-point numbers【浮点数】
  - Atoms【原子】
  - Ranges【范围】
  - Regular expressions【正则表达式】
- System types:
  - PIDs and ports
  - References
- Collection types:
  - Tuples【元组】
  - Lists【列表】
  - Maps【映射】
  - Binaries

函数也是一种类型。下一章会用专门的章节来讲它。

你可能很惊讶上面的列表中没有包含诸如字符串和结构体这样的东西。Elixir 是有的，但它们是由上述基本类型来构成。它们全都很重要。字符串同样有专门的章节讲，列表（list）和映射（map）有好几章来讲（包括其他类似字典的类型）。映射那一章也会讲到 Elixir 的结构体。

最后，关于正则表达式（Regular expression）和范围（Range）是否是值类型还有些争议。从技术上讲，它们不是——表象之下它们都只是结构体。但当前把它们看作是不同的类型会更方便。

### Value Types

Elixir 的值类型指的是数字（number）、原子（atom）、范围（range）和正则表达式（regular expression）。

***……节略……***

#### Atoms【原子】

原子是代表某事物名称的常量。它以一个冒号`:`开头，后面跟一个原子单词或 Elixir 操作符。原子单词由一系列UTF-8字母（包括组合标记）、数字、下划线和符号（@）构成。它能以感叹号或问号结尾。你还可以通过把冒号后的字符用双引号括起来以创建包含任意字符的原子。下面这些都是合法的原子：

```
:fred :is_binary? :var@2 :<> :=== :"func/3" :"long john silver" :эликсир :mötley_crüe
```

原子的名称就是它的值。两个相同名称的原子在比较时始终会被看作相等的，即使它俩是由远隔重洋的两台电脑上的不同应用程序所创建。

我们会把原子用在非常多的标记值（tag value）上。

***……节略……***

### Collection Types

到上面为止我们看到的类型在其他编程语言中很常见。 现在起会开始看到更多独特的类型，所以我们接下来要详细介绍。

Elixir 集合可以包含任何类型的值（包括使用其他集合）。

#### Tuples【元组】

元组是有序的值的集合。跟所有 Elixir 的数据结构一样，元组一旦创建即不可改变。

元组写在大括号中，元素用逗号分隔。

```elixir
{ 1, 2 } { :ok, 42, "next" } { :error, :enoent }
```

一般而言 Elixir 的元组包含二至四个元素——更多的话你可能应该去看看`map`或者`struct`。

可以把元组用在模式匹配中：

```elixir
iex> {status, count, action} = {:ok, 42, "next"}
{:ok, 42, "next"}
iex> status
:ok
iex> count
42
iex> action
"next"
```

在函数中，当没有错误时，返回一个首元素为原子`:ok`的元组是很常见的事。下面是一个例子（假设你当前目录中有一个名为`mix.exs`的文件）：

```elixir
iex> {status, file} = File.open("mix.exs")
{:ok, #PID<0.39.0>}
```

因为文件打开成功，所以元组包含一个`:ok`的状态和一个可用于访问文件内容的 PID。

一个常见的做法是写一个预设成功的匹配：

```elixir
iex> { :ok, file } = File.open("mix.exs")
{:ok, #PID<0.39.0>}
iex> { :ok, file } = File.open("non-existent-file")
** (MatchError) no match of right hand side value: {:error, :enoent}
```

打开第二个文件失败，返回元组的首元素是`:error`。这使得匹配失败，错误信息表明第二个元素包含了失败原因——`enoent`是 Unix 中"文件不存在"的意思。

#### Lists【列表】

我们已经见过了 Elixir 的列表字面量语法`[1, 2, 3]`。你因此可能会认为列表和其他语言中的数组很像，但并不是。（实际上，元组才是 Elixir 中跟数组最接近的）相反，列表实际上是链表的数据结构。

|                          列表的定义                          |
| :----------------------------------------------------------: |
| 列表可以是空的，也可以是头部和尾部。 头部包含一个值，尾部本身就是一个列表。 |

（如果你用过 Lisp 语言，会看到二者很像。）

后面在《Lists and Recursion》章中会讲到，列表的递归定义是 Elixir 编程的核心。

处于其实现方式，列表很容易线性遍历，但是以随机顺序访问它们则代价昂贵。（要获取第 n 个元素，必须要扫描 n - 1 个前面的元素。）获取列表的头部并提取尾部则总是开销很小的。

列表还有一个性能特征。还记得我们说过所有的 Elixir 数据结构都是不可变的吗？这意味一个列表一旦被创建就永不可变。所以，如果我们要移除其头部，保留尾部，不必拷贝这个列表，相反可以返回一个指向尾部的指针。这是将在第 7 章《Lists and Recursion》中介绍的所有列表遍历技巧的基础。

Elixir 对于列表有一些特别的操作符：

```elixir
iex> [1,2,3] ++ [4,5,6]
[1, 2, 3, 4, 5, 6]
iex> [1, 2, 3, 4] -- [2, 4]
[1, 3]
iex> 1 in [1,2,3,4]
true
iex> "wombat" in [1, 2, 3, 4]
false
```

##### Keyword Lists【关键字列表】

由于我们经常需要键值对的简单列表，Elixir 提供了一种快捷方式。如果我们这样写：

```elixir
[ name: "Dave", city: "Dallas", likes: "Programming" ]
```

Elixir 会把它转换成以二元元组作为元素的列表：

```elixir
[ {:name, "Dave"}, {:city, "Dallas"}, {:likes, "Programming"} ]
```

而且，当一个关键字列表作为函数最后一个参数时，Elixir 允许我们不写中括号。

```elixir
DB.save record, [ {:use_transaction, true}, {:logging, "HIGH"} ]
```

上面的代码可以简写成：

```elixir
DB.save record, use_transaction: true, logging: "HIGH"
```

在任何预期得到一个值的列表的上下文中，如果关键字列表是其最后一项，我们也可以不要括号。

```
iex> [1, fred: 1, dave: 2]
[1, {:fred, 1}, {:dave, 2}]
iex> {1, fred: 1, dave: 2}
{1, [fred: 1, dave: 2]}
```

### Maps【映射】

映射是键值对的集合。映射字面量像这样：

```elixir
%{ key => value, key => value }
```

下面是一些示例：

{% raw %}

```elixir
iex> states = %{ "AL" => "Alabama", "WI" => "Wisconsin" }
%{"AL" => "Alabama", "WI" => "Wisconsin"}

iex> responses = %{ { :error, :enoent } => :fatal, { :error, :busy } => :retry }
%{{:error, :busy} => :retry, {:error, :enoent} => :fatal}

iex> colors = %{ :red => 0xff0000, :green => 0x00ff00, :blue => 0x0000ff }
%{blue: 255, green: 65280, red: 16711680}
```
{% endraw %}

第一个例子，键是字符串。第二个的是元组，第三个的是原子。尽管一个映射的所有键通常都会是相同的类型，但这并非必须。

```elixir
iex> %{ "one" => 1, :two => 2, {1,1,1} => 3 }
%{:two => 2, {1, 1, 1} => 3, "one" => 1}
```

如果键是原子，你可以使用和关键字列表相同的简写方式：

```elixir
iex> colors = %{ red: 0xff0000, green: 0x00ff00, blue: 0x0000ff }
%{blue: 255, green: 65280, red: 16711680}
```

你也能在映射的键中使用表达式：

```elixir
iex> name = "José Valim"
"José Valim"
iex> %{ String.downcase(name) => name }
%{"josé valim" => "José Valim"}
```

为什么我们同时拥有映射和关键字列表？映射只允许键是唯一的，而关键字列表的键可以重复。映射是高效的（特别是当其内容增长时），而且还可用于 Elixir 的模式匹配中，这个后续章节中会讨论到。

一般来说，使用关键字列表来执行命令行参数和传递选项等操作，在需要关联数组时使用映射。

#### Accessing a Map

你通过映射的键来获取值。中括号的语法适用于所有映射：

{% raw %}

```elixir
iex> states = %{ "AL" => "Alabama", "WI" => "Wisconsin" }
%{"AL" => "Alabama", "WI" => "Wisconsin"}
iex> states["AL"]
"Alabama"
iex> states["TX"]
nil
iex> response_types = %{ { :error, :enoent } => :fatal,
...> { :error, :busy } => :retry }
%{{:error, :busy} => :retry, {:error, :enoent} => :fatal}
iex> response_types[{:error,:busy}]
:retry
```
{% endraw %}

如果键是原子，可以使用点号表示法：

```elixir
iex> colors = %{ red: 0xff0000, green: 0x00ff00, blue: 0x0000ff }
%{blue: 255, green: 65280, red: 16711680}
iex> colors[:red]
16711680
iex> colors.green
65280
```

当使用点号表示法时，如果没有对应的键就会得到一个 KeyError 的错误。

【待续】
