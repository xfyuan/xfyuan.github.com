---
layout: post
title: Build Docker时使用SSH Private Key的新玩法
author: xfyuan
categories: [ Tool ]
tags: [docker ]
comments: true
image: "https://raw.githubusercontent.com/xfyuan/ossimgs/master/uPic/IMG_20201015_122251.jpg"
---

在实际工作中，Build Docker 镜像时，经常碰上需要在 Docker 镜像内用到 SSH Private Key 的场景。比如 Docker 镜像内要从 GitHub、GitLab 的私有库 Clone 代码，或者要安装私有库的Gem、NPM Package等。而如果直接把自己的 SSH Private Key 打包到 Docker 镜像中的话，是存在很大安全风险的。如何解决这个问题？

在之前，我们往往是通过 Squash 或者 Docker Multi Stage 等方式来处理，但都有各自不足之处。而 Docker 在 18.09 版本后，推出了 BuildKit 的 SSH mount type。我们就可以用这个特性来解决了。

首先，需要在 Dockerfile 的顶部添加这样一行来开启该实验特性：

```bash
# syntax=docker/dockerfile:1.0.0-experimental
```

然后，在 Dockerfile 中需要使用 SSH Private Key 的地方都加上

```bash
--mount=type=ssh
```

比如，Rails 项目安装有私有库的 Gem 包时，就写成这样：

```bash
RUN --mount=type=ssh bundle install
```

以此类推。Dockerfile 准备好之后，再设置一下环境变量以启用 BuildKit：

```bash
export DOCKER_BUILDKIT=1
```

最后，即可使用如下命令来 Build Docker 镜像了：

```bash
docker build --ssh default=/Users/xxxxx/.ssh/id_rsa -f Dockerfile -t rails-demo-dev:1.0.0 .
```

搞定。

这种方式，既能正常使用上 SSH Private Key，又能使其在镜像中不留痕迹。完美！



参考阅读：

- https://medium.com/@tonistiigi/build-secrets-and-ssh-forwarding-in-docker-18-09-ae8161d066
- https://medium.com/@amimahloof/securely-build-small-python-docker-image-from-private-git-repos-c3e6d5da4626