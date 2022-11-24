---
layout: post
title: 拷贝目录结构而不包含文件
author: Mr.Z
categories: [ Programming ]
tags: [macos]
comments: true
image: "https://gcore.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/image20221124.jpeg"
---

最近在 macOS 上碰到一个小问题，需要把原来一个很大的目录拷贝到另一个位置，要求必须保持其内部所有的子目录结构，但不需要拷贝每个目录下的任何文件，因为到时会有新的文件放到各个目录下。

这里比较棘手的地方在于，原来那个目录下有非常多的子目录和嵌套（至少有上百个以上，而且嵌套层数没有规律），这样的话要是靠手工去一个个复制粘贴，那得累死个人了。😭

以前还真没处理过类似问题，于是花了10分钟搜了一下，最后在 Apple 社区找到了，确实有人早就碰到类似的需求。直接看怎么解决的吧：

```sh
# 进入要复制的目录
cd /path/to/beginning/dir
# 查找所有 dictionary，并在目标目录创建相同名称的子目录
find . -type d -print0 | xargs -0 -I{} mkdir -p "/path/to/DestinationFoler/{}"
```

