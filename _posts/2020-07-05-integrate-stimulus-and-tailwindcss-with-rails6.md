---
layout: post
title: 在 Rails 6 中整合 Stimulus 和 Tailwind CSS
author: Mr.Z
categories: [ Programming ]
tags: [ruby, rails, stimulus, tailwindcss]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200715a017.jpg"
---

上一篇博客提到了 Stimulus。Stimulus 也是 Basecamp 开源发布的一个前端 JS 方案（我个人认为，跟 React、Vuejs这些 JS 框架相比，Stimulus 应该还称不上是一个框架）。Stimulus 的文档很简单，主要就 [Handbook](https://stimulusjs.org/handbook/introduction) 和 [Reference](https://stimulusjs.org/reference/controllers) 两部分，基本两个小时就能看完。

Tailwind CSS 则是目前很火的一个 CSS 库，我个人很看好。它有点类似著名的 Bootstrap 框架，但又有显著不同。简单地说，Tailwind CSS 是一个让你能不写 CSS 就能实现 CSS 效果的一个 CSS 工具库。Tailwind CSS 的具体优点，我准备以后用专门的文章进行介绍，本文不做过多展开。

所以，本文就来看下在 Rails 6 中如何集成 Stimulus 和 Tailwind CSS 并进行简单地使用。

首先，当然是使用

```ruby
rails new stw_demo -d postgresql
```

来创建一个新 Rails 项目，并进行常规的`database.yml`、`Gemfile`等配置，这里不做赘述了。

### 集成 Stimulus 并创建一个小的 Demo

然后，运行如下命令来安装 Stimulus

```ruby
rails webpacker:install:stimulus
```

修改`config/routes.rb`为

```ruby
root to: 'home#index'
```

修改`app/controllers/home_controller.rb`为

```ruby
class HomeController < ApplicationController
  def index
  end
end
```

修改`app/views/home/index.html.erb`为

```erb
<div data-controller="hello">
  <h3> Default text when connect stimulus: </h3>
  <span data-target="hello.output"></span>

  <h3> disply text when click button: </h3>
  <div>
  <button data-action="click->hello#sayHello">Say Hello!</button>
  <span data-target="hello.sayResult">123</span>
  </div>
</div>
```

修改`app/javascript/controllers/hello_controller.js`为

```javascript
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "output", "sayResult" ]

  connect() {
    this.outputTarget.textContent = 'Welcome, Stimulus!'
  }
  sayHello() {
    this.sayResultTarget.textContent = 'Hello, Stimulus!'
  }
}
```

修改`app/javascript/controllers/index.js`为

```javascript
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /_controller\.js$/)
application.load(definitionsFromContext(context))
```

然后运行`rails s`，浏览器打开`http://localhost:3000`，即可体验 Stimulus 的实际效果了。

### 集成 Tailwind CSS

使用 yarn 进行安装

```sh
yarn add tailwindcss
yarn add @tailwindcss/ui
```

生成 tailwind 的配置文件

```sh
npx tailwindcss init
```

这会在项目根目录下生成一个`tailwind.config.js`，加入下面内容

```javascript
module.exports = {
  purge: [],
  theme: {
    extend: {},
  },
  variants: {},
  plugins: [],
}
```

然后，对根目录下的`postcss.config.js`进行修改，加入

```javascript
require('tailwindcss'),
require('autoprefixer'),
```

`postcss.config.js`最终是这样

```javascript
module.exports = {
  plugins: [
    require('postcss-import'),
    require('tailwindcss'),
    require('autoprefixer'),
    require('postcss-flexbugs-fixes'),
    require('postcss-preset-env')({
      autoprefixer: {
        flexbox: 'no-2009'
      },
      stage: 3
    })
  ]
}
```

再在`app/javascript`下创建一个名为`stylesheets`的目录，并在其下创建一个`application.scss`文件

```css
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";
```

然后在`app/javascript/packs/application.js`内添加如下几行

```javascript
require('stylesheets/application.scss')
```

`app/javascript/packs/application.js`最终看起来是这样

```javascript
require("@rails/ujs").start()
require("turbolinks").start()
require("channels")
import '../stylesheets/application.scss'
```

至此，Tailwind CSS 就可以在 Rails 中使用了。来试试把前面的 Home index 页面应用上，把其 erb 文件改为如下

```erb
<div class="py-6 mx-auto max-w-7xl sm:px-6 lg:px-8" data-controller="hello">
  <!-- Replace with your content -->
  <div class="px-4 py-6 sm:px-0">
    <div class="border-4 border-gray-200 border-dashed rounded-lg h-96">
      <div>
        Default text when connect stimulus:
        <span data-target="hello.output"></span>
      </div>

      <div>
        disply text when click button:
        <button class="px-4 py-2 font-bold text-white bg-blue-500 rounded hover:bg-blue-700" data-action="click->hello#sayHello">Say Hello!</button>
        <span data-target="hello.sayResult">123</span>
      </div>
    </div>
  </div>
  <!-- /End replace -->
</div>
```

运行`rails s`，访问`http://localhost:3000`，应该就可以看到效果了。

### 加入 Alpine.js

Tailwind CSS 只是一个工具库，并未提供现成的页面模块可以参考。不过不要紧，他们已经推出了 Tailwind-UI 的库，已经包含了这些内容，比如常见的页面布局，Header 设计，以及 Navigation 菜单等。因为这些需要一些简单 JS 的配合，Tailwind 官方文档里推荐了 Alpine.js 的库作为辅助。我们来把这些加入到项目中，以便快速实现一个不错的页面布局。

安装 Alpine.js

```sh
yarn add alpinejs
```

在`app/javascript/packs/application.js`内加入这行

```javascript
require("alpinejs")
```

然后，修改`app/views/layouts/application.html.erb`为如下：

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>STW Demo</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  </head>

  <body>
    <div>
      <nav x-data="{ open: false }" @keydown.window.escape="open = false" class="bg-gray-800">
        <div class="px-4 mx-auto max-w-7xl sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-16">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <h3 class="text-lg text-gray-300 ">MyApp</h3>
              </div>
              <div class="hidden md:block">
                <div class="flex items-baseline ml-10">
                  <a href="#" class="px-3 py-2 text-sm font-medium text-white bg-gray-900 rounded-md focus:outline-none focus:text-white focus:bg-gray-700">Dashboard</a>
                  <a href="#" class="px-3 py-2 ml-4 text-sm font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Team</a>
                  <a href="#" class="px-3 py-2 ml-4 text-sm font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Projects</a>
                  <a href="#" class="px-3 py-2 ml-4 text-sm font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Calendar</a>
                  <a href="#" class="px-3 py-2 ml-4 text-sm font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Reports</a>
                </div>
              </div>
            </div>
            <div class="hidden md:block">
              <div class="flex items-center ml-4 md:ml-6">
                <button class="p-1 text-gray-400 border-2 border-transparent rounded-full hover:text-white focus:outline-none focus:text-white focus:bg-gray-700">
                  <svg class="w-6 h-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                  </svg>
                </button>
                <div @click.away="open = false" class="relative ml-3" x-data="{ open: false }">
                  <div>
                    <button @click="open = !open" class="flex items-center max-w-xs text-sm text-white rounded-full focus:outline-none focus:shadow-solid">
                      <img class="w-8 h-8 rounded-full" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" />
                    </button>
                  </div>
                  <div x-show="open" x-transition:enter="transition ease-out duration-100" x-transition:enter-start="transform opacity-0 scale-95" x-transition:enter-end="transform opacity-100 scale-100" x-transition:leave="transition ease-in duration-75" x-transition:leave-start="transform opacity-100 scale-100" x-transition:leave-end="transform opacity-0 scale-95" class="absolute right-0 w-48 mt-2 shadow-lg origin-top-right rounded-md">
                    <div class="py-1 bg-white rounded-md shadow-xs">
                      <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Your Profile</a>
                      <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Settings</a>
                      <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Sign out</a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="flex -mr-2 md:hidden">
              <button @click="open = !open" class="inline-flex items-center justify-center p-2 text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:bg-gray-700 focus:text-white">
                <svg class="w-6 h-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                  <path :class="{'hidden': open, 'inline-flex': !open }" class="inline-flex" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                  <path :class="{'hidden': !open, 'inline-flex': open }" class="hidden" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        </div>
        <div :class="{'block': open, 'hidden': !open}" class="hidden md:hidden">
          <div class="px-2 pt-2 pb-3 sm:px-3">
            <a href="#" class="block px-3 py-2 text-base font-medium text-white bg-gray-900 rounded-md focus:outline-none focus:text-white focus:bg-gray-700">Dashboard</a>
            <a href="#" class="block px-3 py-2 mt-1 text-base font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Team</a>
            <a href="#" class="block px-3 py-2 mt-1 text-base font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Projects</a>
            <a href="#" class="block px-3 py-2 mt-1 text-base font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Calendar</a>
            <a href="#" class="block px-3 py-2 mt-1 text-base font-medium text-gray-300 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Reports</a>
          </div>
          <div class="pt-4 pb-3 border-t border-gray-700">
            <div class="flex items-center px-5">
              <div class="flex-shrink-0">
                <img class="w-10 h-10 rounded-full" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" />
              </div>
              <div class="ml-3">
                <div class="text-base font-medium leading-none text-white">Tom Cook</div>
                <div class="mt-1 text-sm font-medium leading-none text-gray-400">tom@example.com</div>
              </div>
            </div>
            <div class="px-2 mt-3">
              <a href="#" class="block px-3 py-2 text-base font-medium text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Your Profile</a>
              <a href="#" class="block px-3 py-2 mt-1 text-base font-medium text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Settings</a>
              <a href="#" class="block px-3 py-2 mt-1 text-base font-medium text-gray-400 rounded-md hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700">Sign out</a>
            </div>
          </div>
        </div>
      </nav>
      <header class="bg-white shadow">
        <div class="px-4 py-6 mx-auto max-w-7xl sm:px-6 lg:px-8">
          <h2 class="text-3xl font-bold leading-tight text-gray-900">
            Dashboard
          </h2>
        </div>
      </header>

      <main>
      <%= yield %>
      </main>
    </div>
  </body>
</html>
```

再次运行`rails s`，访问`http://localhost:3000`，可以看到出现的常规页面布局，顶部右侧的头像点击可以弹出菜单。

### 最后的优化设计（加入自定义字体）

我们有时希望使用更独特优美的字体来作为默认字体，以此增强页面的显示效果。下面我们来加入目前有点流行的 Inter 字体。

安装字体

```sh
yarn add 'typeface-inter'
```

然后需要告诉 Tailwind CSS 使用这个字体。首先，修改`app/javascript/packs/application.js`加入下面这行

```javascript
require('typeface-inter')
```

再修改`tailwind.config.js`为

```javascript
module.exports = {
  theme: {
    fontFamily: {
      body: ['inter']
    },
    extend: {},
  },
  variants: {},
  plugins: [],
}
```

最后，需要修改上面的`application.scss`为如下以应用新字体

```css
@import "tailwindcss/base";
html {
  @apply font-body;
}
@import "tailwindcss/components";
@import "tailwindcss/utilities";
```

这样，我们就搭建好了一个集成 Stimulus + Tailwind CSS + Tailwind UI + Alpine.js 的 Rails 项目基础，而且应用了自定义的 Inter 字体。接下来，就可以在这个基础上进行开发了。



