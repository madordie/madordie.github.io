---
title: iOS逆向-class-dump工具
date: 2017-08-10 12:40:27
tags:
categories:
    - iOS
    - 逆向
---

## 安装class-dump

去[stevenygard.com](http://stevenygard.com/projects/class-dump/)下载最新的包。

将包中的`class-dump`可执行文件复制到`/opt/class-dump`。(我的逆向相关工具均在这下面😂）

在`~/.base_profile`中添加`export PATH=/opt/class-dump:$PATH`

运行`source ~/.base_profile`

最后确认一下安装OK ：

```shell
$ class-dump --v
class-dump 3.5 (64 bit) compiled Nov 16 2013 12:22:33
```

<!--more-->

## 功能

使用一个记录一个吧～

### 用来导出`ipa`/`.decrypted`头文件

此处只能导出未加密的`ipa`，或者砸过壳的。[具体砸壳过程传送门](https://madordie.github.io/reverse-ios-dump-decrypted/)

```shell
$ ls WeChat.decrypted
WeChat.decrypted
$ class-dump -H WeChat.decrypted -o ./Headers/
$ ls Headers
Headers
```

即得头文件目录：`Headers`

