---
layout: post
title: 深入Rails的Zeitwerk模式
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20221204.jpeg"
rating: 4
---

*本文已获得原作者（**Simon Coffey**）授权许可进行翻译。原文深入讲述了 Rails 中新的 Zeitwerk 自动加载模式的实现原理，是对前一篇《[Rails7的Zeitwerk模式解惑](https://xfyuan.github.io/2022/11/rails7-zeitwerk-mode/)》很好的补充*

- 原文链接：[Rails autoloading — now it works, and how!](https://www.urbanautomaton.com/blog/2020/11/04/rails-autoloading-heaven/)
- 作者：Simon Coffey（[Twitter](http://twitter.com/urbanautomaton)）

*【正文如下】*

Rails 从一开始就有自动加载。自动加载意味着当我们想要引用`User` model 时，不必还要手写`require 'User'`。没人有时间为每个需要用到`User`的文件都来这么干，对吧？

我已经写过一篇关于 Rails 最早的 autoloader（现在叫做“传统”模式的 autoloader）的文章【译者注：[该文链接](https://www.urbanautomaton.com/blog/2013/08/27/rails-autoloading-hell/)】：它是如何工作的，又是如何创造了诸多弊端的。那个时候，我对它很是气愤，为它可浪费了不少时间来调试它造成的问题。

前一篇文章涵盖了很多细节，但传统的自动加载的诸多问题的根本在于其机制：它使用了`Module#const_missing`来检测一个常量何时无法通过正常含义来解析，然后它尝试去查找并加载一个文件来定义它。

有两个原因使得这种方案无法很可靠地工作：

- `Module#const_missing`仅当一个常量无法通过正常含义来解析时才执行。因为 Ruby 中给定的常数引用[可以潜在地解析为许多常数定义](https://cirw.in/blog/constant-lookup.html)，这意味着在某些情况下，Ruby 可以在自动加载生效之前就为一个常量引用返回了错误的值。
- 当`Module#const_missing`被执行时，它并未提供足够的信息来可靠地检测是哪个常量应该被返回。这也就意味着，自动加载，有时将会为一个常量引用返回错误的值得。

经典的 autoloader 的大部分复杂性都涉及修补这两个无法克服的问题，这使得其很难理解或调试，也不可避免地会出错。

然而对 Rails 6，有了一个新的 loader：[Zeitwerk](https://github.com/fxn/zeitwerk)。它[声称已经解决了传统模式的所有问题](https://medium.com/@fxn/zeitwerk-a-new-code-loader-for-ruby-ae7895977e73)，这真是个令人兴奋的消息！

为了做到这点，它使用了三个关键机制：

- `Module#autoload`
- `Kernel#require`
- `TracePoint`

让我们来看看他如何把这些编织到一起的。

## Goodbye `#const_missing`, Hello `#autoload`

Ruby 有一个内置的自动加载机制，`Module#autoload`。这使我们可以提前告诉 Ruby 哪个文件将定义一个特定的常量，而无需付出立即加载该文件的成本。仅当我们第一次引用到那个常量时，Ruby 才会实际去加载它：

```ruby
# a.rb
puts "Loading a.rb"
A = "Hi! I'm ::A"
```

```ruby
autoload :A, 'a'

puts A
# Loading a.rb
# Hi! I'm ::A
```

而这跟`Module#const_missing`的最重要差别在于，我们告诉 Ruby 哪个文件定义了哪个常量，在该常量被使用之前，且在常量解析期间这个信息会被带入进去。

这就潜在地排除了`#const_missing`方案上述两个关键性的错误。我们将不再试图去检测并从错误中恢复，而只是用额外的信息来增强 Ruby 现有的常量解析机制。

要使用`Module#autoload`，你需要在常量被使用之前就知道哪个文件将定义给定的常量。Rails（以及 Ruby 约定）在常量名称和文件之间定义了可预测的映射，这在理论上让我们能够自动化如下变换：

```ruby
MyModule::MyClass # => my_module/my_class.rb
```

然而，传统的 autoloader 支持在初始化时从不存在的文件中来加载常量。如果我在`app/models/user.rb`中创建了一个新的`User` model，我可以直接在一个已经打开运行中的 rails console 里调用`User.create`而无需做任何事情。

除非有某些进程监控着文件系统的改变，否则我们是无法使用`Module#autoload`在其初始化时来自动加载不存在的文件的。监控文件系统很麻烦，也不那么可靠，特别是你需要支持多个操作系统时。

不过，这个功能会多有用呢？如果我们缩减 autoloader 的定义域，让其初始化时仅仅支持已存在的文件的话，`Module#autoload`便成为了一个选择。事实上，这就是 Zeitwerk 所做的事。我们通过实例来看看。

## Loading a single file

要使用 Zeitwerk，我们初始化一个 loader，并给它一个或多个根目录以从中加载。通过加入一个 logger，就能看到它的操作：

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir('/ex')
loader.logger = Logger.new(STDOUT)
```

现在我们就可以把一些文件放入根目录中，启动 loader。在贯穿本文的示例代码片段中，我会在那些影响结果的行之后以注释形式展示打印的输出。

```ruby
# /ex/a.rb
A = "Hi! I'm ::A"
```

```ruby
loader.setup
# Zeitwerk: autoload set for A, to be loaded from /ex/a.rb

puts A
# Zeitwerk: constant A loaded from file /ex/a.rb
# Hi! I'm ::A
```

当我们调用`loader.setup`时能看到 Zeitwerk 检测并准备要自动加载的文件（这正是`Module#autoload`执行的时候）。然后当我们第一次引用常量`A`时，就看到它从之前被检测到的文件中被载入，最终我们看到了其打印出的值。

有趣的是，Zeitwerk 可以检测实际发生的加载以记录下它！要看到它是如何做的，让我们来看看比单个文件更复杂的情况。

## Implicit namespaces

在第一个示例中，我们看到了单个文件在 loader 的根路径内。几乎任何有一定体积的项目都会有一定深度的目录结构，以及一定深度的嵌套模块。

如果我们创建一个文件`c/d.rb`，则会想要加载一个常量`C::D`。这意味着我们必须首先加载`C`。

然而，`C`可能会是一个无趣的命名空间模块；如果对每个这样的命名空间我们都不得不为其创建如下的样板文件，那就很乏味了：

```ruby
# /ex/c.rb
module C
end
```

因此 Zertwerk 允许这些命名空间是隐式的。无需那些样板文件，Zeitwerk 从目录名来“自动导入”命名空间模块；本质上，它不需要那样一个 ruby 文件就为我们声明了一个名为`C`的模块。

不过，这展示了一个问题：我们使用 ruby 默认的`Module#autoload`来做实际的加载，而它对所要转换为模块的目录一无所知。那么，我们如何告诉 ruby 要怎样提前加载`C`呢？

来看看当目录中只有单个文件时会发生什么：

```ruby
# /ex/c/d.rb
C::D = "Hi! I'm C::D"
```

```ruby
loader.setup
# Zeitwerk: autoload set for C, to be autovivified from /ex/c
```

在初始化的 setup 时，我们可以看到 Zeitwerk 只为自动加载准备了`C`。因此，它一定只立刻查找根目录的文件。

在根目录里，它只发现了一个目录，`/ex/c`，所以它不会说从一个文件“`C`...被自动加载”，而是会说从那个目录“`C`...被自动导入”了。

```ruby
puts C
# Zeitwerk: module C autovivified from directory /ex/c
# Zeitwerk: autoload set for C::D, to be loaded from /ex/c/d.rb
# C
```

然后当我们引用`C`时，会看到它被[自动导入](https://github.com/fxn/zeitwerk/blob/034ae30d73247b8dda7df2992903ce560cd7f47f/lib/zeitwerk/loader/callbacks.rb#L39-L40)了，然后`C::D`被为自动加载而得到设置——Zeitwerk 必须向下深入`c`目录以查找更多要自动加载的东西。

```ruby
puts C::D
# Zeitwerk: constant C::D loaded from file /ex/c/d.rb
# Hi! I'm C::D
```

最终我们引用到了`C::D`，它从`c/d.rb`这个常规的 ruby 文件得以被自动加载。

如果没有 ruby 文件被读取，关于`C` 的自动导入又是如何工作的呢？

Zeitwerk 通过拦截`Module#autoload`其中的加载那一部分代码来做到这点。当我们调用`autoload :C, '/ex/c'`时，这意味着在`C`被首次使用的时候，ruby 会自动调用`require '/ex/c'`。

默认情况下，如果我们试图`require`一个目录时，ruby 会抛出一个`LoadError`。但由于`Kernel#require`是跟 ruby 任何其他方法一样的方法，Zeitwerk 就能够[拦截该`require`调用](https://github.com/fxn/zeitwerk/blob/034ae30d73247b8dda7df2992903ce560cd7f47f/lib/zeitwerk/kernel.rb#L24-L32)，在其中加入一些“猴子补丁”：

```ruby
# lib/zeitwerk/kernel.rb
module Kernel
  module_function

  alias_method :zeitwerk_original_require, :require

  def require(path)
    if loader = Zeitwerk::Registry.loader_for(path)
      if path.end_with?(".rb")
        zeitwerk_original_require(path).tap do |required|
          loader.on_file_autoloaded(path) if required
        end
      else
        loader.on_dir_autoloaded(path)
      end
    else
      # code to handle paths not managed by Zeitwerk
    end
  end
end
```

现在 Zeitwerk 就有机会在文件被读取之前去查找所要加载的路径了。通过使用绝对文件路径和`.rb`扩展名（这是可选的）来声明其自动加载，它就能可靠地知道哪个`require`的调用是在其所负责的目录内，以及哪些是针对目录或 ruby 文件的。

对于应用中每个加载的文件，Zeitwerk 都做了如下一些事：

- 如果它是一个由 loader 负责管理的 ruby 文件……
  - **就让 ruby 加载它，并标记其常量为已加载**
- 如果它是一个由 loader 负责管理的目录……
  - **就自动导入模块，并设置其子目录用于自动加载**
- 否则，loader 就不做管理，则……
  - **让 ruby 加载它吧**

目录处理的代码相当难懂，但这里我们能够看到命名空间模块被创建，被赋予给有关的常量名，然后加载操作记录下日志。

到此为止，一切良好！我们加载了常规的文件，看到了隐式命名空间，已有的目录被用于推断命名空间模块。这已经涵盖了 Zeitwerk 三个主要基石技巧中的两个了。

要看到 Zeitwerk 的行囊中最后那一个杀手锏，得来看看另一个场景。

## Explicit namespaces

有时候我们确实想要显式定义命名空间模块，比如在那个模块上有一个方法时。这个场景下将会同时需要一个 ruby 文件来定义模块，和包含那些文件的目录来定义命名空间常量。

这意味着当我们加载一个常规 ruby 文件时，有额外的工作要做。如果那个文件定义了一个 class 或一个 module，并且有一个匹配的子目录在其加载路径中，我们就需要确保为那个子目录设置了自动加载，就如同上面为隐式命名空间所做的那样。

这就是[`TracePoint`](https://ruby-doc.org/core-2.7.2/TracePoint.html) 的用武之地了。`TracePoint`是 ruby 标准库的一部分，能让我们为发生在 ruby 解释器中的确定事件来定义回调，这些事件有：方法调用，module 或 class 的定义，等等。

我们对`:class`事件特别感兴趣，该事件会在一个 module 或 class 无论何时被定义时都告知我们：

```ruby
trace = TracePoint.new(:class) do |tp|
  puts [tp.event, tp.self].inspect
end
trace.enable

module A; end
# [:class, A]
```

通过在这个事件上设置一个 trace，Zeitwerk 就能在任何新模块被定义时知道。类似于它查看`require`的调用以检查它是否负责这些路径，它去查看 class 或 module 的名称以查看它是否是一个常量，其加载应该由 Zeitwerk 来负责。

来看看 Zeitwerk 的做法：

```ruby
# /ex/c.rb
module C
  def self.hello
    "Hi! I'm ::C"
  end
end

# /ex/c/d.rb
module C
  D = "Hi! I'm C::D"
end
```

```ruby
loader.setup
# Zeitwerk: autoload set for C, to be loaded from /ex/c.rb

puts C.hello
# Zeitwerk: autoload set for C::D, to be loaded from /ex/c/d.rb
# Zeitwerk: constant C loaded from file /ex/c.rb
# Hi! I'm ::C

puts C::D
# Zeitwerk: constant C::D loaded from file /ex/c/d.rb
# Hi! I'm C::D
```

这里我们能看到 Zeitwerk 在`c.rb`还仍然在加载时就能够检测`C`的定义。由于`C`是一个它所负责的常量，并且由于有一个`c`目录在 loader 的根目录内，它就向下深入到`c`目录里并设置那个位置的自动加载，搜寻`d.rb`，并设置`C::D`的自动加载。

事实上，这比它表现出来的还要灵活。我们能够从任何地方重新打开自动加载的常量，即使定位已经在 Zeitwerk 所管理路径之外，并且 loader 路径内的定义将依旧能生效。

使用同样的文件来作为我们最后一个示例：

```ruby
loader.setup
# Zeitwerk: autoload set for C, to be loaded from /ex/c.rb

module C
  # Zeitwerk: autoload set for C::D, to be loaded from /ex/c/d.rb
  # Zeitwerk: constant C loaded from file /ex/c.rb
  puts D
  # Zeitwerk: constant C::D loaded from file /ex/c/d.rb
  # Hi! I'm C::D
end

puts C.hello
# Hi! I'm ::C
```

这是一个在传统自动加载模式下会失败的例子。当我们打开在加载路径之外的`C`模块，且它还未被加载时，我们就定义了它；而`Module#const_missing`根本就没被调用。因此，`c.rb`将永远不会被加载，而方法`C.hello`将永远不会被定义。

然而，使用 TracePoint，我们就能发现 autoloader 所应负责的常量的重定义，并从 loader 路径（如果存在的话）预先加载相关文件。

## Conclusion

对于 Zeitwerk 还有更多内容（预加载，重加载，线程安全，等等），但那已经超出本文篇幅了。

至此真是令人愉悦的旅程。这儿仍然有复杂的地方，但基石看起来确实非常牢固了。我还没有在新项目上使用新的 loader，但当我这样做时，我觉得会更有信心，可以或多或少地使用常量（特别是命名空间模块），而不必再太花心思了。

非常感谢 Xavier Noria 以及[其他所有](https://github.com/fxn/zeitwerk#thanks)为 Zeitwerk 做出贡献的人！

