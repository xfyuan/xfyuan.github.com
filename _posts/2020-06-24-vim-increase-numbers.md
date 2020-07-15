---
layout: post
title: Vim 批量递增数字的技巧
author: Mr.Z
categories: [ Vim ]
tags: [vim]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715vim-increase-numbers.gif"
---

众所周知，Vim 自带的默认快捷键`⌃-A`、`⌃-X`可以对单个数字进行增减操作，这在碰到适用的场景时当然非常方便。但是，编程中另一种场景也是经常遇到的：

**你可能要同时对多行上的多个变量命名，名称中带有数字，且需要依次递增。**

比如 Vim 中可以通过`yy4p`快速复制生成这样的多行变量

```ruby
car01
car01
car01
car01
car01
```

那么如何把其快速改写为

```ruby
car01
car02
car03
car04
car05
```

这样的结果呢？Vim 是否有快捷键或什么技巧来高效处理这个场景？还是说只能针对每个变量名一个一个手工去改？

Vim 是如此强大，答案当然是肯定的。

看本文头部的 Gif 操作动图就一目了然了。



