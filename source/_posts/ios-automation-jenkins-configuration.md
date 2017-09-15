---
title: iOS自动化-Jenkins环境搭建
date: 2017-09-10 09:49:32
tags:
    - 构建
    - Jenkins
categories:
    - iOS
---

- [iOS自动化-Jenkins环境搭建](../ios-automation-jenkins-configuration)
- [iOS自动化-Jenkins编译工程](../ios-automation-jenkins-build)

## 介绍

>  **Jenkins**
> *Build great things at any scale*
> The leading open source automation server, Jenkins provides hundreds of plugins to support building, deploying and automating any project.

如[官网](https://jenkins.io)所说`Build great things at any scale`

<!--more-->

## 安装

当然你首先需要一个macOS的系统，为后来的构建做基础。

Jenkins中可以使用`pkg`、`war`的方式运行，当然还有在[Installing Jenkins](https://jenkins.io/doc/book/getting-started/installing/)中提供一些安装方式：

>  **macOS**
To install from the website, using a package:

> - Download the latest package
> - Open the package and follow the instructions

> Jenkins can also be installed using brew:

> - Install the latest release version
> ```sh
brew install jenkins
```
> - Install the LTS version
>```sh
brew install jenkins-lts
```

这里使用`brew`，因为**很方便**：
```sh
# 安装
$ brew update && brew install jenkins

# 更新
$ brew update & brew upgrade jenkins

# 后台运行 还支持`stop`、`restart`等 (这种方式还是有差别的，下面会说明)
$ brew services start jenkins
```

## 运行

建议先来看一波`--help`

```sh
$ jenkins --help
```

下面是常用的几种方案，此处如果第一次安装，建议采用`方案一`或者`方案二`，暂时不建议新手使用后台运行的方案～～（会在打包的时候出现证书的问题）

### 方案一

直接运行`jenkins`命令，可以看到日志输出，但是不能退出命令。

```sh
$ jenkins
```

经过漫长的初始化，会将

- `~/.jenkins`目录作为`JENKINS_HOME`
- `localhost:8080`作为默认URL

终端输出`Started initialization`一行之后就可以正常打开了。

在浏览器打开[http://10.12.12.10:8080](http://10.12.12.10:8080)就可以正常加载啦～

退出运行：`control + C` 组合键。

### 方案二

直接`open`，看不到日志输出，所对应的运行环境和方案一相同。

```sh
$ open /usr/local/opt/jenkins/libexec/jenkins.war
```

命令结束，稍等片刻(初始化相关目录、环境)，在浏览器打开[http://10.12.12.10:8080](http://10.12.12.10:8080)就可以正常加载啦～

### 方案三

使用`brew`直接挂在后台作为服务运行起来

```sh
$ sudo brew services start jenkins
```

`brew`还提供其他的参数，比如说`restart`、`list`、`stop` 等等。

此方案和上面的运行环境是不一样的，会有些权限的差别。

### 其他方案

使用`launchctl`、`nohup` 等其他方案进行的后台运行，同方案三差不多。

需要说的是`launchctl`是macOS下系统提供的后台运行方案，`brew`等，均来自于此。

在`launchctl`后台中需要一个`plist`，但是`brew`已经做好了，放置在`~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist`。需要说的是`launchctl`是macOS下系统提供的后台运行方案，`brew`等，均来自于此，具体的配置参数都和`launchctl`一样的，搜索一下很多。`brew`为我们已经准备好了一个，直接使用`方案三`就行。

具体操作可以Google一下，很多的～

## 安装完成后的配置

在Jenkins初始化完毕为了验证管理员身份，需要将Jenkins机器上的一个字符串输入到[http://10.12.12.10:8080](http://10.12.12.10:8080)中进行验证，具体文件目录在输入的界面就能看到，不要大惊小怪。

之后开始选择安装插件。这里可以选择推荐的～～，也可以自己勾选。为了方便，这里直接选择推荐的方案进行安装。

经过漫长的等待，终于将插件安装完毕，并启动了起来～～

接下来开始去配置工程吧！传送门：[iOS自动化-Jenkins编译工程](../ios-automation-jenkins-build)

## 可能会碰到的错误

### Error: Permission denied - ***

```sh
$ brew services start jenkins
Error: Permission denied - ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
```
这种很明显`Permission denied`，在命令行前添加`sudo`，然后输入密码即可。如下：

```sh
$ sudo brew services start jenkins
```

### `方案二`后的地址哪里来的？

这里推荐的安装方案是`brew install jenkins`

通过下面的方式找到`brew`安装的位置

```sh
$ $ brew services list
Name       Status  User Plist
beanstalkd stopped
influxdb   stopped
jenkins    started keith  ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
nginx      stopped
sonarqube  stopped
FDDdeiMac:~ FDD$ cat ~/Library/LaunchAgents/homebrew.mxcl.jenkins.plist
...
<string>/usr/local/opt/jenkins/libexec/jenkins.war</string>
...
```
