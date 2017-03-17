---
layout: post
title: 使用 Alfred workflow 上传截图到七牛并自动生成外链URL
tags: [alfred]
comments: true
---

今年准备多写点Blog文章了。

前两周抽了些时间把 Github page 重新弄了下：Jekyll 升了个级，Theme 换了个顺眼的，自我介绍写了点新的。。正万事俱备，就要动笔的时候，发现了个有点不爽的问题——图片。

Jekyll 是用 markdown 格式来写文章，而写 markdown 的时候要放入一张图片到文章里，可就没那么友好了。不像 Office Word 之类软件，可以直接拖入图片到文章中，markdown 是通过插入 `![xxx](http://xxx.com/xxx.png)` 这样的代码来显示图片的，那么至少得经过这样几步：

* 上传图片到网络上的一个图片空间（图床）
* 拷贝该图床上这张图片的对应URL代码
* 粘贴到 markdown 文章中，改写为上述那样合适的形式

更不用说一篇文章如果需要的图片稍微多一点，每张图片都这样来一遍操作，那得把人烦死，那点子写作的欲望早就会被扔到爪洼国了。

身为一名 Dev，碰到这个情况，当然要用程序员的方式来解决问题！

我选用的国内图床是七牛。七牛对免费用户还不错，只要通过了它的实名认证，就可以有10G的空间，10G的访问流量／月等（详细服务可去参看七牛官网）。

## 准备七牛空间

要使用七牛的服务，大概需要这样几步：

* 注册七牛开发者账号 `https://portal.qiniu.com/signup?code=3looau4kfei4y`
* 登录七牛开发者平台，添加一个存储空间。要给这个存储空间取个名字，七牛给这个名字取了个术语叫 `Bucket`
* 在“个人中心 > 密钥管理”中查看AccessKey 和 SecretKey（下面的上传工具会用到）
* 使用七牛官方提供的 command line tool：qshell 可在本地电脑进行管理和上传（之前的 qsync 已经被废弃了）

qshell 的下载和用法可在其官网 `http://developer.qiniu.com/code/v6/tool/qshell.html` 找到。本文不多赘述。

要上传单个图片，我们需要使用 qshell 的 fput 命令:

```
qshell fput <Bucket> <Key> <LocalFile>
```

Bucket 就是上面提到的存储空间名字。

例如：`qshell fput your-bucket xyz.png /path/to/image/xyz.png`

## 对主要流程的思考

现在，图床有了，怎样上传图片也知道了，该是考虑整个目标实现流程的时候了。

**重申一下目标：自动化完成 “上传图片 --> 获取对应 markdown 图片URL” 整个过程。**

分析一下，每次添加一个截图到文章里，大概可分为七步，其中会用到一些工具：

* 使用 OSX 系统的快捷键：⌘+⇧+⌃+4 截图，并存入剪贴板中
* 使用 pngpaste 把剪贴板的图片写入到一个临时文件
* OSX 自带截图工具默认 PNG 格式，图像文件体积偏大。七牛虽然提供 10G 的免费空间，但积少成多，能省一点是一点，所以尽量缩减图片体积是必要的。我用了 pngquant 来优化临时文件的图像大小。
* 把优化后的临时文件用 qshell 上传到七牛
* 上传成功后自动删除临时文件
* 自动生成七牛空间对应上传图片的 markdown 图片URL代码
* 最后，把 markdown 图片URL代码存入系统剪贴板

这一系列步骤自动化完成后，我就只需按 ⌘+V 即可把 markdown 图片URL代码粘贴到文章里了。

*上面用到的三个工具：`pngpaste`，`pngquant`，`qshell`，其中前两者都可以通过 OSX 的 Homebrew 来安装。*

## 创建 Alfred workflow

思路有了，就开始干吧！

对于这样需要把一系列流程步骤进行自动化处理的事情，毫无疑问首选 OSX 上的“神兵利器” —— Alfred。Alfred 的 Workflow 正适合用来干这事。

**要使用 Alfred 的 workflow，得购买它的 PowerPack 版本。Free 版本未开放 workflow 功能。相信我，掏这笔银子是绝对值得的！**

在 Alfred 的 “Workflows” 窗口，点 + 号创建一个 “Empty Workflow”，名字取你喜欢的。

![markdown/20170317231207.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170317231207.png)

在这个空白 workflow 中，需要先创建一个触发器，来开始整个工作流。

在右侧窗口中右键菜单中选 “Inputs --> Keyword” 添加一个 Keyword 触发器。我设定的 keyword 是 `qiniu`，title  描述为“上传剪切板图片到七牛并获取外链URL”。这个title 是让在 Alfred 的命令窗口输入 `qiniu` 时显示该命令用来干嘛的。

![markdown/20170317231829.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170317231829.png)

然后再添加一个 action。

在右侧窗口中右键菜单中选 “Actions --> Run Script” 添加一个脚本执行器。在输入框中输入如图代码。qiniu.rb 文件会在稍后添加，它是整个工作流的核心部分，上述七个步骤的2～6步（即除去首尾之外的全部）工作都将由它来完成。

至于为什么选用 Ruby 脚本，原因很简单 —— 我是一名 Ruby developer。

![markdown/20170317232628.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170317232628.png)

这第二步的 action 执行后，会输出 markdown 图片URL代码，所以需要再添加最后一步：把代码存入系统剪贴板。Alfred 已经帮你准备好了这个常见的操作，直接使用它就好：

在右侧窗口中右键菜单中选 “Outputs --> Copy to Clipboard” 添加 “Copy to Clipboard” 执行器。一切默认即可。

![markdown/20170317234138.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170317234138.png)

最后，我们还应该添加一个 OSX 系统提醒，让这个 workflow 的使用体验更友好。

在右侧窗口中右键菜单中选 “Outputs --> Post Notification” 添加 “Post Notification” 执行器。title 写为“截图上传成功！Markdown URL已复制到剪贴板”，其他使用默认。

![markdown/20170317234515.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170317234515.png)

这样整个 workflow 所有环节都已经构建好了，我们只需用线将上面四个部分连起来，以组成一个工作流，即可大功告成！

![markdown/20170317234815.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170317234815.png)

## 2 - 6 步的代码实现

现在来看看要怎样实现 2 - 6 个步骤。一步一步来。

#### 第2步

```
* 使用 pngpaste 把剪贴板的图片写入到一个临时文件
```

pngpaste 的使用很简单：

```
pngpaste /path/to/temp.png
```

#### 第3步

```
* 用 pngquant 来优化临时文件的图像大小
```

pngquant 用法：

```
pngquant -f -o /path/to/temp.png /path/to/temp.png
```

-f 参数确保覆盖源文件

#### 第4步

```
* 把优化后的临时文件用 qshell 上传到七牛
```

qshell 使用其 fput 命令来上传：

```
qshell fput xfyuan markdown/xyz.png /path/to/temp.png
```

`xfyuan` 是我七牛空间的Bucket名称。

`markdown/` 是使用了七牛的命名空间形式作为区分，我用 `markdown` 来表示跟 Blog 文章相关的图片。

#### 第5步

```
* 上传成功后自动删除临时文件
```

这个不用多说：

```
rm -f /path/to/temp.png
```

#### 第6步

```
* 自动生成七牛空间对应上传图片的 markdown 图片URL代码
```

七牛的免费开发者账户会得到一个上传文件外链的默认域名（在存储空间管理页面可看到），我的是：

![markdown/20170318001411.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170318001411.png)

而上传图片的名称就是上面的 `markdown/xyz.png`，二者拼起来即可得到对应的外链访问URL：

```
http://omwi90lh4.bkt.clouddn.com/markdown/xyz.png
```

markdown 的图片格式即为：

```
![markdown/xyz.png](http://omwi90lh4.bkt.clouddn.com/markdown/xyz.png)
```

## qiniu.rb 代码

qiniu.rb 就是把上述各步代码放到一起，加上必要的一些处理，确保其正常运行和基本的异常处理即可。

全部代码如下：

```ruby
#!/usr/bin/env ruby

require 'date'

qiniu_domain = "http://omwi90lh4.bkt.clouddn.com"
qiniu_bucket = 'xfyuan'
qiniu_scope  = 'markdown'
folder       = '~/works/_tmp/'

filename = "#{DateTime.now.strftime('%Y%m%d%H%M%S')}.png"
upload_file = "#{folder}#{filename}"

# paste screenshot to a temp file
system "./pngpaste #{upload_file}"

if File.file? File.expand_path(upload_file)
  # optimize png
  system "./pngquant -f -o #{upload_file} #{upload_file}"

  # use qiniu qshell tool to upload screenshot image
  qiniu_filename = "#{qiniu_scope}/#{filename}"
  system "./qshell fput #{qiniu_bucket} #{qiniu_filename} #{upload_file} > /dev/null"

  # remove temp file
  system "rm -f #{upload_file}"

  # generate markdown image url
  qiniu_image_url = "#{qiniu_domain}/#{qiniu_filename}"
  markdown_image_url = "![#{qiniu_filename}](#{qiniu_image_url})"
  print markdown_image_url

else
  print "剪切板没有图片！"
end
```

有几个值得注意的地方：

* 临时文件使用当前的时间戳作为文件名
* qshell 上传文件用到了 `> /dev/null` 避免其上传成功后输出的一大堆信息干扰到最后的剪贴板内容
* 应该判断当前剪贴板上是否有图像，如果没有就中断退出，给予警告提示

## 最后的重要一步

还有一个问题：qiniu.rb 文件放到哪里才能让 Alfred workflow 执行时能找到并正确运行？

很简单。

打开 Keyword 触发器设置窗口：

![markdown/20170317231829.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170317231829.png)

**看到 “Cancel” 按钮左边那个图标了？**点击它，会在 Finder 中自动打开该 Workflow 的对应目录。把 qiniu.rb 文件放到这里，Workflow 运行时就能找到。

同理，上述步骤中用到的三个工具：`pngpaste`，`pngquant`，`qshell`，为了让 Workflow 运行时能找到它们，我们也应该把它们的执行文件各自拷贝放到这个目录，否则代码是无法正常工作的。

另外，还可以稍微美化一下 Workflow，例如给它加个图标。

最后，Workflow 的对应目录会是这样：

![markdown/20170318005441.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170318005441.png)

## 最终的使用体验

本文的全部图片插入都通过使用该 Alfred Workflow 来完成。

Alfred 命令窗口：

![markdown/20170318005752.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170318005752.png)

上传成功，系统弹窗提醒：

![markdown/20170318010241.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170318010241.png)

轻松快速粘贴到文章里：

![markdown/20170318010042.png](http://omwi90lh4.bkt.clouddn.com/markdown/20170318010042.png)

干得漂亮！