---
layout: post
title: 行云流水般的NeoVim Builtin LSP操作
author: xfyuan
categories: [ Tool ]
tags: [neovim]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210225_130053.jpg"
---

既然我们的 NeoVim 已经配置好 Builtin LSP 的 Server 和 Client，就该来看看如何使用它的问题了，也就是相关的 Keybinding 设定。好的 Keybinding 设定会让人在使用时运指如飞。

[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) 的 Readme 文档里已经给出了它的默认 Keybinding 设置，比如下面这几个比较常用的（更多可参考它的文档）：

```lua
-- 查看函数声明
buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
-- 查看函数定义
buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
-- 查看函数帮助文档
buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
-- 查看函数相关引用
buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
-- 查看前一处语法错误
buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
-- 查看后一处语法错误
buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
```

然而，试用之后发现，这样的配置用起来并不舒服。这些快捷键定义杂乱无章，不方便记忆；当结果有多个条目时，它默认使用 Vim 的 Quickfix 窗口，也不方便查询。

对于后者， 自然而然就会想到 FZF 这把犀利的瑞士军刀。Google 之后，发现早就有人想到这点，已经做了一个插件：[nvim-lspfuzzy](https://github.com/ojroques/nvim-lspfuzzy)。这个插件让 NeoVim 把 LSP 的结果列表使用 FZF 来显示，并可进行高效筛选以及代码跳转。这是它的 demo 演示：

![https://github.com/ojroques/nvim-lspfuzzy/raw/main/demo.gif](https://github.com/ojroques/nvim-lspfuzzy/raw/main/demo.gif)

参照其文档安装好之后，在`~/.config/nvim/init.nvim`中添加一行配置：

```lua
require('lspfuzzy').setup {}
```

然后我在`.vimrc`中做了这样的 Keybinding 设定：

```bash
nnoremap <silent><leader>ls <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent><leader>ll <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent><leader>lg <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent><leader>la <cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap <silent><leader>l; <cmd>lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent><leader>l, <cmd>lua vim.lsp.diagnostic.goto_next()<CR>

```

可以看到，我把全部快捷键都定义为以`<leader>l`开头，这样即有规律，便于记忆了。而 FZF 的加持更是如虎添翼，写起代码来行云流水，流畅自如。

下一篇再介绍另一个很棒的 LSP 插件，让人写起代码来更加赏心悦目😄