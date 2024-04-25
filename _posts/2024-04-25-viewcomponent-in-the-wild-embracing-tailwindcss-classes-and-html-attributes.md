---
layout: post
title: " 狂野的ViewComponent（三）: TailwindCSS类和HTML属性"
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, view_component, evil martians]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20240425_0539.jpg"
rating: 5
---

*本文已获得原作者（**Vladimir Dementyev**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了在单体式模块架构下，使用 ViewComponent 来构建组件化的现代 Rails 前端的故事。（本文是下篇）*

- 原文链接：[ViewComponent in the Wild III: TailwindCSS classes & HTML attributes](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-embracing-tailwindcss-classes-and-html-attributes)
- 作者：Vladimir Dementyev、**Travis Turner**
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

Ruby on Rails 全栈开发正重回正轨：其方向就是优先考虑 HTML！为了向前迈进，我们需要更好的工具来管理视图层。GitHub 的 ViewComponent 库仍然是 Rails 开发人员为 HTML 带入理智的首选。

我们在 Evil Martians 使用这个库已经有一段时间了，我们准备展示自本系列开始以来所积累的新技巧和诀窍。在本文中，我们将讨论如何集成 TailwindCSS 样式以及在 view component 中对 HTML 属性的传播。出发吧！

## 本系列其他部分

1. [ViewComponent in the Wild I: building modern Rails frontends](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends)
2. [ViewComponent in the Wild II: supercharging your components](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-supercharging-your-components)



几年前，我们开始采用 ViewComponent 来帮助我们组织 HTML 模板和 partials。起初，我们主要将其用作一种软件设计模式，以帮助控制代码。然而，随着生态系统和我们经验的发展，ViewComponent 成为创建应用的设计系统的关键元素。

设计系统是用于制作 UI 的可重用元素和指南的集合。在代码中，设计系统通过 UI 工具包来呈现，UI 工具包是视图层的一部分，负责实现设计系统的 UI 元素。“可重复使用的元素”自然会产生组件。但是，如果没有 storybook，维护 UI 套件是不可能的。ViewComponent 与 [Lookbook](https://lookbook.build/)（我们在[上一篇文章](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-supercharging-your-components#setting-up-a-storybook-bonus)中讨论过）一起为你提供了所需的一切来开始由设计系统驱动的 UI 开发。

Rails 专注于生产力，而编写代码最有效率的方式就是根本不写代码。针对 Ruby 和 Rails 应用的现成 UI 套件仍然是稀有动物，其中大多数仍处于 alpha 阶段。因此，你可能必须为应用程序制作自定义的 UI 库。但不用担心！我们已经经历过几次，并准备分享有价值的技巧，以简化使用 ViewComponent 的 UI 工具包的开发。今天的“菜单”如下：

1. Style variants（样式变体）
2. HTML attributes propagation（HTML 属性传播）
3. Browser tests for components（组件的浏览器测试）

## Style variants

TailwindCSS 已经征服了 UI 开发的世界。当你能够使用 HTML 类来定义所有样式时，为什么还要为 CSS 规则、嵌套和命名（BEM、SMACSS 等）而烦恼呢？让 HTML 成为单一来源，与现代全栈 Rails 的“无构建”理念特别吻合。

使用 TailwindCSS，你可以开发一致的 UI，而无需接触 CSS 文件。你可以在 `tailwind.config.js` 文件中定义设计系统的基本要素（排版、网格等）和设计 token，并享受原子（和动态）CSS 类的魔力。然而，这是有代价的：HTML 中会有几十个类。让我们来看一个示例 Button 组件：

```ruby
class UIKit::Button::Component < ApplicationComponent
  option :type, default: proc { "button" }

  erb_template <<~ERB
    <button type="<%= type %>"
      class="items-center justify-center rounded-md border border-slate-300
      bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm ring-blue-700
      hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2
      focus:ring-offset-blue-50 dark:border-slate-950 dark:bg-blue-700
      dark:text-blue-50 dark:ring-blue-950 dark:hover:bg-blue-800 dark:focus:ring-offset-blue-700">
      <%= content %>
    </button>
  ERB
end
```

上面的示例中，我们使用了 ViewComponent 的 inline 模板功能（在 v3 中加入）和通过 view_component-contrib 库生成的 `ApplicationComponent` 类（可在本系列的[第二部分](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-supercharging-your-components#setting-up-a-storybook-bonus)中了解更多信息）。我们可以按如下方式呈现它：

```erb
<%= render UIKit::Button::Component.new do %>
  Click Me
<% end %>
```

这会生成如下 UI：

![img](https://evilmartians.com/static/e7b67b65b91ae4d2c621dd8c40661486/138ad/button.webp)

但这仅仅是个开始，因为按钮组件从来都不是只有一种格式。每个 UI 工具包都包含多个按钮变体。让我们考虑添加按钮的 outline 版本。

这需要有条件地包含一些类，具体取决于所选的变体：

```ruby
class UIKit::Button::Component < ApplicationComponent
  option :type, default: proc { "button" }
  option :variant, default: proc { :default }

  STYLES = {
    default: "text-white bg-blue-600 ring-blue-700 \
      hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 \
      focus:ring-offset-blue-50 dark:border-slate-950 dark:bg-blue-700 \
      dark:text-blue-50 dark:ring-blue-950 dark:hover:bg-blue-800 dark:focus:ring-offset-blue-700",
    outline: "bg-slate-50 hover:bg-slate-100 focus:outline-none \
      focus:ring-2 focus:ring-slate-600 focus:ring-offset-2 \
      focus:ring-offset-blue-50 dark:border-slate-950 dark:bg-slate-700 \
      dark:ring-slate-950 dark:hover:bg-slate-800 dark:focus:ring-offset-slate-700"
  }.freeze

  erb_template <<~ERB
    <button type="<%= type %>"
      class="items-center justify-center rounded-md border border-slate-300
      px-4 py-2 text-sm font-medium shadow-sm <%= STYLES.fetch(variant) %>">
      <%= content %>
    </button>
  ERB
end
```

现在，我们可以在渲染按钮时指定一个可选变量：

```ruby
```

```erb
<div class="flex flex-row space-x-4">
  <%= render UIKit::Button::Component.new do %>
    Click Me
  <% end %>
  <%= render UIKit::Button::Component.new(variant: :outline) do %>
    Click Me
  <% end %>
</div>
```

![img](https://evilmartians.com/static/b013f38859e145e25b2b5c4eddd1c5fe/b6be3/two_buttons.webp)

将类列表中的动态部分提取到一个常量中就可以了。但这只是针对单个变体维度和几个变体。在实践中，通常有更多的变体和变化。

例如，我们可能有不同的尺寸变体（小号、全号等）。有时，这些变化不是独立的，需要为某些组合添加额外的类。为了说明这一点，处理按钮组件的 `disabled` 状态可能就需要我们编写以下代码：

```ruby
class UIKit::Button::Component < ApplicationComponent
  option :type, default: proc { "button" }
  option :variant, default: proc { :default }
  option :disabled, default: proc { false }

  STYLES = {
    # ...
  }.freeze

  erb_template <<~ERB
    <button type="<%= type %>"
      class="items-center justify-center rounded-md border border-slate-300
      px-4 py-2 text-sm font-medium shadow-sm <%= STYLES.fetch(variant) %>
      <%= disabled_classes if disabled %>"
      <%= "disabled" if disabled %>>
      <%= content %>
    </button>
  ERB

  def disabled_classes
    if variant == :outline
      "opacity-75 bg-slate-300 pointer-events-none"
    else
      "opacity-50 pointer-events-none"
    end
  end
end
```

组件的代码不仅变得越来越纠缠不清，而且它的工作方式也不像我们预期的那样了。问题在于，对于处于禁用状态的按钮的 outline 版本，我们现在有两个冲突的类： `bg-slate-50` （来自 `STYLES[:outline]` ）和 `bg-slate-300` （来自 `#disabled_classes` ）。而前者胜出生效。

我们如何恢复组件样式的清晰度、可维护性和正确性？这正是介绍样式变体的时候。

Style Variants 是 view_component-contrib 包中包含的一个插件，其灵感来自 [Tailwind Variants](https://www.tailwind-variants.org/) 和 [CVA](https://cva.style/docs/getting-started/variants) 项目。它允许你以声明方式定义样式规则，如下所示：

```ruby
class UIKit::Button::Component < ApplicationComponent
  option :type, default: proc { "button" }
  option :variant, default: proc { :default }
  option :disabled, default: proc { false }

  style do
    base {
      %w[
        items-center justify-center px-4 py-2
        text-sm font-medium
        border border-slate-300 shadow-sm rounded-md
        focus:outline-none focus:ring-offset-2
      ]
    }
    variants {
      variant {
        primary {
          %w[
            text-white bg-blue-600 ring-blue-700
            hover:bg-blue-700
            focus:ring-offset-blue-50
            dark:border-slate-950 dark:bg-blue-700 dark:text-blue-50 dark:ring-blue-950
            dark:hover:bg-blue-800
            dark:focus:ring-offset-blue-700
          ]
        }
        outline {
          %w[
            bg-slate-50
            hover:bg-slate-100
            focus:ring-slate-600 focus:ring-offset-blue-50
            dark:border-slate-950 dark:bg-slate-700 dark:ring-slate-950
            dark:hover:bg-slate-800
            dark:focus:ring-offset-slate-700
          ]
        }
      }
      disabled {
        yes { %w[opacity-50 pointer-events-none] }
      }
    }
    defaults { {variant: :primary, disabled: false} }
    # The "compound" directive allows us to declare additional classes to add
    # when the provided combination is used
    compound(variant: :outline, disabled: true) { %w[opacity-75 bg-slate-300] }
  end

  erb_template <<~ERB
    <button type="<%= type %>" class="<%= style(variant:, disabled:) %>"<%= " disabled" if disabled %>>
      <%= content %>
    </button>
  ERB
end
```

所有样式逻辑都在 `style do ... end` 块中描述。在 HTML 模板中，我们只使用 `#style(**)` 帮助方法并将变体值传递给它。因此，我们不再有分散在组件代码中的类。

我们可能会强制执行自定义约定以用于样式变体定义。例如，你可能会注意到，我们已按修饰符对类进行分组（如 `focus:*` 和 `dark:*` 类放在单独的行上）。可以编写一个自定义的 RuboCop 规则来强制执行此约定（甚至可以自动排列类）。因此，从文本片段切换到 Ruby 代码也开辟了新的 DX 可能性。

该 `compound` 指令取代了我们以前 `#disabled_classes` 的方法。它是如何解决类冲突问题的？默认情况下，Style Variants 插件对类的性质没有任何假设（即，它不是特定于 TailwindCSS 的）。为了让它更聪明一点，并教它如何解决 CSS 冲突，我们可以将它与 [tailwind_merge](https://github.com/gjtorikian/tailwind_merge) gem 集成：

```ruby
class ApplicationComponent < ViewComponentContrib::Base
  include ViewComponentContrib::StyleVariants

  style_config.postprocess_with do |classes|
    TailwindMerge::Merger.new.merge(classes.join(" "))
  end
end
```

样式变体显著改进了使用 TailwindCSS 支持的 UI 组件的 DX。HTML 不再被冗长的样式定义所污染。CSS 类组织良好且可静态分析。通过这种方法，我们设法简化了 HTML 属性的定义 `class` 。其他方面呢？好，我们来谈谈 HTML 属性传播。

## HTML attribute propagation

对于基本的（原子）UI 元素，如按钮和表单 input，必须支持所有可能的函数式 HTML 属性（例如， `required` 、 `disabled` 、 `autocomplete` 等）。假设一个通用 input 组件定义如下：

```ruby
class UIKit::Input::Component < ApplicationComponent
  option :name

  option :id, default: proc { nil }
  option :type, default: proc { "text" }
  option :value, default: proc { nil }
  option :autocomplete, default: proc { "off" }
  option :placeholder, default: proc { nil }
  option :required, default: proc { false }
  option :disabled, default: proc { false }

  erb_template <<~ERB
    <span class="relative">
      <input type="<%= type %>"
        <% if id %> id="<%= id %>"<% end %>
        <% if value %> value="<%= value %>"<% end %>
        <% if name %> name="<%= name %>"<% end %>
        autocomplete="<%= autocomplete %>"
        <% if placeholder %> placeholder="<%= placeholder %>"<% end %>
        <% if required %> required<% end %>
        <% if disabled %> disabled<% end %>
      >
    </span>
  ERB
end
```

在这里，我们有一个用于注入这些属性的巨可怕的模板（仅当它们被定义时）。当我们有 `content_tag` （甚至 `text_field_tag` ）时，为什么要处理原始字符串？原因各不相同（从“避免将帮助方法与纯 HTML 混合使用” 到 “为了性能”）。无论如何，这里重要的是可以找到这样的代码，并非凭空捏造。

我们也可以声明我们想要公开的所有 HTML 属性（通过 dry-initializer 的 `.option` DSL）。但事实证明，这远非最佳。首先，它们可能有很多，而且大多数必须按原样注入 HTML 中。其次，经常有来自外部的属性，我们不希望我们的隔离性组件对它们负责（例如，Stimulus 的 data 属性，或 `test_id` 用于浏览器测试）。

作为明确的第一步，我们提出了属性 Bag 的想法：

```ruby
class UIKit::Input::Component < ApplicationComponent
  option :name

  option :html_attrs, default: proc { {} }
  option :input_attrs, default: proc { {} }, type: -> { {autocomplete: "off", required: false}.merge(_1) }

  erb_template <<~ERB
    <span class="relative" <%= tag.attributes(**html_attrs) %>>
      <input <%= tag.attributes(**input_attrs) %>>
    </span>
  ERB

  def before_render
    input_attrs.merge({name:})
  end
end
```

我们没有枚举所有可能的选项，而只添加了两个选项： `html_attrs` （对于容器元素）和 `input_attrs` 。为了将哈希转换为 HTML 属性字符串，我们使用 Rails 的内置 `tag.attributes` 帮助方法（从 Rails 7 开始可用）。下面是用于组件的新接口：

```erb
<%= render UIKit::Input::Component.new(
  name: "name",
  input_attrs: {placeholder: "Enter your name", autocomplete: "on", autofocus: true}) %>
```

请注意，我们仍然接受输入字段的名称作为单独的选项，以强调其基本作用（以及它是必需的）。

上面的声明 DSL 看起来仍然不够理想（尤其是 `type: ...` 部分）。因此，我们可以更进一步，像这样对 API 语法糖化：

```ruby
class UIKit::Input::Component < ApplicationComponent
  option :name

  html_option :html_attrs
  html_option :input_attrs, default: {autocomplete: "off", required: false}

  erb_template <<~ERB
    <span class="relative" <%= dots(html_attrs) %>>
      <input <%= dots(input_attrs) %>>
    </span>
  ERB
end
```

请注意， `#dots` 别名是对 JS 对象扩展运算符 （ `...` ） 的引用。

## Browser tests for components

为了完成我们的年度“火星上的 ViewComponent”报告，我想分享我们最近发布的另一个小扩展，旨在改善开发人员使用视图组件时的体验。

在本系列的第一部分中，我们提到可测试性是切换到组件的主要优势之一。但是，除了单元测试之外，你还可以使用 Rails 的系统测试来测试交互式组件：

```ruby
# spec/system/components/my_component_spec.rb

it "does some dynamic stuff" do
  visit("/rails/view_components/my_component/default")
  click_on("JavaScript-infused button")

  expect(page).to have_content("dynamic stuff")
end
```

此类测试依赖于预览功能，该功能会扰乱 storybook，并在测试环境和开发环境之间引入耦合。为了解决这个问题，我们为测试构建了 inline 模板：

```ruby
it "does some dynamic stuff" do
  visit_template <<~ERB
    <form id="myForm" onsubmit="event.preventDefault(); this.innerHTML = '';">
      <h2>Self-destructing form</h2>
      <%= render Button::Component.new(type: :submit, kind: :info) do %>
        Destroy me!
      <% end %>
    </form>
  ERB

  expect(page).to have_text "Self-destructing form"

  click_on("Destroy me!")

  expect(page).to have_no_text "Self-destructing form"
end
```

现在，被测试的 HTML 可以直接在测试本身中定义了，而此功能可通过 [rails-intest-views](https://github.com/palkan/rails-intest-views) gem 获得。试一试吧！

## A last note

自从本系列的第一篇文章在撰写本文大约一年半前发表以来，我们构建 Rails 全栈应用的方式已经发生了变化。

TailwindCSS 赢得了 CSS 的战争（我们曾经尝试过 PostCSS Modules），Webpacker 退役了，UI 组件库终于来到了 Rails 的世界。

尽管如此，ViewComponent 仍然是我们的核心 UI 技术，可以轻松地让我们跟上不断变化的软件开发趋势。这正是我们继续投资于它的原因！
