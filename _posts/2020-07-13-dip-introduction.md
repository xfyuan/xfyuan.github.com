---
layout: post
title: 让Docker-Compose如虎添翼的DIP
author: xfyuan
categories: [ Tool ]
tags: [docker]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/20200713BeQY9A.jpg"
---

前一篇博客“[骑鲸之路——Docker模式下的Rails开发环境构筑（翻译）](https://xfyuan.github.io/2020/07/dockeerizing-rails-development/)”的文章末尾，作者提到了一个叫 [Dip](https://github.com/bibendi/dip) 的工具，引起了我的兴趣。作为 Evil Martions 的开源作品，品质应该是有保证的，值得一试。我经过几天的试用后，感觉很是“惊艳”，觉得完全把它看作 Docker 本地开发环境的两大杀手级生产力工具：Docker-Compose + Dip，称为“帝国双璧”亦不为过。这篇博客就来简单介绍下 Dip 的使用。

要说 Dip，得先说 Docker-Compose 这个 Docker 容器的编排工具。一般来说，一个项目都会由多个 Docker 容器组成（几乎不可能只有单个容器），比如“Rails + DB + Redis + ElasticSearch”这样。而 Docker-Compose 则通过设定一个称为`docker-compose.yml`的配置文件，提供了把多个容器“串联”起来的能力，让我们不用手工输入繁琐的 Docker 命令去一个个单独启动容器，这已经大幅度提高了我们使用 Docker 的方便性。下面是个`docker-compose.yml`的例子：

```yaml
version: '2'

services:
  app:
    image: ruby:2.4-buster
    environment:
      - GEM_HOME=/bundle
      - BUNDLE_PATH=/bundle
      - HISTFILE=/app/tmp/.bash_history
    working_dir: /app
    volumes:
      - .:/app
      - bundle:/bundle

volumes:
  bundle:
```

但是，当使用 Docker-Compose 稍微长一点时间后，你可能就会发现依然存在一些让你难受的地方。

比如，当每次要使用它时，都得敲下面这样的命令：

```bash
docker-compose run --rm web bundle exec rails c
```

`docker-compose`这个命令本身就太长，不便于输入。当然，你可以给它设置一个 alias（例如我本地就设为`dp`）。然而后面那一长串又怎么办呢？想想每天的日常开发，可能这种类似的命令要输入好几十次，无论对手指还是心理，都是一种折磨-_-

再比如，使用了 Docker 容器作为开发环境，由于代码的运行、数据库的存储等就都是在容器中了，那么要运行测试或者查看数据库内表中数据时，就都得先使用如下命令进入容器：

```bash
docker-compose run --rm app bash
```

然后在容器内才能再运行所需要的命令：

```bash
8523c2:/# bundle exec rspec
```

把一件事非得分成好几步来操作，这当然显得过于繁琐累赘了，一点也不简洁高效。

**Evil Martins 的开发者们也发现了这一点。而他们则是想办法来尝试解决这个问题。所以，[Dip](https://github.com/bibendi/dip) 就应运而生。**

Dip 的安装很简单，有三种方式，任选其一即可：

- Homebrew 安装：`Homebrew install dip`

- Gem 安装：`gem install dip`

- 直接下载已编译版本：

  ```bash
  curl -L https://github.com/bibendi/dip/releases/download/v6.0.0/dip-`uname -s`-`uname -m` > /usr/local/bin/dip chmod +x /usr/local/bin/dip
  ```

安装好之后，就可以针对你项目下的`docker-compose.yml`，在同级目录下添加 Dip 的配置文件`dip.yml`。

比如对于上面的`docker-compose.yml`例子，对应的`dip.yml`可以是这样的：

```yaml
version: '4'

compose:
  files:
    - docker-compose.yml

interaction:
  bash:
    description: Open the Bash shell in app's container
    service: app
    command: /bin/bash

  pry:
    description: Open Pry console
    service: app
    command: ./bin/console

  bundle:
    description: Run Bundler commands
    service: app
    command: bundle

  rspec:
    description: Run Rspec commands
    service: app
    command: bundle exec rspec

  rubocop:
    description: Run Rubocop commands
    service: app
    command: bundle exec rubocop

provision:
  - rm -rf Gemfile.lock
  - dip bundle install
```

`dip.yml`配置妥当后，就可以开始“愉快”地使用 Dip 了。

首先，你能随时使用`dip ls`，显示配置好的可用命令，而无需每次都去打开文件查找有哪些。显示效果类似这样：

```bash
bash     # Open the Bash shell in app's container
pry      # Open Pry console
bundle   # Run Bundler commands
rspec    # Run Rspec commands
rubocop  # Run Rubocop commands
```

而象上文提到的测试场景，有了 Dip，只需输入这个命令：

```bash
dip rspec
```

即可随时运行所有测试。

**重要的是，Dip 会在运行命令时，首先自动找到`docker-compose.yml`中相应的 Service，自动启动其容器（这里是`app`，如果有依赖的容器也会自动启动），然后在容器内运行设定好的命令（`bundle exec rspec`）。在命令运行结束之后，Dip 还会贴心地自动关闭刚才启动的所有容器，减少系统资源的占用。**

由此可以看到，Dip 针对上面提到的“痛点”，让我们不用登入容器就可以进行各种工作，也不用再担心容器的启动状态，把那些繁琐的操作步骤进行了完美的精简，貌似已经少到“减无可减”的地步了。

**但作者认为这还不够，并不满足于此，所以他给 Dip 添加了一个更加“黑科技”的技能点。**当你在自己的`.bashrc`或`.zshrc`中只要再加上这一行：

```bash
eval "$(dip console)"
```

甚至就可以把上面那些命令中的`dip`都省掉！比如`dip rspec`直接敲`rspec`就可以了。这样在项目下，你可以随时直接运行这些命令：

```bash
bundle install
rails s
rake routes | grep admin
rspec spec/models/user_spec.rb:16
```

而只看这些命令，别人还会以为你完全就是在原生环境而非 Docker 环境下开发呢！**让你使用时根本感觉不到是在 Docker 环境下，这算是真正的大道至简了。**

除此之外，Dip 还提供了诸如`dip ssh`、`dip nginx`、`dip dns`之类的高级功能，本文这里就暂不讨论了，读者可以参看它的[官方文档](https://github.com/bibendi/dip)自行尝试。

总而言之，就像本文标题所说的那样，Dip 让 Docker-Compose 更加如虎添翼，也让本地以 Docker 作为开发环境的体验更加高效流畅、丝般顺滑。作为我个人而言，已经把 Dip 作为必备工具加入自己的日常开发工具箱了。