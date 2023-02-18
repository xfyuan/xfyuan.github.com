---
layout: post
title: 正式切换到NeoVim Builtin LSP了！
author: xfyuan
categories: [Vim]
tags: [neovim]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210203_085652.jpg"
---

从 2019 年起，我的 Vim（实际是 NeoVim）都使用 [coc.nvim](https://github.com/neoclide/coc.nvim)作为 LSP（Language Server Protocol，微软的一套标准）。但现在，时代变了。

不可否认，coc.nvim 刚诞生的时候很是惊艳了众人一把。目前它仍然很火 🔥，GitHub 的 star 数已经达到了 15.2K。

![https://user-images.githubusercontent.com/251450/55009068-f4ed2780-501c-11e9-9a3b-cf3aa6ab9272.png](https://user-images.githubusercontent.com/251450/55009068-f4ed2780-501c-11e9-9a3b-cf3aa6ab9272.png)

但是，由于 coc.nvim 是基于 JS 开发的，它的生态圈（它的各种 Plugin）也都是 JS。而要在 NeoVim 之外再依赖于另一套语言的 Plugin（不光是 JS，有些依赖 Python 的也是），总是会莫名其妙地经常发生各种问题。比如，最近我的 coc.nvim 的自动提示就出毛病了：刚打开 NeoVim 时，提示菜单能出来，但出去吃个午饭回来，下午再继续写代码时，它就死活没响应了（我的 NeoVim 上班时打开后基本一整天都不会关的）。

最近实在对 coc.nvim 的各种毛病忍受不了，于是把目光转向了 NeoVim 的内置 LSP。

调研了一下，发现随着 NeoVim 0.5 版本愈来愈临近，其内置的 LSP 也愈加完善了。如果它的原生 LSP 支持就能满足我的日常使用需求，那 coc.nvim 及其相关 Plugin 整个一套都可以丢掉了。岂不美哉？😄

更令人欣喜地是，目前 NeoVim 官方也认识到了 LSP 对于开发者的重要性，因此对于各种语言 LSP 如何安装和配置，都通过插件和文档的形式，力求让使用者能够毫不费力地经过简单几个步骤就能完成。非常贴心！可以说，比当初我配置 coc.nvim 的时候简单轻松一百倍 ❤️

接下来，后续准备用几篇博客来详细记述一下自己的 NeoVim 有关 LSP 相关配置的内容了。

![https://neovim.io/images/logo@2x.png](https://neovim.io/images/logo@2x.png)
