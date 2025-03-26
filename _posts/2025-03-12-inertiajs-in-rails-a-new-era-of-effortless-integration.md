---
layout: post
title: Monolith的新时代
author: xfyuan
categories: [Translation, Programming]
tags: [ruby, rails, inertiajs, frontend, evil martians]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/img20250312.jpg"
rating: 5
---

_本文已获得原作者（**Svyatoslav Kryukov**、**Travis Turner**）和 Evil Martians 授权许可进行翻译。原文讲述了 Inertia.js 这个新兴工具在 Rails 中的集成。对 Monolith 架构的促进，并以具体实例进行了演示。_

- 原文链接：[Inertia.js in Rails: a new era of effortless integration](https://evilmartians.com/chronicles/inertiajs-in-rails-a-new-era-of-effortless-integration)
- 作者：Svyatoslav Kryukov、**Travis Turner**
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发者博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

_【序】_

Inertia.js 也是我去年在 RubyConf China 2024 上做的讲演主题的核心内容之一，下面是 B 站和 YouTube 的视频地址，有兴趣的朋友可以去看看:

#### Bilibili

<iframe src="//player.bilibili.com/player.html?isOutside=true&aid=113808513172219&bvid=BV1R2cceWEvS&cid=27810661447&p=1&autoplay=0" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" width="560" height="315"></iframe>

#### Youtube

<iframe width="560" height="315" src="https://www.youtube.com/embed/2Qbj3jmksOQ?si=AqG8WEBGCnHlaP7o" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

_【正文如下】_

## 引言

我们的 CEO [Irina Nazarova](https://twitter.com/inazarova) 在她的 RailsConf 主题演讲“2024 年的 Startups on Rails”中，指出了年轻的 Rails 初创公司的第一个需求——在 Rails 社区中提供适当的 React 支持。因此，我们最近推出了 [Turbo Mount](https://evilmartians.com/chronicles/the-art-of-turbo-mount-hotwire-meets-modern-js-frameworks)，当你的应用只需要几个高度交互的组件时，它简化了场景。但今天，我们更进一步，展示如何简单地将 Inertia.js 与 Rails 集成。

[Hotwire](https://hotwired.dev/) 和 [Inertia.js](https://inertiajs.com/) 都是使用 Rails 构建现代 Web 应用的好工具。但是，它们具有不同的用例和目标受众：

- **Hotwire** 是一组工具，可使用 Turbo Streams 和 Turbo Frames 实现 HTML 的服务器端渲染和页面的部分更新。

  对于希望在交互性和实时更新方面增强服务端渲染的 Rails 应用而无需编写大量 JavaScript 代码的开发人员来说，这是一个不错的选择。对于应用需要一个或两个高度交互组件的情况，[Turbo Mount](https://evilmartians.com/chronicles/the-art-of-turbo-mount-hotwire-meets-modern-js-frameworks) 可用于将 React、Vue 或 Svelte 组件直接挂载到经典 HTML 页面的一部分中。

**Inertia.js** 是一个协议和一组库，支持从传统 HTML 模板完全过渡到使用 React、Vue、Svelte 或其他前端框架组件作为视图层的构建块。

这种方案非常适合精通前端框架的团队，他们希望利用自己的技能创建更加动态和响应式的用户界面，同时仍然保持传统的服务端驱动的路由（routing）和控制器（controller）。

这种设置消除了对客户端的路由、API 或通常与拥有单独的前端和后端应用相关的大量 JavaScript 样板的需求。

尽管 [`inertia_rails`](https://github.com/inertiajs/inertia-rails) 已经存在了一段时间，但它仍然不如 Hotwire 或 [StimulusReflex](https://stimulusreflex.com/) 等其他解决方案受欢迎。然而，我们相信 Inertia.js 非常适合 Rails 应用，它涵盖了许多需要功能齐全的 JavaScript 框架的使用案例。

我们还希望让 Inertia.js 在 Rails 社区中更受欢迎。随着最近将 [`inertia_rails-contrib` 项目](https://github.com/skryukov/inertia_rails-contrib)上游到核心 `inertia_rails` gem 中，Rails 开发人员现在可以直接在核心项目中访问增强的工具和[特定于 Rails 的文档](https://inertia-rails.dev/)。这种集成简化了在 Rails 应用程序中使用 Inertia.js 的过程，并加强了对 Rails 生态系统的支持。

在本文中，我们将首先仔细研究 Inertia.js 的工作原理。然后，我们将了解如何使用 `inertia_rails` 生成器将其集成到 Rails 应用中。

将本文视为快速概览就好，我们不会深入研究。也会分享一些文档链接。最后，我们将讨论 Rails 生态系统中Inertia.js的未来。

## How Inertia.js works

要使用 Inertia.js，我们的服务端应用需要实现 [Inertia.js 协议](https://inertia-rails.dev/guide/the-protocol)。该协议基于为两种类型请求提供服务的理念：经典 HTML 请求和 Inertia.js 请求。让我们更详细地讨论一下它是如何工作的：

1. **初始页面加载**：当用户第一次访问应用时，服务端会返回一个完整的 HTML 响应，就像传统服务端渲染的 Rails 应用一样。此 HTML 响应包括必要的 assets 和一个特殊的根 `<div>` 元素，该元素具有 `data-page` 属性，其中包含 JSON 格式的初始页面数据。

2. **后续页面访问**：Inertia.js提供了一个 [<link> 组件](https://inertia-rails.dev/guide/links)，用于替代标准 `<a>` 标记。当用户单击 `<Link>` 时，Inertia.js 会向服务端发送带有 `X-Inertia` 标头的 AJAX 请求。（另一种选择是使用 [Inertia 的 `router`](https://inertia-rails.dev/guide/manual-visits) 以编程方式导航到新页面。

3. **服务端响应**：使用 `X-Inertia` 标头后，Rails 应用会识别 Inertia 请求并返回一个 JSON 响应，其中包含要呈现的页面组件的名称、该组件的必要数据、新的页面 URL，最后是当前 assets 的构建版本。

   Inertia.js 使用该数据更新页面内容和浏览器地址栏中的 URL，而无需刷新整个页面。

Inertia.js 背后的想法非常简单：不需要 Redux 或 REST API——默认情况下，每个请求都只返回一个 JSON 响应，其中包含渲染页面所需的所有数据。

> 对于更复杂的用例，Inertia.js 提供了不同的方法来延迟加载数据，或对页面进行部分更新（有关更多信息，请参阅[部分重新加载文档](https://inertia-rails.dev/guide/partial-reloads)）。

## Inertia.js Rails integration

让我们看看如何使用 `inertia_rails` 生成器启动一个新的 带 Inertia.js 的 Rails 应用。首先，我们将设置一个新的 Rails 应用，忽略默认的 JavaScript 和 assets pipeline 设置：

```sh
rails new inertia_rails_example --skip-js --skip-asset-pipeline

cd inertia_rails_example
```

接下来，我们将安装 `inertia_rails` gem 并运行安装生成器：

```sh
bundle add inertia_rails

bin/rails generate inertia:install
```

生成器会安装 [Vite 前端构建工具](https://vite-ruby.netlify.app/)，可以选择安装 [Tailwind CSS](https://tailwindcss.com/)，并要求你选择一个前端框架.我们将选择 React。

```sh
$ bin/rails generate inertia:install
Installing Inertia's Rails adapter
Could not find a package.json file to install Inertia to.

Would you like to install Vite Ruby? (y/n) y
         run  bundle add vite_rails from "."
Vite Rails gem successfully installed
         run  bundle exec vite install from "."
Vite Rails successfully installed

Would you like to install Tailwind CSS? (y/n) y
Installing Tailwind CSS
         run  npm add tailwindcss postcss autoprefixer @tailwindcss/forms @tailwindcss/typography @tailwindcss/container-queries --silent from "."
      create  tailwind.config.js
      create  postcss.config.js
      create  app/frontend/entrypoints/application.css
Adding Tailwind CSS to the application layout
      insert  app/views/layouts/application.html.erb
Adding Inertia's Rails adapter initializer
      create  config/initializers/inertia_rails.rb
Installing Inertia npm packages

What framework do you want to use with Inertia? [react, vue, svelte] (react)
         run  npm add @inertiajs/react react react-dom @vitejs/plugin-react --silent from "."
Adding Vite plugin for react
      insert  vite.config.ts
     prepend  vite.config.ts
Copying inertia.js entrypoint
      create  app/frontend/entrypoints/inertia.js
Adding inertia.js script tag to the application layout
      insert  app/views/layouts/application.html.erb
Adding Vite React Refresh tag to the application layout
      insert  app/views/layouts/application.html.erb
        gsub  app/views/layouts/application.html.erb
Copying example Inertia controller
      create  app/controllers/inertia_example_controller.rb
Adding a route for the example Inertia controller
       route  get 'inertia-example', to: 'inertia_example#index'
Copying page assets
      create  app/frontend/pages/InertiaExample.jsx
      create  app/frontend/pages/InertiaExample.module.css
      create  app/frontend/assets/react.svg
      create  app/frontend/assets/inertia.svg
      create  app/frontend/assets/vite_ruby.svg
Copying bin/dev
      create  bin/dev
Inertia's Rails adapter successfully installed
```

就是这样！生成器已经设置了 Inertia.js Rails 适配器，安装了必要的 NPM 包，安装并配置了 Vite 和 Tailwind CSS，并创建了一个示例页面。此时，你可以通过运行 `bin/dev` 来启动 Rails 服务器并导航到 http://localhost:3100/inertia-example。应该会看到带有 React 组件的 Inertia.js 页面。

<video width="720" height="450" controls="controls">
  <source src="https://evilmartians.com/static/c4c8da169203cc3bdd6ee643c158ea84/install-generator.av1.mp4" type="video/mp4">
</video>

让我们仔细看看生成的 controller 和 component。Controller 位于 `app/controllers/inertia_example_controller.rb` 文件中：

```ruby

class InertiaExampleController < ApplicationController
  def index
    render inertia: "InertiaExample", props: {
      name: params.fetch(:name, "World")
    }
  end
end
```

请注意，控制器使用 `inertia` 方法来渲染 Inertia.js 页面。`props` 包含了将传递给 React 组件的 props。使用 serializers 为前端准备 props 是一种很好的做法，但为了简单起见，我们只从 URL 传递 `name` 参数。要了解更多信息，请查看 [Inertia.js Rails 文档中的`惯性`方法](https://inertia-rails.dev/guide/responses)。

React 组件位于文件 `app/frontend/pages/InertiaExample.jsx`：

```jsx
import { Head } from "@inertiajs/react";
import { useState } from "react";

import reactSvg from "/assets/react.svg";
import inertiaSvg from "/assets/inertia.svg";
import viteRubySvg from "/assets/vite_ruby.svg";

import cs from "./InertiaExample.module.css";

export default function InertiaExample({ name }) {
  const [count, setCount] = useState(0);

  return (
    <>
      <Head title="Inertia + Vite Ruby + React Example" />

      <div className={cs.root}>
        <h1 className={cs.h1}>Hello {name}!</h1>

        {/*<div...>*/}

        <h2 className={cs.h2}>Inertia + Vite Ruby + React</h2>

        {/*<div className="card"...>*/}
        {/*<p className={cs.readTheDocs}...>*/}
      </div>
    </>
  );
}
```

该组件接受从 controller 传递的 `name` prop。你可以更新 URL 中的 `name` 参数以查看组件中的更改。

除此之外，我们的页面是一个常规的 React 组件，它使用 `useState` hook 来管理 count 状态。

## Inertia.js generators

为了简化 Inertia.js 集成，我们向 `inertia_rails` Gem 添加了一组生成器。让我们看看如何生成新的 Inertia.js resource：

```sh
bin/rails generate inertia:scaffold Post title:string body:text published_at:datetime
      invoke  active_record
      create    db/migrate/20240618171615_create_posts.rb
      create    app/models/post.rb
      invoke    test_unit
      create      test/models/post_test.rb
      create      test/fixtures/posts.yml
      invoke  resource_route
       route    resources :posts
      invoke  scaffold_controller
      create    app/controllers/posts_controller.rb
      invoke    inertia_tw_templates
      create      app/frontend/pages/Post
      create      app/frontend/pages/Post/Index.jsx
      create      app/frontend/pages/Post/Edit.jsx
      create      app/frontend/pages/Post/Show.jsx
      create      app/frontend/pages/Post/New.jsx
      create      app/frontend/pages/Post/Form.jsx
      create      app/frontend/pages/Post/Post.jsx
      invoke    resource_route
      invoke    test_unit
      create      test/controllers/posts_controller_test.rb
      create      test/system/posts_test.rb
      invoke    helper
      create      app/helpers/posts_helper.rb
      invoke      test_unit
```

生成器将创建具有指定属性的新 Post resource。它生成 model、controller、view 和前端组件。

<video width="720" height="450" controls="controls">
  <source src="https://evilmartians.com/static/45deed3c8ffd2df2a8c5ab74ef4f0024/crud-demo.av1.mp4" type="video/mp4">
</video>

由于生成器会创建大量文件，因此让我们只看一下生成的 controller 中的表单处理，其余的留给你探索。

我们将从 `app/controllers/posts_controller.rb` 文件中的 `edit` 和 `update`开始：

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]

  inertia_share flash: -> { flash.to_hash }

  # GET /posts/1/edit
  def edit
    render inertia: 'Post/Edit', props: {
      post: serialize_post(@post)
    }
  end

  # PATCH/PUT /posts/1
  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      redirect_to edit_post_url(@post), inertia: { errors: @post.errors }
    end
  end

  #...
end
```

首先，让我们检查一下 `inertia_share` helper 方法。我们使用它来向所有 Inertia.js 响应添加 Flash 消息。在 React 组件中显示 `flash[：notice]` 消息。

`edit`行为使用 `render: inertia` 来渲染包含序列化的 post 数据的 `Post/Edit` 页面。所有前端组件（pages）都位于 `app/frontend/pages/Post` 目录中。

最后，如果更新成功，则 `update` 会更新 post 并重定向到 post show 页面。请注意，如果存在任何验证错误，它不会引发错误，而是重定向回 edit 页面，并在`inertia` key 中序列化错误。

（另一个值得您花时间的有趣主题是一般[的错误处理文档](https://inertia-rails.dev/guide/error-handling)。）

接下来，我们看一下组件 `app/frontend/pages/Post/Edit.jsx` ：

```jsx
import { Link, Head } from "@inertiajs/react";
import Form from "./Form";

export default function Edit({ post }) {
  return (
    <>
      <Head title="Editing post" />

      <div className="mx-auto md:w-2/3 w-full px-8 pt-8">
        <h1 className="font-bold text-4xl">Editing post</h1>

        <Form
          post={post}
          onSubmit={(form) => {
            form.transform((data) => ({ post: data }));
            form.patch(`/posts/${post.id}`);
          }}
          submitText="Update post"
        />

        <Link
          href={`/posts/${post.id}`}
          className="ml-2 rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium"
        >
          Show this post
        </Link>
        <Link
          href="/posts"
          className="ml-2 rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium"
        >
          Back to posts
        </Link>
      </div>
    </>
  );
}
```

请注意，我们使用 `@inertiajs/react` 的 `Link` 导航到其他页面，而无需重新加载整个页面。就像默认的 Rails 脚手架一样，我们生成一个处理表单提交的表单组件：

```jsx
import { useForm } from "@inertiajs/react";

export default function Form({ post, onSubmit, submitText }) {
  const form = useForm({
    title: post.title || "",
    body: post.body || "",
    published_at: post.published_at || "",
  });
  const { data, setData, errors, processing } = form;

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(form);
  };

  return (
    <form onSubmit={handleSubmit} className="contents">
      <div className="my-5">
        <label htmlFor="title">Title</label>
        <input
          type="text"
          name="title"
          id="title"
          value={data.title}
          className="block shadow rounded-md border border-gray-400 outline-none px-3 py-2 mt-2 w-full"
          onChange={(e) => setData("title", e.target.value)}
        />
        {errors.title && (
          <div className="text-red-500 px-3 py-2 font-medium">
            {errors.title.join(", ")}
          </div>
        )}
      </div>

      {/* ... */}
    </form>
  );
}
```

`表单`组件使用 `@inertiajs/react` 中的 `useForm` hook 来处理表单状态和提交。这个 hook 与 Rails 的默认值配合得很好，允许你提交表单并显示验证错误，而无需编写大量样板代码。

总的来说，与 Inertia.js 和 Rails 集成相关的内容有很多值得探索的地方，因此我们再次鼓励去查看完整的 [Inertia.js Rails 文档](https://inertia-rails.dev/)，以了解有关可用功能和最佳实践的更多信息。

## The future of Inertia.js in the Rails ecosystem

现在 Rails 生态系统中发生了很多令人兴奋的事情：Hotwire、Turbo 和 StimulusReflex 越来越受欢迎，并改变了我们的构建方式。

而 Inertia.js 是 Rails 工具包的另一个重要补充。我们相信它在 Rails 领域有着光明的未来。它提供了一种简单而优雅的方式来构建现代 Web 应用，而无需复杂的客户端路由和 API。

通过这个项目，我们的目标是让 Inertia.js 更受欢迎，并分享构建优秀应用所需的工具和资源。

如果你有兴趣了解有关 Inertia.js 的更多信息（以及它如何帮助构建更好的 Rails 应用），请前往 [Inertia.js Rails 文档](https://inertia-rails.dev/)。如果你已在 Rails 应用程序中使用 Inertia.js，我们很乐意倾听你的体验以及使用 Inertia.js 的任何提示或技巧！有什么最佳实践、提示或技巧吗？

无论你是想更深入地了解 Inertia.js 还是想参与贡献，都可以加入我们的[inertia_rails](https://github.com/skryukov/inertia_rails-contrib)！
