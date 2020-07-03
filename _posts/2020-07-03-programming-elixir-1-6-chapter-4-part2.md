---
layout: post
title: 《Programming Elixir >= 1.6》第四章：基本语法（节选二）
author: Mr.Z
categories: [ Translation, Programming ]
tags: [elixir]
comments: true
image: assets/images/a015.jpg
---

这是《Programming Elixir >= 1.6》第四章的第二部分。不多说了，直接上正文吧。

【下面是正文】

（接第一部分）

### Binaries

有时你需要以比特位（bit）和字节（byte）序列的形式访问数据。例如，JPEG 和 MP3 文件的头部就有一些字段，那里单个字节可以编码成两三个单独值。

Elixir 通过二进制数据类型来做到这些。二进制字面量被包含在`<<`和`>>`之间。

基本的语法是将连续的整数转成字节：

```elixir
iex> bin = << 1, 2 >>
<<1, 2>>
iex> byte_size bin
2
```

你可以添加修饰符来控制每个字段的类型和大小。下面的例子是一个单字节包含三个字段，大小分别是2、4、2比特位。（示例中使用了一些内置库函数来显示二进制数据的结果）

```elixir
iex> bin = <<3 :: size(2), 5 :: size(4), 1 :: size(2)>>
<<213>>
iex> :io.format("~-8.2b~n", :binary.bin_to_list(bin))
11010101
:ok
iex> byte_size bin
1
```

二进制数据既重要却又神秘。重要在于 Elixir 用它们来表示 UTF 字符串，神秘是因为至少在最初阶段你都不太可能直接使用它们。

### Dates and Times

Elixir 1.3 添加了一个日历（calendar）模块和四个新的日期与时间相关的类型。最初，它们只不过用来放置数据，但 Elixir 1.5 开始为它们添加一些功能。

`Calendar`模块代表了操作日期的规则。当前仅仅实现了`Calendar.ISO`，即公历的 ISO-8601 表示。

`Date`类型处理年、月、日，以及对儒略历的引用。

```elixir
iex> d1 = Date.new(2018, 12, 25)
{:ok, ~D[2018-12-25]}
iex> {:ok, d1} = Date.new(2018, 12, 25)
{:ok, ~D[2018-12-25]}
iex> d2 = ~D[2018-12-25]
~D[2018-12-25]
iex> d1 == d2
true
iex> Date.day_of_week(d1)
2
iex> Date.add(d1, 7)
~D[2019-01-01]
iex> inspect d1, structs: false
"%{__struct__: Date, calendar: Calendar.ISO, day: 25, month: 12, year: 2018}"
```

（`~D[…]`和`~T[…]`是 Elixir 中的魔符*sigil*用法。它们是一种构建值的字面量的方式。当我们读到字符串和二进制时会再遇见它们。）

Elixir 也可以表示一个日期的范围：

```elixir
iex> d1 = ~D[2018-01-01]
~D[2018-01-01]
iex> d2 = ~D[2018-06-30]
~D[2018-06-30]
iex> first_half = Date.range(d1, d2)
#DateRange<~D[2018-01-01], ~D[2018-06-30]>
iex> Enum.count(first_half)
181
iex> ~D[2018-03-15] in first_half
true
```

时间类型处理时、分、秒，以及几分之一秒。后者存储为一个包含微秒和有效位数的元组（tuple）。（时间值与秒中有效位数相关的事实意味着`~T[12:34:56.0]`跟`~T[12:34:56.00]`是不相等的。）

```elixir
iex> {:ok, t1} = Time.new(12, 34, 56)
{:ok, ~T[12:34:56]}
iex> t2 = ~T[12:34:56.78]
~T[12:34:56.78]
iex> t1 == t2
false
iex> Time.add(t1, 3600)
~T[13:34:56.000000]
iex> Time.add(t1, 3600, :millisecond)
~T[12:34:59.600000]
```

一共有两种日期时间的类型：`DateTime`和`NaiveDateTime`。Naive 版本只包含日期和时间，前者则还能关联时区。`~N[...]`的魔符方式可以创建`NaiveDateTime`的结构体。

如果你在代码中使用日期和时间，则可能需要使用第三方库，例如 Lau Taarnskov 的日历库，来扩充这些内置类型。

### Names, Source Files, Conventions, Operators, and So On

Elixir 的标识符必须以字母和下划线开头，后面可跟字母、数字和下划线。这里的字母是指任何 UTF-8 字母的字符（可带组合标记），而数字是指 UTF-8 十进制数的字符。如果你使用 ASCII，那么毋需担心。标识符可用问号或感叹号结尾。

下面是一些合法命名的变量例子：

```elixir
name josé _age まつもと _42 адрес!
```

不合法命名的变量例子如下：

```elixir
name• a±2 42
```

模块（module）、记录（record）、协议（protocol）和行为（behavior）的名称都以大写字母开头，且是驼峰式的（如 BumpyCase）。其他标识符以小写字母或下划线开头，且惯常用下划线分隔单词。当变量首字符是下划线时，只要它在模式匹配或函数参数列表中不被使用，那么 Elixir 是允许的。

惯例上源码文件都使用两个字符的缩进——且用 space 而非 tab。

注释以`#`开头直至一行的结尾。

Elixir 自带了一个代码格式化器，用来把代码转化成"统一规范”的格式。后面会提到它。本书中的很多示例都会跟随该规范（除去个别我认为有点丑陋外）。

#### Truth

Elixir 有三种特别的关于布尔操作的值：`true`、`false`和`nil`。`nil`在布尔上下文中被视作 false。

（提一下：这三种值都是相同名称的原子的别名，所以`true`就是原子`:true`。）

大多上下文中，任何不是`false`或`nil`的值都被认为是 true。有时我们把这称为 truthy 而不叫 true。

#### Operators

Elixir 有丰富的操作符。这儿只列出本书中用到的一部分：

*比较运算符*

```elixir
a === b # strict equality (so 1 === 1.0 is false)
a !== b # strict inequality (so 1 !== 1.0 is true)
a == b # value equality (so 1 == 1.0 is true)
a != b # value inequality (so 1 != 1.0 is false)
a > b # normal comparison
a >= b # :
a < b #:
a <= b #
```

Elixir中的排序比较不像许多语言那样严格，因为你可以比较不同类型的值。如果类型相同或者兼容（如`3 > 2`或`3.0 < 5`），比较会使用自然排序。否则会基于如下规则来比较：

```
number < atom < reference < function < port < pid < tuple < map < list < binary
```

*布尔运算符*

（操作符期望其第一个参数为 true 或者 false）

```elixir
a or b  # true if a is true; otherwise b
a and b # false if a is false; otherwise b
not a   # false if a is true; true otherwise
```

*短路布尔运算符*

操作符可使用任何类型作为参数。任何不是`false`或`nil`的值都被认为是 true。

```elixir
a || b # a if a is truthy; otherwise b
a && b # b if a is truthy; otherwise a
!a # false if a is truthy; otherwise true
```

*算术运算符*

```
+ - * / div rem
```

整数相除会得到一个浮点数结果。使用`div(a, b)`可得到整数。

`rem`是余数操作符，作为函数来调用（`rem(11, 3) => 2`）。它与普通模运算的不同之处在于结果与函数的第一个参数具有相同的符号。

*连接运算符*

```elixir
binary1 <> binary2 # concatenates two binaries (Later we'll
                   # see that binaries include strings.)
list1 ++ list2     # concatenates two lists
list1 -- list2     # removes elements of list 2 from a copy of list 1
```

`in`运算符

```elixir
a in enum  # tests if a is included in enum (for example,
           # a list, a range, or a map). For maps, a should
           # be a {key, value} tuple.
```

### Variable Scope

Elixir 基于词法域，域的基本单元是函数体。定义在函数内部的变量（包括函数参数）都是函数的局部变量。此外，模块也定义了一个局部变量域，但这些变量只能在模块顶层访问，而不能在模块中定义的函数内访问。

#### Do-block Scope

很多语言允许你把多个代码语句放到一起作为单个代码块，通常都使用大括号包起来。下面是个 C 语言的例子：

```c
int line_no = 50;
/* ..... */
if (line_no == 50) {
  printf("new-page\f");
  line_no = 0;
}
```

Elixir 没有类似这样的代码块，但它用一些其他的方式来实现。最常见的是`do`代码块：

```elixir
line_no = 50
# ...
if (line_no == 50) do
  IO.puts "new-page\f"
  line_no = 0
end
IO.puts line_no
```

然而，Elixir 中这是一种危险的代码写法。特别是，很容易忘记在代码块外面初始化`line_no`，且在代码块后又依赖于`line_no`其值。这时，你会看到一个警告提示：

```elixir
$ elixir back_block.ex
warning: the variable "line_no" is unsafe as it has been set inside one of: case, cond, receive, if, and, or, &&, ||. Please explicitly return the variable value instead. Here's an example:
    case integer do
      1 -> atom = :one
      2 -> atom = :two
    end
should be written as
    atom =
      case integer do
1 -> :one
2 -> :two end
Unsafe variable found at:
  t.ex:10
0
```

#### The with Expression

`with`表达式有双重用途。首先，你可以用它定义一个局部变量域。当你计算某个东西需要一些临时变量，又不想让它们泄漏到外部域的时候，可以使用`with`。其次，它能让你掌控一些模式匹配失败情况的处理。例如，文件`/etc/passwd`包含这样的文本

```sh
_installassistant:*:25:25:Install Assistant:/var/empty:/usr/bin/false
_lp:*:26:26:Printing Services:/var/spool/cups:/usr/bin/false
_postfix:*:27:27:Postfix Mail Server:/var/spool/postfix:/usr/bin/false
```

行中的两个数字是对应用户的用户 ID 和组 ID。

下面的代码是查找`_lp`用户的对应值。

```elixir
content = "Now is the time"
lp = with {:ok, file} = File.open("/etc/passwd"),
     content = IO.read(file, :all), # note: same name as above
     :ok = File.close(file),
     [_, uid, gid] = Regex.run(~r/^lp:.*?:(\d+):(\d+)/m, content)
    do
      "Group: #{gid}, User: #{uid}"
    end
IO.puts lp #=> Group: 26, User: 26
IO.puts content #=> Now is the time

```

***格式化代码的比较***

`with`语句正好是 Elixir 关于代码格式化上还未取得一致的例子。如果使用其内置代码格式化器，格式化的结果是这样的。

```elixir
content = "Now is the time"
lp =
  with {:ok, file} = File.open("/etc/passwd"),
       content = IO.read(file, :all),
       :ok = File.close(file),
       [_, uid, gid] = Regex.run(~r/^_lp:.*?:(\d+):(\d+)/m, content) do
    "Group: #{gid}, User: #{uid}"
  end
# => Group: 26, User: 26
IO.puts(lp)
# => Now is the time
IO.puts(content)
```

哪种更好我留给你来判断了。

`with`表达式让我们在打开文件、读取内容、关闭文件和查找某行时能更高效地使用临时变量。`with`中的变量被传递为后面`do`块的参数使用。

变量`content`是`with`的局部变量，不会被在外部访问到。

#### with and Pattern Matching

上面的示例中，`with`表达式的头部使用`=`来进行基本的模式匹配。其中任何一个匹配失败，都会抛出一个`MatchError`异常。但也许我们以一种更优雅的方式来处理。这里`<-`就能一展身手了。如果在`with`表达式中使用`<-`代替`=`，它依然进行匹配，但匹配失败时会返回无法匹配的值。

```elixir
iex> with [a|_] <- [1,2,3], do: a
1
iex> with [a|_] <- nil, do: a
nil
```

我们来使用这种方法让上面示例的`with`语句在无法找到用户时返回`nil`而不是抛出一个异常。

```elixir
result = with {:ok, file} = File.open("/etc/passwd"),
          content = IO.read(file, :all),
          :ok = File.close(file),
          [_, uid, gid] <- Regex.run(~r/^xxx:.*?:(\d+):(\d+)/, content)
        do
          "Group: #{gid}, User: #{uid}"
        end
IO.puts inspect(result) #=> nil

```

当我们试图匹配用户 xxx 时，`Regex.run`会返回`nil`。这使得匹配失败，`nil`成为`with`的返回值。

#### A Minor Gotcha

在表面之下，`with`被 Elixir 视为是一个函数或宏（macro）的调用。这意味着你不能这样写：

```elixir
mean = with                         # WRONG!
         count = Enum.count(values),
         sum   = Enum.sum(values)
       do
        sum/count
       end
```

相反，你可以把第一个参数和`with`写在同一行：

```elixir
mean = with count = Enum.count(values),
            sum   = Enum.sum(values)
       do
        sum/count
       end
```

或者使用括号：

```elixir
mean = with (
         count = Enum.count(values),
         sum   = Enum.sum(values)
       do
        sum/count
       end)
```

和其他`do`语句一样，也有简写方式可用：

```elixir
mean = with count = Enum.count(values),
            sum   = Enum.sum(values)
       do:  sum/count
```

### End of the Basics

至此我们已经讲完了 Elixir 语言的底层部分。接下来两章里我们将会讨论如何创建匿名函数、模块和具名函数。
