---
layout: post
title: 在 Github Actions 支持下升级博客到 Jekyll 4.1
author: Mr.Z
categories: [ Tool ]
tags: [jekyll, github]
comments: true
image: assets/images/a007.jpg
toc: true
---

我一直使用 Github Page 作为自己的博客，简单，够用。而博客是使用 Jekyll 来搭建的，这也是 Github 官方的推荐方式之一。最近发现 Jekyll 已经到了 4.1.0，于是打算把博客也升级到最新版。说干就撸起袖子开始。

### 博客现状

不过稍微快速调研了一下，发现一个悲催的事情：Github 官方目前还是只支持到 Jekyll 3.8.7 而已。虽然这个版本也不算太旧，但最近一次更新也是两年前了。

另外，Jekyll 4 所支持的 Plugin，目前的 Github Page 也暂时还不支持。

怎么办呢？

当然是继续寻找技术层面的解决方案先，而且也很快就找到了——Github 官方去年发布的 **Github Actions** 就是解决方案！

### Github Actions

Github Actions 简单来说就是 Github 官方推出的一套 CI/CD 工具，把 build、test、deploy 直接和你的 Github 代码库整合起来，再也不用去寻找第三方的工具。毕竟自家的东西用起来最称心不是。

Github Actions 的基本流程就是，当你有代码 push 到 Github 代码库时，就会触发 Actions 中事先定义好的 Workflow，对你的代码进行 build、test、deploy等操作。这正好满足了新 Jekyll 版本的要求。

### 升级到 Jekyll 4.1

先 Google 找到一套 Free 的 Jekyll 4 的 Theme（我最终选择的是[Memoirs Jekyll Theme](https://www.wowthemes.net/memoirs-free-jekyll-theme/)）。然后在本地按其要求对原有代码和文件进行替换、修改等常规操作不提。Push 之前当然需要先在本地预览下效果，那么在代码库下先运行

```sh
bundle install
```

安装 Jekyll 4.1 等 Gem 包后，再运行

```sh
bundle exec jekyll serve --watch
```

这样就可以让 Jekyll 运行在本地的 4000 端口。打开浏览器，输入

```ruby
http://localhost:4000
```

就能看到新 Theme 的模样了。

### Jekyll 4 的 Github Actions 支持

进行必要的修改完成，确定无误后，接下来就进行配置 Github Actions 的环节了。这也是最关键的部分，决定了新博客能否被 Github 正确地解析显示。如果不对，博客就无法被人访问了。

幸运的是，这个需求是如此广泛，Jekyll 官方已经给出了一个 Github Actions 的配置范例：[Github Actions for Jekyll 4](https://jekyllrb.com/docs/continuous-integration/github-actions)。从我自己配置好的最终结果来看，基本上只要安装这个官方文档来就万事大吉。这里只简单列出几个比较关键的点，简单说一下。

#### 创建 Github Actions 的 Workflow

在代码库根路径下创建`.github/workflows`，然后在该目录下创建一个`yaml`文件，文件名比如叫`gh-pages.yml`。

这个`yaml`文件的内容可以直接拷贝文档上的范例，因为都是通用的：

```yaml
name: Build and deploy Jekyll site to GitHub Pages

on:
  push:
    branches:
      - master

jobs:
  github-pages:
    runs-on: ubuntu-16.04
    steps:
      - uses: actions/checkout@v2
      - uses: helaili/jekyll-action@2.0.1
...
```

这个`yaml`实际上就是定义了 Github Actions 的一个 workflow。当然其具体规范和含义，可以参考 Github 的官方文档说明，这里就不赘述了。

#### 关于 JEKYLL_PAT

唯一一个需要注意的地方，就是`JEKYLL_PAT`这里。这是设定了一个 secret 的环境变量，`JEKYLL_PAT`是需要设置的一个 Github 的*Personal Access Token*，具体设置方法参考上面 Jekyll 文档中`Providing permissions`这一节的步骤来做即可。

### 大功告成

全部完成之后，把所有新代码 Push 上 Github，然后打开对应代码库的 Actions 标签。如果上述配置都正确无误的话，就会看到这里会出现一个正在运行中的 Github Actions 的 Workflow。接下来要做的就是静静地等待……

5分钟后（包括上面 Workflow 运行时间和 Github 更新博客内容的时间一起），重新打开我的博客，全新的界面出现在面前！试试点击一些链接，确认都没有问题，所有页面完全显示正确，站内搜索和 Disqus 评论等功能一切正常。

至此博客升级顺利完成！

