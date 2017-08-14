---
title: iOS逆向-monkeydev工具
date: 2017-08-14 11:05:57
tags:
    - 逆向
categories:
    - iOS
---

> MonkeyDev wiki
> 这是一个为越狱和非越狱开发人员准备的工具，主要包括四个模块:

>  Logos Tweak

> 使用theos提供的logify.pl工具将*.xm文件转成*.mm文件进行编译，集成了CydiaSubstrate，可以使用MSHookMessageEx和MSHookFunction来Hook OC函数和指定地址。

> CaptainHook Tweak

> 使用CaptainHook提供的头文件进行OC 函数的Hook，以及属性的获取。

> Command-line Tool

> 可以直接创建运行于越狱设备的命令行工具

> MonkeyApp

> 这是自动给第三方应用集成Reveal、Cycript和注入dylib的模块，支持调试dylib和第三方应用，支持Pod给第三放应用集成SDK，只需要准备一个砸壳后的ipa或者app文件即可。

<!--more-->


---
- [MonkeyDev wiki](https://github.com/AloneMonkey/MonkeyDev/wiki)
