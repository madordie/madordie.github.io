---
title: logio
url: logio-brief
date: 2019-5-17
tags:
    - tool
    - logio
categories:
    - iOS
    - macOS
    - 工具
---

# log.io

Real-time log monitoring in your browser.

<!--more-->

# How does it work

> Harvesters watch log files for changes, send new log messages to the server, which broadcasts to web clients. Log messages are tagged with stream, node, and log level information based on user configuration.
>
> Log.io has no persistence layer. Harvesters are informed of file changes via inotify, and log messages hop from harvester to server to web client via TCP and socket.io, respectively.
>
> ![work io](/images/2019-05-17-10-03-13.png)

# Activate streams & nodes to watch log messages

> ![Activate streams & nodes to watch log messages](/images/2019-05-17-10-12-25.png)

# <a name="Simple TCP interface">Simple TCP interface</a>

> Log.io uses a stateless TCP API to receive log messages.
>
> Writing a third party harvester is easy. Open a TCP connection to the > server and begin writing properly formatted messages to the socket.
>
> Read the [API documentation](https://github.com/NarrativeScience/Log.io).

## Send a log message:

```
+log|my_stream|my_node|info|this is log message\r\n
```

## Register a new node, with stream associations

```
+node|my_node|my_stream1,my_stream2\r\n
```

## Remove a node

```
-node|my_node\r\n
```

# Install Log.io

The original project [NarrativeScience/Log.io](https://github.com/NarrativeScience/Log.io) has been unavailable due to lack of maintenance for a long time.

Fortunately, the [blacklabelops-legacy/logio](https://github.com/blacklabelops-legacy/logio) can also be used.

So we can install the project like this：

## Install and start docker

The [docs.docker.com](https://docs.docker.com/install/) is very detailed.

Support [Cloud](https://docs.docker.com/install/)、 [MacOS](https://docs.docker.com/docker-for-mac/install/) 、[Linux](https://docs.docker.com/install/) 、 [Windows](https://docs.docker.com/docker-for-windows/install/)

## Pull image

```sh
$ docker pull blacklabelops/logio
```

## Start the server

```sh
$ docker run -d \
    -p 28778:28778 \
    -p 28777:28777 \
    --name logio \
    blacklabelops/logio
```

## Other configure

[blacklabelops-legacy/logio](https://github.com/blacklabelops-legacy/logio).

# Complete

Browser: http://localhost:28778/
![log.io server](/images/2019-05-17-10-40-18.png)

Now we can write logs to port 28777. 🎉🎉🎉

# Plugins

We only need to perform TCP communication according to the rules <a href="#Simple TCP interface">Simple TCP interface</a>, and the log can be displayed on the browser.

## iOS

[logio for iOS](https://github.com/madordie/logio)

-----

- [logio.org](http://logio.org/)