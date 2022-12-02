---
layout: post
title: GraphQL on Rails——启程
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, graphql]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20201113_205558.jpg"
rating: 4
---

*本文已获得原作者（Dmitry Tsepelev）、（Polina Gurtovaya）和 Evil Martians 授权许可进行翻译。原文是 Rails + React 使用 GraphQL的系列教程第一篇，介绍了以 Rails 作为后端，React + Apollo 作为前端，如何经过基础的配置，构建一个简单图书馆列表页面。*

- 原文链接：[GraphQL on Rails: From zero to the first query](https://evilmartians.com/chronicles/graphql-on-rails-1-from-zero-to-the-first-query)
- 作者：[Dmitry Tsepelev](https://twitter.com/dmitrytsepelev)，[Polina Gurtovaya](https://github.com/HellSquirrel)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

**这是一个在后端使用 Rails、前端使用 React/Apollo 来开发 GraphQL 应用程序的旅行者指导。跟随该系列教程可通过范例学到既有基础的、也有高级的主题内容，让你领略现代技术的威力。**

[GraphQL](https://graphql.org/) 是我们在任何地方（博客、会议、播客，甚至报纸）都能见到的新颖事物之一。听起来你应该抓紧时间，尽快开始以 GraphQL 而非 REST 来重写应用程序，对吧？事实并非如此。记住：没有银弹。在进行决策之前理解该技术的优劣是完全有必要的。

本系列中，我们将给你一个 GraphQL 应用程序开发的简洁指南，不止谈到其优点，也会讨论其注意事项乃至陷阱（当然，还有如何处理它们的方法）。

## GraphQL in a nutshell

根据[规范](https://graphql.github.io/graphql-spec/)，GraphQL是一种*查询语言*和 *runtime（或执行引擎）*。查询语言，[按照定义](https://en.wikipedia.org/wiki/Query_language)，描述了如何与一个信息系统进行通信。Runtime 则负责实现数据的查询。

每个 GraphQL 应用程序的核心都在于一个 [*schema*](https://graphql.org/learn/schema/)：它以有向图的形式描述底层数据。Runtime 必须根据该 schema（及规范中的一些通用规则）来执行查询。这意味着，每个有效的 GraphQL 服务端都以相同的方式运行查询，并以相同的格式返回相同 schema 的数据。换句话说，schema 就是客户端应了解到的关于 API 的一切。

下面是一个简单的 GraphQL 查询的例子：

```graphql
query getProduct($id: Int!) {
  product(id: $id) {
    id
    title
    manufacturer {
      name
    }
  }
}
```

让我们来一行一行解析它：

- 我们定义了一个具名查询（`getProduct`是操作名），接收单独一个参数（`$id`）。操作名是可选的，但它会对可读性有所帮助，也能用于前端进行缓存。
- 我们从 schema 的“根”上“选择”了`product`字段，并传递`$id`值作为参数。
- 我们描述了期望获取的那些字段：该场景中，是想要得到 product 的`id`和`title`，以及 manufacturer 的`name`。

**本质上，一个查询代表了 schema 的一个子图，这带来了 GraphQL 的第一个好处——我们可以在单个查询中，仅获取自己所需要的数据，也可以获取一次所需的所有数据。**

这样，我们就解决了传统 REST API 的一个常见问题——*overfetching（过量获取）*。

另一个关于 GraphQL schema 的明显特性是它们为强类型的（*strongly* *typed*）：客户端和 runtime 两边都确保了从应用程序的类型系统角度看，所传递的数据是合法的。例如，如果有人错误传递了一个字符串的值作为`$id`给上面的查询，客户端就会因抛出异常而失败，甚至不会尝试执行查询。

最后但并非最终的一个好处是 schema 的*自省*：客户端可以从 schema 自身来学习 API，而无需任何额外的文档资源。

那么，我们已经了解了 GraphQL 的不少理论部分。现在该来做一些代码练习了，以确保你不会明早起来就忘掉一切。

## What are we going to build?

通过这个系列，我们将构建一个代表“Martian Library”的应用程序——一个影视、书籍及其他与《红色星球》有关的事物的个人在线收藏。

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/application-32576ed.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/application-32576ed.png)

对于本教程，我们将使用：

- 后端使用Ruby 2.6 和 Rails 6（[RC 版本在此](https://evilmartians.com/chronicles/rails-6-b-sides-and-rarities)）【译者注：Rails 6 正式版目前已经发布了】
- 前端使用 Node.js 9+，React 16.3+，和 Apollo（客户端版本 2+），要确保你已经根据[指导](https://yarnpkg.com/en/docs/install#mac-stable)安装了 yarn。

你可以在[这里](https://github.com/evilmartians/chronicles-gql-martian-library/tree/part-1)找到源码——别忘了在首次运行前执行`bundle install && yarn install`。[Master 分支](https://github.com/evilmartians/chronicles-gql-martian-library)是该项目的当前最新状态。

## Setting up a new Rails project

如果阅读本文的时候 Rails 6.0 还没有发布，那么你可能需要先安装 rc 版本：

```bash
$ gem install rails --pre
$ rails -v
=> Rails 6.0.0.rc1
```

现在我们就可以来运行下面这个超级长的`rails new`命令了：

```bash
$ rails new martian-library -d postgresql --skip-action-mailbox --skip-action-text --skip-spring --webpack=react -T --skip-turbolinks
```

比起 Rails 官方的[“主厨精选”](https://dhh.dk/2012/rails-is-omakase.html)，我们更喜欢自己来定制：略去所不需要的框架和库，选择 PostgreSQL 作为数据库，以预配置的 Webpacker 来使用 React，去掉了测试（别担心——我们会很快加上 RSpec 的）。

在你开始之前，强烈建议关闭`config/application.rb`内所有不必要的生成器：

```ruby
config.generators do |g|
  g.test_framework  false
  g.stylesheets     false
  g.javascripts     false
  g.helper          false
  g.channel         assets: false
end
```

## Preparing the data model

我们需要至少两个 model：

- 用`Item`来描述任何我们想要存储在图书馆中的实体（书籍、电影等）。
- 用`User`来代表应用程序里能够管理收藏品中这些 items 的用户。

让我们来生成它们：

```bash
$ rails g model User first_name last_name email
$ rails g model Item title description:text image_url user:references
```

别忘了添加`has_many :items`的关联关系到`app/models/user.rb`：

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :items, dependent: :destroy
end
```

来添加一些预生成的数据到`db/seeds.rb`：

```ruby
# db/seeds.rb
john = User.create!(
  email: "john.doe@example.com",
  first_name: "John",
  last_name: "Doe"
)

jane = User.create!(
  email: "jane.doe@example.com",
  first_name: "Jane",
  last_name: "Doe"
)

Item.create!(
  [
    {
      title: "Martian Chronicles",
      description: "Cult book by Ray Bradbury",
      user: john,
      image_url: "https://upload.wikimedia.org/wikipedia/en/4/45/The-Martian-Chronicles.jpg"
    },
    {
      title: "The Martian",
      description: "Novel by Andy Weir about an astronaut stranded on Mars trying to survive",
      user: john,
      image_url: "https://upload.wikimedia.org/wikipedia/en/c/c3/The_Martian_2014.jpg"
    },
    {
      title: "Doom",
      description: "A group of Marines is sent to the red planet via an ancient " \
                   "Martian portal called the Ark to deal with an outbreak of a mutagenic virus",
      user: jane,
      image_url: "https://upload.wikimedia.org/wikipedia/en/5/57/Doom_cover_art.jpg"
    },
    {
      title: "Mars Attacks!",
      description: "Earth is invaded by Martians with unbeatable weapons and a cruel sense of humor",
      user: jane,
      image_url: "https://upload.wikimedia.org/wikipedia/en/b/bd/Mars_attacks_ver1.jpg"
    }
  ]
)
```

最后，我们就可以来初始化数据库了：

```bash
$ rails db:create db:migrate db:seed
```

现在我们已经往自己的系统里塞入了一些内容，那就来添加访问它们的方式吧！

## Adding a GraphQL endpoint

为了“制作”我们的 GraphQL API，将使用[graphql-ruby](https://github.com/rmosolgo/graphql-ruby) gem：

```bash
# First, add it to the Gemfile
$ bundle add graphql --version="~> 1.9"
# Then, run the generator
$ rails generate graphql:install
```

你可能会惊讶于一个最小化的`graphql-ruby`应用程序所需文件的数量：如下的样板就是我们为上述所有物品所支付的代价。

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/generator-d6a5280.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/generator-d6a5280.png)

首先，我们来看看 schema，`martian_library_schema.rb`：

```ruby
# app/graphql/martian_library_schema.rb
class MartianLibrarySchema < GraphQL::Schema
  query(Types::QueryType)
  mutation(Types::MutationType)
end
```

该 schema 宣布了所有 query 都应该在`Types::QueryType`，而所有 mutation 都应该在`Types::MutationType`。我们将在本系列教程的第二部分来深入探讨 mutation。本文的目标则是学习如何编写和执行 query。因此，让我们打开`types/query_type.rb` 类——它是所有 query 的入口。里面有什么呢？

```ruby
# app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end
  end
end
```

这证明了`QueryType`就是一个通用 type：其继承于`Types::BaseObject`（我们会把它用作所有 type 的基本类），并且它有 *field 定义*——我们数据图的节点。唯一使得`QueryType`有所不同的是 GraphQL 需要这个 type 必须存在（而`mutation`和`subscription` 两种 type 是可选而非必须）。

注意到上面的代码实际上仅是一个"hello world"了吗？在继续往下走之前（且大量的代码使你厌倦），我们会向你展示如何在浏览器中获取该“hello world”的内容。

让我们来看下生成器已经往`config/routes.rb`中添加了什么：

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql" if Rails.env.development?
  post "/graphql", to: "graphql#execute"
end
```

Mount 的`GraphiQL::Rails::Engine`让我们能使用一个称为 [GraphiQL](https://github.com/graphql/graphiql) 的 web 界面来测试自己的 query 和 mutation。如前所述，schema 是可被检查的，而 GraphiQL 则使用这个特性为我们来构建交互文档。来试一试吧！

```bash
# Let's run a Rails web server
$ rails s
```

在浏览器中打开 http://localhost:3000/graphiql：

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/graphiql-4633e9d.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/graphiql-4633e9d.png)

在左侧窗口，你可以输入一个 query 来执行，然后点击“play”按钮（或按下*Ctrl/Cmd+Enter*），即可在右侧窗口看到响应结果。点击右上角的“Docs”链接，你就可以浏览 schema。

来看下日志——我们想要知道当按下执行按钮时发生了什么。

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/execute_log-e654371.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/execute_log-e654371.png)

请求被发送到`GraphlController`，其也是由`graphql` gem 的生成器添加到应用程序的。

看一眼`GraphlController#execute`方法：

```ruby
# app/controllers/graphql_controller.rb
def execute
  variables = ensure_hash(params[:variables])
  query = params[:query]
  operation_name = params[:operationName]
  context = {
    # Query context goes here, for example:
    # current_user: current_user,
  }
  result = GraphqlSchema.execute(
    query,
    variables: variables,
    context: context,
    operation_name: operation_name
  )
  render json: result
rescue StandardError => e
  raise e unless Rails.env.development?

  handle_error_in_development e
end
```

该方法调用了`GraphqlSchema#execute`方法，以如下参数：

- `query`和`variables`分别代表一个 query 字符串和客户端发送的参数；
- `context`是一个任意 hash，在 query 执行的任何地方都是可用的；
- `operation_name`从进来的请求中取出一个命名操作来执行（可以为空）。

所有的魔法都发生在这个方法内：它解析 query，检测所有将被用来构建响应的 type，并决定所有被请求到的字段。我们唯一需要做的事就是定义这些 type，并声明字段应该被怎样决定。

## What’s in the Martian Library?

让我们从“hello world”转到更真实的东西：从`Types::QueryType`移除范例内容并注册一个称为`:items`的字段，其将返回所有图书馆的 items。我们也需要为该字段添加一个 resolver 方法（resolver 方法名必须匹配字段名）：

```ruby
# app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
    field :items,
          [Types::ItemType],
          null: false,
          description: "Returns a list of items in the martian library"

    def items
      Item.all
    end
  end
end
```

每个字段定义都包含一个名称，一个其结果类型，及一些选项。`:null`是需要的，必须设为`true`或者`false`。我们也定义了可选的`:description`——为字段添加易于阅读的信息是一种好的实践：它会被自动添加到文档中，为开发者提供更多相关信息。对于结果类型的数组表示，`[Types::ItemType]`，意味着字段的值必须是一个数组，且其每个元素都必须是`Types::ItemType`类型。

但我们还没有定义`ItemType`，对吧？幸运的是，`graphql` gem 给了一个方便的生成器：

```bash
$ rails g graphql:object item
```

现在我们就可以修改新创建的`app/graphql/types/item_type.rb`为想要的样子了。

```ruby
# app/graphql/types/item_type.rb
module Types
  class ItemType < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :description, String, null: true
    field :image_url, String, null: true
  end
end
```

如上所见，我们在`ItemType`中暴露了三个字段：

- 非 null 的字段，`id`和`title`
- 可为 null 的字段`description`

我们的执行引擎解析决定字段时是使用如下算法（略有简化）：

- 首先，它在 type 类自身内查找同名定义的方法（如同前面我们在`QueryType`中对`items`做的一样）；我们可以使用`object`方法来访问被解析决定的对象。
- 如果没有找到这样定义的方法，它就尝试在`object`上去调用同名方法。

我们在 type 类中没有定义任何方法，因此假定底层实现了所有字段的方法。

回到http://localhost:3000/graphiql，执行如下 query，确认在响应中获取到了所有 items 的列表：

```graphql
{
  items {
    id
    title
    description
  }
}
```

到目前为止，我们还没有添加任何体现 graph 威力的功能——当前的 graph 深度只有一层。让我们来添加一个非初始节点到`ItemType`上，让 graph 复杂一点。比如，添加一个`user`字段来代表 item 的创建者：

```ruby
# app/graphql/types/item_type.rb
module Types
  class ItemType < Types::BaseObject
    # ...
    field :user, Types::UserType, null: false
  end
end
```

重复使用相同的生成器来创建一个新的 type 类：

```bash
$ rails g graphql:object user
```

这一次我们还想要添加一个计算字段——`full_name`：

```ruby
# app/graphql/types/user_type.rb
module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :full_name, String, null: false

    def full_name
      # `object` references the user instance
      [object.first_name, object.last_name].compact.join(" ")
    end
  end
end
```

使用如下 query 来跟 items 一起获取 users：

```graphql
{
  items {
    id
    title
    user {
      id
      email
    }
  }
}
```

到这一步时，我们就可以把目光从后端移到前端了。让我们来为这个 API 构建一个客户端吧！

## Configuring the frontend application

正如已经提到的，我们推荐你安装[Apollo](https://www.apollographql.com/docs/react/) 框架来处理客户端的 GraphQL。

要让一切顺利运转，我们需要安装所有需要的依赖库：

```bash
$ yarn add apollo-client apollo-cache-inmemory apollo-link-http apollo-link-error apollo-link graphql graphql-tag react-apollo
```

来看下所安装的一些库：

- 我们使用`graphql-tag`构建第一个 query。
- `apollo-client`是一个通用的、与框架无关的库，来执行并缓存 GraphQL 请求。
- `apollo-cache-inmemory`是一个 Apollo 缓存的存储实现。
- `react-apollo`包含一套 React 组件来展示数据。
- `apollo-link`与其他 *links* 给`apollo-client`的操作（你可以在[这里](https://www.apollographql.com/docs/link/overview.html)找到更多细节）实现了一个中间件模式。

现在我们需要为前端应用程序创建一个入口。从`packs`目录移除`hello_react.jsx`并添加`index.js`：

```ruby
$ rm app/javascript/packs/hello_react.jsx && touch app/javascript/packs/index.js
```

为了调试目的，加入如下内容：

```js
// app/javascript/packs/index.js
console.log('👻');
```

生成一个用于前端的 controller：

```bash
$ rails g controller Library index --skip-routes
```

更新`app/views/library/index.html.erb`以包含 React 根元素及一个到 *pack* 的`javascript_pack_tag`：

```erb
<!-- app/views/library/index.html.erb -->
<div id="root" />
<%= javascript_pack_tag 'index' %>
```

最后，在`config/routes.rb`注册一个新的路由：

```ruby
# config/routes.rb
root 'library#index'
```

重启 Rails server，确认看到那个 👻 出现在浏览器的 console 中。

## Configuring Apollo

创建一个文件来存储 Apollo 的配置：

```bash
$ mkdir -p app/javascript/utils && touch app/javascript/utils/apollo.js
```

该文件中，我们想要配置 Apollo 应用的两个核心东西，客户端和缓存（或更准确地说，是创建二者的函数）：

```js
// app/javascript/utils/apollo.js

// client
import { ApolloClient } from 'apollo-client';
// cache
import { InMemoryCache } from 'apollo-cache-inmemory';
// links
import { HttpLink } from 'apollo-link-http';
import { onError } from 'apollo-link-error';
import { ApolloLink, Observable } from 'apollo-link';
export const createCache = () => {
  const cache = new InMemoryCache();
  if (process.env.NODE_ENV === 'development') {
    window.secretVariableToStoreCache = cache;
  }
  return cache;
};
```

让我们花一点时间来看看缓存是如何工作的。

每个 query 响应结果都被放到缓存中（相应的请求通常被用做缓存的 key）。在进行请求之前，`apollo-client`确保响应结果还未被缓存，而如果其已被缓存——请求就不会被执行。该行为是可配置化的：比如，我们可以为某一个特别请求关闭缓存，或者让客户端查找一个不同的 query 的缓存数据。

关于缓存机制，对本教程而言，一个我们需要了解的重要事情是，默认情况下，缓存的 key 是`id`和`__typename`的组合串。因此，获取同样对象两次也只会导致一个请求。

回到代码上来。由于我们使用 HTTP POST 作为传输，所以需要附带一个适当的 CSRF token 到每个请求上以通过 Rails 中的 [forgery protection check](https://guides.rubyonrails.org/security.html#cross-site-request-forgery-csrf)。我们可以从`meta[name="csrf-token"]`拿到它（其是通过`<%= csrf_meta_tags %>`生成的）：

```js
// app/javascript/utils/apollo.js
// ...
// getToken from meta tags
const getToken = () =>
  document.querySelector('meta[name="csrf-token"]').getAttribute('content');
const token = getToken();
const setTokenForOperation = async operation =>
  operation.setContext({
    headers: {
      'X-CSRF-Token': token,
    },
  });
// link with token
const createLinkWithToken = () =>
  new ApolloLink(
    (operation, forward) =>
      new Observable(observer => {
        let handle;
        Promise.resolve(operation)
          .then(setTokenForOperation)
          .then(() => {
            handle = forward(operation).subscribe({
              next: observer.next.bind(observer),
              error: observer.error.bind(observer),
              complete: observer.complete.bind(observer),
            });
          })
          .catch(observer.error.bind(observer));
        return () => {
          if (handle) handle.unsubscribe();
        };
      })
  );
```

来看下我们如何记录错误日志：

```js
// app/javascript/utils/apollo.js
//...
// log erors
const logError = (error) => console.error(error);
// create error link
const createErrorLink = () => onError(({ graphQLErrors, networkError, operation }) => {
  if (graphQLErrors) {
    logError('GraphQL - Error', {
      errors: graphQLErrors,
      operationName: operation.operationName,
      variables: operation.variables,
    });
  }
  if (networkError) {
    logError('GraphQL - NetworkError', networkError);
  }
})
```

生产环境上，更好的做法是使用异常追踪服务（exception tracking service）（比如，Sentry 或者 Honeybadger）：只用覆盖`logError`函数把错误发送到外部系统即可。

曙光在前了——让我们把入口告知客户端以进行查询：

```js
// app/javascript/utils/apollo.js
//...
// http link
const createHttpLink = () => new HttpLink({
  uri: '/graphql',
  credentials: 'include',
})
```

最后，我们就可以创建 Apollo 客户端的实例了：

```js
// app/javascript/utils/apollo.js
//...
export const createClient = (cache, requestLink) => {
  return new ApolloClient({
    link: ApolloLink.from([
      createErrorLink(),
      createLinkWithToken(),
      createHttpLink(),
    ]),
    cache,
  });
};
```

## The very first query

我们将使用[provider pattern](https://reactjs.org/docs/context.html#contextprovider)来把客户端实例传给 React 组件：

```bash
$ mkdir -p app/javascript/components/Provider && touch app/javascript/components/Provider/index.js
```

这是我们第一次使用`react-apollo`的`ApolloProvider`组件：

```js
// app/javascript/components/Provider/index.js
import React from 'react';
import { ApolloProvider } from 'react-apollo';
import { createCache, createClient } from '../../utils/apollo';

export default ({ children }) => (
  <ApolloProvider client={createClient(createCache())}>
    {children}
  </ApolloProvider>
);
```

修改`index.js`以使用新创建的 provider：

```js
// app/javascript/packs/index.js
import React from 'react';
import { render } from 'react-dom';
import Provider from '../components/Provider';

render(<Provider>👻</Provider>, document.querySelector('#root'));
```

如果你使用了`Webpacker v3`，则需要导入`babel-polyfill`以用上诸如 `async/await`等很酷的 JavaScript 特性。不用担心 polyfill 的大小。`babel-preset-env`会帮你移除掉所不需要的一起。

我们来创建一个`Library`组件，在页面上展示 items 的列表：

```bash
$ mkdir -p app/javascript/components/Library && touch app/javascript/components/Library/index.js
```

我们会使用`react-apollo`的`Query`组件，接收`query`字符串作为 property 以获取所 mount 的数据：

```js
// app/javascript/components/Library/index.js
import React from 'react';
import { Query } from 'react-apollo';
import gql from 'graphql-tag';

const LibraryQuery = gql`
  {
    items {
      id
      title
      user {
        email
      }
    }
  }
`;

export default () => (
  <Query query={LibraryQuery}>
    {({ data, loading }) => (
      <div>
        {loading
          ? 'loading...'
          : data.items.map(({ title, id, user }) => (
              <div key={id}>
                <b>{title}</b> {user ? `added by ${user.email}` : null}
              </div>
            ))}
      </div>
    )}
  </Query>
);
```

我们可以通过相应的`loading`和`data` property 分别访问载入状态和已加载数据（使用所谓的[render-props 模式](https://reactjs.org/docs/render-props.html)传递）。

别忘了把组件添加到主页面上：

```js
// app/javascript/packs/index.js
import React from 'react';
import { render } from 'react-dom';
import Provider from '../components/Provider';
import Library from '../components/Library';

render(
  <Provider>
    <Library />
  </Provider>,
  document.querySelector('#root')
);
```

如果你刷新页面，将会看到 items 列表，以及添加它们的用户的 email：

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/items-b791b9f.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/items-b791b9f.png)

祝贺你！你刚刚迈出了通向 GraphQL 的第一步。很棒！

## …And the very first problem

一切看起来都工作得很好，但来看一眼我们的服务端日志：

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/n_plus_one-77d1121.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-1-from-zero-to-the-first-query/n_plus_one-77d1121.png)

SQL 查询`SELECT * FROM users WHERE id = ?`被执行了四次，意味着我们撞上了著名的 *N+1* 问题——服务端对集合中的每个 item 都进行了一次查询，以获取相应的用户信息。

在修复这个问题之前，我们需要确保进行代码调整是安全的，不会搞坏任何东西——所以，来写测试吧，少年！

## Writing some specs

现在该来安装配置 RSpec 了，更准确地说，是`rspec-rails` gem：

```bash
# Add gem to the Gemfile
$ bundle add rspec-rails --version="4.0.0.beta2" --group="development,test"
# Generate the initial configuration
$ rails generate rspec:install
```

为了易于生成测试数据，也安装上 [factory_bot](https://github.com/thoughtbot/factory_bot)：

```bash
$ bundle add factory_bot_rails --version="~> 5.0" --group="development,test"
```

为了让 factory 方法（`create`，`build`等）在测试中全局可见，添加`config.include FactoryBot::Syntax::Methods`到`rails_helper.rb`中。

由于我们在添加 Factory Bot 之前就创建了 model，所以我们得手动生成 factory。单独创建一个文件，`spec/factories.rb`，如下：

```ruby
# spec/factories.rb
FactoryBot.define do
  factory :user do
    # Use sequence to make sure that the value is unique
    sequence(:email) { |n| "user-#{n}@example.com" }
  end

  factory :item do
    sequence(:title) { |n| "item-#{n}" }
    user
  end
end
```

现在已经准备好写我们的第一个测试了。来为`QueryType`创建一个 spec 文件：

```bash
$ mkdir -p spec/graphql/types
$ touch spec/graphql/types/query_type_spec.rb
```

最简单的 query 测试，就像下面这样：

```ruby
# spec/graphql/types/query_type_spec.rb
require "rails_helper"

RSpec.describe Types::QueryType do
  describe "items" do
    let!(:items) { create_pair(:item) }

    let(:query) do
      %(query {
        items {
          title
        }
      })
    end

    subject(:result) do
      MartianLibrarySchema.execute(query).as_json
    end

    it "returns all items" do
      expect(result.dig("data", "items")).to match_array(
        items.map { |item| { "title" => item.title } }
      )
    end
  end
end
```

首先，我们创建在数据库中创建一对 items。然后，定义了要被测试的 query 和subject（`result`），后者通过调用`MartianLibrarySchema.execute`方法所得到。还记得我们在`GraphqlController#execute`那里有一行类似的代码吗？

这个用例非常简单：我们对`execute`的调用既没有传递`variables`也没有传递`context`，当然，有需要的时候我们显然可以这么做。

现在，我们就有足够自信来修复上面的 N+1 问题了！

## GraphQL vs. N+1 problem

最简单的避免 N+1 问题的方式是使用 [eager loading](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations)。我们这里，需要在进行查询以获取`QueryType`中的 items 时预加载用户：

```ruby
# /app/graphql/types/query_type.rb
module Types
  class QueryType < Types::BaseObject
    # ...

    def items
      Item.preload(:user)
    end
  end
end
```

这个方案在简单的场景下是有用的，但并非十分高效：比如，如下代码也会预加载用户，即使客户端不需要它们时：

```graphql
items {
  title
}
```

要讨论解决 N+1 问题的其他方式，值得单独写一篇文章，已经超出了本文的范畴。

大多数解决方案都不外乎以下两种：

- lazy eager loading（比如，使用 [ar_lazy_preload](https://github.com/DmitryTsepelev/ar_lazy_preload) gem）
- batch loading（比如，使用 [graphql-batch](https://github.com/Shopify/graphql-batch) gem）

本文就到这儿了！我们学习了关于 GraphQL 的很多东西，完成了配置后端和前端应用程序的常规工作，进行了第一个查询，甚至还发现并修复了第一个 bug。而这只是我们旅程中微小的一步（尽管文章的篇幅并不微小）。我们会很快回来的，届时将推出如何使用 GraphQL 的 mutation 来操作数据，以及 subscription 来使数据保持最新的内容。敬请关注！

