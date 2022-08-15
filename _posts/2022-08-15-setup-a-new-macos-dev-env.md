---
layout: post
title: Setup a new macOS development environment
author: Mr.Z
categories: [ Programming ]
tags: [mac]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20220815.jpeg"
---

由于一些原因，需要把自己 MacBook 的 macOS 重新安装配置一下**工作/开发**环境。以前都是直接用公司的网络环境，Google、GitHub等访问完全不是问题。结果这次自己一番折腾以后，回头一看，发现还真不是太简单的事情。So，总结其中要点以记录之，作为今后自己和别人的参考，遂有此文。

【初次发布于 2022-08-15】

## 1、创建一个自己专用的 WPS 环境

该步骤此处不多赘述，懂得都懂。

简单说下，我最后选择了 HW 的西雅图，架好 V2ray Server，然后 macOS 使用 V2rayU 连接，能正常打开 Google 即告成功。

## 2、两个 CN 访问的关键预设置

虽然网络都可正常使用了，但由于 CN 的国情在此，对于开发者的几个重要资源的访问速度都成问题，要么不能下载，要么下载超级慢，严重影响正常开发工作，所以一定需要先设置这些才能让下面的安装一路顺风，否则就哭去吧。我就踩进了这个大坑。😭

**目前对于开发者最主要的就是两个资源了：一个 是GitHub，一个是 macOS 专用的 Homebrew。**

### 设置 Homebrew

先说 [Homebrew](https://brew.sh/)。它官网的安装命令是

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

但这个`install.sh`直接拿来用的话，会连接国外的源，无论下载还是更新，都非常慢，所以不能直接使用。解决办法就是使用国内的源，目前主要有*中科大源、清华大学源*两个。我用的是前者。

我们可以先把这个`install.sh`下载下来，用编辑器打开后，找到如下代码：

```sh
  STAT_PRINTF=("stat" "--printf")
  PERMISSION_FORMAT="%a"
  CHOWN=("/bin/chown")
  CHGRP=("/bin/chgrp")
  GROUP="$(id -gn)"
  TOUCH=("/bin/touch")
  INSTALL=("/usr/bin/install" -d -o "${USER}" -g "${GROUP}" -m "0755")
fi
CHMOD=("/bin/chmod")
MKDIR=("/bin/mkdir" "-p")
HOMEBREW_BREW_DEFAULT_GIT_REMOTE="https://github.com/Homebrew/brew"
HOMEBREW_CORE_DEFAULT_GIT_REMOTE="https://github.com/Homebrew/homebrew-core"
```

上面的最后两行就是要修改的位置，把其改为中科大源的 URL：

```sh
HOMEBREW_BREW_DEFAULT_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
HOMEBREW_CORE_DEFAULT_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
```

保存退出。使用`chmod +x install.sh`设为可执行，然后运行`./install.sh`命令安装 Homebrew，就能看到 Homebrew 以飞一般的速度安装了，整个过程大概不到 5 分钟 就完成了。😄

再试试用`brew install xxx`安装自己常用工具，都能非常快就完成。到此 Homebrew 就算配置好了。

### 设置 GitHub

这里的设置，指的是从 GitHub clone 代码。当前的开发者，对 GitHub 的依赖是全方位的，如果 git clone 无法正常工作的话，是会死人的😂。

虽然上面已经配置好网络能正常访问两个 G 打头的网站，但`git clone`仍然需要单独配置才行，否则类似如下这种错误就会不期而至：

```
unable to access 'https://github.com/xxxxxx/xxxx/': LibreSSL SSL_read: error:02FFF03C:system library:func(4095):Operation timed out,
```

在设置前，我们需要先看一下 V2rayU 的 proxy 端口设置情况：

![截屏2022-08-1412.58.48](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/截屏2022-08-14 12.58.48.png)

图中的 sock 和 http 监听端口，可以使用它默认的不变，也可以改成你自己想用的不同端口。这里我们假设就用默认的。

接下来要设置的就是把`git clone `命令走 V2ray proxy 端口。在命令行运行如下命令：

```
git config --global http.proxy http://127.0.0.1:1087
git config --global https.proxy http://127.0.0.1:1087
```

完成。

## 3、安装常用工具

第二步都确认配置好了后，那就可以使用 Homebrew 愉快地安装常用工具了。我的常用工具大概有这些：

```
git git-extras vim neovim tig ripgrep tmux exa zsh
cloc jq ffmpeg rcm htop bat diff-so-fancy zsh-syntax-highlighting
imagemagick reattach-to-user-namespace
postgresql redis
```

## 4、设置开发语言环境

我使用 asdf 工具作为多语言版本管理工具，强烈推荐！！

asdf 具体的使用方法不多说，去看官网就好，很简单。我用 asdf 安装了 ruby、golang、nodejs 环境。前两者都需要设置才能顺利使用。

Ruby 主要需要配置好使用国内的源，用得最多的就是 RubyChina 了。具体做法参考 [RubyChina 官方文档](https://gems.ruby-china.com/)做法就好。

Go 的问题则是它安装 pkg 时大量使用了 github、google 的 URL，github 的问题上面已经配置好了，但后者国内仍然访问困难，所以也需要改成使用国内的源。在`~/.zshrc`中添加如下一行：

```
export GOPROXY=https://mirrors.aliyun.com/goproxy/
```

以使用国内阿里云的源。现在试试用`go get`命令安装一个 pkg，速度果然快多了。👍

## 5、配置 NeoVim

NeoVim 是我的主力编辑器，它的配置文件我放在专门的 GitHub repo 上（https://github.com/xfyuan/nvim）。

把配置文件 clone 到本地的 NeoVim 默认配置文件地址：

```
cd ~/.config
git clone https://github.com/xfyuan/nvim.git
```

然后命令行打开 neovim，运行`:PackerInstall`命令安装插件。由于前面 GitHub 都已经配置好，所以安装速度应该会很快。

## 结语

到此，主要的开发/工作环境算是基本可用了。

至于一些其他常用软件，如微信等，不在本文的范畴之内。

***后续如果有新的变动，本文都会持续更新。***

#### 参考文章

- [2022最新V2Ray搭建图文教程，V2Ray一键搭建脚本！](https://www.itblogcn.com/article/1501.html)
- [mac下镜像飞速安装Homebrew](https://zhuanlan.zhihu.com/p/90508170)
- [M1芯片Mac上Homebrew安装](https://zhuanlan.zhihu.com/p/341831809)
- [github克隆走v2ray代理的配置](https://www.cuger.top/github%E5%85%8B%E9%9A%86%E8%B5%B0v2ray%E4%BB%A3%E7%90%86%E7%9A%84%E9%85%8D%E7%BD%AE/)
- [V2Ray 使用自定义 PAC](https://tr0py.github.io/V2Ray-PAC-Solution/)
