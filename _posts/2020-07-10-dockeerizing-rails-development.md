---
layout: post
title: 骑鲸之路——Docker模式下的Rails开发环境构筑（翻译）
author: Mr.Z
categories: [ Translation, Programming ]
tags: [ruby, rails, docker]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200710UngNYW.jpg"
---

*本文已获得原作者（Vladimir Dementyev）和 Evil Martians 授权许可进行翻译。原文介绍了一套成熟的 Rails 项目的 Docker 化开发环境如何搭建，怎样通过一些配置技巧让其高效运行。也谈到了这种模式下的开发流程和诀窍等问题。关于 Docker 作为开发环境的做法早已不是新鲜事，相关文章更是有非常多了。但本文是一名卓越的 Ruby 开发者在两年开发实践中提炼出的真正经验之谈，解答了之前自己对 Docker 开发环境模式的种种疑惑，因此觉得很有价值，遂成此文。*

- 原文链接：[Ruby on Whales: Dockerizing Ruby and Rails development — Martian Chronicles, Evil Martians’ team blog](https://evilmartians.com/chronicles/ruby-on-whales-docker-for-ruby-rails-development)
- 作者：[Vladimir Dementyev](https://twitter.com/palkan_tula)
- 站点：Evil Martians ——位于纽约和俄罗斯的 Ruby on Rails 开发人员博客。 它发布了许多优秀的文章，并且是不少 gem 的赞助商。

*【下面是正文】*

![20200710WutVn8](https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/20200710WutVn8.png)

**这篇文章是对我在 RailsConf 2019 上演讲[“Terraforming legacy Rails applications”](https://speakerdeck.com/palkan/railsconf-2019-terraforming-legacy-rails-applications)的整理。今天我不是要说服你把应用程序开发切换到 Docker（不过你可以去看一下[当时 RailsConf 的视频](https://www.youtube.com/watch?v=-NKpMn6XSjU)了解更多）。我的目的是分享目前自己在 Rails 项目上使用的配置，其诞生于 Evil Martians 的开发工作中。尽情享用它吧！**

**声明：**本文会根据最佳实践进行定期更新，参看最后的 *Changelog 部分*。

我从三年前就开始在自己的开发环境中使用 Docker 了（代替了 Vagrant，后者对于我的 4GB 内存笔记本来说实在太重了）。一开始，这当然并非那么令人愉悦——我花了两年时间来尝试为自己更为团队找到一个足够好的配置。

让我在这里来为你展示这个配置，并解释其（几乎）每一行吧，因为我们已经看到太多那些关于 Docker 的晦涩难懂的教程了。

**相关源代码可以在 GitHub 的 [evilmartians/terraforming-rails](https://github.com/evilmartians/terraforming-rails/blob/master/examples/dockerdev) 上找到。**

我们在下面范例中使用了这些技术栈：

- Ruby 2.6.3
- PostgreSQL 11
- NodeJS 11 & Yarn (for Webpacker-backed assets compilation)

## [Dockerfile](https://github.com/evilmartians/terraforming-rails/blob/master/examples/dockerdev/.dockerdev/Dockerfile)

Dockerfile 定义了我们 Ruby 应用的环境：这是我们作为开发者运行 servers、console（`rails c`）、tests、Rake tasks 以及与代码进行交互的地方。

```bash
ARG RUBY_VERSION
# See explanation below
FROM ruby:$RUBY_VERSION-slim-buster

ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION

# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Add PostgreSQL to sources list
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# Application dependencies
# We use an external Aptfile for that, stay tuned
COPY .dockerdev/Aptfile /tmp/Aptfile
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev \
    postgresql-client-$PG_MAJOR \
    nodejs \
    yarn=$YARN_VERSION-1 \
    $(cat /tmp/Aptfile | xargs) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Configure bundler
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

# Uncomment this line if you store Bundler settings in the project's root
# ENV BUNDLE_APP_CONFIG=.bundle

# Uncomment this line if you want to run binstubs without prefixing with `bin/` or `bundle exec`
# ENV PATH /app/bin:$PATH

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION

# Create a directory for the app code
RUN mkdir -p /app

WORKDIR /app
```

这个配置仅包含了必不可少的部分，可以被用作一个起点。我来说明下这里做了什么。

头两行看起来有点奇怪：

```bash
ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-slim-buster
```

为什么不使用`FROM ruby:2.6.3`或者任何 Ruby 的稳定版本呢？因为我们想使环境是可从外部进行配置的，以便把 Dockerfile 作为一种模板：

- 明确的运行时版本倚赖会在`docker-compose.yml`中指定（见后面）；
- `apt`的安装依赖列表存放于一个单独的文件里（见后面）

我们也明确指定了 Debian 发行版（buster）以确保为其他依赖（比如 PostgreSQL）添加正确的源。

下面四行定义了 PostgreSQL、NodeJS、Yarn 和 Bundler 的版本：

```bash
ARG PG_MAJOR
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION
```

因为我们不期望任何人不通过 [Docker Compose](https://docs.docker.com/compose/) 来使用该 Dockerfile，所以就不提供默认值了。

然后就是实际的镜像 build 过程。首先，我们需要手动安装一些通用的系统依赖库（Git，cURL等），因为使用了 *slim* 基础镜像以缩小体积：

```bash
# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log
```

我们会在下面解释所有这些安装的系统依赖库的细节，当谈到应用程序特定部分的时候。

通过`apt`安装 PostgreSQL、NodeJS、Yarn 需要添加它们 deb 包的 repos 到源的列表中。

对于 PostgreSQL（基于[官方文档](https://www.postgresql.org/download/linux/debian/)）：

```bash
RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list
```

**注意：**这就是我们使用操作系统发行版为 buster 的原因。

对于 NodeJS（根据 [NodeSource repo](https://github.com/nodesource/distributions/blob/master/README.md#debinstall)）：

```bash
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -
```

对于 Yarn（根据[官方网页](https://yarnpkg.com/en/docs/install#debian-stable)）：

```bash
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
```

现在该来安装那些依赖库了，例如，运行`apt-get install`：

```bash
COPY .dockerdev/Aptfile /tmp/Aptfile
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev \
    postgresql-client-$PG_MAJOR \
    nodejs \
    yarn \
    $(cat /tmp/Aptfile | xargs) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log
```

首先，我们来说下关于 Aptfile 的技巧：

```bash
COPY .dockerdev/Aptfile /tmp/Aptfile
RUN apt-get install \
    $(cat /tmp/Aptfile | xargs)
```

这是我从 [heroku-buildpack-apt](https://github.com/heroku/heroku-buildpack-apt) 借鉴到的，它允许在 Heroku 上安装其他包。如果你使用这个 buildpack，甚至能为本地和线上环境重用相同的 Aptfile（尽管 buildpack 提供了更多的功能）。

我们的[默认 Aptfile](https://github.com/evilmartians/terraforming-rails/blob/master/examples/dockerdev/.dockerdev/Aptfile) 仅包含了一个单独的包（因为要使用 Vim 来编辑 Rails 的 Credentials）：

```bash
vim
```

在我工作过的前一个项目中，我们使用 LaTeX 和 [TexLive](https://www.tug.org/texlive/) 来生成 PDF。我们的 Aptfile 看起来是这样的（那时我还没有运用这个技巧）：

```bash
vim
texlive
texlive-latex-recommended
texlive-fonts-recommended
texlive-lang-cyrillic
```

通过这种方式，我们把所需要的依赖库放在一个单独文件中，使得自己的 Dockerfile 更加通用。

对于`DEBIAN_FRONTEND=noninteractive`，我建议去看下 [answer on Ask Ubuntu](https://askubuntu.com/a/972528)。

而`--no-install-recommends`则通过不安装推荐的包来帮助我们节省一些空间（让镜像更加苗条）。可以参看[这儿](http://xubuntugeek.blogspot.com/2012/06/save-disk-space-with-apt-get-option-no.html)。

最后的部分`RUN` (`apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && truncate -s 0 /var/log/*log`)也为了同样的目的——清理所接收到的包文件（全部都安装好了，这些不再需要了），以及在安装期间所创建的临时文件和日志。我们需要在同一个`RUN`语句中做这些清理，以确保这个[Docker layer](https://docs.docker.com/storage/storagedriver/#images-and-layers)不包含任何垃圾。

最后的部分几乎都是用于 Bundler：

```bash
# Configure bundler
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \

# Uncomment this line if you store Bundler settings in the project's root
# ENV BUNDLE_APP_CONFIG=.bundle

# Uncomment this line if you want to run binstubs without prefixing with `bin/` or `bundle exec`
# ENV PATH /app/bin:$PATH

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION
```

`LANG=C.UTF-8`设置默认为 UTF-8，否则 Ruby 会对字符串使用 US-ASCII 编码，你再也不能使用那些可爱的 emojis 👋

如果你使用`<root>/.bundle`目录来存放项目特定的 Bundler 设置（例如，针对私有 gems 的 credentials），那么就需要设置`BUNDLE_APP_CONFIG`。Ruby 的默认镜像就[定义了这个变量](https://github.com/docker-library/ruby/issues/129#issue-229195231)以使得 Bundler 不回退到本地配置。

你可以选择性地把`<root>/bin`目录添加到`PATH`，以便运行命令时无需带上`bundle exec`前缀。我们这里默认没有加上，因为在多项目环境下它可能无法正常工作（比如，当你在 Rails 应用中有本地 gems 或 engines 的时候）。

## [docker-compose.yml](https://github.com/evilmartians/terraforming-rails/blob/master/examples/dockerdev/docker-compose.yml)

[Docker Compose](https://docs.docker.com/compose/) 是一个编排容器环境的工具。它使我们能够相互链接容器、定义持久化 volumes 和 services。

下面是一个典型 Rails 应用程序开发环境的 compose 文件，使用 PostgreSQL 作为数据库，Sidekiq 作为后台任务处理器：

```yaml
version: '2.4'

services:
  app: &app
    build:
      context: .
      dockerfile: ./.dockerdev/Dockerfile
      args:
        RUBY_VERSION: '2.6.3'
        PG_MAJOR: '11'
        NODE_MAJOR: '11'
        YARN_VERSION: '1.13.0'
        BUNDLER_VERSION: '2.0.2'
    image: example-dev:1.0.0
    tmpfs:
      - /tmp

  backend: &backend
    <<: *app
    stdin_open: true
    tty: true
    volumes:
      - .:/app:cached
      - rails_cache:/app/tmp/cache
      - bundle:/usr/local/bundle
      - node_modules:/app/node_modules
      - packs:/app/public/packs
      - .dockerdev/.psqlrc:/root/.psqlrc:ro
    environment:
      - NODE_ENV=development
      - RAILS_ENV=${RAILS_ENV:-development}
      - REDIS_URL=redis://redis:6379/
      - DATABASE_URL=postgres://postgres:postgres@postgres:5432
      - BOOTSNAP_CACHE_DIR=/usr/local/bundle/_bootsnap
      - WEBPACKER_DEV_SERVER_HOST=webpacker
      - WEB_CONCURRENCY=1
      - HISTFILE=/app/log/.bash_history
      - PSQL_HISTFILE=/app/log/.psql_history
      - EDITOR=vi
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  runner:
    <<: *backend
    command: /bin/bash
    ports:
      - '3000:3000'
      - '3002:3002'

  rails:
    <<: *backend
    command: bundle exec rails server -b 0.0.0.0
    ports:
      - '3000:3000'

  sidekiq:
    <<: *backend
    command: bundle exec sidekiq -C config/sidekiq.yml

  postgres:
    image: postgres:11.1
    volumes:
      - .psqlrc:/root/.psqlrc:ro
      - postgres:/var/lib/postgresql/data
      - ./log:/root/log:cached
    environment:
      - PSQL_HISTFILE=/root/log/.psql_history
    ports:
      - 5432
    healthcheck:
      test: pg_isready -U postgres -h 127.0.0.1
      interval: 5s

  redis:
    image: redis:3.2-alpine
    volumes:
      - redis:/data
    ports:
      - 6379
    healthcheck:
      test: redis-cli ping
      interval: 1s
      timeout: 3s
      retries: 30

  webpacker:
    <<: *app
    command: ./bin/webpack-dev-server
    ports:
      - '3035:3035'
    volumes:
      - .:/app:cached
      - bundle:/usr/local/bundle
      - node_modules:/app/node_modules
      - packs:/app/public/packs
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - RAILS_ENV=${RAILS_ENV:-development}
      - WEBPACKER_DEV_SERVER_HOST=0.0.0.0

volumes:
  postgres:
  redis:
  bundle:
  node_modules:
  rails_cache:
  packs:
```

我们定义了八个 service。为什么要这么多？其中一些只是用来定义共享配置给别的 service 用而已（抽象 service，例如，`app`和`backend`），其他则用于使用应用程序容器（例如，`runner`）的特定命令。

使用这种方案，我们就不必使用`docker-compose up`命令来运行应用程序了，而是总能指定自己期望运行的确定 service 来运行（比如，`docker-compose up rails`）。这在开发时很有用，你很少需要所有 service 同时启动和运行（Webpacker、Sidekiq 等等）。

让我们来看看每个 service。

### app

该 service 的主要目的是提供所有需要的信息以构建我们的应用程序容器（定义在 Dockerfile 上方的部分）：

```yaml
build:
  context: .
  dockerfile: ./.dockerdev/Dockerfile
  args:
    RUBY_VERSION: '2.6.3'
    PG_MAJOR: '11'
    NODE_MAJOR: '11'
    YARN_VERSION: '1.13.0'
    BUNDLER_VERSION: '2.0.2'
```

`context`为 Docker 定义了 [build context](https://docs.docker.com/compose/compose-file/#context)：类似于 build 进程的工作目录，例如，它会被`COPY`命令用到。

我们明确指定了 Dockerfile 的路径，因为并没有把它放在项目根目录下，而是把所有 Docker 有关的文件一起放在一个隐藏目录`.dockerdev`内。

并且，如前所述，我们指定了那些依赖库的确切版本，它们在 Dockerfile 中用`args`所声明的。

一个我们应该注意的地方是我们对镜像打上 tag 的方式：

```bash
image: example-dev:1.0.0
```

在开发中使用 Docker 的一个好处就是在团队里自动同步这些配置的变动的能力。你只需要每次对本地镜像进行改动时升级其版本（或者在 arguments 或者在所依赖的文件）即可。最糟糕的则是使用`example-dev:latest`作为你的 tag。

保留镜像版本还有助于在两种不同的环境下工作，而不会带来任何其他麻烦。比如，当你在一个长期的“chore/upgrade-to-ruby-3”分支上工作时，能够很容易就切换到`master`分支并使用带旧 Ruby 版本的旧镜像，而无需重新构建任何东西。

**最糟糕的就是在你的`docker-compose.yml`中对镜像使用`latest`的 tag。**

我们也告知 Docker 在一个容器内为`/tmp`目录[使用 tmpfs](https://docs.docker.com/v17.09/engine/admin/volumes/tmpfs/#choosing-the-tmpfs-or-mount-flag) 以加快速度：

```yaml
tmpfs:
  - /tmp
```

### backend

我们来到了这篇博客中最有趣的部分。

该 service 定义了关于所有 Ruby service 的共享行为。

我们来先看下 volumes：

```yaml
volumes:
  - .:/app:cached
  - bundle:/usr/local/bundle
  - rails_cache:/app/tmp/cache
  - node_modules:/app/node_modules
  - packs:/app/public/packs
  - .dockerdev/.psqlrc:/root/.psqlrc:ro
```

该 volumes 列表的第一条是挂载当前工作目录（项目根目录）到容器内的`/app`目录，并使用了`cached`策略。该`/cached`修饰器是在 macOS 上提高 Docker 开发效率的关键。本文中我们不深入讨论这个（我们正在就此主题写另一篇文章😉），但你可以看看这个[文档](https://docs.docker.com/docker-for-mac/osxfs-caching/)。

下一行告诉容器使用一个名为`bundle`的 volume 来存储`/usr/local/bundle`的内容（这是[默认](https://github.com/infosiftr/ruby/blob/9b1f77c11d663930f4175c683b1c5f268d4d8191/Dockerfile.template#L47)存放 gems 的地方）。通过这种方式我们把 gems 数据在运行期间进行持久化：所有定义在`docker-compose.yml`中的 volumes 将保持 put 状态，直到我们运行`docker-compose down --volumes`为止。

下面三行也是为了摆脱“Docker 在 Mac 上慢”的诅咒。我们把所有生成的文件放置到 Docker 的 volumes 中以避免在 host 机器一方的繁重磁盘操作：

```yaml
- rails_cache:/app/tmp/cache
- node_modules:/app/node_modules
- packs:/app/public/packs
```

**要让 Docker 在 macOS 上足够快，遵循下面两条规则：使用`:cached`来挂载源文件和针对生成的内容（assets、bundle 等等）使用 volumes。**

最后一行添加了一个特定的`psql`配置到容器。我们经常需要保存其历史命令，这里存储到了 app 的`log/.psql_history`文件。为什么要在 Ruby 容器内执行`psql`？当你运行`rails dbconsole`时在内部就会用到。

我们的`.psqlrc`文件包含下面的技巧来使其通过环境变量指定历史文件路径成为可能（允许通过`PSQL_HISTFILE`环境变量指定历史文件路径，否则就为默认的`$HOME/.psql_history`）：

```bash
\set HISTFILE `[[ -z $PSQL_HISTFILE ]] && echo $HOME/.psql_history || echo $PSQL_HISTFILE`
```

让我们来谈下环境变量：

```yaml
environment:
  - NODE_ENV=${NODE_ENV:-development}
  - RAILS_ENV=${RAILS_ENV:-development}
  - REDIS_URL=redis://redis:6379/
  - DATABASE_URL=postgres://postgres:postgres@postgres:5432
  - WEBPACKER_DEV_SERVER_HOST=webpacker
  - BOOTSNAP_CACHE_DIR=/usr/local/bundle/_bootsnap
  - HISTFILE=/app/log/.bash_history
  - PSQL_HISTFILE=/app/log/.psql_history
  - EDITOR=vi
  - MALLOC_ARENA_MAX=2
  - WEB_CONCURRENCY=${WEB_CONCURRENCY:-1}
```

这里有好些东西，我重点谈一个。

首先是`X=${X:-smth}`的语法。其可以被翻译为“对于容器内的 X 变量，使用 host 机器的 X 环境变量值如果其存在的话，否则就用另一个值”。这样，我们让 service 运行在通过命令所提供的不同环境中就成为可能，例如，`RAILS_ENV=test docker-compose up rails`。

变量`DATABASE_URL`、`REDIS_URL`和`WEBPACKER_DEV_SERVER_HOST`把我们的 Ruby 应用连接到了其他 service。`DATABASE_URL`和`WEBPACKER_DEV_SERVER_HOST`变量是 Rails 原生所支持的（分别是 ActiveRecord 和 Webpacker）。某些库也支持`REDIS_URL`（Sidekiq），但并非所有（比如，Action Cable 必须明确配置才行）。

我们使用了[bootsnap](https://www.github.com/Shopify/bootsnap)来提升应用程序的加载时间，把其缓存存储于跟 Bundler 数据相同的 volume 中，因为这个缓存主要是包含 gems 数据；因此，我们在做另一次 Ruby 版本升级时，就应该一起删除所有内容。

`HISTFILE=/app/log/.bash_history`从开发者的 UX 角度看是很重要的设置：告诉 Bash 在指定位置存储其历史命令以使其持久化。

`EDITOR=vi`被用在，例如，`rails credentials:edit`命令管理 credentials 文件时。

最后，末尾两个设置，`MALLOC_ARENA_MAX`和`WEB_CONCURRENCY`，帮助你检查 Rails 内存的处理情况。

该 service 中尚未涵盖的是：

```yaml
stdin_open: true
tty: true
```

它们使得该 service 是可交互的，例如，提供 TTY。我们需要这个，比如，来运行 Rails console 或者在容器内的 Bash。

这跟使用`-it`选项来运行 Docker 容器是相同的。

### webpacker

这里我只想强调一点就是`WEBPACKER_DEV_SERVER_HOST=0.0.0.0`的配置：它让 Webpack dev server 从外部是可访问的（默认运行在`localhost`上）.

### runner

要解释该 service 的目的，让我来分享一下自己在开发时使用 Docker 的方式：

- 启动一个 Docker daemon，运行一个自定义的`docker-start`脚本：

```bash
#!/bin/sh

if ! $(docker info > /dev/null 2>&1); then
  echo "Opening Docker for Mac..."
  open -a /Applications/Docker.app
  while ! docker system info > /dev/null 2>&1; do sleep 1; done
  echo "Docker is ready to rock!"
else
  echo "Docker is up and running."
fi
```

- 然后我在项目目录下运行`dcr runner`（`dcr`是`docker-compose run`的 alias）以进入容器的 shell 中；这是下面命令的 alias：

```bash
$ docker-compose run --rm runner
```

- 我在这个容器内运行（几乎）一切：tests、migrations、Rake tasks，等等。

如你所见，我不是在需要运行一个任务时去开新容器，而是总使用同一个。

这样，我就如同多年前使用`vagrant ssh`那样来使用`dcr runner`了。

我之所以把它称为`runner`而不是`shell`，是因为它还可在容器内用来运行任意命令。

**注意：**`runner`这个 service 是一个品味问题，跟`web` service 相比，除了默认 `command`（`/bin/bash`）外，它并没有带来任何新东西；因此，`docker-compose run runner`跟`docker-compose run web /bin/bash`是一样的（除了短一些😉）。

## Health checks

当运行诸如`db:migrate`的常规 Rails 命令时，我们期望确认数据库已经启动并准备好连接了。如何告知 Docker Compose 等待所依赖的 service 直至就绪？我们可以使用[健康检查](https://docs.docker.com/compose/compose-file/compose-file-v2/#healthcheck)！

你可能已经注意到我们的`depends_on`定义并非 services 列表：

```yaml
backend:
  # ...
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy

postgres:
  # ...
  healthcheck:
    test: pg_isready -U postgres -h 127.0.0.1
    interval: 5s

redis:
  # ...
  healthcheck:
    test: redis-cli ping
    interval: 1s
    timeout: 3s
    retries: 30
```

注意：健康检查仅被 Docker Compose 文件格式在 v2.1 及更高版本以上支持；这就是我们用在开发中的原因了。

## 题外话：[dip.yml](https://github.com/evilmartians/terraforming-rails/blob/master/examples/dockerdev/dip.yml)

如果你仍然觉得 *Docker Compose* 的方式过于复杂，有一个叫做 [Dip](https://github.com/bibendi/dip) 的工具，是我在 Evil Martians 的同事开发的，目的是让开发体验更加顺滑。

如果你有多个 compose 文件或平台配置，那么它尤其有用，因为它可以把这些配置粘合到一起，并提供一个通用界面来管理 Docker 开发环境。

我们将在未来为你介绍有关它的更多内容，敬请关注！

注：特别感谢 [Sergey Ponomarev](https://github.com/sponomarev) 和 [Mikhail Merkushin](https://github.com/bibendi) 分享了有关该主题的技巧🤘

封面[图片](https://mars.nasa.gov/resources/1246/odyssey-views-a-surface-changed-by-floods/)：*© NASA/JPL-Caltech, 2009*

## Changelog

### 1.1.0 (2019-12-10)

- Change base Ruby image to `slim`.
- Specify Debian release for Ruby version explicitly and upgrade to `buster`.
- Use standard Bundler path (`/usr/local/bundle`) instead of `/bundle`.
- Use Docker Compose file format v2.4.
- Add health checking to `postgres` and `redis` services.

