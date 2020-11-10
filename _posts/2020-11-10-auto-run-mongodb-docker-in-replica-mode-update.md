---
layout: post
title: 自动运行MongoDB Docker为Replica模式（新）
author: Mr.Z
categories: [ Tool ]
tags: [docker, mongodb]
comments: true
image: "https://cdn.jsdelivr.net/gh/xfyuan/ossimgs@master/uPic/IMG_20201107_133102.jpg"
---

在[前一篇博客《自动运行MongoDB Docker为Replica模式》](https://xfyuan.github.io/2020/09/auto-run-mongodb-docker-in-replica-mode/)中，提到了如何自动实现让 MongoDB 在 docker 中以 Replica 模式运行的做法。但最近发现，当时的做法是有点问题的——如果跟其他 docker 镜像用`docker-compose`搭成环境后，其他的 docker 容器无法正常连接到该 MongoDB 使用。

经过一番查询，问题原因很简单。大概是由于`docker-compose` 在启动所有 docker 容器时，构建自身整体的 Network 需要一定时间，而 MongoDB 的 Replica 设置是立即读取生效的，所以 MongoDB 在被启动时还不能正确读取到 Network 的环境配置，从而造成其他容器无法连接到它。

最后，是通过一种比较取巧的方法来绕过了这个问题。即让 MongoDB 启动后不断检测其 Network 环境是否已经正确，直到当其准备好为止，这时再自动触发运行 Replica 模式的 MongoDB，就可以提供正常的服务连接了。

相关的`Dockerfile`配置文件和脚本如下：

#### Dockerfile

```dockerfile
ARG MONGODB_VERSION

FROM mongo:$MONGODB_VERSION
RUN apt-get update -qq && apt-get install -yq netcat

ADD init_replicaset.js /docker-entrypoint-initdb.d/init_replicaset.js
ADD resolve_replicaset_host.sh /root/resolve_replicaset_host.sh

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /usr/local/bin/wait-for-it
RUN chmod +x /usr/local/bin/wait-for-it

CMD bash -c "mongod --replSet mongoreplset --bind_ip_all && wait-for-it -t 0 mongo:27017 -- /root/resolve_replicaset_host.sh"
```

#### init_replicaset.js

```js
rs.initiate({'_id':'mongoreplset', members: [{'_id':0, 'host':'127.0.0.1:27017'}]});
```

#### resolve_replicaset_host.sh

```bash
#!/bin/bash

mongo --eval "rs.initiate({'_id':'mongoreplset','members':[{'_id':0,'host':'mongo:27017'}]})"
```

这里用到了 [https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh](https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh) 这个工具，用来不断测试连接`mongo:27017`是否就绪，如果可以正确连接，就会自动运行`/root/resolve_replicaset_host.sh`这个脚本，设置 MongoDB 以 Replica 模式运行起来。

**当然，还有最后和最重要的一步：**

修改`/etc/hosts`，添加如下一行

```
127.0.0.1 mongo
```

最终测试结果一切工作正常。完美！