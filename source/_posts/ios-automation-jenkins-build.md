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

## 插件安装

所有的插件可以在`系统管理 -> 插件管理`中进行安装、卸载、降级、更新、等操作。

确保以下插件已经被安装：

- 源代码管理：[Git Plugin](https://wiki.jenkins.io/display/JENKINS/Git+Plugin)
- 编译脚本环境变量：[Tool Environment Plugin](http://wiki.hudson-ci.org/display/HUDSON/Tool+Environment+Plugin)

嗯，开始创建工程，然后配置打包吧

