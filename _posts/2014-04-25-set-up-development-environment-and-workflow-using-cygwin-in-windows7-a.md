---
layout: post
title: "Set up development environment and workflow using cygwin in windows7 A"
description: ""
category: tool
tags: [cygwin vim tmux zsh git ruby]
---
{% include JB/setup %}

#使用Cygwin在Windows7下构建开发环境和工作流（上）
2014年4月24日下午8:09

##缘起

**现在的工作由于条件限制，最终只能在Windows7下进行开发。这给习惯了OSX/Linux开发环境的我带来了很大问题。感觉好像从现代社会回到原始社会似的，开发效率一下子降低了50%以上。终于忍无可忍之下，尝试看看能否安装上Cygwin这个传说中windows下模拟linux环境的工具。最后经过一番摸索下，到底成功搞定。以此为记。**

![image](http://en.clipart-fr.com/data/icons/set_03/icones_01560.png)

##目标

首先是开发环境，我在OSX/Linux下做开发常用的工具有这么些：

* Terminal
* Vim
* Tmux
* Zshell
* Git
* Ctags

对于工作流（Workflow），这里是指针对web开发，总有常见的一些必要工作步骤，诸如sass/less编译、css/js minify、unit/integration test、甚至包含sftp上传等，我们可以通过专门的workflow tool来把这些步骤串起来，并且让其自动化完成，无需人工去做。

而之前自己使用的工作流工具，主要是Ruby的guard及相关的一系列gem。现在nodejs很火，其中的工作流工具Grunt/Gulp看起来也很厉害的样子，所以这次准备尝试看看。

**本文准备分成（上）（下）两部分，本篇是第一部分，主要看看在Cygwin下的开发环境搭建。下一篇再讲工作流搭建和使用。**

闲话不多说，开始吧。

##开发环境

###Install Nodejs

因为最新的Nodejs已经不支持Cygwin了，所以必须手动安装。

去[Nodejs官网](http://nodejs.org)下载windows的安装包[http://nodejs.org/dist/v0.10.26/x64/node-v0.10.26-x64.msi](http://nodejs.org/dist/v0.10.26/x64/node-v0.10.26-x64.msi)。运行，直接默认安装好即可。

###Install Cygwin

接下来当然是安装Cygwin。去[Cygwin官网](http://www.Cygwin.com)下载安装文件包[http://Cygwin.com/setup-x86_64.exe](http://Cygwin.com/setup-x86_64.exe)，运行。

一路next，安装路径默认为C:\Cygwin64。“Local Package Directory”为临时文件路径，任意即可。

在“Internet Connect”界面，如果要通过Proxy就选第三项，填入Proxy Host和Port。

在“Select Package”界面，选择你准备安装的软件包。大致选择这些：

* vim
* git
* curl
* wget
* tmux
* ncurse(安装才可使用clear命令)
* zshell
* ctags
* ruby

**Cygwin这里的选择方式和普通软件相比有些不同。你要在那个双箭头的图标上点击，就能看到旁边的文字会在install, skip, reinstall, uninstall等状态切换。你要确保想安装的软件包状态在“install”就对了。**

Next确认无误后，Cygwin就会联网下载软件包进行安装了。

最后的finish界面建议勾选在桌面创建快捷方式。

全部安装完成后，双击桌面图标，如果一切正常，会看到Cygwin的窗口出现。再度看到熟悉的Linux Terminal黑色窗口，还真有些小激动的感觉。

良好的开端！


###Settings

要想仅仅凭借Cygwin默认的设置就进行高效的开发，那是远远不够的，我们必须要进行一些设置才行。一起来看看吧。

####Cygwin

首先是Cygwin自身。点击Cygwin窗口左上角，弹出菜单中选择“options”，显示设置窗口。有这么一些较重要的地方需要调整：

* Terminal --> Type change to "xterm-256color"；
* Looks --> Cursor change to "Block"
* Text --> Local change to "en_US", Character set change to "UTF-8";

点击“OK”保存。

####Bash

使用命令：`vim .bashrc`，按照自己习惯修改bash设置。我自己常用的配置可参见[我的github：bashrc](https://github.com/xfyuan/oh-my-cygwin/blob/master/bashrc)

**很重要的一点是，如果需要proxy联网，必须增加如下3行在bashrc：**

	export http_proxy=http://yourname:yourpasswd@proxyaddress:port
	export https_proxy=https://yourname:yourpasswd@proxyaddress:port
	use_proxy=on

另外一个必须设置的，为了我们能在Cygwin中正常运行node, npm命令，需要添加一行（如果之前的node安装在默认路径的话）：

	export PATH=$PATH:"/cygdrive/c/Program Files/nodejs/"

/cygdrive/c/就是c:\盘。Cygwin下可以简单使用命令`cd c:`来进入c:盘。

####Tmux

Tmux默认设置和键盘快捷键并不好用。我自己修改了一些常用的配置和快捷键映射，参见[我的github：tmux.conf](https://github.com/xfyuan/oh-my-cygwin/blob/master/tmux.conf)

####Vim

最重要的Vim编辑器，其配置自然也是需要自定义才能用起来得心应手。我使用了Vundle来管理vim的plugin。具体的配置可参见[我的github：vimrc](https://github.com/xfyuan/oh-my-cygwin/blob/master/vimrc)，[我的github：vimrc.bundle](https://github.com/xfyuan/oh-my-cygwin/blob/master/vimrc.bundles)

####Git

我自己常用的配置可参见[我的github：gitconfig](https://github.com/xfyuan/oh-my-cygwin/blob/master/gitconfig)


###Zshell（可选）

zshell是比bash更好用的一个shell，我现在已经离不开它了。要用zshell，一定少不了oh-my-zsh！

####oh-my-zsh

去[https://github.com/robbyrussell/oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)，参照其说明，我们在Cygwin中运行：

	curl -L http://install.ohmyz.sh | sh

这会自动帮你把oh-my-zsh安装好。这里有点特殊的是，因为是Cygwin，所以最后无法自动切换到zshell，需要我们手工处理一下。vim打开：

	vim /etc/passwd

找到对应你windows7登录账号的那一行，把最后的“/bin/bash”改为“/bin/zsh”。重启Cygwin，大功告成！

####Zshell Setting

使用`vim .zshrc`编辑zshell的设置，大部分应该都可以参考上面对bashrc的配置即可。我自己常用的配置可参见[我的github：zshrc](https://github.com/xfyuan/oh-my-cygwin/blob/master/zshrc)

值得注意的一个地方是，oh-my-zsh自带了很多plugin，在~/.oh-my-zsh/plugins下即可看到，已经帮你做好了很多事情，直接拿来用就好了。找到.zshrc这一行：

	plugins=(git)

加入你需要的即可，例如：

	plugins=(git tmux history ruby)

###Ruby

因为工作用到sass，所以必须要配置好相关Ruby环境。我们来看看具体过程。

我们在安装Cygwin时已经装好了ruby，版本是1.9.3p448。虽然不是目前最新的2.x版本，但对于工作而言也足够了。

接下来是安装sass相关的gem。

如果能直接联网，就再简单不过了。因为我们是用到compass来编译sass，所以直接运行：

	gem install compass

完成。

如果不能直接联网（例如内部限制等原因），那么可以通过本地安装的方式来做。我们需要先把compass的gem包下载到本地。例如对于compass，我们打开其gem页面[http://rubygems.org/gems/compass](http://rubygems.org/gems/compass)，点击页面中的“Download”，即可下载gem包。

需要注意的是页面下部“Runtime Dependencies”那里，如果有列出其他gem，那么每个都需要下载下来。例如compass就列出了三个：chunky_png, fssm, sass。所以我们需要连同compass一共下载4个gem。

全部下载后，在Cygwin下进入对应的目录，运行如下命令：

	gem install --local chunky_png-x.x.x.gem
	gem install --local fssm-x.x.x.gem
	gem install --local sass-x.x.x.gem
	gem install --local compass-x.x.x.gem

x.x.x是各自版本号。注意务必先安装dependencies的gem，最后安装compass。

这样compass就已可以使用了。


***另外，这里强烈推荐安装一个gem：tmuxinator，它将使我们的tmux如虎添翼。具体使用方法会在下篇工作流中讲到。***


###小结

至此，Cygwin的开发环境基本就算就绪了。

现在我在Cygwin中，可以进行几乎全部日常开发工作：

* **使用 vim/ctags 进行代码编辑；**
* **使用 git 进行版本控制；**
* **随时可 ssh 远程连入server进行操作；**
* **使用命令`compass watch`监控并自动编译sass；**
* **zshell/tmux/tmuxinator 使工作效率更高效；**




##工作流

（待续，见下篇）
