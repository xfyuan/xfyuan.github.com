---
layout: post
title: GraphQL on Rails——至臻
author: xfyuan
categories: [ Translation, Programming ]
tags: [ruby, rails, graphql, evil martians]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20200924_133643.jpg"
rating: 5
---

*本文已获得原作者（Dmitry Tsepelev）、（Polina Gurtovaya）和 Evil Martians 授权许可进行翻译。原文是 Rails + React 使用 GraphQL的系列教程第三篇，介绍了以 Rails 作为后端，React + Apollo 作为前端，如何进行重构、错误处理以及实时更新等高级主题和技巧。*

- 原文链接：[GraphQL on Rails: On the way to perfection](https://evilmartians.com/chronicles/graphql-on-rails-3-on-the-way-to-perfection)
- 作者：[Dmitry Tsepelev](https://twitter.com/dmitrytsepelev)，[Polina Gurtovaya](https://github.com/HellSquirrel)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【正文如下】*

## 引言

**这是一个在后端使用 Rails、前端使用 React/Apollo 来开发 GraphQL 应用程序的旅行者指导。本教程的第三也是最后一部分都是关于实时更新的内容，以及 DRY 代码和实现更好的错误处理。**

在本教程的前一部分里，我们已经构建了 Martian Library 应用程序的原型：用户可以在一个现代的 SPA 页面中动态地管理有关红色星球的制品。但还没到坐下休息放松的时候，因为我们还有一些重构要做。

如果你是从前两部分一路编写了代码——就用你自己的代码即可，如果不是——那么可以从[这里](https://github.com/evilmartians/chronicles-gql-martian-library)拉取。

## All you need is DRY

让我们从后端开始来对 item 的 mutation（`AddItemMutation`和`UpdateItemMutation`）进行 一些 DRY 处理。我们有一些验证用户是否登录的重复代码：

```ruby
# app/graphql/mutations/add_item_mutation.rb

module Mutations
  class AddItemMutation < Mutations::BaseMutation
    # ...

    def resolve
      if context[:current_user].nil?
        raise GraphQL::ExecutionError,
              "You need to authenticate to perform this action"
      end

      save_item
    end
  end
end
```

把其移到`BaseMutation`类中：

```ruby
# app/graphql/mutations/base_mutation.rb

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    def check_authentication!
      return if context[:current_user]

      raise GraphQL::ExecutionError,
            "You need to authenticate to perform this action"
    end
  end
end
```

经过这样的修改，你就可以把`AddItemMutation`和`UpdateItemMutation`中的代码替换为`check_authentication!`的调用。这只是一个我们可以如何使用`BaseMutation`的例子罢了。在真实的应用程序中，它可以包含许多针对重复性工作的有用的帮助方法。

现在，让我们来看看前端代码。这里有怎样的代码重复呢？

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-3-on-the-way-to-perfection/front_duplication-8ee24ae.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-3-on-the-way-to-perfection/front_duplication-8ee24ae.png)

三个 query 看起来都非常类似：在`Item` query 中我们所选择的字段几乎是一样的。我们可以怎样避免这些重复？

幸运的是，GraphQL 有其自身的“variables”，称作 [*fragments*](https://graphql.github.io/graphql-spec/draft/#sec-Language.Fragments).。一个 fragment 就是一个在特定类型上的命名字段集。

该是创建我们第一个 fragment 的时候了：

```bash
$ mkdir -p app/javascript/fragments && touch app/javascript/fragments/Item.graphql
```

把所有重复的字段放入其中：

```graphql
fragment ItemFragment on Item {
  id
  title
  imageUrl
  description
}
```

现在我们需要把 fragment 添加到`AddItemForm`、`UpdateItemForm`和`Library`中的所有 operation 上。例如，`Library`组件中的 query 看起来会是这样：

```graphql
#app/javascript/components/Library/operations.graphql
#import '../../fragments/Item.graphql'

query LibraryQuery {
  items {
    ...ItemFragment
    user {
      id
      email
    }
  }
}
```

## Dealing with errors

我们知道，如果请求没有引起服务端报错的话，GraphQL 总是响应为 *200 OK*。通常有两种类型的错误发生：用户输入错误（校验）和异常。

- *校验错误* 仅出现在 mutation 中，它们被包含在所返回的数据里。为用户提供有用的反馈，以显示在 UI 上。
- *异常* 可以出现在任何 query 中，指示 query 里有什么东西出错了：例如，身份验证/权限的问题，无法处理的输入数据，等等（看后面内容）。如果响应包含异常，客户端就必须“尽全力失败”（比如，展示一个错误页面）。

从前端角度来看，对于错误我们可以如何做呢？

首先，我们可以设置一个错误日志记录器，来快速检测并修复错误（我们已经在[第一部分](https://evilmartians.com/chronicles/graphql-on-rails-1-from-zero-to-the-first-query)中配置好了）。

其次，把组件封装在[错误边界](https://reactjs.org/docs/error-boundaries.html)内是一个好主意，并在出现问题时用悲伤的开发者面孔显示错误屏幕。

第三，我们应该通过查阅文档来避免常见错误。当心点号并正确处理那些可为 null 的字段！看看你的 GraphiQL 文档中的`me` query：

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-3-on-the-way-to-perfection/me_docs-d7f115c.png](https://cdn.evilmartians.com/front/posts/graphql-on-rails-3-on-the-way-to-perfection/me_docs-d7f115c.png)

根据文档，`me`是一个*可为 null* 的字段。我们不能随便使用诸如`me.email`的表达式，而需要确保 user 是存在的。

最后，我们应该在 [render prop](https://reactjs.org/docs/render-props.html) 函数内处理 GraphQL 错误。下面很快会向你展示如何来做。

当用户提交了非法数据，后端返回一个字符串的错误消息列表。让我们来修改下处理错误的方式：将会返回一个 object，包含同样的错误消息列表，但也包含一些 JSON 编码的细节。细节可用于生成客户端消息，或向用户提供额外的反馈（比如，高亮非法的表单字段）。

首先，来定义一个新的`ValidationErrorsType`：

```ruby
# app/graphql/types/validation_errors_type.rb

module Types
  class ValidationErrorsType < Types::BaseObject
    field :details, String, null: false
    field :full_messages, [String], null: false

    def details
      object.details.to_json
    end
  end
end
```

现在，我们需要修改`AddItemMutation`来使用所定义的新类型（请为`UpdateItemMutation`做同样的事）：

```ruby
# app/graphql/mutations/add_item_mutation.rb

module Mutations
  class AddItemMutation < Mutations::BaseMutation
    argument :title, String, required: true
    argument :description, String, required: false
    argument :image_url, String, required: false

    field :item, Types::ItemType, null: true
    field :errors, Types::ValidationErrorsType, null: true # this line has changed

    def resolve(title:, description: nil, image_url: nil)
      check_authentication!

      item = Item.new(
        title: title,
        description: description,
        image_url: image_url,
        user: context[:current_user]
      )

      if item.save
        { item: item }
      else
        { errors: item.errors } # change here
      end
    end
  end
end
```

最后，来为 item model 添加对应的校验：

```ruby
# app/models/item.rb

class Item < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :description, length: { minimum: 10 }, allow_blank: true
end
```

现在，我们需要在接口中使用这些校验。我们应该为`AddItemForm`和`UpdateItemForm`更新逻辑。我们将为你展示对`AddItemForm`如何做，至于`UpdateItemForm`的代码，就留给读者作为一个练习了（当然，你可以在[这儿](https://github.com/evilmartians/chronicles-gql-martian-library/blob/1ea31575aa35246052678be8e9506fe7099db6a8/app/javascript/components/UpdateItemForm/index.js)找到解决办法）。

让我们先来为`operations.graphql`添加一个`errors`字段：

```graphql
#/app/javascript/components/AddItemForm/operations.graphql
#import '../../fragments/Item.graphql'

mutation AddItemMutation(
  $title: String!
  $description: String
  $imageUrl: String
) {
  addItem(title: $title, description: $description, imageUrl: $imageUrl) {
    item {
      ...ItemFragment
      user {
        id
        email
      }
    }
    errors { # new field
      fullMessages
    }
  }
}
```

现在，我们需要在`AddItemForm`及其上一级的`ProcessItemForm`中做一点小的改动，为错误添加一个新元素：

```js
// app/javascript/components/ProcessItemForm/index.js
const ProcessItemForm = ({
  // ...
  errors,
}) => {
  // ...
  return (
    <div className={cs.form}>
      {errors && (
        <div className={cs.errors}>
          <div className="error">{errors.fullMessages.join('; ')}</div>
        </div>
      )}
      {/* ... */}
    </div>
  );
};

export default ProcessItemForm;
```

而在`Mutation`组件中，我们就从`data` property 抓取错误：

```js
// app/javascript/components/AddItemForm/index.js
// ...
<Mutation mutation={AddItemMutation}>
  {(addItem, { loading, data }) => ( // getting data from response
    <ProcessItemForm
      buttonText="Add Item"
      loading={loading}
      errors={data && data.addItem.errors} />
      // ...
    )
  }
</Mutation>
```

如果你想要错误信息显示得更漂亮一点，就在`/app/javascript/components/ProcessItemForm/styles.module.css`添加如下样式：

```css
.form {
  position: relative;
}

.errors {
  position: absolute;
  top: -20px;
  color: #ff5845;
}
```

现在，让我们来谈论下 GraphQL 的第二种错误：*异常*。教程的前一章里，我们已经实现了身份验证，但没有实现一种处理用户带不存在 email 的方式。这不是所期望的行为，所以我们要确保抛出一个异常：

```ruby
# app/graphql/mutations/sign_in_mutation.rb

module Mutations
  class SignInMutation < Mutations::BaseMutation
    argument :email, String, required: true

    field :token, String, null: true
    field :user, Types::UserType, null: true

    def resolve(email:)
      user = User.find_by!(email: email)

      token = Base64.encode64(user.email)

      {
        token: token,
        user: user
      }
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "user not found"
    end
  end
end
```

我们需要更改前端代码来优雅处理这种情形。在`UserInfo`组件中来做。从 render prop 函数所提供的对象中为`Mutation`组件抓取错误参数：

```js
// app/javascript/components/UserInfo/index.js

const UserInfo = () => {
  // ...
  {(signIn, { loading: authenticating, error /* new key */ }) => {
  }}
  // ...
}
```

并在`</form>` 前添加一个元素来显示错误：

```js
// app/javascript/components/UserInfo/index.js

const UserInfo = () => {
  <form>
    // ...
    {error && <span>{error.message}</span>}
  </form>
  // ...
}
```

## Handling input data

让我们再回到`AddItemMutation`和`UpdateItemMutation`。看看 argument 列表，问问你自己，为什么我们有两个几乎相同的列表呢？每次我们向`Item` model 添加新字段，都需要添加新 argument 两次，这可不好。

解决办法相当简单：使用一个单独的 argument，包含所有需要的字段。`graphql-ruby`有一个称为`BaseInputObject`的特殊事物，用来定义类似如此的 argument 类型。我们来创建一个名为`item_attributes.rb`的文件：

```ruby
# app/graphql/types/item_attributes.rb

module Types
  class ItemAttributes < Types::BaseInputObject
    description "Attributes for creating or updating an item"

    argument :title, String, required: true
    argument :description, String, required: false
    argument :image_url, String, required: false
  end
end
```

这个看起来很像之前所创建的类型，但有一个根本的区别：`argument`替代了 field。这是为什么？因为 GraphQL 遵循了 CQRS 原则，以两个不同的 model 来处理数据：读的 model（type）和写的 model（input）。

当心：你不能使用复杂类型作为 argument 类型——它只能是标量类型或其他 input 类型。

现在，我们可以把 mutation 更改为使用这个 argument 了。来从`AddItemMutation`开始：

```ruby
# app/graphql/mutations/add_item_mutation.rb

module Mutations
  class AddItemMutation < Mutations::BaseMutation
    argument :attributes, Types::ItemAttributes, required: true # new argument

    field :item, Types::ItemType, null: true
    field :errors, Types::ValidationErrorsType, null: true # <= change here

    # signature change
    def resolve(attributes:)
      check_authentication!

      item = Item.new(attributes.to_h.merge(user: context[:current_user])) # change here

      if item.save
        { item: item }
      else
        { errors: item.errors }
      end
    end
  end
end
```

如你所见，我们用一个名为`attributes`的单独 argument 替换了整个 argument 列表，修改`#resolve`以接收它，并稍微变更了我们创建 item 的方式。请对`UpdateItemMutation`进行同样的调整。现在我们需要修改前端代码来适配这些改动了。

我们唯一要做的就是添加一个单词和两个大括号到 mutation 上（对于`UpdateItem`也应该做同样的修改）：

```js
#/app/javascript/components/AddItemForm/operations.graphql
#import '../../fragments/Item.graphql'

mutation AddItemMutation(
  $title: String!
  $description: String
  $imageUrl: String
) {
  addItem(
    attributes: { # just changing the shape
      title: $title
      description: $description
      imageUrl: $imageUrl
    }
  ) {
    item {
      ...ItemFragment
      user {
        id
        email
      }
    }
    errors {
      fullMessages
    }
  }
}
```

## Implementing real-time updates

服务端发起的更新在现代应用中很常见：我们的场景里，对于用户，在有人添加新 item 或修改现有 item 时，让其列表得到更新是很有用的。这正是 GraphQL *subscriptions* 的目的所在！

Subscription 是一种把服务端所发起的更新发布到客户端的机制。每个更新都返回特别类型的数据：例如，我们可以添加一个 subscription，当有新 item 被添加时就提醒客户端。当我们发送 *Subscription* operation 到服务端时，它会给我们返回一个 Event Stream。你可以使用任何方式，包括 post，来传输 events，但 Websockets 特别适合这种情形。对我们的 Rails 应用而言，意味着可以使用 ActionCable 来传输。下面是一个典型的 GraphQL subscription 所呈现的样子：

![https://cdn.evilmartians.com/front/posts/graphql-on-rails-3-on-the-way-to-perfection/subscriptions-b00176f.gif](https://cdn.evilmartians.com/front/posts/graphql-on-rails-3-on-the-way-to-perfection/subscriptions-b00176f.gif)

## Laying the cable

首先，我们要创建`app/graphql/types/subscription_type.rb`并注册 subscription，使其在新 item 被添加时触发。

```ruby
# app/graphql/types/subscription_type.rb

module Types
  class SubscriptionType < GraphQL::Schema::Object
    field :item_added, Types::ItemType, null: false, description: "An item was added"

    def item_added; end
  end
end
```

其次，我们要配置 schema 以使用`ActionCableSubscriptions`，并能从`SubscriptionType`中找到可用的 subscriptions：

```ruby
# app/graphql/martian_library_schema.rb

class MartianLibrarySchema < GraphQL::Schema
  use GraphQL::Subscriptions::ActionCableSubscriptions

  mutation(Types::MutationType)
  query(Types::QueryType)
  subscription(Types::SubscriptionType)
end
```

第三，我们要生成一个 ActionCable channel 来处理已订阅的客户端：

```bash
$ rails generate channel GraphqlChannel
```

让我们从[文档](https://graphql-ruby.org/api-doc/1.8.13/GraphQL/Subscriptions/ActionCableSubscriptions)中借用 channel 的实现代码：

```ruby
# app/channels/graphql_channel.rb

class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    result = execute_query(data)

    payload = {
      result: result.subscription? ? { data: nil } : result.to_h,
      more: result.subscription?
    }

    @subscription_ids << context[:subscription_id] if result.context[:subscription_id]

    transmit(payload)
  end

  def unsubscribed
    @subscription_ids.each do |sid|
      MartianLibrarySchema.subscriptions.delete_subscription(sid)
    end
  end

  private

  def execute_query(data)
    MartianLibrarySchema.execute(
      query: data["query"],
      context: context,
      variables: data["variables"],
      operation_name: data["operationName"]
    )
  end

  def context
    {
      current_user_id: current_user&.id,
      current_user: current_user,
      channel: self
    }
  end
end
```

确认把`:channel`传给了 context。还有，我们传递了`current_user`使其在 resolvers 内部可用，跟`:current_user_id`一样，[可被用来](https://graphql-ruby.org/subscriptions/triggers.html)传递范围内的 subscriptions。

现在，我们需要添加在 channel 中获取当前用户的一种方式。以如下方式修改`ApplicationCable::Connection`：

```ruby
# app/channels/application_cable/connection.rb

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = current_user
    end

    private

    def current_user
      token = request.params[:token].to_s
      email = Base64.decode64(token)
      User.find_by(email: email)
    end
  end
end
```

触发 event 相当简单：我们应传递驼峰式的字段名作为第一个 argument，options 是第二个 argument，而订阅的更新的 root object 作为第三个 argument。把其加到`AddItemMutation`：

```ruby
# app/graphql/mutations/add_item_mutation.rb

module Mutations
  class AddItemMutation < Mutations::BaseMutation
    argument :attributes, Types::ItemAttributes, required: true

    field :item, Types::ItemType, null: true
    field :errors, [String], null: false

    def resolve(attributes:)
      check_authentication!

      item = Item.new(attributes.merge(user: context[:current_user]))

      if item.save
        MartianLibrarySchema.subscriptions.trigger("itemAdded", {}, item)
        { item: item }
      else
        { errors: item.errors.full_messages }
      end
    end
  end
end
```

Argument hash 可以包含 arguments，后者被定义在 subscription 中（其将被作为 resolver arguments 传递）。有一个称为`:scope`的第四个可选 argument，用来限制会接收到这些更新的用户的范围。

让我们来添加另一个 subscription，这次是更新 items：

```ruby
# app/graphql/types/subscription_type.rb

module Types
  class SubscriptionType < GraphQL::Schema::Object
    field :item_added, Types::ItemType, null: false, description: "An item was added"
    field :item_updated, Types::ItemType, null: false, description: "Existing item was updated"

    def item_added; end
    def item_updated; end
  end
end
```

下面是在`UpdateItemMutation`中我们将如何触发这种类型的更新：

```ruby
# app/graphql/mutations/update_item_mutation.rb

module Mutations
  class UpdateItemMutation < Mutations::BaseMutation
    argument :id, ID, required: true
    argument :attributes, Types::ItemAttributes, required: true

    field :item, Types::ItemType, null: true
    field :errors, [String], null: false

    def resolve(id:, attributes:)
      check_authentication!

      item = Item.find(id)

      if item.update(attributes.to_h)
        MartianLibrarySchema.subscriptions.trigger("itemUpdated", {}, item)
        { item: item }
      else
        { errors: item.errors.full_messages }
      end
    end
  end
end
```

我们应该提到一点，这种 subscriptions 方式是在 *graphql-ruby* 中为 ActionCable 实现的，会有性能上的瓶颈：大量 Redis 往返，并对每个连接的客户端进行查询重新评估（可在[这里](https://github.com/anycable/anycable-rails/issues/40)查看更多有关的深度解析）。

*对 [AnyCable](https://anycable.io/) 用户这已经不再是问题了——从我们为 eBay 项目的工作成果中抽取出来的 [graphql-anycable](https://github.com/Envek/graphql-anycable) gem 带来了高效的 GraphQL subscriptions。*

## Plugging in

要让我们的应用程序发送数据给 ActionCable，需要一些配置。首先，我们要安装一些新 modules 来处理通过 ActionCable 的 Subscriptions：

```bash
$ yarn add actioncable graphql-ruby-client
```

然后，我们需要添加一些新“魔法”到`/app/javascript/utils/apollo.js`：

```js
// /app/javascript/utils/apollo.js
...
import ActionCable from 'actioncable';
import ActionCableLink from 'graphql-ruby-client/subscriptions/ActionCableLink';
...
const getCableUrl = () => {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.hostname;
  const port = process.env.CABLE_PORT || '3000';
  const authToken = localStorage.getItem('mlToken');
  return `${protocol}//${host}:${port}/cable?token=${authToken}`;
};

const createActionCableLink = () => {
  const cable = ActionCable.createConsumer(getCableUrl());
  return new ActionCableLink({ cable });
};

const hasSubscriptionOperation = ({ query: { definitions } }) =>
  definitions.some(
    ({ kind, operation }) =>
      kind === 'OperationDefinition' && operation === 'subscription'
  );


//..
// we need to update our link
  link: ApolloLink.from([
    createErrorLink(),
    createLinkWithToken(),
    ApolloLink.split(
      hasSubscriptionOperation,
      createActionCableLink(),
      createHttpLink(),
    ),
  ]),

//..
```

尽管这代码事实上看起来有点可怕，但是思路很简单：

- 我们在`createActionCableLink`内为 subscriptions 创建一个新的 Apollo link；
- 在 ApolloLink.split 内决定向哪里发送数据；
- 如果`hasSubscriptionOperation`返回 true，operation 就会被发送到`actionCableLink`。

现在我们需要使用[生成器](https://github.com/HellSquirrel/create-gql-component)创建一个新组件：

```bash
$ npx @hellsquirrel/create-gql-component create /app/javascript/components/Subscription
```

让我们来添加 subscription 到`operations.graphql`：

```graphql
#/app/javascript/components/Subscription/operations.graphql
#import '../../fragments/Item.graphql'

subscription ItemSubscription {
  itemAdded {
    ...ItemFragment
    user {
      id
      email
    }
  }

  itemUpdated {
    ...ItemFragment
    user {
      id
      email
    }
  }
}
```

毫无新意，对吧？再来创建`Subscription`组件：

```js

// /app/javascript/components/Subscription/index.js
import React, { useEffect } from 'react';
import { ItemSubscription } from './operations.graphql';

const Subscription = ({ subscribeToMore }) => {
  useEffect(() => {
    return subscribeToMore({
      document: ItemSubscription,
      updateQuery: (prev, { subscriptionData }) => {
        if (!subscriptionData.data) return prev;
        const { itemAdded, itemUpdated } = subscriptionData.data;

        if (itemAdded) {
          const alreadyInList = prev.items.find(e => e.id === itemAdded.id);
          if (alreadyInList) {
            return prev;
          }

          return { ...prev, items: prev.items.concat([itemAdded]) };
        }

        if (itemUpdated) {
          return {
            ...prev,
            items: prev.items.map(el =>
              el.id === itemUpdated.id ? { ...el, ...itemUpdated } : el
            ),
          };
        }

        return prev;
      },
    });
  }, []);
  return null;
};

export default Subscription;
```

又一个 hook！这里是`useEffect`。它在初始渲染时被调用，并在用户更改时重新运行。

我们要求 hook 来订阅 `add`和`update` 的 event streams。当相应事件被触发时我们就添加或更新 items。

最后一步是把`Subscription`组件添加到`Library`，在`Query`组件内到最后一个`div`的尾部：

```js
import Subscription from '../Subscription';
//...
const Library = () => {
  const [item, setItem] = useState(null);
  return (
    <Query query={LibraryQuery}>
      {({ data, loading, subscribeToMore /* we need subscribe to more arg */}) => (
        <div>
          // ...
          <Subscription subscribeToMore={subscribeToMore} />
        </div>
      )}
    </Query>
  );
};
//...
```

*react-apollo* 库的`Query`组件提供了特别的函数`subscribeToMore`，其被`Subscription`组件所使用。我们把这个函数传递给了`Subscription`组件。

现在我们可以来测试自己的 subscriptions 了！试着在一个浏览器的 tab 中添加新 item 或者修改已有的——你将会看到所有打开的 tabs 中都会出现变化。

## 结语

祝贺你！

这就是我们穿越 Ruby-GraphQL-Apollo 世界的令人激动的冒险之旅的终点了。使用一个小的范例应用，我们实践了所有的基础技术，强调了常见的问题，还介绍了一些高级主题。

这可能是一个具有挑战性的练习，但我们确信你将从中受益。无论如何，你现在都有足够的理论和实践来为自己创建利用上 GraphQL 强大威力的 Rails 应用了！
