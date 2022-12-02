---
layout: post
title: Hotwire之使用Turbo Frame解构页面
author: xfyuan
categories: [ Translation, Programming ]
tags: [rails, hotwire, turbo]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20210312_203551.jpg"
---

本文是对 Turbo Frame 的详细说明，原文出自：[https://turbo.hotwire.dev/handbook/frames](https://turbo.hotwire.dev/handbook/frames)。

Turbo Frames 允许你预定义页面中那些根据需要来更新的部分。任何 frame 内的链接和表单都会被捕获，而 frame 的内容会在接收到响应后被自动更新。不管服务端提供的是整个 document，还是仅包含所请求 frame 的更新版本的片段，都只有那个特定的 frame 会从响应中被提取出来以替代现有的内容。

把页面的某一部分包在`<turbo-frame>`元素中就创建了 Frames 。每个元素必须有一个唯一 ID，用来从服务端请求行页面时匹配要被替换的内容。一个单独页面可以有多个 frames，每一个都确立其自己的上下文：

```html
<body>
  <div id="navigation">Links targeting the entire page</div>

  <turbo-frame id="message_1">
    <h1>My message title</h1>
    <p>My message content</p>
    <a href="/messages/1/edit">Edit this message</a>
  </turbo-frame>

  <turbo-frame id="comments">
    <div id="comment_1">One comment</div>
    <div id="comment_2">Two comments</div>

    <form action="/messages/comments">...</form>
  </turbo-frame>
</body>
```

这个页面有两个 frames：一个展示消息，带一个编辑链接；一个列出所有评论，带一个表单以添加评论。每个 frame 都创建了其自身的上下文，来捕获其中的链接和表单提交。

当编辑消息的链接被点击时，由`/messages/1/edit`提供的响应会把它的`<trubo-frame id="message_1">`部分提取出来，而其内容则会替换到链接点击所在的 frame 上。编辑消息的响应可能是这样的：

```html
<body>
  <h1>Editing message</h1>

  <turbo-frame id="message_1">
    <form action="/messages/1">
      <input name="message[name]" type="text" value="My message title">
      <textarea name="message[name]">My message content</textarea>
      <input type="submit">
    </form>
  </turbo-frame>
</body>
```

注意，`<h1>`并不在`<turbo-frame>`内。这意味着当表单替换展示的消息时它会被忽略掉。只有所匹配的`<turbo-frame>`之内的内容才会在 frame 被更新时用到。

因此，你的页面就可轻松实现双重目的：在整个页面专用于操作的 frame 之内或之外进行编辑。

## Lazily Loading Frames

当页面加载时，其中所包含的 frames 并不必都填充内容。如果`<turbo-frame>`上有一个`<src>`属性，那么一旦该 tag 出现在页面上时其中的 URL 就将被自动加载：

```html
<body>
  <h1>Imbox</h1>

  <div id="emails">
    ...
  </div>

  <turbo-frame id="set_aside_tray" src="/emails/set_aside">
  </turbo-frame>

  <turbo-frame id="reply_later_tray" src="/emails/reply_later">
  </turbo-frame>
</body>
```

这个页面在加载后会立即列出你的 imbox 中所有的可用邮件，但随后会发送两个后续请求，用来在页面底部为搁置或等待稍后回复的邮件展现小托盘。这些托盘都是根据`src`中所指定的 URL 所发出的单独 HTTP 请求而创建的。

上面示例中，托盘起初都是空的，但其也可以填充一些初始化内容，当从`src`获取到了内容时，这些初始化内容就会被覆盖掉：

```html
<turbo-frame id="set_aside_tray" src="/emails/set_aside">
  <img src="/icons/spinner.gif">
</turbo-frame>
```

加载 imbox 页面后，`set-aside`托盘会从`/emails/set_aside`载入内容，而响应必须包含一个跟原始用例中相对应的`<turbo-frame id="set_aside_tray">`元素：

```html
<body>
  <h1>Set Aside Emails</h1>

  <p>These are emails you've set aside</p>

  <turbo-frame id="set_aside_tray">
    <div id="emails">
      <div id="email_1">
        <a href="/emails/1">My important email</a>
      </div>
    </div>
  </turbo-frame>
</body>
```

该页面现在以其最小化形式工作，即仅将具有单独邮件的`div`加载到 imbox 页面上的托盘 frame 中，而且还可以作为提供 header 和描述的直接目标。 就像在带有编辑消息表单的示例中那样。

注意，在`/emails/set_aside`上的`<turbo-frame>`不包含`src`属性。这个属性仅仅添加到需要 lazy 加载内容的 frame 上，而不是添加到提供内容的被渲染的 frame 上。

## Cache Benefits to Lazily Loading Frames

把页面片段转换成 frames 能够帮助使得页面实现更加简单，但同样重要的是这样做能够改善缓存动态。带有很多片段的复杂页面难以被有效缓存，特别是如果它们将许多人共享的内容与专门针对单个用户的内容混合在一起的话。这些片段越多，需要缓存查找的依赖的 key 越多，缓存流失的频率就越高。

Frames 是对在不同时间范围和不同受众上变化的片段进行分离的理想选择。有时，把页面中针对每个用户的元素转换为 frame 是有道理的，如果页面其他部分都是由所有用户共享的话。有时，则是相反的做法更有理由，例如在一个重度的个人化页面，把一个共享的片段转换为 frame 以便共享缓存服务于它。

虽然获取 lazy 加载的 frames 的开销通常很低，但是你仍然应该明智地确定要加载的数量，特别是如果这些 frames 会在页面上造成加载抖动时。然而，如果其内容在页面加载时不是立即可见的，那么 frames 基本上都是 free 的。可能是因为它们隐藏于 modal 或首屏之下。

## Targeting Navigation Into or Out of a Frame

默认情况下，在一个 frame 内部的导航就只针对那个 frame。对于点击链接和提交表单都是如此。但通过设置目标为`_top`，导航可以切换到整个页面而非闭合的 frame。或者也可以切换到另一个命名 frame 上，通过设置目标到该 frame 的 ID 的方式。

在 set-aside tray 的示例中，tray 之内到链接指向单独的邮件。你不会想要这些链接去找匹配`set_aside_tray` ID 的 frame tag。你想要的是直接导航到那些邮件。这通过把 tray frames 标记其`target`属性来实现：

```html
<body>
  <h1>Imbox</h1>
  ...
  <turbo-frame id="set_aside_tray" src="/emails/set_aside" target="_top">
  </turbo-frame>
</body>

<body>
  <h1>Set Aside Emails</h1>
  ...
  <turbo-frame id="set_aside_tray" target="_top">
    ...
  </turbo-frame>
</body>
```

有时，你想要大多数链接在 frame 上下文中进行操作，但少部分不是。对于表单也是同样的。那么你可以把`data-trubo-frame`属性添加到非 frame 的元素上来实现：

```html
<body>
  <turbo-frame id="message_1">
    ...
    <a href="/messages/1/edit">
      Edit this message (within the current frame)
    </a>

    <a href="/messages/1/permission" data-turbo-frame="_top">
      Change permissions (replace the whole page)
    </a>
  </turbo-frame>

  <form action="/messages/1/delete" data-turbo-frame="message_1">
    <input type="submit" value="Delete this message">
    (with a confirmation shown in a specific frame)
  </form>
</body>
```

