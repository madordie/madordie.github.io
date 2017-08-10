---
title: Fastlane自动化笔记
date: 2017-01-04 18:14:07
tags:
categories:
  - Fastlane
---

之前在搭建Jenkins的时候，由于看到Fastlane的配置好复杂，那么多，而当时的需求就是自动打包。。所以没有用，现在想来好气！今天翻到InfoQ的一个文章，又详细的了解了Fastlane之后，觉得此大法甚好，解决很多痛点！决定搞通这一切！
回看之前的[build-ipa-sh.md](https://madordie.github.io/build-ipa-sh)确实比较僵硬。自动化还是很棒的。

<!--more-->

# 基本知识
  ([@icyleaf](http://icyleaf.com))在[Fastlane - iOS 和 Android 的自动化构建工具](https://icyleaf.com/2016/07/intro-fastlane-automation-for-ios-and-android/)中说到：
  > Fastlane 提供的流程的众多工具都是可以独立存在和使用（提供 cli 命令），也可以统一由 fastlane 来控制。它在使用中提出了两个概念：
  >
    - action: Fastlane 的插件，截至当前内置 165 个至多，不过每个动作的颗粒度大小不一。查看详情
    - lane: Fastlane 的任务（或者可以理解为命令），一个可以包含多个 lanes，通过 fastlane cli 传入制定的 lane 来执行。

  自我感觉这句话这个对理解和使用很重要！
  

# 配置
  Fastlane已被Fabric收购，所以按照其安装也很随意([戳我配置](https://fabric.io/features/distribution))。
  对于打包，
  
# 文章
  - [深入浅出 Fastlane 一看你就懂](http://icyleaf.com/2016/07/fastlane-in-action/)
  - [fir.im weekly - 「 持续集成 」实践教程合集](http://blog.fir.im/fir_im_weekly160505)
  - [使用fastlane实现iOS持续集成](https://everettjf.github.io/2015/09/08/ios-ci-with-fastlane)
  - [fastlane docs](https://docs.fastlane.tools)
  - [fastlane GitHub](https://github.com/fastlane/fastlane)
  - [Fastlane实战（一）：移动开发自动化之道](http://www.infoq.com/cn/articles/actual-combat-of-fastlane-part01)
  - [Fastlane实战（二）：Action和Plugin机制](http://www.infoq.com/cn/articles/actual-combat-of-fastlane-part02)
  - [Fastlane实战（三）：Fastlane在Android平台的应用](http://www.infoq.com/cn/articles/actual-combat-of-fastlane-part03)
  - [Fastlane实战（四）：自动化测试篇](http://www.infoq.com/cn/articles/fastlane-automatic-testing)
  - [Fastlane实战（五）：高级用法](http://www.infoq.com/cn/articles/fastlane-pro-tips)
  
