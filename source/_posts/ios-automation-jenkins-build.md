---
title: iOS自动化-Jenkins编译工程
date: 2017-09-14 17:27:15
tags:
    - 构建
    - Jenkins
categories:
    - iOS
---

[忙于iOS11的兼容](../ios11-beta/)

- [iOS自动化-Jenkins环境搭建](../ios-automation-jenkins-configuration)
- [iOS自动化-Jenkins编译工程](../ios-automation-jenkins-build)

## 介绍

Jenkins环境已搭建好，现在我们来开始愉快的为iOS打包吧～

从这个文章中你将要实现以下功能：

- 在Jenkins创建工程
- build出ipa
- 将ipa上传至fir
- 钉钉机器人群通知
- 将dsym上传至bugly

<!--more-->

## 脚本环境安装

这里大多数操作都是用脚本来进行的，不为别的，就为自由～

### fastlane

此乃自动化神器。[文档在此](https://docs.fastlane.tools)。[开源哟～](https://github.com/fastlane/fastlane)

此处主要用来编译、打包。

安装方法：

```sh
$ brew cask install fastlane
```

此神器除了上述功能，还提供很多很多很多很多功能，包括自定义神马的都支持。需要的可以去文档里面翻翻。

### fir.im-cli

[fir.im](https://fir.im)提供的应用内测托管工具。[开源官网](https://github.com/FIRHQ/fir-cli/blob/master/README.md)。

安装方法：

```sh
$ gem install fir-cli
```

此工具也提供打包ipa、apk、上传符号表至BugHD、等功能。但是我们在这里选择了`fastlane gym`

上传加速：

```sh
$ sh -c "$(curl -sSL https://gist.githubusercontent.com/trawor/5dda140dee86836b8e60/raw/turbo-qiniu.sh)"
```

上传加速代码已经[开源至此](http://blog.fir.im/turbo-qiniu/)。

[BugHD](http://bughd.com): 已停止线上免费服务，开始卖私有部署了。

另外，fir 也有[Jenkins插件](http://blog.fir.im/jenkins/)，但是这里选择脚本方式。

## 插件安装

所有的插件可以在`系统管理 -> 插件管理`中进行安装、卸载、降级、更新、等操作。

确保以下插件已经被安装：

- 源代码管理：[Git Plugin](https://wiki.jenkins.io/display/JENKINS/Git+Plugin)
- 编译脚本环境变量：[Tool Environment Plugin](http://wiki.hudson-ci.org/display/HUDSON/Tool+Environment+Plugin)

嗯，开始创建工程，然后配置打包吧

