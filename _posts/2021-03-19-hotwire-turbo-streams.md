---
layout: post
title: Hotwire之使用Turbo Streams焕发活力
author: xfyuan
categories: [ Translation, Programming ]
tags: [rails, hotwire, turbo]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210220_115651.jpg"
---

本文是对 Turbo Streams 的详细说明，原文出自：[https://turbo.hotwire.dev/handbook/streams](https://turbo.hotwire.dev/handbook/streams)。

Turbo Streams 将页面的更改发布为包在自解释的`<turbo-stream>`元素中的 HTML 片段。每个 stream 元素都会同时指定一个 action 和 target ID，以声明其内的 HTML 会怎样处理。这些元素被服务端通过 WebSocket、SSE 或其他传输方式发布，借助由其他用户或进程进行的更新使应用程序焕发活力。抵达你的 imbox 的新邮件就是一个绝佳的范例。

## Stream Messages and Actions

一个 Turbo Streams 消息是一个由`<turbo-stream>`元素组成的 HTML 片段。下面的 stream 消息演示了五种可用的 stream actions：

```html
<turbo-stream action="append" target="messages">
  <template>
    <div id="message_1">
      This div will be appended to the element with the DOM ID "messages".
    </div>
  </template>
</turbo-stream>

<turbo-stream action="prepend" target="messages">
  <template>
    <div id="message_1">
      This div will be prepended to the element with the DOM ID "messages".
    </div>
  </template>
</turbo-stream>

<turbo-stream action="replace" target="message_1">
  <template>
    <div id="message_1">
      This div will replace the existing element with the DOM ID "message_1".
    </div>
  </template>
</turbo-stream>

<turbo-stream action="update" target="unread_count">
  <template>
    <!-- The contents of this template will replace the
    contents of the element with ID "unread_count". -->
    1
  </template>
</turbo-stream>

<turbo-stream action="remove" target="message_1">
  <!-- The element with DOM ID "message_1" will be removed.
  The contents of this stream element are ignored. -->
</turbo-stream>
```

注意，每个`<turbo-stream>`元素都必须把它内含的 HTML 包裹在一个`<template>`元素之内。

你可以在一个单独的 stream 消息中渲染任意数量的 stream 元素，该消息来自于 WebSocket、SSE 或者是一个表单提交后的响应。

## Streaming From HTTP Responses

Turbo 知道自动附带上那些`<turbo-stream>`元素，当它们以`<form>`提交的响应返回并声明了一个`text/vnd.turbo-stream.html`的 [MIME type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types) 时。当提交其 [method](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-method) 属性被设置为`POST`、`PUT`、`PATCH`或`DELETE` 的 `<form>`元素时，Turbo 就会把 `text/vnd.turbo-stream.html` 注入到请求的 [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) header 中的响应格式集之内。在对其 [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) header 包含了这些值的请求进行响应时，服务端就可以调整相应以处理 Turbo Streams，HTTP 重定向，或者不支持 streams 的其他类型的客户端（比如原生应用）。

在一个 Rails controller 中，看起来会是这样的：

```ruby
def destroy
  @message = Message.find(params[:id])
  @message.destroy

  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
    format.html         { redirect_to messages_url }
  end
end
```

## Reusing Server-Side Templates

Turbo Streams 的关键是重用你现有的服务端模板以执行实时的部分页面更改的能力。在页面首次加载时用来渲染消息列表中每一条消息的 HTML 模板，跟用来在之后动态添加到列表的一条新消息的模板，会是相同的。**这就是 HTML-over-the-wire 方案的本质和精华：你不需要再把新消息序列化为 JSON，在 JavaScript 中接收它，并渲染一个客户端的模板。**它就是标准的可重用的服务端模板。

另一个 Rails 中的例子看起来是这样的：

```erb
<!-- app/views/messages/_message.html.erb -->
<div id="<%= dom_id message %>">
  <%= message.content %>
</div>

<!-- app/views/messages/index.html.erb -->
<h1>All the messages</h1>
<%= render partial: "messages/message", collection: @messages %>
```

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def index
    @messages = Message.all
  end

  def create
    message = Message.create!(params.require(:message).permit(:content))

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(:messages, partial: "messages/message",
          locals: { message: message })
      end

      format.html { redirect_to messages_url }
    end
  end
end
```

当创建一条新消息的表单提交给`MessagesController#create` action 时，跟`MessagesController#index`中用来渲染消息列表完全同样的 partial 模板被用来渲染 turbo-stream action。这将作为如下所示的响应出现：

```html
Content-Type: text/vnd.turbo-stream.html; charset=utf-8

<turbo-stream action="append" target="messages">
  <template>
    <div id="message_1">
      The content of the message.
    </div>
  </template>
</turbo-stream>
```

这个`messages/message` partial 模板然后可以被用来渲染后续 edit/update 操作的消息，或者支持由其他用户通过 WebSocket 或 SSE 连接所创建的新消息。能够在整个使用范围内重用相同的模板非常强大，这是减少创建这些现代，快速应用程序所需工作量的关键。

## Progressively Enhance When Necessary

一开始你的交互设计不借助 Turbo Streams 是一种好的实践。当 Turbo Streams 不可用时，让整个应用程序如预期那样运行，然后将它们分层升级。这意味着你将不必依赖更新来处理那些需要在原生应用或其他没有它们的地方都能正常工作的流程。

对于 WebSocket 更新也是同样的。在连接不好，或有服务端问题，你的 WebSocket 可能会中断。如果应用程序被设计为不借助于它而正常工作，这就更有适应性。

## But What About Running JavaScript?

Turbo Streams 有意识地把所能执行的 actions 限制为五种：append、prepend、replace、update 和 remove。如果你在执行这些 actions 时想要触发额外的行为，那你应该使用 [Stimulus](https://stimulus.hotwire.dev/) controller 来附加这些行为。这种限制让 Turbo Streams 专注于通过网络发布 HTML 的本质任务，把额外的逻辑留给专门的 JavaScript  文件。

拥抱这些约束将使你避免将单个响应转变为无法重复使用的行为，从而使应用程序难以遵循。得自于 Turbo Streams 的关键受益是重用初始化渲染页面的模板的能力，贯穿于所有后续更新的过程中。

## Integration with Server-Side Frameworks

在 Turbo 附带的所有技术中，与 Turbo Streams 一起使用，你将看到与后端框架的紧密集成所带来的最大优势。作为官方 Hotwire 套件的一员，我们已经创建了这种集成看起来如何的一个实现参考，即 [turbo-rails gem](https://github.com/hotwired/turbo-rails)。该 gem 依赖于 Rails 中内置的 WebSocket 和 异步渲染的支持，其分别通过 Action Cable 和 Active Job 框架。

使用加入 Active Record 其中的 [Broadcastable](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb) concern，你就可以直接触发来自 领域模型（domain model）的 WebSocket 更新。而使用  [Turbo::Streams::TagBuilder](https://github.com/hotwired/turbo-rails/blob/main/app/models/turbo/streams/tag_builder.rb)，你就可以渲染在 inline controller 响应或专门模板中的`<turbo-stream>`元素，通过一个简单的 DSL 执行那五种 actions 以及相关的渲染。

但是，Turbo 本身是完全与后端无关的。因此我们鼓励其他生态圈中的其他框架来看看针对 Rails 提供的实现参考，以创建它们自己的紧密整合。

另外，将任何后端应用程序与 Turbo Streams 集成的直接方法是依靠 [Mercure 协议](https://mercure.rocks/)。Mercure 通过 [Server-Sent Events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)，为服务端把页面变更播发到每个所连接的客户端提供了一种方便的方式。[这里可以学习如何 Turbo Streams 是如何跟 Mercure 一起使用的](https://mercure.rocks/docs/ecosystem/hotwire)。

