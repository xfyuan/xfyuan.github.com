---
layout: post
title: 《Programming Elixir >= 1.6》第五章：匿名函数
author: xfyuan
categories: [ Translation, Programming ]
tags: [elixir]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200720IMG_20200717_150745.jpg"
---

函数是 Elixir 的数据转换基石的重要引擎之一。Elixir 函数又分为匿名函数和具名函数。《Programming Elixir >= 1.6》用整个第五章专门讲述了“匿名函数”的概念，可见其重要性。如果是写过 JavaScript 的朋友，对“匿名函数”的概念一定不陌生。而 Elixir 的“匿名函数”到底怎样，看这一章就能完全了解。

*【下面是正文】*

## 5. Anonymous Functions

Elixir 是函数式语言，所以毫不意外函数是一个基础类型。

一个匿名函数使用关键字`fn`来创建。

```elixir
fn
  parameter-list -> body
  parameter-list -> body
end
```

可以把`fn...end`想像成有点像包裹字符串字面量的双引号，只是这里把一个函数而非字符串作为返回值。我们可以把这个返回的函数传递给其他函数，也可以向它传参来运行。

最简单的是，函数有一个参数列表和一个函数体，用`->`分隔。

例如，下面定义了一个函数，并把其绑定到变量`sum`，然后调用它：

```elixir
iex> sum = fn (a, b) -> a + b end
#Function<12.17052888 in :erl_eval.expr/5>
iex> sum.(1, 2)
3
```

第一行代码创建了一个函数，带两个参数（名为 a 和 b）。函数的实现方法位于`->`之后（本例中只是简单把两个参数相加），到关键字`end`为止。我们把该函数存到变量`sum`上。

第二行代码使用语句`sum.(1, 2)`执行了这个函数。点`.`语法表示调用函数，且传递的参数放在括号中。（你可能注意到了，我们在调用具名函数时并没有使用点语法——这是一个匿名函数和具名函数的差别。）

如果函数不带任何参数，仍需要使用括号来调用它：

```elixir
iex> greet = fn -> IO.puts "Hello" end
#Function<12.17052888 in :erl_eval.expr/5>
iex> greet.()
Hello
:ok
```

然而，可以在定义函数时不要括号：

```elixir
iex> f1 = fn a, b -> a * b end
#Function<12.17052888 in :erl_eval.expr/5>
iex> f1.(5,6)
30
iex> f2 = fn -> 99 end
#Function<12.17052888 in :erl_eval.expr/5>
iex> f2.()
99
```

### Functions and Pattern Matching

当我们调用`sum.(2, 3)`时，很自然会认为是简单地把 2 赋予参数 a、3 赋予参数 b。但是这个词，赋予，应当给我们敲响警钟。Elixir 没有赋值，而是试图把值和模式进行匹配。（这些我们已经在前面的《Pattern Matching》一章中讲过了。）

当我们写下

```elixir
a = 2
```

Elixir 会通过把 a 绑定到 2 来进行模式匹配。这才是刚才的`sum`函数被调用时发生的事。如果我们传递 2 和 3作为参数时，Elixir 会试图把传入的参数和定义的参数 a 和 b 进行匹配（这样就绑定 a 为 2以及 b 为 3）。这等同于：

```elixir
{a, b} = {2, 3}
```

这意味着我们在调用一个函数时可以进行更复杂的模式匹配。例如，下面的函数把一个二元元组中的两个元素颠倒了顺序：

```elixir
iex> swap = fn { a, b } -> { b, a } end
#Function<12.17052888 in :erl_eval.expr/5>
iex> swap.( { 6, 8 } )
{8, 6}
```

下一节中，我们会看到通过利用模式匹配的威力来达到函数的多种实现方式。

### One Function, Multiple Bodies

单个函数定义允许你定义不同的实现，具体取决于传递的参数的类型和内容。（你无法根据参数的数量进行选择 - 函数定义中每个子句必须具有相同数量的参数。）

最简单的，我们能够使用模式匹配来选择哪个子句被执行。下面的例子中，由于我们知道`File.open`在成功打开文件时会返回一个首元素为 :ok 的元组，所以我们可以定义一个函数，要么显示打开文件的第一行，要么在文件无法打开时显示一个简单的错误信息。

```elixir
iex> handle_open = fn
...> {:ok, file} -> "Read data: #{IO.read(file, :line)}"
...> {_, error} -> "Error: #{:file.format_error(error)}"
...> end
#Function<12.17052888 in :erl_eval.expr/5>
iex> handle_open.(File.open("code/intro/hello.exs"))
"Read data: IO.puts \"Hello, World!\"\n"
iex> handle_open.(File.open("nonexistent"))
"Error: no such file or directory"
```

来看一下函数定义的内部。2、3行我们定义了两个单独的函数体，每个都用一个元组作为参数。第一个需要元组的首元素为 :ok，第二个使用特别的变量`_`（下划线）来匹配任何其他的值作为首元素。

再看第6行，我们调用了该函数，且把使用`File.open`打开一个已存在文件的结果传递给它。这意味着它接收到的是元组`{:ok, file}`，这正好匹配了第2行的函数字句。相应地调用`IO.read`读取该文件的第一行。

接着我们再次调用`handle_oepn`，这次尝试打开一个不存在文件。返回的元组（`{:error, :enoent}`）被传递给它，并寻找一个可匹配的子句。第2行会由于首元素不是 :ok 而匹配失败，但下一行能匹配成功。error 恰好能完美契合该子句的代码格式。

留意一下代码的其他部分。第3行我们调用了`:file.format_error`，`:file`部分表示了底层 Erlang 的`File`模块，因此我们能调用其`format_error`函数。与第6行的`File.open`调用对比一下，那里的`File`部分对应的是 Elixir 的内建模块。这是一个 Elixir 代码中使用底层环境（函数）的好例子。很棒的是，你能使用全部现有的 Erlang 库——有成千上万经过了时间检验的代码任你取用。但这也有点复杂了，你在调用时将不得不在 Erlang 的函数和 Elixir 的函数中进行区分。

最后，上例中展示了 Elixir 的*字符串插值*。在一个字符串中，`#{...}`的内容会被解析并使用其结果来代替。

### Functions Can Return Functions

这儿有一些奇怪的代码：

```elixir
iex> fun1 = fn -> fn -> "Hello" end end
#Function<12.17052888 in :erl_eval.expr/5>
iex> fun1.()
#Function<12.17052888 in :erl_eval.expr/5>
iex> fun1.().()
"Hello"
```

奇怪的地方在于第一行。它很难理解，所以我们把它展开来看。

```elixir
fun1 = fn ->
					fn ->
						"Hello"
					end
				end
```

变量`fun1`被绑定到一个函数。这个函数不带参数，其函数体是第二个函数定义。第二个函数也不带参数，返回字符串“Hello”。

当我们调用外层函数（使用`fun1.()`），它返回内层函数。这个返回值当我们再调用（`fun1.().()`）时内层函数即被执行，“Hello”被返回。

一般来说我们不会写出类似`fun1.().()`这样的代码。然而我们可以调用外层函数并绑定结果给一个变量。还可以用括号把内层函数括起来使其不易混淆。

```elixir
iex> fun1 = fn -> (fn -> "Hello" end) end
#Function<12.17052888 in :erl_eval.expr/5>
iex> other = fun1.()
#Function<12.17052888 in :erl_eval.expr/5>
iex> other.()
"Hello"
```

#### Functions Remember Their Original Environment

让我们更深入地看下嵌套函数。

```elixir
iex> greeter = fn name -> (fn -> "Hello #{name}" end) end #Function<12.17052888 in :erl_eval.expr/5>
iex> dave_greeter = greeter.("Dave")
#Function<12.17052888 in :erl_eval.expr/5>
iex> dave_greeter.()
"Hello Dave"
```

当我们调用外层函数，其返回内层的函数定义。这时并没有把 name 替换成字符串。然而当我们调用内层函数（`dave_greeter.()`）时，替换发生了，结果显示出来。

有些奇怪的事情发生了。内层函数使用外层函数的`name`参数。在`greeter.("Dave")`执行并返回时，外层函数已经结束，参数已不在定义域了。但是当我们运行内层函数，它又使用了这个参数的值。

这之所以能正常运行是由于在 Elixir 中函数会自动携带变量的绑定，包括其在定义时的域。上面例子中，变量`name`是在外层函数的域中被绑定。当内层函数定义时，它继承了这个域，且把`name`相关的绑定一起带上了。这就是闭包——它的域会包含其变量的绑定，并把这些绑定打包成可以保存并在以后使用的东西。

来看看更多的玩意儿。

#### Parameterized Functions

上一个示例中，外层函数带一个参数，内层函数则没有。现在试试都带参数的情况。

```elixir
iex> add_n = fn n -> (fn other -> n + other end) end #Function<12.17052888 in :erl_eval.expr/5>
iex> add_two = add_n.(2)
#Function<12.17052888 in :erl_eval.expr/5>
iex> add_five = add_n.(5)
#Function<12.17052888 in :erl_eval.expr/5>
iex> add_two.(3)
5
iex> add_five.(7)
12
```

这里内层函数把其参数`other`加到外层函数的参数`n`上。每次调用外层函数，我们传一个值给其参数`n`，它返回一个函数，这个函数把`n`和其自己的参数相加。

### Passing Functions as Arguments

函数就是值，所以可以把它们传给其他函数。

```elixir
iex> times_2 = fn n -> n * 2 end
#Function<12.17052888 in :erl_eval.expr/5>
iex> apply = fn (fun, value) -> fun.(value) end #Function<12.17052888 in :erl_eval.expr/5>
iex> apply.(times_2, 6)
12
```

这里，`apply`是一个带第二个函数和一个值的函数。它返回的是第二个函数以那个值作为参数运行的结果。

在 Elixir 中，这种函数传递的能力几乎在到处都被漂亮地使用着。例如，内置的`Enum`模块有一个`map`函数，使用两个参数：一个集合和一个函数。它返回一个列表，是在那个集合的每个元素上都调用那个函数后的结果。

```elixir
iex> list = [1, 3, 5, 7, 9]
[1, 3, 5, 7, 9]
iex> Enum.map list, fn elem -> elem * 2 end
[2, 6, 10, 14, 18]
iex> Enum.map list, fn elem -> elem * elem end
[1, 9, 25, 49, 81]
iex> Enum.map list, fn elem -> elem > 6 end
[false, false, false, true, true]
```

#### Pinned Values and Function Parameters

我们之前看模式匹配时，看到过 pin 操作符（`^`）允许在模式中使用一个变量的当前值。这种方式也能用在函数参数上。

```elixir
defmodule Greeter do
  def for(name, greeting) do
    fn
      (^name) -> "#{greeting} #{name}"
      (_) -> "I don't know you"
    end
  end
end
mr_valim = Greeter.for("José", "Oi!")

IO.puts mr_valim.("José") # => Oi! José
IO.puts mr_valim.("Dave") # => I don't know you
```

这里，`Greeter.for`函数返回一个带两个 head 的函数（还记得列表的头和尾吗？）。当第一个参数为传给`for`的 name 的值时，第一个 head 就能匹配上。

#### The & Notation

创建短小帮助函数的策略是如此普遍，所以 Elixir 提供了一种快捷方式。我们先来看一下。

```elixir
iex> add_one = &(&1 + 1) # same as add_one = fn (n) -> n + 1 end
#Function<6.17052888 in :erl_eval.expr/5>
iex> add_one.(44)
45
iex> square = &(&1 * &1)
#Function<6.17052888 in :erl_eval.expr/5>
iex> square.(8)
64
iex> speak = &(IO.puts(&1))
&IO.puts/1
iex> speak.("Hello")
Hello
:ok
```

`&`操作符把其后的表达式转换为一个函数。在表达式内，`&1, &2`等类似的占位符依次对应第一个、第二个等函数的参数。所以`&(&1 + &2)`会被转换为`fn p1, p2 -> p1 + p2 end`。

如果你觉得这种做法很聪明，那我们再来看看上面代码中有`speak`的那一行。一般来说 Elixir 会生成一个匿名函数，所以`&(IO.puts(&1))`会变成`fn x -> IO.puts(x) end`。然而 Elixir 注意到匿名函数的函数体是一个简单具名函数（IO 模块的 puts 函数）的调用，且其参数按正确的顺序对应（意思是，匿名函数的第一个参数就是具名函数的第一个参数，以此类推）。因此 Elixir 就会优化这个匿名函数，用具名函数（`IO.puts/1`）的一个直接引用来代替它。

要使其正常工作，参数必须保持正确的顺序：

```elixir
iex> rnd = &(Float.round(&1, &2))
&Float.round/2
iex> rnd = &(Float.round(&2, &1))
#Function<12.17052888 in :erl_eval.expr/5>
```

当用这种方式定义函数时，你可能会看到对 Erlang 的引用蹦出来，这是因为 Elixir 运行在 Erlang VM 上的缘故。当你尝试更多如`&abs(&1)`的东西时，可以看到这种行为的更多体现。这里 Elixir 把对于 abs 函数的使用直接映射到底层的 Erlang 库，返回`&:erlang.abs/1`。

因为`[]`和`{}`在 Elixir 中都是操作符，列表和元组的字面量也能被转换为函数。下面这个函数用来返回一个元组，其元素包含两个整数相除后的商和余数：

```elixir
iex> divrem = &{ div(&1,&2), rem(&1,&2) } #Function<12.17052888 in :erl_eval.expr/5>
iex> divrem.(13, 5)
{2, 3}
```

最后，`&`操作符也可用于字符串（或类似字符串）的字面量：

```elixir
iex> s = &"bacon and #{&1}"
#Function<6.99386804/1 in :erl_eval.expr/5>
iex> s.("custard")
"bacon and custard"

iex> match_end = &~r/.*#{&1}$/
#Function<6.99386804/1 in :erl_eval.expr/5>
iex> "cat" =~ match_end.("t")
true
iex> "cat" =~ match_end.("!")
false
```

还有第二种`&`函数捕获操作符的使用方式。你能传给它一个已有函数的名称和元数（参数的个数），它返回的匿名函数会调用这个函数。传递给匿名函数的参数会依次传给这个具名函数。我们已经看到过了：当你在 iex 中输入`&(IO.puts(&1))`，看到显示的结果是`&IO.puts/1`。这里`puts`是 IO 模块的函数，带一个参数。在 Elixir 中对其的命名方式为`IO.puts/1`。当把`&`放在它的前面时，我们是把它封装为了一个函数。再看看其他的例子：

```elixir
iex> l = &length/1
&:erlang.length/1
iex> l.([1,3,5,7])
4

iex> len = &Enum.count/1
&Enum.count/1
iex> len.([1,2,3,4])
4

iex> m = &Kernel.min/2 # This is an alias for the Erlang function
&:erlang.min/2
iex> m.(99,88)
88
```

这种方式对于我们自己写的具名函数也是适用的（尽管我们还没有讲怎样写具名函数）。

`&`快捷方式为我们提供了一种绝妙的方式来把函数传递给其他函数。

```elixir
iex> Enum.map [1,2,3,4], &(&1 + 1)
[2, 3, 4, 5]
iex> Enum.map [1,2,3,4], &(&1 * &1)
[1, 4, 9, 16]
iex> Enum.map [1,2,3,4], &(&1 < 3)
[true, true, false, false]
```

### Functions Are the Core

本书开头，我们说过编程的基石是数据的转换。函数是 提供这种转换的微小引擎。它们居于 Elixir 的最中心。

至此我们已经领略了匿名函数——尽管我们能把它们和变量绑定，但这些函数自己并没有名称。Elixir 也有具名函数。下一章就会讲到它们。