---
layout: post
title: M1 Macbook上的Jekyll二三事
author: Mr.Z
categories: [ Programming ]
tags: [jekyll, github]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/20210913-225138.jpg"
---

最近，在 M1 Macbook 上想要把博客运行起来，一番折腾之后，最终顺利搞定。把这过程中碰到的几个问题记录一下。

从 GitHub 上 clone 了 Repository 到本地，`bundle install`之后，运行`bundle exec jekyll s -w`，死活启动不起来。报这样的错误：

```
bundler: failed to load command: jekyll (/xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/bin/jekyll)
TypeError: unable to resolve type 'size_t'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/ffi-1.13.1/lib/ffi/types.rb:69:in `find_type'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/ffi-1.13.1/lib/ffi/library.rb:589:in `find_type'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/ffi-1.13.1/lib/ffi/struct.rb:277:in `find_type'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/ffi-1.13.1/lib/ffi/struct.rb:271:in `find_field_type'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/ffi-1.13.1/lib/ffi/struct.rb:311:in `array_layout'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/ffi-1.13.1/lib/ffi/struct.rb:217:in `layout'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native/sass_value.rb:53:in `<class:SassList>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native/sass_value.rb:52:in `<module:Native>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native/sass_value.rb:4:in `<module:SassC>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native/sass_value.rb:3:in `<top (required)>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native.rb:16:in `require_relative'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native.rb:16:in `<module:Native>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native.rb:6:in `<module:SassC>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc/native.rb:5:in `<top (required)>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc.rb:31:in `require_relative'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/sassc-2.4.0/lib/sassc.rb:31:in `<top (required)>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-sass-converter-2.1.0/lib/jekyll/converters/scss.rb:3:in `require'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-sass-converter-2.1.0/lib/jekyll/converters/scss.rb:3:in `<top (required)>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-sass-converter-2.1.0/lib/jekyll-sass-converter.rb:4:in `require'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-sass-converter-2.1.0/lib/jekyll-sass-converter.rb:4:in `<top (required)>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-4.1.0/lib/jekyll.rb:209:in `require'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-4.1.0/lib/jekyll.rb:209:in `<top (required)>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-4.1.0/exe/jekyll:8:in `require'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/gems/jekyll-4.1.0/exe/jekyll:8:in `<top (required)>'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/bin/jekyll:23:in `load'
  /xxxxxx/xfyuan.github.com/vendor/bundle/ruby/2.7.0/bin/jekyll:23:in `<top (required)>'
```

跑不起来，本地就无法预览效果和调试了，这必须解决。

开始以为是 Ruby 版本兼容问题，但是依次试过了 2.6.x、2.7.x 以及 3.0.x 版本，都不行。

翻了好几个 GitHub 项目的 issues 列表，最后找到原因是 Gem `ffi`的对 M1 Macbook 的兼容性问题。把它升级到最新版本（`bundle update ffi`）就能正常启动 Jekyll 了。

另一件事是有关 [Jekyll 的 GitHub Action](https://github.com/helaili/jekyll-action) 的。

最近几天突然收到好多我的博客 GitHub Action 失败的 Email 通知，点开链接一看，好家伙，已经红了一片～

![zdfeZC](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/zdfeZC.png)

晚上抽点时间查了一下，原来是 Jekyll GitHub Action 版本已经升级了，有几处 Deprecated 调整导致的。

一个报错是这样的：

```
Can't find any online and idle self-hosted runner in the current repository, account/organization that matches the required labels: 'ubuntu-16.04'
Waiting for a self-hosted runner to pickup this job...
```

明显是找不到 Ubuntu 16.04 的版本。这个简单，按照 Jekyll GitHub Action 最新版本改为`Ubuntu-latest`就好。

另一处升级是关于`JEKYLL_PAT`的。这个在我之前一篇关于 [Jekyll 升级到 4.1 的博客](https://xfyuan.github.io/2020/06/update-blog-to-jekyll-4-1-with-github-actions/)中提到过。但是现在 Jekyll GitHub Action 已经废弃了这个写法，而是根据 GitHub 的政策改为使用`GITHUB_TOKEN`了。具体是把原来的这一行：

{% raw %}

```
JEKYLL_PAT: $%{{ secrets.JEKYLL_PAT }}
```
{% endraw %}

改为：

{% raw %}

```
token: ${{ secrets.GITHUB_TOKEN }}
```
{% endraw %}

所以，升级后的最新版本是这样的：

{% raw %}

```yaml
name: Build and deploy Jekyll site to GitHub Pages

on:
  push:
    branches:
      - master

jobs:
  gh-pages:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: helaili/jekyll-action@2.0.1
        env:
          token: ${{ secrets.GITHUB_TOKEN }}
```
{% endraw %}

如此，GitHub Action 又恢复了正常。

![BlIKnr](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/BlIKnr.png)
