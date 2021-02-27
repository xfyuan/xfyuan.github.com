---
layout: post
title: NeoVim Builtin LSP的基本配置
author: Mr.Z
categories: [ Tool ]
tags: [neovim]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210220_115520.jpg"
---

上一篇博客说过，现在官方对 NeoVim Builtin LSP 的配置已经做到了足够简洁易用的地步。这一篇就来看看怎样按照 NeoVim 官方的说明，一步一步把 LSP 给配置为可用于实际开发中。

为了简化 LSP 的安装和配置，NeoVim 官方专门创建了 [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) 插件来帮助我们。这个插件把所有 LSP 背后的繁琐都封装到其内部，让使用者再也毋需担心出现费了大半天功夫结果仍然无法用起来的事。

我自己的日常开发工作中主要会用到 Ruby、JavaScript 和 Golang 这几种编程语言，所以当然就需要把 NeoVim 的 LSP 配置为支持它们了。

首先，安装好 nvim-lspconfig 插件：

```bash
Plug 'neovim/nvim-lspconfig'
```

然后，按照 nvim-lspconfig 的文档说明，打开`~/.config/nvim/init.vim`，在其中添加如下配置：

```lua
lua << EOF
require'lspconfig'.solargraph.setup{}
require'lspconfig'.tsserver.setup{}
require'lspconfig'.gopls.setup{}
EOF
```

接下来的步骤是……没了！😄

我的 Ruby、JavaScript 和 Golang 三种语言在 NeoVim 上的 LSP 支持就此完成！

当然了，全部工作其实还没完。但 NeoVim 层面的部分确实已经结束了，算是足够简洁了吧？

*上面我都是使用了 nvim-lspconfig 的默认配置，因为足够了。但如果你想要针对每种语言单独做一些特别的设置，那么可以参考 nvim-lspconfig 的[这个文档](https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md)。*

接下来，我还需要在自己系统上把上述三种语言的 LSP Server 安装上，然后 NeoVim 以上所配置好的 LSP Client 就可以正确地连接上它们。

Ruby 的  LSP Server 我使用 Solargraph，通过 Gem 安装：

```bash
gem install solargraph
```

JavaScript 的  LSP Server 我使用 tsserver，通过 npm 安装：

```bash
npm install -g typescript typescript-language-server
```

Golang 的  LSP Server 我使用 gopls，通过 go mod 安装：

```bash
go get golang.org/x/tools/gopls@latest
```

全部装好之后，用 NeoVim 打开一个上述三种语言的任意一个项目的代码文件，在 Vim 命令行模式下输入`:LspInfo`，回车，应该就可以看到所有配置成功的 LSP 信息了。

