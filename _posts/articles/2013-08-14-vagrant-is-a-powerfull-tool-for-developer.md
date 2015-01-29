---
layout: post
title: A powerful tool for developer, Vagrant
excerpt: "程序员的神兵利器－Vagrant"
tags: [vagrant]
modified: 2013-08-14
comments: true
---

* Table of Contents
{:toc}

#程序员的神兵利器－Vagrant

2013年8月14日上午10:50

####参考网址：

[Vagrant官网](http://www.vagrantup.com)

[Railscasts: Virtual Machines with Vagrant](http://railscasts.com/episodes/292-virtual-machines-with-vagrant)

##缘起

![Vagrant](http://www.vagrantup.com/images/logo_vagrant-81478652.png)

最近发现了一个超酷的东西——Vagrant，一见之下惊为天人。真是又高兴又伤心，高兴的是这东西简直太棒了，从此自己的“兵器谱”里又增加一件利器；伤心的是怎么现在才看到，实在是相见恨晚啊。

##什么是Vagrant

简单来说，**Vagrant 就是一个虚拟机的集成管理器**。

我们用它可以快速创建虚拟机，可以快速部署好所需的各种环境，无论你想要开发环境或是上线环境都能一键搞定。甚至你可以部署多台都没问题。

想想看，假设一台Application Server，再加一台Master Database + 一台Slave Database，也许可以再来一台Monitor Server等等，全部都可以用你那台开发工作的电脑来实现，只要有足够内存。是不是很牛的样子？所以说，要让我们不用Vagrant，给个理由先？

##安装

我们所需要的实际是 Vagrant＋Virtualbox 这两样东西。

Vagrant可以在上面列出的官网去下载软件包，目前最新版本是1.2.7。

Vagrant支持的是Virtualbox这个虚拟机软件。Virtualbox是开源的，它以前是独立发布，现在已经被Oracle收购了，直接去官网下载安装即可。另外，Vagrant还支持VMvare虚拟机，不过这个功能是收费的，一般就不用考虑了。

##基本使用

###添加Box源

我们要先确定使用什么系统，是准备用Ubuntu，还是上Centos，或者BSD系列。确定好后，我们就可以到[vagrantbox.es](http://vagrantbox.es)这个地方查找。Vagrant把每个打包好的虚拟机系统叫做box。这里都是网络上的热心人已经打包好的box，各种系统都有，必有一款能满足你的需要。

例如我习惯使用CentOS，就可以这样来添加一个box到Vagrant里：

	vagrant box add CentOS-64 http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130427.box

这样Vagrant就会下载这个box，下载完成后添加到自己的box列表里。可以用：

	vagrant box list

来查看。***如果网速不够快，一个技巧就是可以先把这个box下载到本地，然后在上面命令中使用本地文件地址就好了。***

每个box都相当一个系统的安装源，接下来我们就要用到了。

###开始第一个虚拟机

我们新建一个工作目录vm，然后在vm里使用这个命令：

	vagrant init CentOS-64

然后我们会看到如下提示信息：

	A `Vagrantfile` has been placed in this directory. You are now
	ready to `vagrant up` your first virtual environment! Please read
	the comments in the Vagrantfile as well as documentation on
	`vagrantup.com` for more information on using Vagrant.

Vagrant在vm目录生成了一个“Vagrantfile”的设定文件。全部的设定都在这个文件里，我们先不管，以后再研究。现在先让虚拟机跑起来！

输入命令：

	vagrant up

稍微等待一段时间后，我们就会看到Vagrant会输出很多行信息：

	Bringing machine 'default' up with 'virtualbox' provider...
	[default] Setting the name of the VM...
	[default] Clearing any previously set forwarded ports...
	[default] Creating shared folders metadata...
	[default] Clearing any previously set network interfaces...
	[default] Preparing network interfaces based on configuration...
	[default] Forwarding ports...
	[default] -- 22 => 2222 (adapter 1)
	[default] Booting VM...
	[default] Waiting for VM to boot. This can take a few minutes.
	[default] VM booted and ready for use!
	[default] Configuring and enabling network interfaces...
	[default] Mounting shared folders...
	[default] -- /vagrant

Yes！虚拟机已经正式在运行了。

那么怎么连上去呢？照常规那样开一个ftp软件，输入ip、帐号、密码去连接吗？No！

	vagrant ssh

这个命令直接就把你送进虚拟机去了。默认帐户是vagrant，密码一样。现在开始折腾这台机器吧……

另外，虚拟机已经有一个/vagrant目录，和我所在的vm目录是直接映射的。vm里的任何文件都能在/vagrant目录里看到和使用。酷吧？

###打包自己的Box

当你把自己的虚拟机做好所需的环境，例如我的CentOS-64会升级好yum软件包，安装好MySQL、PHP等环境后，不想以后每次都把这个过程重来一次，或者假如在团队里不想每个成员的开发环境各自五花八门乱七八糟，我就可以把这个做好的CentOS-64打包出来，分享给团队成员。

	vagrant package

稍等一点时间后，Vagrant会在vm目录下输出一个package.box的文件。没错，这完全跟我们在上面vagrantbox.es下载的box文件一样的，实际上那里热心人分享的box文件都是这么来的。所以可以用同样的方法添加到box列表里去，例如：

	vagrant box add CentOS-64S package.box

这样以后我们就可以直接使用这个新box来生成虚拟机：

	vagrant init CentOS-64S

新虚拟机直接就是一个做好的PHP Server。

原来的CentOS-64这个box完全可以删掉了，还可以节省一点空间：

	vagrant box remove CentOS-64

##虚拟机的设定

上面说到Vagrant会为每个虚拟机都生成一个Vagrantfile设定文件。

用任意文本编辑器打开它，如果你对Ruby语言有一点了解的话，就会明白实际整个内容都是Ruby Code。而且Vagrant很贴心的准备了详尽到有些啰嗦的注释给你，这里强烈建议你仔细看看。实际对于每个选项设定都说的非常清楚了。

主要的设定大概有这么些：

***注：下面提到的设定有些是默认注释掉的，没有开启，务必要取消注释才会生效。***

	config.vm.box = "CentOS-64"

这指定了虚拟机使用哪个Box源。

	config.vm.network :forwarded_port, guest: 80, host: 8080

这个设定非常牛，它会把Host机器（就是安装Vagrant的机器）的8080端口转发（forwoard）到虚拟机的80端口。例如你部署到虚拟机的网站运行后，当你在Host机器上浏览器打开`http://localhost:8080`后，就会自动转到虚拟机正在运行的Apache或Nginx 80端口服务，也就是访问部署的网站。**实际上，这个功能是架起了Host机器和虚拟机之间沟通的桥梁。** 以此类推，我们可以增加更多的端口转发，如常用的MySQL 3306端口，Rails 的3000端口等。

	config.vm.network :private_network, ip: "192.168.33.10"

	config.vm.network :public_network

这两个是设定网络连接方式。前者把虚拟机网络设定为私有模式，和你Host机器同一网络的其他电脑是看不到它的。后者相反，设为公开模式，和你Host机器有类似的IP，同一网络的其他电脑都能看到它。**一般都采用前者，而且IP也建议不以“192.168”开头，以免冲突，例如可以设为“66.66.66.10”这样……**

	vb.customize ["modifyvm", :id, "--memory", "1024"]

这个可以手工设定虚拟机使用多少内存，根据你自己情况来定就好。类似Linux这样的Server，一般512就够了。

其他的设定还有些，不是特别重要，读者可以自行去了解看看了。

##多台虚拟机组合

我们的产品正式部署上线的时侯，经常都可能不是一台而采用多台服务器的情况。例如 Database 要和 Application 分开，Database 有时还有 Master、Slave 之分，有时还需要 Balance Server 等等。更重要的是，这么多台机器之间都是需要相互沟通的。那么在正式部署前进行实况模拟就是很有必要的了。

**这时就正是Vagrant的英雄用武之地，这可是Vagrant的“杀手级功能”。重头戏登场！**

我们来架设一台Web Server，一台Master Database ＋ 一台Slave Database 的组合。

在Vagrantfile设定文件里改成这样：

	Vagrant.configure("2") do |config|

	  config.vm.define :web do |web|
	    web.vm.box = "CentOS-64"
	    web.vm.network :private_network, ip: "66.66.66.10"
	  end

	  config.vm.define :db0 do |db|
	    db.vm.box = "CentOS-64"
	    db.vm.network :private_network, ip: "66.66.66.20"
	  end

	  config.vm.define :db1 do |db|
	    db.vm.box = "CentOS-64"
	    db.vm.network :private_network, ip: "66.66.66.21"
	  end

	end

各项设定如同上述，只是名称分别使用了“web”、“db0”、“db1”，并且设定了不同的IP。

然后我们使用`vagrant up`启动，可以看到跑出来很多行信息，注意到每行前面都有类似“[web]”、“[db0]”这样的开头，表示各自是哪一台机器。信息流停止后，表示我们的虚拟机组合跑起来了！

SSH可以指定连到哪一台去：

	vagrant ssh web

	vagrant ssh db0

酷得一塌糊涂啊！！

再来看看各台虚拟机之间的连通。

先进去到Web Server：

	vagrant ssh web

在web机器里连接db0:

	ssh 66.66.66.20

轻而易举大功告成！

还有更牛的东西在后头呢。Vagrant允许你单独启动组合里某一台虚拟机，例如：

	vagrant up web

只启动了Web Server，Database 机器并没有启动。

Vagrant甚至允许你在启动时使用正则表达式：

	vagrant up /db[0-9]/

现在你启动全部Database Server了，即使你有db0,db1,db2...db9 这么多台也没问题。

现在对Vagrant有一个大概的了解了吧，就赶紧去试一试吧，相信你会像我一样喜欢上它。
