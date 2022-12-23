---
layout: post
title: Vite化的Rails
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, vite]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20221221.jpeg"
rating: 4
---

*本文已获得原作者（Vladimir Dementyev）和 Evil Martians 授权许可进行翻译。原文介绍了使用 Vite- Ruby 实现热重载（live reload）和热替换（hot replacement）的 Vite 化 Rails 的故事*

- 原文链接：[Vite-lizing Rails: get live reload and hot replacement with Vite Ruby](https://evilmartians.com/chronicles/vite-lizing-rails-get-live-reload-and-hot-replacement-with-vite-ruby)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

最近，我把自己的 [AnyCable demo](https://github.com/anycable/anycable_rails_demo) 应用升级到了 Ruby 3 和 Rails 7，用上了后者的新 asset 管理工具。而结果则是，`assets:precompile`变得像闪电一样快，但却丢失了一个产品环境上重要的特性：热重载（live reloading）。在 2022 年切换回 Webpacker 当然不是个好主意。幸运的是，[Vite Ruby](https://vite-ruby.netlify.app/) 已经被我注意到有好一段时间了，所以我决定尝试一下。

自从 Assets Pipeline（[Sprockets](https://github.com/rails/sprockets)）被引入以来，Rails 对于 assets 问题已经有了答案。这不只是对于 Ruby 和 Rails，对于整个 web 开发框架世界而言，都是极为重要的一步。

然后，前端革命开始了。而我们，Rails 社区，需要赶上这个潮流。所以，[Webpacker](https://github.com/rails/webpacker) 诞生了。尽管它对于其目标而言还算工作的不错，但它在 Rails 生态圈里始终像一个“外来者”。

Rails 7 则翻开了 asset 打包工具的新的一页。Webpacker 被放弃了；代替它的，我们用一种官方的方式来处理前端：import maps, [jsbundling-rails](https://github.com/rails/jsbundling-rails), [cssbundling-rails](https://github.com/rails/cssbundling-rails), [tailwindcss-rails](https://github.com/rails/tailwindcss-rails)。所有这些工具都构建在现代工具之上，与 Rails 能很好协同，且易于使用。好吧，除了这种多样性会给开发者带来一些困惑外。

> The Rails team works hard to improve the documentation around the *modern Asset Pipeline* and the variety of available choices. Follow this [pull request](https://github.com/rails/rails/pull/45400) to learn more.

问题在于，它们提供了一种类似于 Sprockets 的体验，即面向构建。但对很多开发者而言，实时反馈很重要，他们习惯于此。所以，问题就成了：有什么是`webpack-dev-server`的现代工具替代者呢？而我的答案就是：[Vite](https://vitejs.dev/)。

本文中，我会分享自己的 Vite Ruby 的设置（使用 [AnyCable demo](https://github.com/anycable/anycable_rails_demo)），并涵盖如下主题：

- Getting started with Vite on Rails
- Live reload and HRM
- To dockerize Vite, or not

## Getting started with Vite on Rails

从 ”`<whatever>bundling-rails`” 迁移到 Vite 几乎就像 [vite_rails 文档中所说](https://github.com/ElMassimo/vite_ruby/tree/main/vite_rails)的那样简单：安装 gem，运行安装 rake 任务（`bundle exec vite install`）。

我以`vite_javascript_tag`和`vite_stylesheet_tag`各自代替了`javascript_include_tag`和`stylesheet_link_tag` helper，并把`vite.json`中的`sourceCodeDir`的值更新为`frontend`（由于我本地已经偏离了 Rails 的`app/javascript`方案）。

> 你可以在[这儿](https://github.com/anycable/anycable_rails_demo/commit/f6c8eb068d5823c64784fdaa0e23d335882a223e)找到相应的提交代码。

我也创建了`frontend/entrypoints/application.css`文件，指向`styles/index.css`（之前被 esbuild 用来编译`app/assets/builds/application.css`）。

经过如上些许调整之后，我期望自己的应用无需任何其他额外改动就能跑起来了（由 Vite Ruby 的 [auto build](https://vite-ruby.netlify.app/guide/development.html#auto-build-🤖) 特性所支持）。但事实并非如此，我看到了如下的 server 日志：

```sh
Building with Vite ⚡️
vite v2.9.13 building for development...

transforming...

✓ 13 modules transformed.

Could not resolve './**/*_controller.js' from frontend/controllers/index.js
error during build:
Error: Could not resolve './**/*_controller.js' from frontend/controllers/index.js
    at error (/app/node_modules/rollup/dist/shared/rollup.js:198:30)
    at ModuleLoader.handleResolveId (/app/node_modules/rollup/dist/shared/rollup.js:22508:24)
    at /app/node_modules/rollup/dist/shared/rollup.js:22471:26

Build with Vite failed! ❌
```

我们依赖 [esbuild-rails](https://github.com/excid3/esbuild-rails) 来支持 glob 导入（`import './**/*_controller.js'`）以自动载入 [Stimulus](https://stimulus.hotwired.dev/) controllers，但现在，由于切换到了 Vite，不再有这个了。

很幸运，我们有`import.meta.globEager`，其返回补丁后的 module map，所以我们可以用上它：

```js
const controllers = import.meta.globEager("./**/*_controller.js");

for (let path in controllers) {
  let module = controllers[path];
  let name = path.match(/\.\/(.+)_controller\.js$/)[1].replaceAll("/", "--");
  application.register(name, module.default);
```

这看起来需要一点儿 hack 似的技巧。别担心，有 [stimulus-vite-helpers](https://github.com/ElMassimo/stimulus-vite-helpers) 插件，能仅用一行代码就为我们做到这个：

```js
import { registerControllers } from "stimulus-vite-helpers";

const controllers = import.meta.globEager("./**/*_controller.js");
registerControllers(application, controllers);
```

棒极了！大功告成：我们已经把应用迁移到了 Vite Ruby。不过，你还记得我们为什么要迈出第一步的吗？

## Live reload and HMR

在自动构建模式中，Vite Ruby 按需编译 assets，一个 entrypoint 对应一个输出文件，就跟之前 Sprockets 那样：

![https://evilmartians.com/static/282938887de611e1bf9a34cca5c0d85f/73477/vite_auto_build.avif](https://evilmartians.com/static/282938887de611e1bf9a34cca5c0d85f/73477/vite_auto_build.avif)

这就是 Ruby 开发者在开发时可能如何使用 Vite Ruby 的样子；然而，Vite 最大的卖点是“实时服务端启动”和“极快的HMR”（HMR 指 *hot module replacement*）。要如何用起来呢？我们需要运行一个 Vite 开发服务器！

利用 Vite Ruby，简单地运行`bin/vite dev`命令即可。下面是在  Vite 开发服务器帮助下加载的页面：

![https://evilmartians.com/static/a7144a85fcda1fec7d43b6cf07d90b8d/3f194/vite_dev_server.avif](https://evilmartians.com/static/a7144a85fcda1fec7d43b6cf07d90b8d/3f194/vite_dev_server.avif)

现在我们有许多 Javascript 文件加载了：所有的依赖模块和自定义模块——但仅是该页面所需要的那些。源代码已经在底层使用 [Rollup](https://rollupjs.org/) 处理过了，并且第三方库（NPM）也被预编译（这次是通过  [esbuild](https://esbuild.github.io/)）。但你无需担心这些前端技术栈，Vite 会替你摆平它们。

这是“实时服务端启动”，那 HMR 呢？

Hot module replacement 是一种刷新当前浏览器 Javascript 环境状态而无需重载整个页面（只重载模块）的技术。不是 JavaScript 代码的每块碎片都能被热重载，但如 Vue 和 React 的现代框架都兼容这项技术。顺便说一下，Stimulus 也是的。

Vite 使用插件来提供 HMR 能力（该 bundler 自己只提供了 [API](https://vitejs.dev/guide/api-hmr.html)）。所以，我们需要把 [Stimulus HMR](https://github.com/ElMassimo/vite-plugin-stimulus-hmr) 添加到配置中：

```js
import StimulusHMR from 'vite-plugin-stimulus-hmr'

export default {
  plugins: [
    StimulusHMR(),
  ],
};
```

现在我们就能打开一个附有 Stimulus controller 的页面试试了：

![stimulus_hmr](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/stimulus_hmr.gif)

看到了吧？Java Script 代码被重载，controllers 被重新连接，而页面内容保持不变（比如，那个输入字段）。这就是 hot module replacement 的实际效果。

我上面已经说过，HMR 仅可用于兼容的 JavaScript 代码。那如果想要对，比如说，HTML 模板的变化，做出响应呢？这时可以使用曾经用过且可靠的 live reload，通过  [vite-plugin-full-reload](https://github.com/ElMassimo/vite-plugin-full-reload)。下面是我们最终的配置：

```js
import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import StimulusHMR from "vite-plugin-stimulus-hmr";
import FullReload from "vite-plugin-full-reload";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    StimulusHMR(),
    // You can specify any paths you want to watch for changes
    FullReload(["app/views/**/*.erb"])
  ],
});
```

## Dockerizing Vite, or not

你可能知道，我会在[一个 Docker 化的环境](https://evilmartians.com/chronicles/ruby-on-whales-docker-for-ruby-rails-development)中来构建应用。设置 Vite Ruby 在 Docker 内正常运作也相当直观：

- 添加 volumes 来放置 Vite assets：

  ```yaml
  x-backend: &backend
    # ...
    volumes:
      # ...
      - vite_dev:/app/public/vite-dev
      - vite_test:/app/public/vite-test
  
  volumes:
    # ...
    vite_dev:
    vite_test:
  ```

- 定义一个新 service 来运行 Vite 的 dev server：

  ```yaml
  vite:
    <<: *backend
    command: ./bin/vite dev
    volumes:
      - ..:/app:cached
      - bundle:/usr/local/bundle
      - node_modules:/app/node_modules
      - vite_dev:/app/public/vite-dev
      - vite_test:/app/public/vite-test
    ports:
      - "3036:3036"
  ```

- 最后，我们通过提供`VITE_RUBY_HOST`的值来把 Rails “连接”到`vite` service：

  ```yaml
  x-backend: &backend
    environment:
      # ...
      VITE_RUBY_HOST: ${VITE_HOST:-vite}
  ```

现在，我们就能执行`docker-compose up vite`（或`dip up vite`）而把一个 dev server 运行起来。

注意下，我在配置中使其能够提供不同的 Vite host（`${VITE_HOST:-vite}`）。这可被用于混合式的配置里：Rails 运行在 Docker 中，而 Vite 运行于本地。

我们主要把 Vite 用在前端重度化的项目里，如需要 JavaScript 框架且致力于前端团队的项目。这通常需要高级的 “DX 机械”（linters，git hook，IDE 扩展，等等），多数场景下无法很好地与 Docker 协调。这就是为何我们支持让其回退到本地开发环境（仅对于前端而言）。

但我们正在使用一个 Ruby gem（`vite_ruby`）来管理 Vite 配置，所以这是否意味着现在我们仅仅为了这小小的 Vite 封装器就不得不在本地运行完整的、笨重的 Rails 应用呢？当然不是。让我给你展示一种更好的方式吧。

> 相关调整请查看这个[代码提交](https://github.com/anycable/anycable_rails_demo/commit/8846291ff738b95cb939352c1ff01f4179efbec0)。

首先，我们通过保留一个单独的 Gemfile（以及其他可能的前端依赖库） 来隔离`vite_ruby`：

```ruby
# gemfiles/frontend.gemfile
source "https://rubygems.org"

# https://github.com/ElMassimo/vite_ruby
gem "vite_rails"
```

我们通过使用`eval_gemfile "gemfiles/frontend.gemfile"`在主 Gemfile 中来 include 它（这样我们就能在 Rails 应用里使用 Vite helper 或在产品环境中运行命令）。

然后，我们定义一个`bin/vite`命令，其使用这个`frontend.gemfile`：

```bash
#!/bin/bash

cd $(dirname $0)/..

export BUNDLE_GEMFILE=./gemfiles/frontend.gemfile
bundle check > /dev/null || bundle install

bundle exec vite $@
```

这个技巧我同样[用在 Rubocop 上](https://dev.to/palkan_tula/faster-rubocop-runs-for-rails-apps-10me)：一个`bundle exec` 封装器，使用自定义的 Gemfile 并自动安装依赖。你需要的只是 Ruby（对，你仍需要它，但其他的都不用了）。

现在，你就可以像通常那样载入一个 Vite dev server 了：

```bash
bin/vite dev
```

而你也能通过指定`VITE_HOST`参数来载入一个 docker 化的 Rails 应用“连接到”这个本地运行的 server：

```bash
VITE_HOST=host.docker.internal dip rails s
```

注意：在`config/vite.json`里设置`"host": "0.0.0.0"`很重要，这样 Docker 容器才能正常访问到 dev server。

使用 Dip，我们可以更进一步，为混合式开发提供一个方便的快捷方式：

```yaml
# dip.yml
# ...
interaction:
  frontend:
    description: Frontend development tasks
    subcommands:
      rails:
        description: Run Rails server pointing to a local Vite dev server
        service: web
        environment:
          VITE_HOST: host.docker.internal
        compose:
          run_options: [ service-ports, use-aliases ]
```

如此，你完全不需要考虑 hosts 的事了，只用运行`dip frontend rails` 就万事大吉。

## Wrapping things up

旅程至此告一段落了。我们现在拥有了设置好的 Ruby Vite，运行良好的 live reload，hot replacement，以及所期望的实时性，都被完美修复了！随意分享并把其用到你自己的项目中吧——我希望它能派上用场助你一臂之力！


