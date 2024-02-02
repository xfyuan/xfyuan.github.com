---
layout: post
title: " 狂野的ViewComponent（二）: 为组件增压加速"
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, view_component, evil martians]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20221112.jpeg"
rating: 5
---

*本文已获得原作者（**Alexander Baygeldin**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了在单体式模块架构下，使用 ViewComponent 来构建组件化的现代 Rails 前端的故事。（本文是下篇）*

- 原文链接：[ViewComponent in the Wild II: supercharging your components](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-supercharging-your-components)
- 作者：**Alexander Baygeldin**、**Travis Turner**
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

GitHub 的 ViewComponent 已经诞生有好一段时间了，帮助开发者们在构建 Ruby on Rails 应用的视图层时保持明智的做法。它越来越受到欢迎——但并未如期望的那样快速流行。在这个分为上下两篇的系列文章里，我将阐述为什么你需要去尝试一下它。我们将讨论一些最佳实践，并展示在 Evil Martians 中使用了 ViewComponent 的项目上所积累的相当多的经验和技巧。

在本系列的前一篇中，我们说明了在后端使用组件方案来构建视图层是极为……狂野的！此外，我们甚至学会了如何正确应用这种方案，但还没有看到它在实际的野生环境（当然，就是产品环境）是怎样使用的。现在是填补这个空白的时候了。

这一次，我们将最终深入到 ViewComponent 设置的所有角落缝隙（甚至更多地方）。你会学到如何让视图组件随你意愿而舞——如同 Evil Martian 的方式。与前一篇不同，这一篇会有大量的代码，所以请系好安全带坐稳了！

本文目录：

1、Supercharging your components（为组件增压加速）

2、Setting up a storybook! (Bonus)（设置 storybook）

3、Wrapping up（总结）

## Supercharging your components

尽管 ViewComponent 做到了它所应做的（并且做的很好），但它并不能像 Rails 那样让你轻松上手，它仍然缺乏很多约定，你别无选择，只能自己去搞清楚。但别害怕，在这篇文章里，我会帮你节省时间，展示我们在 Evil Martians 是如何围绕视图组件来结构化代码的，这样你就可以立即开始高效的工作了。

> 对于基础介绍，请先阅读[官方的新手指导](https://viewcomponent.org/guide/getting-started.html)。

但请注意，本文中所展示的大多数技术都会被认为对 ViewComponent 而言是“未经检验的”。这是我们在 Evil Martians 内使用视图组件的做法，所以很自然，它会是非常主观的。不过，已经有计划把部分内容合并到上游去，所以请保持关注！😉

### view_component-contrib

但首先，让我们介绍下 [view_component-contrib](https://evilmartians.com/opensource/view-component-contrib)  gem，本文中我们将基于它来构建项目。它是对于 ViewComponent 的一个扩展和补丁的集合，都是我们在不同项目上发现的一些很有用的经验。它处理了很多底层的东西，这样我们就可以专注于享受“盛宴”而无需考虑“盛宴”从何而来。你可以用简单的一行命令安装它：

```sh
rails app:template LOCATION="https://railsbytes.com/script/zJosO5"
```

这会加载一个配置向导来设置你想要的内容。（如果你不确定如何回答其中的部分问题，请继续阅读本文，就能找到答案！）

此时起，我就假设你已经安装好它了。

### Folder structure

对于 Rails（及其他类似的框架）很棒的是我们很少需要去考虑把什么文件放到哪个地方，一切都是约定好的：model 放到`app/models`，controller 放到`app/controllers`，诸如此类。但视图组件要怎么放呢？其所有的关联文件（assets，translations，previews，等等）应该保存到哪里呢？

ViewComponent 的文档里建议使用`app/components`目录，但我认为这有点误导性（这名字过于通用了，看不出它与视图层的关联性）。此外，你不想把所有前端有关的东西都放到一起吗（按照 Rails 的约定，通常是在`app/views`，或者`app/frontend`）？基于此，我更愿意把组件放到`app/views/components`。

> 请注意，这完全是一个个人品味的事情，并非硬性规定。如果你不想与 ActionView 的约定混到一起也是完全可以的！你可以把视图组件放到任何你觉得合理的地方。

然而，由于 Rails 默认是期望 controller 和 mailer 的视图也都放到`app/views`，这样该目录将很快就变得凌乱不堪（甚至可能有命名冲突）。为了避免这个，让目录更整洁，我们用对应的子目录来用作视图的命名空间：

```sh
views/
  components/
  layouts/
  controllers/
    my_controller/
      index.html.erb
  mailers/
    my_mailer/
      message.html.erb
```

要支持这点，把这一行添加到`ApplicationController`：

```ruby
append_view_path Rails.root.join("app", "views", "controllers")
```

对于`ApplicationMailer`也要同样添加一行：

```ruby
append_view_path Rails.root.join("app", "views", "mailers")
```

现在，我们到`app/views/components`目录内部看看：

```sh
components/
  example/
    component.html.erb (this is our template)
    component.rb (Example::Component class)
    preview.rb (Example::Preview class)
    styles.css (CSS styles)
    whatever.png (other assets)
```

如果你使用了`view_component-contrib`那么看到的就是这样（否则会[有所不同](https://github.com/palkan/view_component-contrib#organizing-components-or-sidecar-pattern-extended)）。`component.rb`和`component.html.erb`（你可以用任何其他模板）显然是必需的，而其他文件都是可选的。瞧瞧组件所需的所有文件是如何很好地呆在一个目录中的吧。我内心的完美主义为此而高兴！

哦，如果想的话，我们还可以把组件放到它自己子目录的命名空间内：

```sh
components/
  way_down/
    we_go/
      example/
        component.rb (WayDown::WeGo::Example::Component class)
        preview.rb (WayDown::WeGo::Example::Preview class)
```

### Helpers

下面是组件如何渲染的默认方式：

```erb
<%= render(Example::Component.new(title: "Hello World!")) %>
```

这不算坏，但很快就会导致大量重复性代码出现。让我们来拯救下自己的手腕，减少些敲键盘的次数。在`ApplicationHelper`中添加如下语法糖：

```ruby
def component(name, *args, **kwargs, &block)
  component = name.to_s.camelize.constantize::Component
  render(component.new(*args, **kwargs), &block)
end
```

现在，我们就可以这样写了：

```erb
<%= component "example", title: "Hello World!" %>
```

如果使用了命名空间，则这样写：

```erb
<%= component "way_down/we_go/example", title: "Hello World!" %>
```

### Base classes

为应用内每个实体类型创建抽象基础类是常见的实践方式，以使得更易于扩展框架而不借助“猴子补丁”（比如`ApplicationController`，`ApplicationMailer`等）。

对于组件，我们没理由不也这么做：

```ruby
# app/views/components/application_view_component.rb

class ApplicationViewComponent < ViewComponentContrib::Base
  extend Dry::Initializer

  include ApplicationHelper
end
```

通过加入[dry-initializer](https://dry-rb.org/gems/dry-initializer)，我们今后就可以远离声明式的`#initialize`方法的编写，也无需再敲那些繁琐累赘的样板代码。至于`include ApplicationHelper`，需要它以便能在组件模板及其 previews 中定义`component` helper。

这是 previews 的基础类大概的样子：

```ruby
# app/views/components/application_view_component_preview.rb

class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
  # Hides this class from previews index
  self.abstract_class = true

  # Layouts are inherited (but can be overriden)
  layout "component_preview"
end
```

### Effects

前一篇文章里，我们学到了全局状态以 context 进行传递，这可以用[dry-effects](https://dry-rb.org/gems/dry-effects/) 来处理。我们来看看实践中是如何做到让`current_user`在全局可用的。

你所需要做的仅仅是把如下代码添加到`ApplicationController`：

```ruby
include Dry::Effects::Handler.Reader(:current_user)

around_action :set_current_user

private

def set_current_user
  # Assuming you have `#current_user` method defined:
  with_current_user(current_user) { yield }
end
```

以及如下代码添加到`ApplicationViewComponent`：

```ruby
include Dry::Effects.Reader(:current_user, default: nil)
```

现在，无论何时你要获取 current user，你在任何组件内的任何地方都只用调用`#current_user`而已。易如反掌！

然而，并非生产环境代码才是利用 context 的唯一场所。前一篇文章中，我们学到了如何隔离性测试组件，如果你记性不差的话，应该还记得我们在测试中使用了同样的`#with_current_user` helper。当然，这必须被单独设置。

下面就是如何配置 RSpec 的大概样子：

```ruby
# spec/support/view_component.rb

require "view_component/test_helpers"
require "capybara/rspec"

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :view_component
  config.include Capybara::RSpecMatchers, type: :view_component
  config.include Dry::Effects::Handler.Reader(:current_user), type: :view_component

  config.define_derived_metadata(file_path: %r{/spec/views/components}) do |metadata|
    metadata[:type] = :view_component
  end
end
```

### Nesting

我们已经确定了你可以对组件进行命名空间的处理，这有助于避免`app/views/components`目录过于臃肿。还有另外一个技术能用来达到同样的目标：嵌套组件（这种情况下，要让子组件位于父组件的目录内）。毕竟，如果你确信某个组件永远不会在父组件之外使用，那么就没有理由将其放在组件根目录中了。

现在，如果你把一个组件嵌套放在另一个组件之内，并想根据其完整名称来渲染的话（比如，`my_parent/my_child`），自然是没问题的，但我们可以更进一步，做到使用其位于父组件中的相对名称来渲染。

在`ApplicationViewComponent`中添加如下代码：

```ruby
class << self
  def component_name
    @component_name ||= name.sub(/::Component$/, "").underscore
  end
end

def component(name, ...)
  return super unless name.starts_with?(".")

  full_name = self.class.component_name + name.sub('.', '/')

  super(full_name, ...)
end
```

现在就可以这样来渲染了：

```erb
<%= component ".my-nested-component" %>
```

这个小技术简单易行——深度嵌套有其自身的缺点，有时平铺的目录结构正是你所需要的。

### I18n

ViewComponent 有开箱即用的 [I18n 支持](https://viewcomponent.org/guide/translations.html)。这让你对于每个组件都能够拥有其隔离的本地化语言文件。然而，如果你更愿意让多语言翻译位于一个中心化的存储位置，`view_component-contrib`提供了一个替代方案：[namespacing](https://github.com/palkan/view_component-contrib#i18n-integration-alternative)。不管哪种方式，你都可以使用相对路径。

假如你有一个文件`config/locales/en.yml`如下：

```yaml
en:
  view_components:
    way_down:
      we_go:
        example:
          title: "Hello World!"
```

那么在你的`way_down/we_go/example`组件内就可以这样引用：

```erb
<!-- app/views/components/way_down/we_go/example/component.html.erb -->

<h1><%= t(".title") %></h1>
```

### CSS

在我们的设置中是把所有相关的 assets 都存放到组件目录，但实际上，Ruby 应用并不关心它们存放在哪。关心它们在哪是 assets pipeline 的工作，以便正确打包它们——尽管这完全是另一个话题了，但由于我们在组件模板内使用 CSS 类，那么还是值得讨论一番。

CSS 自然是全局的；这使得它有点难以跟组件一起使用，因为组件被设计为隔离性的。我们想要把 CSS 类限制在组件的定义域，并避免所有可能的命名冲突，所以不能简单地把所有组件内部的`styles.css`文件串联起来放到一个单独而庞大文件就完事。围绕这个问题一般有两种方式来处理。

一种是使用诸如 [BEM](https://en.bem.info/) 的约定，或者把 CSS 类以一种排除了所有名称冲突的方式来命名。例如，你可以为所有 CSS 类加上前缀`c--component-name--`（这里`c`表示`component`）。然而，这对开发者而言，增加了额外的认知负担，而且随着时间推移而愈加重复。

你可能了解 [CSS modules](https://github.com/css-modules/css-modules) 方案，它通过在打包过程中把 CSS 类的名称转换为具有唯一性的识别符来实现隔离性，这样开发者在写代码时甚至都不需要关注这事了。不幸的是，这个方案对于 JavaScript 能很好工作，但对 Ruby 则没那么容易做到同样的事（至少目前如此），因为我们并不会打包 Ruby 源码。

所以，要怎么办呢？好吧，我们不能如 CSS 类名那样使用随机识别符，但这并不意味我们就必须手写`c--component-name--`。我们同样可以让打包过程帮自己做到这事。如何实现这点要看你具体的 assets pipeline 配置，但其核心思想都是基于我们的命名约定来自动生成 CSS 类名。

出于示例目的，我们假设使用了 PostCSS 来打包 CSS 文件。这种情况下，我们可以用上 [`postcss-modules`](https://github.com/madyankin/postcss-modules) 包。首先安装它（`yarn add postcss-modules`，你使用 Yarn 的话），然后把如下代码添加到`postcss.config.js`：

```js
module.exports = {
  plugins: {
    'postcss-modules': {
      generateScopedName: (name, filename, _css) => {
        const matches = filename.match(/\/app\/views\/components\/?(.*)\/index.css$/)

        // Don't transform CSS files from outside of the components folder
        if (!matches) return name

        // Transforms "way_down/we_go/example" into "way-down--we-go--example"
        const identifier = matches[1].replaceAll('_', '-').replaceAll('/', '--')

        return `c--${identifier}--${name}`
      },
      // Don't generate *.css.json files (we don't need them)
      getJSON: () => {}
    }
  }
}
```

当然，我们需要遵循组件模板内使用同样的命名约定。为了让工作轻松点，把这个 helper 添加到`ApplicationViewComponent`：

```ruby
class << self
  def identifier
    @identifier ||= component_name.gsub("_", "-").gsub("/", "--")
  end
end

def class_for(name)
  "c--#{self.class.identifier}--#{name}"
end
```

然后，如果你有如下的 CSS 类的话：

```css
/* app/views/components/example/styles.css */

.container {
  padding: 10px;
}
```

就可以在组件模板中这样来引用它了：

```erb
<!-- app/views/components/example/component.html.erb -->

<div class="<%= class_for("container") %>">
  Hello World!
</div>
```

完美！如今你就能安全地使用任何 CSS 类名，它们的定义域将会被自动限制于其所在的组件内了。

我不得不提到一点，如果你正在使用 Tailwind（或类似的 CSS 框架），那么甚至都完全不需要上面的做法，因为很可能使用它们的内置类就已经足够满足你的样式需求了。

### JS

> 想了解更多，请参考我们的另一篇博客：["Hotwire: Reactive Rails with no JavaScript?"](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript)（[中文译文：“Hotwire: 没有JavaScript的Reactive Rails”](https://xfyuan.github.io/2021/04/hotwire-reactive-rails-with-no-javascript/)）

生活中有些事情永远不会改变：太阳东升西落，活着就要交税，以及构建交互界面就需要——JavaScript。话虽如此，如果你不想的话当然可以不写。前一篇文章里我简短提到过，使用 Hotwire 技术栈（特别是  [Turbo](https://turbo.hotwired.dev/)），就能尽可能避免编写 JavaScript 并将同样得到一个生动活泼的响应式 Web 应用。

然而，某些时候，你仍然想要为 UI 添加一些点缀，这时 [Stimulus](https://stimulus.hotwired.dev/) 就是一个干这事的出色工具。你可以用它很容易地为 HTML 元素通过自定义的`data-controller`属性加上动态行为（定义在 Stimulus controller 类中）。来看一个 [Stimulus 文档](https://stimulus.hotwired.dev/handbook/hello-stimulus)中的例子并把其放到我们的组件里。

首先，我们创建 Stimulus controller 类（通常，每个组件一个`controller.js`就足够了）：

```js
// app/views/components/hello/controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name"]

  greet() {
    const element = this.nameTarget
    const name = element.value
    console.log(`Hello, ${name}!`)
  }
}
```

然后，我们把它跟 HTML 模板通过`data`属性连接起来：

```erb
<!-- app/views/components/hello/component.html.erb -->

<div data-controller="hello">
  <input data-hello-target="name" type="text">
  <button data-action="click->hello#greet">Greet</button>
</div>
```

最后，我们在 application entrypoint 内把所有一切缝合起来（具体位置严重依赖于你的 assets pipeline 如何配置）：

```js
// app/assets/javascripts/application.js

import { Application } from "@hotwired/stimulus"
import HelloController from "../../views/components/hello/controller"

window.Stimulus = Application.start()
Stimulus.register("hello", HelloController)
```

> 想了解更多，请参考我们的另一篇博客：“[Vite-lizing Rails: get live reload and hot replacement with Vite Ruby](https://evilmartians.com/chronicles/vite-lizing-rails-get-live-reload-and-hot-replacement-with-vite-ruby)”（中文译文：[Vite化的Rails](https://xfyuan.github.io/2022/12/vite-lizing-rails/)）

这样倒是能工作，但是有太多改进可做。首先，我们想要推断 controller 名称并自动把其注册到相对应的 controller 类。再一次地，这严重依赖于你的 assets pipeline 配置，但假如我们使用的是 Vite，那么就可以这样：

```js
// app/assets/javascripts/application.js

import { Application } from '@hotwired/stimulus'

const application = Application.start()

window.Stimulus = application

const controllers = import.meta.globEager(
  "./../../app/views/components/**/controller.js"
)

for (let path in controllers) {
  let module = controllers[path]
  let name = path
    .match(/app\/views\/components\/(.+)\/controller\.js$/)[1]
    .replaceAll("_", "-")
    .replaceAll("/", "--")

  application.register(name, module.default)
}
```

这里我们收集了所有组件的全部`controller.js`文件，并使用根据组件目录路径推断出的 Stimulus controller 名称把它们关联起来。而所有这一切都发生在打包过程中。

> 如果你对 Stimulus 在其他前端工具中的配置感兴趣，可以看看[这里的讨论](https://github.com/palkan/view_component-contrib/discussions/14)。

现在，如果你注意力集中的话，可能已经注意到推断出的 controller的名称都是跟我们在前一节的`::identifier`方法里所定义的极为类似的方式。这并非巧合：对于 CSS，在打包过程和 Ruby 应用之间，无法直接链接起来，所以我们不得不依靠命名约定。

把如下代码添加到`ApplicationViewComponent`：

```ruby
def controller_name
  self.class.identifier
end
```

这样，在模板的`data`属性中就无需再手写 controller 名称了（确保命名同步），我们可以这样写：

```erb
<!-- app/views/components/hello/component.html.erb -->

<div data-controller="<%= controller_name %>">
  <input data-<%= controller_name %>-target="name" type="text">
  <button data-action="click-><%= controller_name %>#greet">Greet</button>
</div>
```

### Generators

对于使用许多的技巧来尝试减少样板代码，让编码变得更轻松，我们已经用了本文相当一部分篇幅来介绍了，但并非所有样板代码都能被完全去除掉（问问 Go 开发者吧😉）。

例如，在视图组件的场景下，当添加一个新组件时，我们依然需要创建一堆文件（previews，specs，组件自身的 Ruby class，等等）。当然，手工来做这种事是令人厌倦的，所以 ViewComponent 提供了一些开箱即用的 [generators](https://viewcomponent.org/guide/generators.html)。你只需要执行如下命令：

```sh
bin/rails g component Example
```

然而，generator 不止在适配项目需求方面有用。这就是为什么`view_component-contrib`在安装期间创建了不少自定义的 generators 的缘故，你可以打开其代码库看看，并按照自身需求来修改使用。通过把 generators 纳入为项目的一部分，你对于其工作流就有了更多的掌控。

### Runtime linters

最后且同样重要的是，来看看我们如何增强和实施某些我们在[前一篇文章](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends)中确定的最佳实践——特别是，避免在视图组件中进行数据库查询的建议。

尽管一些最佳实践在构建时的 linters 来实施更好（比如，自定义的 Rubocop 规则），但对另一些（比如下面我们所感兴趣的）则由运行时的 linters 来做为佳。幸运的是，ViewComponent 提供了 [ActiveSupport instrumentation](https://viewcomponent.org/guide/instrumentation.html) 可以帮我们做到这点。

我们首先要启用该 instrumentation：

```ruby
# config/application.rb

config.view_component.instrumentation_enabled = true
```

然后，在`development.rb`和`test.rb`环境内添加自定义配置选项，以使我们在开发中运行测试时能够捕获有问题的视图组件：

```ruby
config.view_component.raise_on_db_queries = true
```

然而，启用这个策略而不留任何余地就太简单粗暴了，所以我们可允许组件确实需要时能够选择退出该策略。要做到这点，添加如下代码到`ApplicationViewComponent`：

```ruby
class << self
  # To allow DB queries, put this in the class definition:
  # self.allow_db_queries = true
  attr_accessor :allow_db_queries
  alias_method :allow_db_queries?, :allow_db_queries
end
```

现在，只需要实现该 linter 即可：

```ruby
# config/initializers/view_component.rb

if Rails.application.config.view_component.raise_on_db_queries
  ActiveSupport::Notifications.subscribe "sql.active_record" do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)

    Thread.current[:last_sql_query] = event
  end

  ActiveSupport::Notifications.subscribe("!render.view_component") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    last_sql_query = Thread.current[:last_sql_query]
    next unless last_sql_query

    if (event.time..event.end).cover?(last_sql_query.time)
      component = event.payload[:name].constantize
      next if component.allow_db_queries?

      raise <<~ERROR.squish
        `#{component.component_name}` component is not allowed to make database queries.
        Attempting to make the following query: #{last_sql_query.payload[:sql]}.
      ERROR
    end
  end
end
```

当然，你也可以使用这种技术来实施其他的——只要你能想到的。

## Setting up a storybook! (Bonus)

到这里为止，你应该已经装备了足够的知识，能够在项目上开始自信地使用 ViewComponent。然而，有一个主题我有意遗漏掉了，因为它是可选的，并非必须，即：[previews（预览）](https://viewcomponent.org/guide/previews.html)。当然，不要因为“可选”这个词就忽略这个部分，我告诉你吧，previews 是组件工具箱中最有用的那一个。

### The many benefits of using previews

你有多少次想知道如何将一项大任务拆分成更小的部分，以便最终能坐下来做一些切实可行的事情？就我而言，太多太多了。幸运的是，在处理视图代码时不必如此：这就要归功于组件 previews，它让我们能够隔离性地创建和测试组件，这样就很难出问题。你只需要 mock 一些数据，然后在浏览器中查看新组件如何呈现就好。

**Previews 使得我们能够对视图组件进行隔离性开发**

但还不仅如此！你可以对所有涉及组件的各种场景都创建 previews，并测试所有可能的边界情况。而且，如果你对应用中的每个组件都这样做的话，你就基本同时拥有了一个实时的文档。不光开发人员会觉得它有帮助，而且整个团队都会！噢对了，你知道还可以在单元测试中[把 previews 用作测试用例](https://viewcomponent.org/guide/previews.html#previews-as-test-cases)吗？简直棒极了，对吧？

### Looking for Lookbook

ViewComponent 已经提供了一种在浏览器中查看组件 previews 的方式（通过`/rails/view_component`路由），但太简陋了。如果我们的 storybook 有更多功能不是更好么，比如搜索、分类、动态参数，等等？在前端世界有 [Storybook.js](https://github.com/storybookjs/storybook)，支持所有这些功能甚至更多——那在 Ruby 中我们有类似的东西吗？

当然有的——它叫 [Lookbook](https://github.com/allmarkedup/lookbook)！我们已经把它应用在一个 Evil martians 近期的项目上（大获成功），现在很高兴把其中的一些经验和技巧分享出来。

> 顺便说一下，Lookbook 已经发布了1.0 版本

![collapsible.av1](https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/collapsible.av1.gif)

### Basic setup

首先，把 gem 添加到 `Gemfile`：

```ruby
gem "lookbook", require: false
```

默认我们不需要启用它（避免在生产环境上运行其文件观察器）。要在开发和/或 staging 环境启用，可以使用`LOOKBOOK_ENABLED`环境变量。

不幸的是，由于 Lookbook 引擎需要在 Rails 配置之后加载以注册其initializers（而 Rails 并没有这样的 hook），我们就只有一种方式在创建时条件性地 require 它：

```ruby
# config/application.rb

config.lookbook_enabled = ENV["LOOKBOOK_ENABLED"] == "true" || Rails.env.development?
require "lookbook" if config.lookbook_enabled
```

接下来，在`routes.rb`中添加路由（你也可以在`config/routes/development.rb`中来添加它，如果你想把产品环境和开发环境的路由区分开的话）：

```ruby
if Rails.application.config.lookbook_enabled
  mount Lookbook::Engine, at: "/dev/lookbook"
end
```

差不多就要完成了，最后一步是对 previews 也设置 [effects](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-supercharging-your-components#effects)。还记得我们是如何把`current_user`注入到`ApplicationController`中并使其在组件里被解析的吗？好吧，这里我们要做的稍有不同，因为 previews 是在另一个 controller 中渲染的，跟`ApplicationController`无关。

为了不纠缠过多细节，下面是整个设置相关的代码：

```ruby
# app/views/components/application_view_component_preview.rb

class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
  # See https://github.com/lsegal/yard/issues/546
  send :include, Dry::Effects.State(:current_user)

  def with_current_user(user)
    self.current_user = user

    block_given? ? yield : nil
  end
end
```

```ruby
# config/initializers/view_component.rb

ActiveSupport.on_load(:view_component) do
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
  ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract

  if Rails.application.config.lookbook_enabled
    Rails.application.config.to_prepare do
      Lookbook::PreviewsController.class_eval do
        include Dry::Effects::Handler.State(:current_user)

        around_action :nullify_current_user

        private

        def nullify_current_user
          with_current_user(nil) { yield }
        end
      end
    end
  end
end
```

现在，在你的 previews 里就有`#with_current_user`方法可用了（哇哦！）：

```ruby
class Example::Preview < ApplicationViewComponentPreview
  def default
    with_current_user(User.new(name: "Handsome"))
  end
end
```

### Opinionated previews

有好几种方式在 previews 中渲染组件：可以用`view_component-contrib`提供的默认 preview 模板，在`::Preview` class 实例方法（比如叫`examples`）内手工渲染组件；或者可以为每个 example 创建一个单独的`.html.{erb, slim 等}`模板，以跟应用内其他地方完全一样的方式来渲染组件。在我们最近的一个项目上，使用了后者的方案，且一点也不感到后悔。

在我们的设置里，每个组件都有一个`preview.html.erb`文件，用来作为所有组件示例的默认 preview 模板，并且也可以在`previews`子目录内添加更多示例特定的 preview 模板。来看看我们是如何为上面 Demo 演示中的`Collapsible`组件编写 previews 的：

```ruby
# app/views/components/collapsible/preview.rb

class Collapsible::Preview < ApplicationViewComponentPreview
  # @param title text
  def default(title: "What is the goal of this product?")
    render_with(title:)
  end

  # @param title text
  def open(title: "Why is it open already?")
    render_with(title:)
  end
end
```

上面的`@param`标签告诉 Lookbook 把其当作一个动态参数对待，我们在浏览 Lookbook 时会实时修改它。有不少其他标签可用，你可以参考 [Lookbook 文档](https://github.com/allmarkedup/lookbook)了解更多内容。

这是 preview 模板大概的样子：

```erb
<!-- app/viewc/components/collapsible/preview.html.erb -->

<%= component "collapsible", title: do %>
  Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid.
<% end %>
```

```erb
<!-- app/viewc/components/collapsible/previews/open.html.erb -->

<%= component "collapsible", title:, open: true do %>
  Anim pariatur cliche reprehenderit, enim eiusmod high life accusamus terry richardson ad squid.
<% end %>
```

请注意，如果我们在一个典型的视图或另一个组件的模板中渲染组件，将使用的代码是完全相同的（仅在这种场景下，如`title`这样的局部变量来自于`#render_with`方法）。

当然，一开始，为每个组件创建一个单独的 preview 模板可能看起来有点“样板化”，但作为交换，你可以完全自由地选择每个组件的呈现方式，此外，你还可以随时修改它，而不会破坏其他组件的 preview。

这就是说，可能更重要得多的是，组件在整个代码库中都以完全相同的方式渲染——不管它是在 previews 还是生产环境（从经验上讲，这让项目上的前端开发者会非常高兴）。

### Previews for mailers

我们已经有了组件的 previews，但何必就此止步呢？还有更多可以从 preview 受益的事情。

假设我们有如下的 mailer：

```ruby
# app/mailers/test_mailer.rb

class TestMailer < ApplicationMailer
  def test(email, title)
    @title = title

    mail(to: email, subject: "This is a test email!")
  end
end
```

```erb
<!-- app/views/mailers/test_mailer/test.html.erb -->

<% content_for :content do %>
  <h1><%= @title %></h1>
<% end %>
```

这是应用中所有 mailer 共用的页面布局：

```erb
<!-- app/views/layouts/mailer.html.erb -->

<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <%= stylesheet_link_tag "email" %>
  </head>
  <body>
    <div class="container">
      <%= yield :content %>
    </div>
  </body>
</html>
```

都没什么特别的，不过典型的 Action Mailer 代码而已。

让我们来做一点有趣的事，为 mailers 添加一个基础 preview class（注意`@hidden`标签，它会防止该 class 显示在 Lookbook 中）：

```ruby
# app/views/components/mailer_preview/preview.rb

# This preview is used to render mailer previews.
#
# @hidden
class MailerPreview::Preview < ApplicationViewComponentPreview
  layout "mailer_preview"

  def render_email(kind, *args, **kwargs)
    email = mailer.public_send(kind, *args, **kwargs)

    {
      locals: {email:},
      template: "mailer_preview/preview",
      source: email_source_path(kind)
    }
  end

  private

  def mailer
    mailer_class = self.class.name.sub(/::Preview$/, "").constantize
    mailer_params ? mailer_class.with(**mailer_params) : mailer_class
  end

  def email_source_path(kind)
    Rails.root.join("app", "views", "mailers", mailer.to_s.underscore, "#{kind}.html.erb")
  end

  def mailer_params = nil
end
```

其想法是当从上一个继承时自动推断出 mailer class，然后以所提供的参数进行渲染，并把输出注入到邮件的自定义 preview 模板中（`mailer_preview/preview`）。如果需要，`mailer_params`方法应该由该 class 的后代来实现。

还请注意下我们从`render_email`返回的`source`关键字：它是一个 ViewComponent 和 Lookbook 都不知道的自定义关键字。它包含邮件模板的完整路径，并且稍后，我们将用它来调整 Lookbook 中的`Source` 标签页，所以，往下看吧。

好了，这是 preview 模板：

```erb
<!-- app/views/components/mailer_preview/preview.html.erb -->

<header>
  <dl>
    <% if email.respond_to?(:smtp_envelope_from) && Array(email.from) != Array(email.smtp_envelope_from) %>
      <dt>SMTP-From:</dt>
      <dd id="smtp_from"><%= email.smtp_envelope_from %></dd>
    <% end %>

    <% if email.respond_to?(:smtp_envelope_to) && email.to != email.smtp_envelope_to %>
      <dt>SMTP-To:</dt>
      <dd id="smtp_to"><%= email.smtp_envelope_to %></dd>
    <% end %>

    <dt>From:</dt>
    <dd id="from"><%= email.header['from'] %></dd>

    <% if email.reply_to %>
      <dt>Reply-To:</dt>
      <dd id="reply_to"><%= email.header['reply-to'] %></dd>
    <% end %>

    <dt>To:</dt>
    <dd id="to"><%= email.header['to'] %></dd>

    <% if email.cc %>
      <dt>CC:</dt>
      <dd id="cc"><%= email.header['cc'] %></dd>
    <% end %>

    <dt>Date:</dt>
    <dd id="date"><%= Time.current.rfc2822 %></dd>

    <dt>Subject:</dt>
    <dd><strong id="subject"><%= email.subject %></strong></dd>

    <% unless email.attachments.nil? || email.attachments.empty? %>
      <dt>Attachments:</dt>
      <dd>
        <% email.attachments.each do |a| %>
          <% filename = a.respond_to?(:original_filename) ? a.original_filename : a.filename %>
          <%= link_to filename, "data:application/octet-stream;charset=utf-8;base64,#{Base64.encode64(a.body.to_s)}", download: filename %>
        <% end %>
      </dd>
    <% end %>
  </dl>
</header>

<div name="messageBody">
  <%== email.decoded %>
</div>
```

也别忘了基础页面布局：

```erb
<!-- app/views/layouts/mailer_preview.html.erb -->

<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width" />
    <style type="text/css">
      html, body, iframe {
        height: 100%;
      }

      body {
        margin: 0;
      }

      header {
        width: 100%;
        padding: 10px 0 0 0;
        margin: 0;
        background: white;
        font: 12px "Lucida Grande", sans-serif;
        border-bottom: 1px solid #dedede;
        overflow: hidden;
      }

      dl {
        margin: 0 0 10px 0;
        padding: 0;
      }

      dt {
        width: 80px;
        padding: 1px;
        float: left;
        clear: left;
        text-align: right;
        color: #7f7f7f;
      }

      dd {
        margin-left: 90px; /* 80px + 10px */
        padding: 1px;
      }

      dd:empty:before {
        content: "\00a0"; // &nbsp;
      }

      iframe {
        border: 0;
        width: 100%;
      }
    </style>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
```

还剩一件事，就是告诉 Rails 在哪里能发现 emails 的 previews 模板，这样 Lookbook 就能把它们取出来（我们把它们跟 email 模板存放到一起）：

```ruby
# config/application.rb

config.view_component.preview_paths << Rails.root.join("app", "views", "mailers")
```

噢，这些可真不少，但现在终于可以从`MailerPreview::Preview` class 继承并仅用一行代码即可渲染 email 了：

```ruby
# app/views/mailers/test_mailer/preview.rb

class TestMailer::Preview < MailerPreview::Preview
  # @param body text
  def default(body: "Hello World!")
    render_email(:test, "john.doe@example.com", body)
  end
end
```

瞧瞧，这就是我们的 mailer previews：

![https://evilmartians.com/static/2edeb91cd094e0ed2868831bdd9973b8/f5a1c/mailer_preview.avif](https://evilmartians.com/static/2edeb91cd094e0ed2868831bdd9973b8/f5a1c/mailer_preview.avif)

### Previews for frontend components

在 Evil Martians 的最近一个项目中，我们决定偏离常规的 SPA 和 MPA 路线，而代之以 hybrid 方案：大多数应用界面都是以 ViewComponent 写的，但部分（特别是前端）被写成了 React 应用。这是一个深思熟虑后的方案，因为这允许我们把工作平均分配给团队成员（这样前端就不会成为瓶颈）。这有助于我们控制其复杂性（而不是在后端使用 GraphQL API 或其他方式来做成完全的 SPA）。

一切进行得很顺利，只有一个问题：我们不想在一个项目里有两个单独的 storybook，所以决定把 React 写就的前端组件也放到 Lookbook 来。我将展示我们是如何做的，但首先来看看目录结构：

```sh
app/
  views/
    components/ (ViewComponent components)
frontend/
  components/ (React components)
    Example/
      previews/ (example-specific previews)
        something.tsx
      index.tsx (React component)
      preview.rb (Frontent::Example::Preview)
      preview.tsx (default preview)
```

如你所见，前端组件目录的结构跟后端使用的非常相似，除了 preview 文件是`.tsx`扩展名而非`.html.erb`之外。解决办法就是把前端 previews 编写为 React 组件，对其单独打包并动态注入到 Lookbook。

这是`preview.tsx`：

```tsx
// frontend/components/Example/preview.tsx

import * as React from 'react'

import Example from './index'

interface Params {
  title: string
}

export default ({ title }: Params): JSX.Element => {
  return (
    <Example title={title} />
  )
}
```

这是`preview.rb`：

```ruby
# frontend/components/Example/preview.rb

class Frontend::Example < ReactPreview::Preview
  # @param title text
  def default(title: "Hello World!")
    render_with(title:)
  end

  def something
  end
end
```

当然了，我们也需要告诉 Rails 在哪里找到它们：

```ruby
# config/application.rb

config.view_component.preview_paths << Rails.root.join("frontend", "components")
```

这样就足够了，能正常工作：

![https://evilmartians.com/static/72a7fe878c565c598a54c9340a8bfa9c/3be41/react_preview.avif](https://evilmartians.com/static/72a7fe878c565c598a54c9340a8bfa9c/3be41/react_preview.avif)

看起来很好，对吧？但要让它像这样工作，我们还需要不少胶水代码，所以坐稳了！让我们从 React 组件 previews 的基础 class 开始：

```ruby
# app/views/components/react_preview/preview.rb

require "json"

# Define namespace for React component previews.
module Frontend; end

# This preview is used to render React component previews.
#
# @hidden
class ReactPreview::Preview < ApplicationViewComponentPreview
  layout "react_preview"

  class << self
    def render_args(example, ...)
      super.tap do |result|
        result[:template] = "react_preview/preview"
        result[:source] = preview_source_path(example)
        result[:locals] = {
          component_name: react_component_name,
          component_props: result[:locals].to_json,
          component_preview: example
        }
      end
    end

    private

    def react_component_name
      name.sub(/^Frontend::/, "")
    end

    def preview_source_path(example)
      base_path = Rails.root.join("frontend", "components", react_component_name)

      if example == "default"
        base_path.join("preview.tsx")
      else
        base_path.join("previews", "#{example}.tsx")
      end
    end
  end
end
```

这是`react_preview/preview`模板：

```erb
<!-- app/views/components/react_preview/preview.html.erb -->

<script>
  window.componentName = '<%= component_name %>'
  window.componentPreview = '<%= component_preview %>'
  window.componentProps = <%= raw(component_props) %>
</script>
```

这里，我们覆盖了 ViewComponent 的内部方法`render_args`来做到一件事：通过把其传递给浏览器的全局变量，我们为前端提供了其渲染一个特定 preview 所有所需的数据。如你所见，我们从 Ruby 的 preview class（`Frontend::Example` → `Example`）推断出 React 组件名称，并把通过`render_with`传递的所有参数收集到一个单独的 JSON 以作为组件的 props。而且，还有上一节中的自定义`:source`属性，但这次，它包含了 preview `.tsx `文件的完整路径（请留意，我们后面会需要它的）。

Cool！现在我们渲染组件所需的一切都已就位，该是真正来做的时候了。再一次的，这跟你的 assets pipeline 配置相关，但使用 Vite 的话，则大致上如下：

```erb
<!-- app/views/layouts/react_preview.html.erb -->

<!DOCTYPE html>
<html lang="en" class="h-full">
  <head>
    <meta name="viewport" content="width=device-width,initial-scale=1">

    <%= vite_client_tag %>
    <%= vite_react_refresh_tag %>
    <%= vite_javascript_tag "preview" %>
  </head>

  <body>
    <div id="preview-container">
      <%= yield %>
    </div>
  </body>
</html>
```

下面是实际用到的胶水代码：

```js
// frontend/entrypoints/preview.js

import { createRoot } from 'react-dom/client'
import { createElement } from 'react'

const defaultPreviews = import.meta.globEager('../components/*/preview.tsx')

const namedPreviews = import.meta.globEager('../components/*/previews/*.tsx')

function previewModule(componentName, previewName) {
  if (previewName === 'default') {
    return defaultPreviews[`../components/${componentName}/preview.tsx`].default
  } else {
    return namedPreviews[
      `../components/${componentName}/previews/${previewName}.tsx`
    ].default
  }
}

const container = document.getElementById('preview-container')

const root = createRoot(container)
const element = createElement(
  previewModule(window.componentName, window.componentPreview),
  window.componentProps
)

root.render(element)
```

我知道这很明显，但我想重新指出一下，将此代码放入单独的打包中很重要，以免干扰你的生产环境代码。

好了，我们几乎万事大吉了……开个玩笑，我们实际已经完工了！嘻嘻，代码太多了，是吧？这真的值得吗？这留给你去决定，但从我们的经验来讲，在 hybrid 应用中对于所有可视元素只有一个单独的 storybook 让事情变得简单多了。

### Fixing up the Source tab

Lookbook 中的`Source`标签页会显示当前 preview 的高亮源码（基本上就是该组件的实时文档）。然而，对于我们的 Ruby 视图组件它工作得很好，但 React 组件和 mailers 则并非如此。来修复它！

还记得我们在试图把所有东西塞入 Lookbook 时所添加的自定义`:source`属性么？现在该是它派上用场的时候了。我们需要的只是如下“猴子补丁”：

```ruby
# config/initializers/view_component.rb

ActiveSupport.on_load(:view_component) do
  if Rails.application.config.lookbook_enabled
    Rails.application.config.to_prepare do
      class << Lookbook::Lang
        LANGUAGES += [
          {
            name: "tsx",
            ext: ".tsx",
            label: "TypeScript",
            comment: "// %s"
          }
        ]
      end

      Lookbook::PreviewExample.prepend(Module.new do
        def full_template_path(template_path)
          @preview.render_args(@name)[:source] || super
        end
      end)
    end
  end
end
```

看看效果：

![https://evilmartians.com/static/25c996b9efc9f3ccb625304b3e392b5d/79cf1/source_tab_preview.avif](https://evilmartians.com/static/25c996b9efc9f3ccb625304b3e392b5d/79cf1/source_tab_preview.avif)

是的，我知道，“猴子补丁”并不可靠，但使用它的成本也也很低！所以，在上游有人决定实现一个类似的功能之前，你都可以先用着它。

在本节中，我们学到了如何使用 Lookbook gem 为应用设置一个 storybook，甚至还有为实现一些超越其设计初衷的事情要如何调整它。我认为它的效果非常好！现在我们能够隔离开发，不光是在 ViewComponent 组件上，也在其他很多事情上。

然而，我认为这回避了一个问题：如果 previews 是一个对此类事情如此有用的工具，那它不是应该更容易去设置才对吗？有一个在 Rails 中整合 previews 的通用格式会怎样呢？当然了，这还是一个很模糊的想法，但却非常值得琢磨——说不定哪一天就实现了呢！😉

## Wrapping up

我认为现在可以说，到此为止，我们的 ViewComponent 确实已经算是增压加速了。我们已经在本文中涵盖了太多内容（大部分都是纯技术性的），所以后退一步，问问自己：我们实际上学到了什么呢？我们获得了自己想要的吗？最后，我们会再做一次吗？

我只能说，对我自己而言，答案毫无疑问：“是的”。如果要我总结我们在 ViewComponent 上的经验，我会说有这样一些：

✅ 一般而言，对于视图代码的推测理解变得更加容易了

✅ 更新视图代码并依靠测试覆盖是安全的了

✅ 在前端和后端团队之间的协作得到了改进

✅ 前端不再成为简单 UI 应用的瓶颈了

当然，还有其他的替代方案可以尝试：[Trailblazer cells](https://github.com/trailblazer/cells) 和 [nice_partials](https://github.com/bullet-train-co/nice_partials)，但我相信你都将得到相同的受益。

那么这种方案有没有弊端呢？好吧，你会仍然需要教你的前端开发者去学习一些 Ruby 知识，这在某些团队中不那么容易。在我们这儿，完全不是问题，但不得不考虑到 Ruby 是我们团队的原生语言。

好啦，朋友们，上面就是我想说的全部了！前端世界已经发生过一场革命了，我认为该是也在后端发生的时候了——所以，上船启航吧！🚂

特别感谢，ViewComponent 的作者 [Joel Hawksley](https://github.com/joelhawksley) 抽出时间来审阅本文，和我们的 principal backend engineer [Vladimir Dementyev](https://github.com/palkan) 提出的很多想法，以及当然，还有超棒的 [`view_component-contrib` gem](https://github.com/palkan/view_component-contrib)。
