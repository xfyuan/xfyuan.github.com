---
layout: post
title: JetBrains 惜 Neovim
author: xfyuan
categories: [ Programming ]
tags: [jetbrains, neovim]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img_20230911.jpg"
---

众所周知，JetBrains 是全球知名的 IDE 软件。我这两年一直申请用着它家的[开源开发许可证](https://www.jetbrains.com/community/opensource/#support)。前两年我还专门写过[一篇博客](http://xfyuan.github.io/2021/09/jetbrains-assigned-open-source-licence-to-me/)来讲述申请的具体流程。

但今年情况有了变化。JetBrains 家的政策貌似变了。

之前我一直是以我自己的这个博客的 GitHub Repo 来申请的。而在前两天我重新填写申请今年的许可时，却收到了这样一封邮件：

```markdown
We're writing to you in regards to your OSS development license request.

We've run an automated check of your GitHub repository to see if your open source project meets the requirements of our Open Source Support Program. Unfortunately, the check failed because the project has not been actively developed recently. We need to see regular code commits submitted for the past 3 months or more. Readme.md and other non-code commits do not count.

If you continue working on your project for a few more months, you're welcome to re-apply for support.
```

大意是说“我们检查了你的 Repo 仓库，但是很抱歉，发现项目近三个月没有更新。我们需要看到正常的代码提交。Readme.md 和其他非代码类型的提交是不算数的。”

我的博客近三个月当然有提交更新，所以三个月这个条件是满足的。不过，文章都是以`Markdown`的格式存放的，所以全被 JetBrains 识别为非代码提交了😭

好吧，估计是太多 Markdown 内容的 Repo 被用来提交，所以 JetBrains 干脆加上了这条新规则。

那么，就换一个好了。

看我博客的朋友都知道，我是 Vim/Neovim 的重度使用者。恰好，我的另一个频繁更新的 GitHub Repo 正是我的 [NeoVim 配置仓库](https://github.com/xfyuan/nvim)。这个 NeoVim 的配置全都是以 Lua 语言的文件，完完全全是地道的编程语言，这回绝对符合条件了吧😄

于是乎，重新按照[申请流程](http://xfyuan.github.io/2021/09/jetbrains-assigned-open-source-licence-to-me/)，填写表单，提交。轻车熟路。

不出所料，第二天就收到了认证成功的邮件。

```markdown
Congratulations, your request to JetBrains for Open Source development license(s) has been approved! The license certificate is attached to this message.
```

收到邮件时，我对 JetBrains 产生了一丝敬意。因为 NeoVim 就是开发者常用的编辑器之一，跟它家的 IDE 其实是同行了。而它不认为这是上门来砸场子，一视同仁地颁发许可证，惺惺相惜，不外如是。想起一句词：“天下英雄谁敌手？曹刘。”🤝🤝

至于有朋友可能会问，那下一句“生子当如孙仲谋”该是谁呢？————也许是 Visual Studio Code 吧。

