---
layout: post
title: 把 SF Mono 字体 Patch 为 Nerd Font
author: xfyuan
categories: [ Tool ]
tags: [font]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200708z00pVA.jpg"
---

作为一名开发者，在编程中使用等宽字体是很重要的。我最近几年一直使用的是 Adobe 公司的 Source Code Pro 字体。这款等宽字体的字形设计优美，间距适中，阅读时眼睛不易疲劳，完全可以排到等宽字体的 Top 3。不过再好的东西，时间长了也有审美疲劳。正好最近看到了这一篇文章[《从 DejaVu Sans Mono 换成 Hack 字体了》](https://zhuanlan.zhihu.com/p/89833093)，作者的审美甚合我心，于是打换一款试试。

上面引用的文章中的几款字体当然都很不错，我也一一在本地尝试了，但还是差一点那种令自己心动的“感觉”。正在犹豫不决之际，无意中看到了苹果公司今年的 WWDC 大会，其中正好谈到了字体设计的主题。于是眼前一亮，因为我对于 Apple 在设计上的品味一向是非常信服的，在使用 Source Code Pro 之前，恰恰就是以 macOS 自带的 Menlo 等宽字体作为常用编程字体。而现在，Apple 的新字体已经换成了 SF（旧金山） 字体家族，其中自然也包括等宽系列，**SF Mono**。

因为自己的 macOS 已经升级到了 Catalina，所以实际上系统已经安装了 SF Mono 字体。只是位置比较隐秘，在字体册中是看不到的。其实际位置在

```sh
/Applications/Utilities/Terminal.app/Contents/Resources/Fonts
```

接下来就是需要把 SF Mono 字体 Patch 上 Nerd Font 了。关于 Nerd Font 的介绍，可以参考其[官网](https://github.com/ryanoasis/nerd-fonts)。Nerd Font 其实已经预先 Patch 好了不少常用等宽字体，在其 Release 页面可以直接下载。但 SF Mono 由于 Apple 版权原因，Nerd Font 肯定不能公然发布的，所以只能自己使用 Nerd Font 提供的 Script 来手动 Patch。

过程并不复杂，只是需要先 Homebrew 安装好 fontforge

```sh
brew install fontforge
```

然后把 Nerd Font 的 Repo 使用 git clone 到本地（Repo 非常大，所以使用 --depth=1  选项）

```sh
git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git
```



再把上面目录位置下的 SF Mono 字体复制到某个临时目录，比如叫 tmpfont。

最后，在临时目录下运行命令

```sh
fontforge -script nerd-font/font-patcher -s -c tmpfont/SFMono-Medium.otf -out ./tmpfont/patched
```

即可看到 Patch 的过程在飞快进行。稍等片刻后，在 patched 目录下就能看到生成好的字体了。

安装好字体，把 Terminal 和 Vim 的字体都设置为 SF Mono，随便打开一个文件看看效果吧：

![20200708OuNhXm](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200708OuNhXm.jpg)

