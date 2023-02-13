---
layout: post
title: 懒惰的Neovim
author: xfyuan
categories: [Programming]
tags: [vim neovim]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20230214.jpeg"
---

“懒惰是程序员的美德”，这是一句计算机软件开发领域的名言。越是好的程序员，越追求高效的工作模式。这种高效，在旁人看来，往往体现为一种“懒惰”的外在形式。换句话说，“懒惰”不过是“高效”的一件伪装而已。

我最近接触到了一个超大的 Rails 项目，其目录下包含的文件数量达到了 10 万的级别。当我用 Neovim 打开它开始工作的时候，无论是搜索文件进行切换，还是在项目内 Grep 查找文本，都明显感觉到了响应速度的迟缓，达到了 3 ～ 4 秒的延迟。要知道，这些操作是开发时会频繁进行的操作，一天估计怎么也要数百次，要每次都是这种迟钝的顿挫感，那对工作影响是极大的拖累，已经到了必须要解决的地步。

而故事就从最近刚刚出现的一个 Neovim 插件（Plugin）—— [lazy.nvim](https://github.com/folke/lazy.nvim) 说起。lazy.nvim 的作者是 [folke](https://github.com/folke)。这可是 Neovim Plugin 社区一个著名的作者，

![folke](https://avatars.githubusercontent.com/u/292349?v=4)

他推出了许多高质量的 Neovim 插件，例如：[which-key.nvim](https://github.com/folke/which-key.nvim)，[trouble.nvim](https://github.com/folke/trouble.nvim)，[noice.nvim](https://github.com/folke/noice.nvim)，和当前 Neovim 最火 🔥 的配色主题（colorscheme）：[tokyonight.nvim](https://github.com/folke/tokyonight.nvim)。这些插件现在都高居 GitHub 同类插件排名的前一页或前三页上。

而他最新（2022.12.22）推出的一款 Neovim Plugin Manager（插件管理器），则以极其出色的功能特性和加载速度，从诞生至今不过短短的两个月，就已经迅速在 Neovim 社区内获得推崇无数，把之前一直排名第一的另一款插件管理器 packer.nvim 挤下了王座。lazy.nvim 可以说是站在了 packer.nvim 的肩上，吸取了后者在设计上的经验和教训，做出了更好的使用体验。尤其是在速度上完胜后者，成为其最大的亮点。

从 lazy.nvim 推出之日起，我就一直在关注它的发展——因为 folke 的 GitHub 早就在自己的收藏夹里了 😄，而出于上述两个方面的原因，终于决定花点时间，对自己的 Neovim 配置进行一次完全的重构，基于 lazy.nvim 的重构，而且是全部 Lua 语言的实现方式。

重构的过程就不赘述了。值得一提的一个点是重构之后的文件目录结构更加合理了。原先我是把很多插件的声明加载代码和它们的配置代码进行了分离，写到不同的文件中。这既让文件目录结构变得臃肿，也不那么优美。要修改维护的时候得在多处地方调整，容易遗漏掉。而本次重构则使用 lazy.nvim 的 lazy 加载特性很好地解决了这个问题——每个插件都跟自己的配置放在同一处。

至于重构前后的加载速度有多大差别？用截图直接对比看看吧：

- 旧配置（packer.nvim）

  ![nvim-before-1](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/nvim-before-1.jpeg)

  ![nvim-before-2](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/nvim-before-2.jpeg)

- 新配置（lazy.nvim）

  ![nvim-after-1](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/nvim-after-1.jpeg)

  ![nvim-after-2](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/nvim-after-2.jpeg)

从 216.1 ms 到 23.46 ms，几乎是 10 倍的提升！❤️

回到本文开头的那句话，那么这里可以续一句：

**懒惰是程序员的美德，懒惰（Lazy）的 Vimer 就用 lazy.nvim。**

*如果对我的个人 Neovim 配置有兴趣，可以在[这里查看](https://github.com/xfyuan/nvim)，欢迎交流*🤝
