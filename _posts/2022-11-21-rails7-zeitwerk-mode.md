---
layout: post
title: Rails7 的Zeitwerk模式解惑
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20221121.jpeg"
rating: 4
---

*本文已获得原作者（**Athira Kadampatta**、**Supriya Laxman Medankar**）和 Kiprosh 授权许可进行翻译。原文详细讲述了 Rails 7 中新的 Zeitwerk 自动加载模式。*

- 原文链接：[Autoloading pitfalls fixed by Rails 7’s default Zeitwerk mode](https://blog.kiprosh.com/autoloading-pitfalls-fixed-by-rails-7-s-default-zeitwerk-mode/)
- 作者：**Athira Kadampatta**、**Supriya Laxman Medankar**
- 站点：Kiprosh，一家印度的软件开发公司。

*【正文如下】*

Rails 中传统的 autoloader 很有帮助，但仍然有一些瑕疵造成自动加载偶尔会出毛病。为了解决这个问题， [Xavier Noria](https://github.com/fxn) 在 Rails 6 的[这个 PR](https://github.com/rails/rails/pull/35235) 中提出了 zeitwerk 模式并使其可配置使用。Rails 7 则更进一步，zeitwerk 完全替代了传统的 autoloader。

本文中，我们会看看传统的自动加载会碰到的问题，以及 Zeitwerk 模式如何解决的。（你可以阅读[这篇文章](https://www.urbanautomaton.com/blog/2013/08/27/rails-autoloading-hell/) 来理解 Rails 的 autoloader 是怎样工作的）。

## How classic autoloading works?

起初，Rails 使用的是在 Active Support 中称作 [Classic Autoloading](https://guides.rubyonrails.org/v6.0/autoloading_and_reloading_constants_classic_mode.html) 的实现来作为 autoloader，一直持续到 Rails 6。

[Classic Autoloading](https://guides.rubyonrails.org/v6.0/autoloading_and_reloading_constants_classic_mode.html) 依赖的是 Ruby 的常量查找。要解析一个常量，会首先在所定义的类的词法域中查找，然后在其祖先链中查找。如果该常量未找到，`const_missing`方法就会被 Ruby 调用。Rails 覆写了 Ruby 的`const_missing` 方法，并使用`autoload_paths` 根据惯例约定来解析常量。

## How zeitwerk autoloading works?

新引入的 [Zeitwerk Mode](https://guides.rubyonrails.org/v6.0/autoloading_and_reloading_constants.html) 则不依赖 Ruby 的常量查找。

相反，它利用的是 Ruby 的 `Module#autoload`  方法提前告知 Ruby 哪个文件将定义一个特定常量，而不需要立即加载该文件。

![https://blog.kiprosh.com/content/images/2022/09/Rails-autoload-how-it-works.png](https://blog.kiprosh.com/content/images/2022/09/Rails-autoload-how-it-works.png)

## Common Problems resolved by zeitwerk mode

传统模式存在许多[问题](https://guides.rubyonrails.org/v6.0/autoloading_and_reloading_constants_classic_mode.html#common-gotchas)，但都已被 zeitwerk 模式解决了。这其中，我们会看看三个不同的陷阱，每个都带有示例。

### 1、**When Constants aren't Missed**

假设我们有如下 model 结构：

```ruby
# course.rb
class Course
  def initialize
    puts "From Course"
  end
end

# mit_university/course.rb
module MitUniversity
  class Course
    def initialize
      puts "From MitUniversity::Course"
    end
  end
end

# mit_university/engineering.rb
module MitUniversity
  class Engineering
    def initialize
      @course = Course.new
    end
  end
end
```

#### With Classic Mode

```ruby
Loading development environment (Rails 5.2.7.1)
2.7.5 :001 > Course.new
From Course
 => #<Course:0x0000563bfa029810>
2.7.5 :002 > MitUniversity::Engineering.new
From Course
 => #<MitUniversity::Engineering:0x0000563bf9e7ab40 @course=#<Course:0x0000563bf9e7aaf0>>
```

这里，由于我们在调用`MitUniversity::Course`之前调用了`Course`，Ruby 的常量查找就已经在内存中自动加载了`Course`，所以如果我们想要为`MitUniversity::Engineering`创建一个对象时，它就会引用到已在内存中被自动加载的`Course`，而不去搜索`MitUniversity::Course`了。这让自动加载依赖于常量被调用的顺序。

#### With Zeitwerk Mode

```ruby
Loading development environment (Rails 7.0.3)
2.7.5 :001 > Course.new
From Course
 => #<Course:0x00005615a9707fa0>
2.7.5 :002 > MitUniversity::Engineering.new
From MitUniversity::Course
 => #<MitUniversity::Engineering:0x00005615ae41d290 @course=#<MitUniversity::Course:0x00005615ae40b270>>
2.7.5 :003 >
```

因为 zeitwerk 模式为所有常量定义了`autoload_path`，它已经知道了到哪里去查找哪个常量。所以尽管首先初始化`Course`，但在`MitUniversity::Engineering`类中调用时，它仍然如期望的那样加载了`MitUniversity::Course`。

### 2、**Autoloading within Singleton Classes**

这是一个关于 Singleton 类方法的类似问题，已经被 zeitwerk 模式所解决。例子如下所示：

```ruby
# mit_university/course.rb
module MitUniversity
  class Course
    def initialize
      puts "From MitUniversity::Course"
    end
  end
end

# mit_university/engineering.rb
module MitUniversity
  class Engineering
    class << self
      def details
        Course.new
      end
    end
  end
end
```

#### With classic mode

如果我们在调用`MitUniversity::Course`之前调用 `MitUniversity::Engineering.details`，它将会抛出`uninitialized constant Course`的错误。这是由于，当自动加载被触发时，Rails 只去检查顶层命名空间，因为 singleton 类是匿名的，所以 Rails 不会知道嵌套的`MitUniversity`。

```ruby
Loading development environment (Rails 5.2.7.1)
2.7.5 :001 > MitUniversity::Engineering.details
Traceback (most recent call last):
        2: from (irb):3
        1: from app/models/mit_university/engineering.rb:5:in `details'
NameError (uninitialized constant Course)
2.7.5 :002 > MitUniversity::Course
 => MitUniversity::Course
2.7.5 :003 > MitUniversity::Engineering.details
From MitUniversity::Course
 => #<MitUniversity::Course:0x0000560cabb27c18>
```

#### With zeitwerk mode

Zeitwerk 模式则不会抛出任何错误，并且即使之前没有自动加载它也能载入该常量。

```ruby
Loading development environment (Rails 7.0.3)
2.7.5 :001 > MitUniversity::Engineering.details
From MitUniversity::Course
 => #<MitUniversity::Course:0x0000559ebba13dd0>
```

### 3、**Autoloading and Single-table Inheritance (STI)**

假设我们有如下 Single-table Inheritance (STI) 的 model 已定义：

```ruby
class Polygon < ApplicationRecord
end

class Triangle < Polygon
end

class Rectangle < Polygon
end

class Square < Rectangle
end
```

`Square`继承自 `Rectangle`，所以当我们调用`Rectangle.all`时，结果必须包含`Polygon`类型的`Square`以及`Rectangle`。

#### With classic mode

然而，当我们调用`Rectangle.all`时，并不能在结果中看到`Square`记录。我们可以看到所生成的 SQL 查询中并未包含`Square`。

```ruby
Loading development environment (Rails 5.2.7.1)
 2.7.5 :001 > Rectangle.all
  Rectangle Load (0.4ms)  SELECT `polygons`.* FROM `polygons` WHERE `polygons`.`type` = 'Rectangle' /* loading for inspect */ LIMIT 11
 => #<ActiveRecord::Relation [#<Rectangle id: 1, area: 100.0, type: "Rectangle", type_id: nil, created_at: "2022-08-28 14:00:50.705523000 +0000", updated_at: "2022-08-28 14:00:50.705523000 +0000">, #<Rectangle id: 2, area: 200.0, type: "Rectangle", type_id: nil, created_at: "2022-08-28 14:01:09.543825000 +0000", updated_at: "2022-08-28 14:01:09.543825000 +0000">]>
 2.7.5 :002 > Square
 => Square(id: integer, area: float, type: string, type_id: integer, created_at: datetime, updated_at: datetime)
 2.7.5 :003 > Rectangle.all
  Rectangle Load (0.9ms)  SELECT `polygons`.* FROM `polygons` WHERE `polygons`.`type` IN ('Rectangle', 'Square') /* loading for inspect */ LIMIT 11
 => #<ActiveRecord::Relation [#<Rectangle id: 1, area: 100.0, type: "Rectangle", type_id: nil, created_at: "2022-08-28 14:00:50.705523000 +0000", updated_at: "2022-08-28 14:00:50.705523000 +0000">, #<Rectangle id: 2, area: 200.0, type: "Rectangle", type_id: nil, created_at: "2022-08-28 14:01:09.543825000 +0000", updated_at: "2022-08-28 14:01:09.543825000 +0000">, #<Square id: 5, area: 250.0, type: "Square", type_id: nil, created_at: "2022-08-28 14:01:52.165141000 +0000", updated_at: "2022-08-28 14:01:52.165141000 +0000">]>
```

要解决这个问题，我们不得不在`rectangle.rb`文件底部加上`require_dependency 'square'`：

```ruby
# app/models/rectangle.rb
class Rectangle < Polygon
end
require_dependency 'square'
```

#### With zeitwerk mode

由于在 zeitwerk 模式中，`Square`已被自动加载进来，我们就无需添加`require_dependency 'square'`这一行了：

```ruby
Loading development environment (Rails 7.0.3)
2.7.5 :001 > Rectangle.all
  Rectangle Load (0.9ms)  SELECT `polygons`.* FROM `polygons` WHERE `polygons`.`type` IN ('Rectangle', 'Square') /* loading for inspect */ LIMIT 11
 => #<ActiveRecord::Relation [#<Rectangle id: 1, area: 100.0, type: "Rectangle", type_id: nil, created_at: "2022-08-28 14:00:50.705523000 +0000", updated_at: "2022-08-28 14:00:50.705523000 +0000">, #<Rectangle id: 2, area: 200.0, type: "Rectangle", type_id: nil, created_at: "2022-08-28 14:01:09.543825000 +0000", updated_at: "2022-08-28 14:01:09.543825000 +0000">, #<Square id: 5, area: 250.0, type: "Square", type_id: nil, created_at: "2022-08-28 14:01:52.165141000 +0000", updated_at: "2022-08-28 14:01:52.165141000 +0000">]>
```

### Conclusion

对于 Rails 7，Zeitwerk 已经成为默认模式，而传统模式已不可用了。这是一个很有影响的变化，改进了 Rails 中常量自动加载的方式，解决了诸多如上所述的传统模式带来的问题。

### References

1. [Common gotchas](https://guides.rubyonrails.org/v6.1/autoloading_and_reloading_constants_classic_mode.html#common-gotchas)
2. [Rails autoloading — now it works, and how!](https://www.urbanautomaton.com/blog/2020/11/04/rails-autoloading-heaven/)
3. [Understanding Zeitwerk in Rails 6](https://medium.com/cedarcode/understanding-zeitwerk-in-rails-6-f168a9f09a1f)
4. [Classic to Zeitwerk HOWTO](https://guides.rubyonrails.org/classic_to_zeitwerk_howto.html)
5. [RailsConf 2022 - Opening Keynote: The Journey to Zeitwerk by Xavier Noria](https://www.youtube.com/watch?v=DzyGdOd_6-Y&list=PLbHJudTY1K0f1WgIbKCc0_M-XMraWwCmk)

