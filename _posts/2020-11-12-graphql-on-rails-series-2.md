---
layout: post
title: GraphQL on Rails——更新
author: Mr.Z
categories: [ Translation, Programming ]
tags: [ruby, rails, graphql]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20201121_131305.jpg"
rating: 4
---

*本文已获得原作者（Dmitry Tsepelev）、（Polina Gurtovaya）和 Evil Martians 授权许可进行翻译。原文是 Rails + React 使用 GraphQL的系列教程第二篇，介绍了以 Rails 作为后端，React + Apollo 作为前端，如何进行数据更新的教学。*

- 原文链接：[GraphQL on Rails: Updating the data](https://evilmartians.com/chronicles/graphql-on-rails-2-updating-the-data)
- 作者：[Dmitry Tsepelev](https://twitter.com/dmitrytsepelev)，[Polina Gurtovaya](https://github.com/HellSquirrel)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

**这是一个在后端使用 Rails、前端使用 React/Apollo 来开发 GraphQL 应用程序的旅行者指导。本教程的第二部分将涵盖 mutation（更新数据的方式）和有关客户端缓存的高级主题**

在该指南的[第一部分](https://evilmartians.com/chronicles/graphql-on-rails-1-from-zero-to-the-first-query)中，我们学到了 GraphQL 是什么，并创建了一个 Martian Library 应用程序的很初级的版本。如果你还没阅读的话，现在正好去看一下。

我们已经配置了`graphql-ruby` gem 和 Apollo 框架以确保它们能一起很好地工作，也通过添加一个很初级的查询节点到 schema 上来实战检验了其配置。现在该继续前行了！

## Introducing mutations

我们已经知道，在 GraphQL 中有三种基础 operation—— query，mutation，及 subscriptions。本文中，我们将介绍 mutation——一种从 GraphQL 进行数据更改的机制。

从客户端的角度看，mutation 看起来跟 query 很像，只有一点细微的差别——它们从“mutation”节点开始：

```graphql
mutation SignInUser($email: String) {
  signIn(email: $email) {
    id
  }
}
```

然而，其主要的区别，是语义上的：首先，mutation 负责修改（或*转变*）数据。在执行引擎处理它们的方式上，也有一个差别：根据规范，GraphQL 服务端[必须确保](https://graphql.github.io/graphql-spec/June2018/#sec-Mutation) mutation 是被连续执行的，而 query 则能被并行执行。

在上面的 mutation 示例中，我们通过用户的 email 向服务端请求身份验证，以如下方式：

- 我们以一个 operation 名`SignInUser`和一个变量`$email`（所有 GraphQL 中的变量都以`$`开头）来定义一个 mutation 开始。
- 我们有一个想要执行修改的列表在大括号内（该列表称作 *selection set*）——这里我们只有一个叫`signIn`的字段。
- 跟 query 一样，在根字段内我们可以有嵌套的 selection sets（即，从 mutation 返回值选择特定字段）。

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/mutation-77c15e7.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/mutation-77c15e7.png)

这些就是理论方面我们所需要了解的东西了。接下来的内容将专注于实践：我们将添加 mutation 来对用户进行身份验证，以及让用户添加新 items 到 Martian library。

## Housekeeping

先来快速看下在前一部分教程完成后我们的成果。你可在[这里](https://github.com/evilmartians/chronicles-gql-martian-library/tree/part-1)找到源码——别忘了在首次运行前执行`bundle install && yarn install`。[Master](https://github.com/evilmartians/chronicles-gql-martian-library) 分支则代表了该项目的当前状态。

我们使用`graphql-tag`库来执行查询，并使它们在同一个文件中靠近组件：

```js
// app/javascript/components/Library/index.js

import React from "react";
import { Query } from "react-apollo";
import gql from "graphql-tag";

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
          ? "loading..."
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

或者，你可以把这些 operation 放在不同的文件中，以`.graphql`（或`.gql`）扩展名，保存在同一个目录下，作为组件定义。这种方案在开发中型——到大型——的应用程序时尤其有用，提供了清晰的项目结构。我们在本教程中对于所有的新 operation 都将使用它。

要让 Webpack “理解”`.gql`文件，我们需要在`/config/webpack/environment.js`中配置一个特别的 loader：

```js
// config/webpack/environment.js
const { environment } = require("@rails/webpacker");

environment.loaders.append("graphql", {
  test: /\.(graphql|gql)$/,
  exclude: /node_modules/,
  loader: "graphql-tag/loader"
});

module.exports = environment;
```

别忘了重启来让配置生效。

现在已经准备好实现身份验证逻辑了。

## Implementing authentication

GraphQL 规范没有告诉你如何实现身份验证逻辑，甚至不需要你有这个——这取决于开发者。然而，你很难想象一个真实的应用程序没有它，我们的 Martian Library 也不例外——我们需要一种方式来追踪所有被添加到图书馆的 items 的*拥有者*。

我们让事情简单些，以用户的 email 进行验证，毋需密码，短信，及其他确认方式。

下面是我们的身份验证机制的概览：

- 用户提供 email 来发起身份验证请求
- 服务端验证该用户存在并以一个*身份验证 tokan* 返回响应
- 用户每次后续请求都带上该 token（比如，通过 HTTP Header）以证明其身份

我们将使用一个 GraphQL mutation，`signIn`，来执行身份验证，并以一个 base64 加密的 email 作为身份验证 token，以及一个“Authorization” header 来传递该 token。注意，使用 GraphQL API 来验证用户并非是必须的：其可以在“外部”完成，比如，通过 REST。这在当你仅允许已验证用户访问 GraphQL API 时特别有用。

我们也期望在 UI 中指示用户是否已经通过身份验证。为此，我们将添加一个 panel ，如果用户已登录则显示其名称，否则显示“Sign In”按钮：

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/user_info-af682ad.gif](https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/user_info-af682ad.gif)

### Crafting authentication schema

让我们先来添加一个 API 以获取当前用户的信息。

我们想让事情简单些：添加一个`me`字段到 query 的根上来返回其 context 的当前用户：

```ruby
# app/graphql/types/query_type.rb

module Types
  class QueryType < Types::BaseObject
    # ...
    field :me, Types::UserType, null: true

    def me
      context[:current_user]
    end
  end
end
```

如何得到`:current_user`？我们来添加一个`ApplicationController#current_user`方法，实现上述的身份验证逻辑：

```ruby
# app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  private

  def current_user
    token = request.headers["Authorization"].to_s
    email = Base64.decode64(token)
    User.find_by(email: email)
  end
end
```

最后，我们更新`GraphqlController#execute`方法以传递`current_user`到 context 内：

```ruby
# app/controllers/graphql_controller.rb

class GraphqlController < ApplicationController
  def execute
    result = MartianLibrarySchema.execute(
      params[:query],
      variables: ensure_hash(params[:variables]),
      # Only this line has chagned
      context: { current_user: current_user },
      operation_name: params[:operationName]
    )
    render json: result
  end

  # ...
end
```

漂亮！现在我们的客户端就能拿到当前用户的信息了。但不幸的是，它总是返回`nil`——我们还没有加上告知当前谁正在使用应用的方法。来修复它！

打开`Mutations::BaseMutation`类并粘贴如下代码（默认生成器继承自更复杂的`GraphQL::Schema::RelayClassicMutation`类）：

```ruby
# app/graphql/mutations/base_mutation.rb

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
  end
end
```

我们将使用这个类作为`SignInMutation`的父类：

```ruby
# app/graphql/mutations/sign_in_mutation.rb

module Mutations
  class SignInMutation < Mutations::BaseMutation
    argument :email, String, required: true

    field :token, String, null: true
    field :user, Types::UserType, null: true

    def resolve(email:)
      user = User.find_by!(email: email)
      return {} unless user

      token = Base64.encode64(user.email)
      {
        token: token,
        user: user
      }
    end
  end
end
```

如你所见，我们指定了 mutation 可以返回一个 token 和一个当前的用户，而唯一接收的参数是`email`。在`#resolve`方法内，我们查找用户，如果找到了，就以 base64 加密的 email 作为 token 返回，否则返回`null`。

第一眼看去，mutation 类就像一个常规的 Rails controller，但它有一个重要的优点：它是强类型的，通过其 schema 来验证输入的数据。

最后，我们需要在`MutationType`中暴露这第一个 mutation：

```ruby
# app/graphql/types/mutation_type.rb

module Types
  class MutationType < Types::BaseObject
    field :sign_in, mutation: Mutations::SignInMutation
  end
end
```

总结一下，为了添加一个新 mutation，你需要完成如下步骤：

- 添加一个类实现 mutation 逻辑，其包含：
- 输入值的类型定义（arguments）；
- 返回值的类型定义；
- `#resolve`方法
- 添加一个新的入口到`MutationType`中

注意，我们根本没有提到 spec 测试：可以使用在之前编写的 query spec 所用过的相同技术来添加这里的 spec。或者去看看我们在示例代码库中写好的测试！

### Adding user info panel

让我们暂时先忘掉 Ruby 一会，把注意力放到前端应用来。

由于我们的代码库在不断增长，所以需要考虑一个更好的代码组织方式。我们对于 UI 组件推荐如下结构：

- 每个组件存放到一个单独的目录中（比如，`app/javascript/components/MyComponent`）
- `index.js`包含实现部分
- query 定义在`operations.graphql`中
- 样式放到`styles.module.css`中（如文件名所建议的那样，我们使用[css modules](https://github.com/css-modules/css-modules)而毋需担心样式冲突）

为了避免为每个组件都手动创建这些文件的繁琐，我们写了一个[gql-component generator（graphql 组件生成器）](https://github.com/HellSquirrel/create-gql-component)。用它来创建一个称为`UserInfo`的组件吧：

```bash
$ npx @hellsquirrel/create-gql-component create app/javascript/components/UserInfo
```

注意：样式代码在本文中被去掉了，以保持简洁，但你可以在 GitHub 的 [repo](https://github.com/evilmartians/chronicles-gql-martian-library) 中找到所有的样式文件。如果你使用我们的生成器，样式会被自动添加。

这将是你的文件结构看起来的样子：

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/component_structure-9a81b3c.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/component_structure-9a81b3c.png)

`UserInfo`组件负责“Sign In”的功能，以及当通过身份验证时展示当前用户名。让我们来首先添加这些功能所需要的 API 查询到`operations.graphql`中：

```graphql
query Me {
  me {
    id
    fullName
  }
}

mutation SignMeIn($email: String!) {
  signIn(email: $email) {
    token
    user {
      id
      fullName
    }
  }
}
```

我们定义了`SignMeIn` operation，带所需的`$email`参数，为`String`类型，“执行”`signIn` mutation 并在成功时返回一个验证 token 和当前用户信息。你可能注意到了`Me`和`SignMeIn` operation上的某些重复——别担心，稍后我们会展示如何处理它们。

再打开`index.js`并使用上面定义的 operation 来定义我们的组件。我们期望先加载用户信息，且仅当用户没有被身份验证时才展示“Sign In”表单：

```js
<Query query={Me}>
  {({ data, loading }) => {
    if (loading) return "...Loading";
    if (!data.me) {
      // Show login form
      return;
    }

    const { fullName } = data.me;
    return <div className={cs.info}>😈 {fullName}</div>;
  }}
</Query>
```

要显示表单，我们应当使用`Mutation`组件并传递`SignMeIn` operation 为一个`mutation` property：

```js
<Mutation mutation={SignMeIn}>
  {(signIn, { loading: authenticating }) =>
    authenticating ? (
      "..."
    ) : (
      <form onSubmit={() => signIn(/* email here */)}>
        <input type="email" />
        <input type="submit" value="Sign In" />
      </form>
    )
  }
</Mutation>
```

别忘了导入 `userRef` hook，`Query`和`Mutation`组件，跟该组件中使用的 query 一起：

```js
import React, { useRef } from 'react';
import { Query, Mutation } from "react-apollo";
import { Me, SignMeIn } from "./operations.graphql";
```

这段代码看起来很像前面创建的`Library`组件。`Mutation`组件的 render prop 接收一个执行 mutation 的函数作为第一个参数（`signIn`），而第二个参数是一个 mutation 结果 object 的 object，包含返回的数据，加载的状态等等。

要传递 email 给 mutation，我们需要从 input（使用`ref`）来获取它，把它放入`variable`内，并执行 mutation：

```js
const UserInfo = () => {
  const input = useRef(null);

  // ...

  return (
    <form
      onSubmit={event => {
        event.preventDefault();
        signIn({
          variables: { email: input.current.value }
        });
      }}
    >
      <input
        ref={input}
        type="email"
        className={cs.input}
        placeholder="your email"
      />
    </form>
  );
};
```

当在 JavaScript 中调用 mutation 时，我们以如下方式把值绑定到 variables：使用跟 operation 中同样的名称，但不要`$`前缀，比如，`signIn({ variables: { email: '...' } })`。

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/mutation_variables-9cf2be2.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-2-updating-the-data/mutation_variables-9cf2be2.png)

让我们确保把 token 存储到某个地方以便在随后的请求和页面重载重用它：

```js
<form
  onSubmit={event => {
    event.preventDefault();
    signIn({
      variables: { email: input.current.value },
    }).then(({ data: { signIn: { token } } }) => {
      if (token) {
        localStorage.setItem('mlToken', token);
      }
    });
  }}
>
```

在我们执行“Sign In”之后，就应该更新用户信息了（通过`Me` query）。

### Dealing with cache

有两种选择可以做到这点：

- 当 mutation 完成时重新请求`me` query（我们可以使用`Mutation`组件上`refetchQueries` property）——这个是有用的，但有更好的方式。
- 等待 mutation 完成并手动更新缓存。`apollo-cache-inmemory`为此提供了`writeQuery`函数。而`react-apollo`库的`Mutation`组件有一个称为`update`的特殊 property。它接收`cache`作为第一个参数，mutation 结果作为第二个参数。我们想要使用`writeQuery`方法手动添加一个新的缓存数据。这就好比在说“Hey，Apollo！这儿有一些数据，假装你是从服务端接收到它们的吧。”

```js
<Mutation
  mutation={SignMeIn}
  update={(cache, { data: { signIn } }) => {
    cache.writeQuery({
      query: Me,
      data: { me: signIn.user },
    });
  }}
>
```

如下就是`UserInfo`组件最终看起来的样子：

```js
import React, { useRef } from "react";
import { Query, Mutation } from "react-apollo";
import { Me, SignMeIn } from "./operations.graphql";
import cs from "./styles";

const UserInfo = () => {
  const input = useRef(null);

  return (
    <div className={cs.panel}>
      <Query query={Me}>
        {({ data, loading }) => {
          if (loading) return "...Loading";
          if (!data.me) {
            return (
              <Mutation
                mutation={SignMeIn}
                update={(cache, { data: { signIn } }) => {
                  cache.writeQuery({
                    query: Me,
                    data: { me: signIn.user }
                  });
                }}
              >
                {(signIn, { loading: authenticating }) =>
                  authenticating ? (
                    "..."
                  ) : (
                    <div className={cs.signIn}>
                      <form
                        onSubmit={event => {
                          event.preventDefault();
                          signIn({
                            variables: { email: input.current.value }
                          }).then(({ data: { signIn: { token } } }) => {
                            if (token) {
                              localStorage.setItem("mlToken", token);
                            }
                          });
                        }}
                      >
                        <input
                          ref={input}
                          type="email"
                          className={cs.input}
                          placeholder="your email"
                        />
                        <input
                          type="submit"
                          className={cs.button}
                          value="Sign In"
                        />
                      </form>
                    </div>
                  )
                }
              </Mutation>
            );
          }

          const { fullName } = data.me;
          return <div className={cs.info}>😈 {fullName}</div>;
        }}
      </Query>
    </div>
  );
};

export default UserInfo;
```

恭喜！我们刚刚通过添加`useRef`到组件而购买了一张称作[“React Hooks”](https://reactjs.org/docs/hooks-intro.html)的火车票。

更好的做法是把`UserInfo`拆分为两个单独的组件。第一个负责“Sign In”逻辑，第二个负责用户信息展示。你来自己搞定它吧！

别忘了把组件添加到`/javascript/packs/index.js`：

```js
// app/javascript/packs/index.js

import React from "react";
import { render } from "react-dom";
import Provider from "../components/Provider";
import Library from "../components/Library";
import UserInfo from "../components/UserInfo";

render(
  <Provider>
    <UserInfo />
    <Library />
  </Provider>,
  document.querySelector("#root")
);
```

### Adding tokens to Apollo client

运行我们的应用程序，试着使用一个合法 email 登录。

一切正常，除了当你重新加载页面时——你会看到登录表单再次出现，即使你之前已成功登录了！解释很简单：我们把 token 存放在浏览器中，但没有“教” Apollo 使用它。让我们来修复这个问题！

看一下`utils/apollo.js`：

```js
// app/javascript/utils/apollo.js
// ...
const getToken = () =>
  document.querySelector('meta[name="csrf-token"]').getAttribute("content");
const token = getToken();
const setTokenForOperation = async operation =>
  operation.setContext({
    headers: {
      "X-CSRF-Token": token
    }
  });
```

我们已经有一个 CSRF token 发送到服务端了。再来添加一个新的——“Authorization” token：

```js
// app/javascript/utils/apollo.js
// ...
const getTokens = () => {
  const tokens = {
    "X-CSRF-Token": document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content")
  };
  const authToken = localStorage.getItem("mlToken");
  return authToken ? { ...tokens, Authorization: authToken } : tokens;
};

const setTokenForOperation = async operation => {
  return operation.setContext({
    headers: {
      ...getTokens()
    }
  });
};
```

再登录试试，重载页面——你会看到信息栏的用户名了！我们的“幸运之路”看起来畅通无阻。身份验证流程 ✅

## Mutating the library

现在我们要添加一些更多的 mutation ——这里没什么新东西，但我们需要它来使范例应用看起来更好，并得到更多的实践机会。

我们来增加一个 mutation 以向图书馆添加新 item。照例，我们需要定义传入参数和返回类型：

```ruby
# app/graphql/mutations/add_item_mutation.rb

module Mutations
  class AddItemMutation < Mutations::BaseMutation
    argument :title, String, required: true
    argument :description, String, required: false
    argument :image_url, String, required: false

    field :item, Types::ItemType, null: true
    field :errors, [String], null: false

    def resolve(title:, description: nil, image_url: nil)
      if context[:current_user].nil?
        raise GraphQL::ExecutionError,
              "You need to authenticate to perform this action"
      end

      item = Item.new(
        title: title,
        description: description,
        image_url: image_url,
        user: context[:current_user]
      )

      if item.save
        { item: item }
      else
        { errors: item.errors.full_messages }
      end
    end
  end
end
```

这段代码里有几个要注意的地方：

- 我们检查`context[:current_user]`的存在，如果其未设定则抛出异常。
- 我们返回的类型包含两个字段：`item`和`errors`。为什么不用`save!`并抛出异常？用户输入的校验错误不应该被看作异常；我们的前端应用应把其视为一种合法响应并反馈给用户。

其他的一切都看起来像是典型的 Rails controller 中的旧式`#create`行为。而如同`#update`的类似行为也非常简单：

```ruby
# app/graphql/mutations/update_item_mutation.rb

module Mutations
  class UpdateItemMutation < Mutations::BaseMutation
    argument :id, ID, required: true
    argument :title, String, required: true
    argument :description, String, required: false
    argument :image_url, String, required: false

    field :item, Types::ItemType, null: true
    field :errors, [String], null: false

    def resolve(id:, title:, description: nil, image_url: nil)
      if context[:current_user].nil?
        raise GraphQL::ExecutionError,
              "You need to authenticate to perform this action"
      end

      item = Item.find(id)

      if item.update(title: title, description: description, image_url: image_url)
        { item: item }
      else
        { errors: item.errors.full_messages }
      end
    end
  end
end
```

你可能已经注意到在这两个类中有很多重复——不用担心，本系列的第三部分将涵盖重构的技术内容来修复这个问题。

最后，把新 mutation 注册到`MutationType`中：

```ruby
# app/graphql/types/mutation_type.rb

module Types
  class MutationType < Types::BaseObject
    # ...
    field :add_item, mutation: Mutations::AddItemMutation
    field :update_item, mutation: Mutations::UpdateItemMutation
  end
end
```

### Updating Library component

在开始之前，来重新生成一下我们的 library 组件以遵循新架构（解构 operation，添加样式）：

```bash
$ npx @hellsquirrel/create-gql-component create app/javascript/components/Library
```

把如下 query 放入`operations.graphql`中：

```graphql
query LibraryQuery {
  items {
    id
    title
    imageUrl
    description
    user {
      id
      email
    }
  }
}
```

并“刷新” library 组件的实现方式：

```js
// app/javascript/components/Library
import React, { useState } from "react";
import { Query } from "react-apollo";
import { LibraryQuery } from "./operations.graphql";
import cs from "./styles";

const Library = () => {
  const [item, setItem] = useState(null);
  return (
    <Query query={LibraryQuery}>
      {({ data, loading }) => (
        <div className={cs.library}>
          {loading || !data.items
            ? "loading..."
            : data.items.map(({ title, id, user, imageUrl, description }) => (
                <button
                  key={id}
                  className={cs.plate}
                  onClick={() => setItem({ title, imageUrl, id, description })}
                >
                  <div className={cs.title}>{title}</div>
                  <div>{description}</div>
                  {imageUrl && <img src={imageUrl} className={cs.image} />}
                  {user ? (
                    <div className={cs.user}>added by {user.email}</div>
                  ) : null}
                </button>
              ))}
        </div>
      )}
    </Query>
  );
};

export default Library;
```

注意，我们把每个 item 都包裹在`button` HTML 元素内：我们期望它们是可点击的，以展示更新过的表单。现在，我们的前端应用看起来漂亮多了。让我们来添加一些新的亮点吧！

### Adding form components

我们来为创建和编辑 item 添加更多的组件。这些组件都很类似，所以我们可以把很多逻辑都放到可重用的`ProcessItemForm`组件内。

```bash
$ npx @hellsquirrel/create-gql-component create app/javascript/components/ProcessItemForm
```

组件代码如下：

```js
// app/javascript/components/ProcessItemForm/index.js

import React, { useState } from "react";
import cs from "./styles";

const ProcessItemForm = ({
  initialTitle = "",
  initialDescription = "",
  initialImageUrl = "",
  onProcessItem,
  buttonText,
  loading
}) => {
  const [title, setTitle] = useState(initialTitle);
  const [description, setDescription] = useState(initialDescription);
  const [imageUrl, setImageUrl] = useState(initialImageUrl);
  return (
    <div className={cs.form}>
      <input
        type="text"
        placeholder="title"
        value={title}
        className={cs.input}
        onChange={e => setTitle(e.currentTarget.value)}
      />
      <input
        type="text"
        placeholder="description"
        value={description}
        className={cs.input}
        onChange={e => setDescription(e.currentTarget.value)}
      />

      <input
        type="text"
        placeholder="url"
        value={imageUrl}
        className={cs.input}
        onChange={e => setImageUrl(e.currentTarget.value)}
      />
      {loading ? (
        "...Loading"
      ) : (
        <button
          onClick={() => onProcessItem({ title, description, imageUrl })}
          className={cs.button}
        >
          {buttonText}
        </button>
      )}
    </div>
  );
};

export default ProcessItemForm;
```

我们唯一所需要添加的是创建 item 的 form——我们把其称为`AddItemForm`。

```bash
$ npx @hellsquirrel/create-gql-component create app/javascript/components/AddItemForm
```

我们要把 AddItemMutation 添加到`operations.graphql`：

```graphql
# /app/javascript/components/AddItemForm/operations.graphql

mutation AddItemMutation(
  $title: String!
  $description: String
  $imageUrl: String
) {
  addItem(title: $title, description: $description, imageUrl: $imageUrl) {
    item {
      id
      title
      description
      imageUrl
      user {
        id
        email
      }
    }
  }
}
```

并在`index.js`中使用它：

```js
import React from "react";
import { Mutation } from "react-apollo";
import { AddItemMutation } from "./operations.graphql";
import ProcessItemForm from "../ProcessItemForm";

const AddItemForm = () => (
  <Mutation mutation={AddItemMutation}>
    {(addItem, { loading }) => (
      <ProcessItemForm
        buttonText="Add Item"
        loading={loading}
        onProcessItem={({ title, description, imageUrl }) =>
          addItem({
            variables: {
              title,
              description,
              imageUrl
            }
          })
        }
      />
    )}
  </Mutation>
);

export default AddItemForm;
```

别忘了添加 form 到`/javascript/packs/index.js`：

```js
import React from "react";
import { render } from "react-dom";
import Provider from "../components/Provider";
import Library from "../components/Library";
import UserInfo from "../components/UserInfo";
import AddItemForm from "../components/AddItemForm";

render(
  <Provider>
    <UserInfo />
    <AddItemForm />
    <Library />
  </Provider>,
  document.querySelector("#root")
);
```

现在我们遭遇了跟在`UserInfo`组件中同样的问题。我们需要告知应用：`LibraryQuery`应该被更新。因此我们必须刷新缓存：通过读取整个列表并把新 item 合并到列表上以设置一个新列表。

来改一下`javascript/components/AddItemForm/index.js`：

```js
// javascript/components/AddItemForm/index.js
// ...
import { LibraryQuery } from '../Library/operations.graphql';
// ...

<ProcessItemForm
  //...
  // Update library query after Mutation will be finished
  onProcessItem={({ title, description, imageUrl }) =>
    addItem({
      variables: {
        title,
        description,
        imageUrl,
      },

      // adding the second argument to 'addItem' method
      update: (cache, { data: { addItem } }) => {
        const item = addItem.item;
        if (item) {
          const currentItems = cache.readQuery({ query: LibraryQuery });
          cache.writeQuery({
            query: LibraryQuery,
            data: {
              items: [item].concat(currentItems.items),
            },
          });
        }
      },
    })
  }
  // ...
```

搞定！现在我们会看到新的 item 被添加到页面列表了。

来为更新 item 再添加一个组件，称为`UpdateItemForm`。代码非常类似于 AddItemForm。运行生成器：

```bash
$ npx @hellsquirrel/create-gql-component create app/javascript/components/UpdateItemForm
```

下面是 operations 文件中的内容：

```graphql
mutation UpdateItemMutation(
  $id: ID!
  $title: String!
  $description: String
  $imageUrl: String
) {
  updateItem(
    id: $id
    title: $title
    description: $description
    imageUrl: $imageUrl
  ) {
    item {
      id
      title
      description
      imageUrl
    }
  }
}
```

这是组件文件中的内容：

```js
// /app/javascript/components/UpdateItemForm

import React from "react";
import { Mutation } from "react-apollo";
import { UpdateItemMutation } from "./operations.graphql";
import ProcessItemForm from "../ProcessItemForm";
import cs from "./styles";

const UpdateItemForm = ({
  id,
  initialTitle,
  initialDescription,
  initialImageUrl,
  onClose
}) => (
  <div className={cs.overlay}>
    <div className={cs.content}>
      <Mutation mutation={UpdateItemMutation}>
        {(updateItem, { loading }) => (
          <ProcessItemForm
            initialImageUrl={initialImageUrl}
            initialTitle={initialTitle}
            initialDescription={initialDescription}
            buttonText="Update Item"
            loading={loading}
            onProcessItem={({ title, description, imageUrl }) => {
              updateItem({
                variables: {
                  id,
                  title,
                  description,
                  imageUrl
                }
              });
              onClose();
            }}
          />
        )}
      </Mutation>
      <button className={cs.close} onClick={onClose}>
        Close
      </button>
    </div>
  </div>
);

export default UpdateItemForm;
```

并把 UpdateItemForm 添加到 library（位于 button 之后）：

```js
// /app/javascript/components/Library/index.js

//...
import UpdateItemForm from "../UpdateItemForm";

// ...
<button />;

{
  item !== null && (
    <UpdateItemForm
      id={item.id}
      initialTitle={item.title}
      initialDescription={item.description}
      initialImageUrl={item.imageUrl}
      onClose={() => setItem(null)}
    />
  )
}
// ...
```

现在如果我们点击 item 并修改，它就会神奇地更新了。为什么呢？

当获取一个 item 列表时，响应结果被规范化，且每个 item 都被添加到缓存。`apollo`为每个有`__typename`和`id`的实体都生成一个 key：`${object__typename}:${objectId}`。当 mutation 完成的时候，我们获取到有相同`__typename`和`id`的对象，`apollo`在缓存中找到它，并进行更改（组件也被重新渲染）。

我们能做得更好一些么？当然！

为什么我们要等待服务端的响应呢？如果我们对服务端有足够的信心，那么我们可以使用乐观式更新。让我们再添加一个参数到 updateItem 函数：

```js
// /app/javascript/components/UpdateItemForm

//...
updateItem({
  variables: {
    //...
  },

  // adding the second argument to 'updateItem' method

  optimisticResponse: {
    __typename: "Mutation",
    updateItem: {
      __typename: "UpdateItemMutationPayload",
      item: {
        id,
        __typename: "Item",
        title,
        description,
        imageUrl
      }
    }
  }
});
//..
```

这些就是本文的全部内容了！我们学习了 mutation 和 query 之间的区别，学习了在后端如何实现它们，以及如何在前端使用它们。现在，我们的应用支持用户登录和图书馆的管理，所以几乎已准备好发布到 production 了！然而，代码看起来还有些笨拙，有重构的空间——这正是我们将在第三部分中要做的，并添加一些其他改进，例如实时更新和更好的错误处理。敬请关注！

