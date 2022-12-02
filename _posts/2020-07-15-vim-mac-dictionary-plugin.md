---
layout: post
title: 实现在Vim内直接查询macOS词典的Plugin
author: xfyuan
categories: [ Tool ]
tags: [vim]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715xotlyj.jpg"
---

我每天都会使用 Vim。用 Vim 不论编写自己的代码还是阅读别人的代码，这中间自然都会碰到一些不认识的英文词汇，自己就总会习惯性地想随手查一下单词的中文释义。而如何最高效地解决这个问题便成了一个有趣的事情。

最早的时候，基本上就是用鼠标点开 macOS 的词典 App，输入要查询的单词，查看结果。如果一天中只不过偶尔为之，那当然不是问题。但有时难免会有频繁碰到陌生词汇的时候，每个要查的词都得手动输入，这样繁琐的做法自然就不可取了。

然后就用上了 macOS 上大名鼎鼎的 Alfred 这个 App。GitHub 上有一个给它写的 workflow，让你可以在 Alfred 的弹出窗口中输入要查的单词，下方自动显示查询结果。这在效率上已经是前进了一大步，基本足够应对绝大多数的场景。但用的时间长了，还是发现它有不足的地方。因为 Alfred 显示查询结果时只能在一行中，而很多时候一个单词的释义内容很长，一行根本显示不完。这时就只能还是再敲一下回车键打开词典查看。比如下图中的 Service 释义，实际内容可远远不止截图中这么一点：

![20200715w8UrRn](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715w8UrRn.png)

前几天，又碰到了这样的场景，多次不断打开又关闭 macOS 自带词典之后，我就在考虑能否换个思路完全解决这个问题？

既然自己主要都是在 Vim 内才有这个“需求”，平时一般的场景用 Alfred 便足够对付了，那么就重点想想在 Vim 内的解决方案好了。这么一想，自然首先考虑 Vim 的 Plugin 了。Vim 的 Plugin 生态圈足够大，说不定有人早就碰到类似问题，已经写了 Plugin 来实现呢。

上 GitHub 一搜，还真被我找到这么一个：[vim-mac-dictionary](https://github.com/johngrib/vim-mac-dictionary)。不过看提交历史，最近一次还是在 2018 年，貌似作者已经没管了。本地安装试了下，倒是能工作。但我不满意的一点是，它把查询结果都显示在下方的弹出 quickfix 窗口内，而且默认高度不够，释义文本稍微多一些就看不完，还得把光标移过去，手动翻页查看。使用体验并不好。

现在已经是 9012 年了，我早已用上了 NeoVim，其很棒的一个特性就是支持 Floating Window。**那么用 Floating Window 来显示词典释义，显示面积足够大，看完释义后再快捷键快速关闭弹窗，继续在原来窗口内工作，这样的工作流既顺畅又自然，岂不美哉？**

于是就按这个思路来吧。具体实现过程并没啥太特别的地方，这里不赘述了。反正最后上述想法得以完美实现，我的这个 [Vim Plugin](https://github.com/xfyuan/vim-mac-dictionary) 已经放到了 GitHub 上，目前而言，实际体验自己感觉很满意。

附一个动态效果图：

![vim-mac-dict-plugin-demo](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200714vim-mac-dict-plugin-demo.gif)