---
layout: post
title: Use vagrant and chef to create virtual environment quickly
author: Mr.Z
excerpt: "Vagrant＋Chef 快速部署虚拟机环境"
modified: 2013-08-15
categories: [ Tool ]
tags: [vagrant,chef]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a002.jpg"
toc: true
---

# Vagrant＋Chef 快速部署虚拟机环境

2013年8月15日上午10:50

## 前言

在上一篇《程序员的神兵利器－Vagrant》讲到了Vagrant实在是我们程序员“居家旅行、杀人灭口”的必备工具。

当时说到使用Box源做好一个虚拟机后，一般都需要安装各种软件包和PHP、Ruby等相关的东西直到最后做好一个完整的服务器环境。

稍微有过一些SA管理员类似经验的人都会明白，这个过程实在不能算是愉快，完全是一个枯燥又乏味、不断重复再重复的累赘事。做好一台服务器环境花上好几个小时那是常有的事儿。万一中途发现遗漏了什么东西忘记安装，十有八九只能从头再来。等你好不容易做完，抬头一看，边上还有好几台机器等着你继续呢，就眼前一黑……

好了，还是打住，不要再回顾这样辛酸的血泪史了——从现在开始可以让它一去不复返，只要你用上Vagrant。

## 概述

Vagrant使用了Chef来帮助我们实现快速、自动化部署的目标。SA管理员要感谢[OPSCODE社区](http://community.opscode.com)为大家做出了如此出色的Chef来极大减轻他们的工作量。*（题外说一句，另一个目前很火的部署工具Puppet也很出色，更棒的是Vagrant同样内置了对Puppet的支持。不过Puppet不是本文讲述的对象，有兴趣的读者可以自己去研究。）*

**Vagrant和Chef都是用Ruby语言写成的，再联想到当今如Rails这样不凡的东西，不禁要额外感慨一下，诞生了如此多Ruby写就的卓越作品，到底是因为Ruby要比其他语言超出一筹，还是因为全世界那些更有创造力的人才都跑到Ruby圈子里去了？更也许是因为Ruby如此优秀，以至于吸引了那么多有创造力的人才？**

## Chef简介

要理解Vagrant＋Chef快速部署的实现，首先需要简单了解一下Chef。

Chef实际上就是一个专业的部署工具。对于每个软件包的安装过程，Chef定义了一整套的规范，按照这个规范的多个文件，各司其职，最后实现完整安装好整个软件包。具体细节这里我们不用关心，只需要知道这些文件最后都放在一个目录内，这个目录就叫做一个“cookbook”。每个cookbook里都可以包含多个“recipe”。

以Git为例，我们来看看一个cookbook的目录结构：

	.
	├── Berksfile
	├── CHANGELOG.md
	├── CONTRIBUTING
	├── Gemfile
	├── LICENSE
	├── README.md
	├── TESTING.md
	├── attributes
	│   └── default.rb
	├── metadata.rb
	├── recipes
	│   ├── default.rb
	│   ├── server.rb
	│   ├── source.rb
	│   └── windows.rb
	└── templates
	    └── default
	        ├── git-xinetd.d.erb
	        ├── sv-git-daemon-log-run.erb
	        └── sv-git-daemon-run.erb

最重要的是那三个子目录：attributes、recipes、templates。

* attributes：顾名思义，目录里放置的是安装过程一些需要用到的参数设定。你可以在后面用自己的设定覆盖它；

* recipes：recipe意思是“菜谱”，很形象的取名。不同的recipe实现不同的安装方式。例如default.rb会直接安装系统编译好的包（以CentOS而言，就等于`yum install git`），而source.rb就会采用源代码编译的方式来安装。其他类推。

* templates：每个软件包安装好后，都可能有自己的conf或其他类似东西，例如Apache在/etc/httpd下的一系列conf。这些conf大部分都需要做一些调整才能用在实际环境中。你就可以把这些conf文件预先改好，放到templates下，到时Chef会自动把它们放到对应的位置上。*当然了，你不能直接copy，看到后缀名erb没有？这是ruby特有的模版文件类型，你要按照正确语法来写才行。*

那么每一个cookbook都需要自己从头来写么？只要你愿意当然没问题，但是完全不用去重复造轮子。OPSCODE社区已经汇集了很多做好的cookbook，相信要比你自己写的完善得多。地址在这里：

OPSCODE Cookbooks：[https://github.com/opscode-cookbooks](https://github.com/opscode-cookbooks)

可以看到这里几乎囊括了所有常见和不常见的软件包，什么Apache、Nginx、MySQL、Git、PHP等等，应有尽有。只管拿来用吧。

另一个概念是“role”。所谓role，就是一系列cookbook的组合，例如Apache＋MySQL＋PHP＋Memcached 这样。**实际上可以看出，role才是我们最后真正需要的东西。**

有了对Chef了解的基础，现在可以步入正题了。

## Vagrant＋Chef实现快速部署

### Vagrantfile的chef部分

Vagrant对Chef的使用方式全在每个虚拟机的Vagrantfile设定文件内，默认是注释掉的，去掉注释后会是这样：

	config.vm.provision :chef_solo do |chef|
	  chef.cookbooks_path = "../my-recipes/cookbooks"
	  chef.roles_path = "../my-recipes/roles"
	  chef.data_bags_path = "../my-recipes/data_bags"
	  chef.add_recipe "mysql"
	  chef.add_role "web"
	
	  # You may also specify custom JSON attributes:
	  chef.json = { :mysql_password => "foo" }
	end

可以看到上述提到的各个Chef术语，现在不用担心看不明白了。

前三行是对cookbooks、roles、data_bags三个目录地址的设定。**特别要强调的是，地址都是以Vagrantfile所在目录为基准的。**

我们可以直接在Vagrantfile添加recipe，如同上面的`add_recipe "mysql"`这样；也可以通过`chef.json = { :mysql_password => "foo" }`来设定attribute。

***但是不建议这么做***，因为我们往往需要安装很多软件包，如果一一放到这里就太臃肿了，而且也不便于其他虚拟机复用。

### 我们采用role方式

假设Vagrantfile所在目录叫vm，我们在vm的同级新建目录chef，chef下新建目录cookbooks、roles、data_bags。

从上面提到的opscode cookbooks github使用`git clone`方式下载你需要的各个cookbook，放到cookbooks目录下，例如我用到的cookbook有这么些：

	https://github.com/opscode-cookbooks/apache2.git
	https://github.com/opscode-cookbooks/mysql.git
	https://github.com/opscode-cookbooks/php.git
	https://github.com/opscode-cookbooks/yum.git
	https://github.com/opscode-cookbooks/openssl.git
	https://github.com/opscode-cookbooks/build-essential.git
	https://github.com/opscode-cookbooks/xml.git
	https://github.com/yevgenko/cookbook-php-fpm.git
	https://github.com/opscode-cookbooks/nginx.git
	https://github.com/opscode-cookbooks/ohai.git
	https://github.com/opscode-cookbooks/runit.git
	https://github.com/opscode-cookbooks/vim.git
	https://github.com/opscode-cookbooks/git.git
	https://github.com/opscode-cookbooks/tmux.git
	https://github.com/opscode-cookbooks/memcached.git
	https://github.com/opscode-cookbooks/logrotate.git
	https://github.com/opscode-cookbooks/man.git
	https://github.com/fnichol/chef-ruby_build.git
	https://github.com/opscode-cookbooks/postgresql.git
	https://github.com/opscode-cookbooks/passenger_apache2.git
	https://github.com/fnichol/chef-rbenv.git

接下来就是创建所需要的role文件了。所有role文件都放在roles目录下，新建一个role：web-server.rb：

	name "web-server"
	
	override_attributes(
	  "nginx"=> {
	    "version" => "1.4.2",
	    "source"=> {
	      "modules"=> [
	        "http_stub_status_module",
	        "http_ssl_module",
	        "http_gzip_static_module"
	      ]
	    }
	  },
	  "mysql" => {
	    "server_root_password" => "1234",
	    "server_repl_password" => "1234",
	    "server_debian_password" => "1234"
	  }
	)
	
	run_list(
	  "recipe[yum::yum]",
	  "recipe[yum::epel]",
	  "recipe[yum::remi]",
	  "recipe[yum::repoforge]",
	  "recipe[build-essential]",
	  "recipe[openssl]",
	  "recipe[man]",
	  "recipe[vim]",
	  "recipe[git]",
	  "recipe[tmux]",
	  "recipe[logrotate::global]",
	  "recipe[xml]",
	  "recipe[ohai]",
	  "recipe[runit]",
	  "recipe[memcached]",
	  "recipe[mysql::server]",
	  "recipe[nginx::source]",
	  "recipe[php-fpm]",
	  "recipe[php]",
	  "recipe[php::module_curl]",
	  "recipe[php::module_gd]",
	  "recipe[php::module_mcrypt]",
	  "recipe[php::module_memcache]",
	  "recipe[php::module_memcached]",
	  "recipe[php::module_mysql]",
	  "recipe[php::module_sqlite3]"
	)

`name "web-server"`表示这个role的名字。

override_attributes 正如之前所说，可以覆盖cookbook默认的attribute，设定成我们自己需要的。

run_list 表示了整个安装用到的全部cookbook列表。稍微要注意下的是双冒号的那些行，如`recipe[mysql::server]`。这表示mysql cookbook下有多个recipe，而我们只使用server那个，其他的不需要。

### 最后一步

**现在离大功告成只差最后一步了！**我们要让Vagrant知道怎样引用所创建的role，修改Vagrantfile chef部分如下：

	config.vm.provision :chef_solo do |chef|
	  chef.cookbooks_path = "../chef/cookbooks"
	  chef.roles_path = "../chef/roles"
	  chef.data_bags_path = "../chef/data_bags"
	  # chef.add_recipe "mysql"
	  chef.add_role "web-server"
	
	  # You may also specify custom JSON attributes:
	  # chef.json = { :mysql_password => "foo" }
	end

### 见证奇迹的时刻

好了，让我们确保网络畅通，在命令行输入`vagrant up`，回车！

当当当当——开始见证Vagrant＋Chef的奇迹时刻吧！

泡一杯咖啡，坐在屏幕前，慢慢地欣赏上面瀑布般不停滚动流出的信息文字：

	[2013-08-13T15:07:02+00:00] INFO: *** Chef 11.4.4 ***
	[2013-08-13T15:07:03+00:00] INFO: Setting the run_list to ["role[web-server]"] from JSON
	[2013-08-13T15:07:03+00:00] INFO: Run List is [role[web-server]]
	…
	…
	[2013-08-13T15:20:30+00:00] INFO: package[php-mysql] installing php-mysql-5.4.17-2.el6.remi from remi repository
	[2013-08-13T15:20:51+00:00] INFO: template[nginx.conf] sending reload action to service[nginx] (delayed)
	[2013-08-13T15:20:51+00:00] INFO: bash[compile_nginx_source] sending restart action to service[nginx] (delayed)
	[2013-08-13T15:20:51+00:00] INFO: service[nginx] restarted
	[2013-08-13T15:20:51+00:00] INFO: Chef Run complete in 827.681006003 seconds
	[2013-08-13T15:20:51+00:00] INFO: Running report handlers
	[2013-08-13T15:20:51+00:00] INFO: Report handlers complete

共用时827秒，一台升级到CentOS最新系统版本，并且安装好Nginx＋MySQL＋PHP＋Memcached＋Git＋Tmux＋Vim的Web Server热腾腾出炉了！

一气呵成啊！套句广告词，“一顺到底才叫爽”！Vagrant＋Chef就是有这么酷。

### 关于role

收拾下激动的心情（相信我，我当时第一次看到这个结果时也真的被震撼了！），再说两句role。如同上面的web-server.rb那样，我们完全可以针对不同的服务器环境做好不同的role，例如DB Server来个db-server.rb，Rails Server来个rails-server.rb……以此类推。到时候，想要什么样的服务器，一转眼就端盘上菜了。

然后，就没有然后了。一劳永逸说的就是这个。繁重的工作从此远去，过程反而成为乐趣。

## 最后

Vagrant＋Chef，可以用于快速部署我们的开发服务器环境，或者是对于线上生产服务器环境的模拟。但总而言之，归根结底都是虚拟机环境，这是由Vagrant本身所决定的。

有读者很可能会问，那么对于真实的服务器环境怎么办呢？也能做到这样一气呵成的部署吗？

当然是可以的。但这个就和Vagrant没有关系了，这时要用到的是Chef。关于Chef的详细讲述将又是另一篇好大文章了。
