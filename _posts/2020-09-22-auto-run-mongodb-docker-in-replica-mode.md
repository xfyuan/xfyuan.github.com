---
layout: post
title: 自动运行MongoDB Docker为Replica模式
author: Mr.Z
categories: [ Tool ]
tags: [docker, mongodb]
comments: true
image: "https://i.loli.net/2020/09/22/t2ri8TQV6DhPUpN.jpg"
---

最近工作中碰到一个有意思的问题：需要让 MongoDB 的 Docker 镜像以 Replica 模式运行起来。而官方 MongoDB 的 Docker 镜像默认是单机而非 Replica 模式。当然，如果你启动 Docker 后再进入容器内，手动修改配置生效，肯定能搞定。但毫无疑问这是效率很低的做法。如何让这一切自动实现，而不是每次重新运行 MongoDB 都手工去改？

其实，官方 MongoDB Docker 页面已经指出了解决方向。如下图：

![aJi38q9bnFp4r5g](https://i.loli.net/2020/09/22/aJi38q9bnFp4r5g.jpg)

意思是说在启动时，位于`/docker-entrypoint-initdb.d`目录下的`.sh, .js`文件都会被自动作为配置读取生效。

所以，我们需要本地 Build 一下 MongoDB，并先写好所需要的配置文件，在 Build 时把该配置文件放入上述目录内，最后生成的镜像就能实现自动 Replica 模式的启动。

直接上最终的`Dockerfile`：

```dockerfile
ARG MONGODB_VERSION

FROM mongo:$MONGODB_VERSION
ADD ./dockerize/mongo/init_replicaset.js /docker-entrypoint-initdb.d/init_replicaset.js
CMD ["mongod", "--replSet", "mongoreplset", "--bind_ip_all"]
```

和配置文件`init_replicaset.js`：

```js
rs.initiate({'_id':'mongoreplset', members: [{'_id':0, 'host':'127.0.0.1:27017'}]});
```

就是这样了。