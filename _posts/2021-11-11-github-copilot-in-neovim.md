---
layout: post
title: 在NeoVim上使用GitHub Copilot！
author: Mr.Z
categories: [ Programming ]
tags: [neovim, github]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/20211110-231856.jpg"
---

最近，GitHub 推出了一个写代码的神器——GitHub Copilot，火遍国内国外，大江南北。GitHub 称其为 **“Your AI pair programmer”** —— “你的人工智能结对编程助手”。

![截屏2021-11-10下午10.23.12](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/截屏2021-11-10 下午10.23.12.png)

有了它，在你的编辑器内写代码时，就不再只是以前那种常规的语法或者代码片段的简单提示了，而是能够智能地给出整段整段的相关代码提示。换句话说，它是在“帮”你写代码，而你完全可以在它的基础上稍微改改就可以使用，这样的开发效率那就高了不是一星半点了。

看看下面的演示，超级 Cool 是吧～

![https://miro.medium.com/max/1400/1*oxlDwTck7wpccg7MEM4l4w.gif](https://miro.medium.com/max/1400/1*oxlDwTck7wpccg7MEM4l4w.gif)

更棒的是， GitHub 官方除了对它自己的编辑器 [VS Code](https://github.com/github/copilot-docs/blob/main/docs/visualstudiocode/gettingstarted.md#getting-started-with-github-copilot-in-visual-studio-code) 支持之外，还推出了针对 [JetBrains](https://github.com/github/copilot-docs/blob/main/docs/jetbrains/gettingstarted.md#getting-started-with-github-copilot-in-jetbrains) 和 [NeoVim](https://github.com/github/copilot.vim#getting-started) 的 Copilot 插件。

而我仔细一瞅，GitHub 给它家找来写 NeoVim 插件的作者，竟然是大名鼎鼎的 Tim Pope，哇哦，真是太令人惊喜了！在 Vim 插件的世界里，一直有着“TPope 出品，必属精品”的说法。恰恰我又是 NeoVim 的重度用户，那必须得试试看了！

在 NeoVim 中使用 GitHub Copilot 相当简单，没有太复杂的配置：

- 你需要有 Nodejs v12 以上的版本；
- 安装 NeoVim 的 0.6.0 的 pre 版本。如果是 macOS 就更简单：`brew install neovim --HEAD`；
- 使用你的 NeoVim 插件管理器安装 GitHub 官方的插件：`github/copilot.vim`。我用的是`packer.nvim`，就是添加一行`use 'github/copilot.vim'`即可；
- 安装好后，运行 NeoVim，然后执行命令：`:Copilot setup`，命令栏会出现相关说明，大概是获取授权之类，依照提示一步步执行操作就好。

这就配置好了！

使用同样简单，**见证奇迹的方法只有一种：敲入一定代码后，稍微停顿片刻，等到暗色提示代码显示后，按`tab`键就行。**有时候，你需要做的就是敲几个字母，按下`tab`，再敲几个字母，再按`tab`，不断继续……直到完事。😉

比如，我想写一个 Ruby 的斐波那契数列的实现方法，先输入`def fibona`后，稍等片刻，GitHub Copilot 就智能地给出了提示：

![截屏2021-11-10下午9.46.13](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/截屏2021-11-10 下午9.46.13.png)

嗯，是我想要的答案，按下`tab`后

![截屏2021-11-10下午9.46.35](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/截屏2021-11-10 下午9.46.35.png)

打完收工～简直是一种神奇的体验感。

写代码从此无难事。
