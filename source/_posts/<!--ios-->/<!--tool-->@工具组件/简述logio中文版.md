---
title: 实时显示日志logio
url: logio-brief-zh-cn
date: 2019-5-22
tags:
    - tool
    - logio
categories:
    - iOS
    - macOS
    - 工具
---

# log.io

一个能在浏览器上实时显示日志的工具。

<!--more-->

# 工作原理

以下摘自[logio.org](http://logio.org/)，我觉得已经非常的详细了，这里就不啰嗦了。

> Harvesters watch log files for changes, send new log messages to the server, which broadcasts to web clients. Log messages are tagged with stream, node, and log level information based on user configuration.
>
> Log.io has no persistence layer. Harvesters are informed of file changes via inotify, and log messages hop from harvester to server to web client via TCP and socket.io, respectively.
>
> ![work io](/images/2019-05-17-10-03-13.png)
> ![Activate streams & nodes to watch log messages](/images/2019-05-17-10-12-25.png)

## <a name="Simple TCP interface">通信使用的TCP接口</a>

> Log.io uses a stateless TCP API to receive log messages.
>
> Writing a third party harvester is easy. Open a TCP connection to the > server and begin writing properly formatted messages to the socket.
>
> Read the [API documentation](https://github.com/NarrativeScience/Log.io).

### 消息发送

```
+log|my_stream|my_node|info|this is log message\r\n
```

### 注册一个新的node和stream

如果原来已经存在，那么还是原来的那个。

```
+node|my_node|my_stream1,my_stream2\r\n
```

### 删除node

```
-node|my_node\r\n
```

# 安装Log.io服务端

这个年久失修的原始项目[NarrativeScience/Log.io](https://github.com/NarrativeScience/Log.io)已经没办法正常工作了。。

幸运的是，docker版本的[blacklabelops-legacy/logio](https://github.com/blacklabelops-legacy/logio)还可以用，所以我们就用这个吧。

## 安装并开启docker

docker的文档[docs.docker.com](https://docs.docker.com/install/)依旧非常详细，不再赘述。

值得一提的是支持的平台有很多，比如：[Cloud](https://docs.docker.com/install/)、 [MacOS](https://docs.docker.com/docker-for-mac/install/) 、[Linux](https://docs.docker.com/install/) 、 [Windows](https://docs.docker.com/docker-for-windows/install/)

## pull 镜像

```sh
$ docker pull blacklabelops/logio
```

## 开启服务

```sh
$ docker run -d \
    -p 28778:28778 \
    -p 28777:28777 \
    --name logio \
    blacklabelops/logio
```

值得一提的是，原文档[blacklabelops-legacy/logio](https://github.com/blacklabelops-legacy/logio)中是没有`-p 28777:28777`参数的，会导致其28777端口无响应，应该是一个手误或者特殊需要？反正这里打开就好了。

## 其他配置

其他配置在[blacklabelops-legacy/logio](https://github.com/blacklabelops-legacy/logio)中也很详细😂，需要的请自取。比如说日志、https、等

## 最终效果图

在浏览器上打开http://localhost:28778/即可。（localhost 是安装server的IP）
![log.io server](/images/2019-05-17-10-40-18.png)

于是乎，我们就可以向localhost:28778疯狂的写日志了. 🎉🎉🎉

# 支持的插件

这个日志服务<a href="#Simple TCP interface">对外接口</a>比较简单，所以理论上来讲，只需要可以进行TCP通信的包均可以支持，包括但不限于安卓、iOS。

## iOS

[logio for iOS](https://github.com/madordie/logio)

iOS上之前有一个类似的[LogIO-CocoaLumberjack](https://github.com/s4nchez/LogIO-CocoaLumberjack), 我这里做了简单的更新，目的是不绑定[CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)。

-----

- [logio.org](http://logio.org/)