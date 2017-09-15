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

这里大多数操作都是用脚本来进行的，不为别的，就为自由和以后～

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

嗯，开始创建工程，然后配置打包吧！

## 工程创建

左侧的`新建(New Item)`我就不说了吧～，点击输入项目名字，然后选择第一个`构建一个自由风格的软件项目`就行啦～～

此处项目名字暂且成为`test`。这里只说一些比较重要的，没有活不成的那种配置。别的自己研究一下或者点击右侧❓就能看到介绍。

### 源码管理

此处点击`Git`，展开之后输入`Repository URL`即可。

`Repository URL`输入完毕之后点击别处，Jenkins的Git插件会自动校验该URL是否能够clone下来代码。出现红色就自己根据错误修改一下咯。。

另外此处支持`ssh` 的方式，大致样式为：`ssh://sunjigang@github.com:29418/projects/aaa`。

`Branches to build` 写上你的构建分支～，根据自己需求来，`master`一般为仓库的默认分支。

### 构建触发器

此处表示该项目的构建触发条件。（可选）

我们这里说一下`Poll SCM`：

定时检查源码变更。条件是 一定要配置`Git`这样的源码管理。

例子：

- `H/15 * * * *`：每15分钟构建一次
- `0 2 * * *`： 每天2:00构建一次

### 构建

此处为构建的核心😂。当然，我们为了自由，此处全部使用`shell`脚本。

```sh
# 工程名
workspace='xxx.xcworkspace'
# 构建scheme
scheme='xxx'
# 打包类型：app-store, ad-hoc, package, enterprise, development, and developer-id.
export_method='enterprise'
# fir的token，在fir->用户->token 获取
fir_token='c5077e0368888b9750ae848b9fe00***'
# fir上传短链接，效果为 https://fir.im/xxx
fir_url='xxx'
# 钉钉机器人token
dingtalk_token='6d09e43ddc62e540be914ff2e901e28b921d55c5ad457f6f3571f9f881287***'
# 钉钉机器人发送的内容
dingtalk_content="iOSXXX已经上传至 http://fir.im/${fir_url} ,吧啦吧啦吧啦～"

# 构建
fastlane gym
    --workspace $workspace \
    --scheme $scheme \
    --export_method $export_method \
    clean

# fir
ipa=$(pwd)/$(ls *.ipa)
git log -10 > git.log
fir p $ipa -T $fir_token -s $fir_url -c git.log

# 钉钉通知
curl "https://oapi.dingtalk.com/robot/send?access_token=${dingtalk_token}" -H 'Content-Type: application/json'    -d '
    {"msgtype": "text",
        "text": {
            "content":${dingtalk_content}
        }
    }'
```

至此 已经完成了打包、上传fir、钉钉机器人通知。

上述脚本只是配置的例子，可以根据自己需求，自己编写和配置。特别是

- `.xcworkspace`的位置，要找清楚呀
- `scheme`无法找到是因为你在提交代码的时候没有将其设置为shared
- `fastlane gym` 支持很多参数，是对`xcodebuild`的封装，[源码及文档在此](https://github.com/fastlane/fastlane/tree/master/gym)

### 上传dsym至Bugly

这个还是有点点复杂的，因为bugly并未提供完整的cli工具链，需要手动跑jar包。不过都是可以完成的。


