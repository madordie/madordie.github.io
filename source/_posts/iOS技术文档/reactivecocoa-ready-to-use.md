---
title: 准备食用RAC(ReactiveCocoa)的顾虑
url: reactivecocoa-ready-to-use
date: 2016-07-12 09:53:14
tags:
    - ReactiveCocoa
categories:
      - iOS
---

对于目前的项目，如果引用RAC，会对项目造成哪些影响的相关思考。

<!--more-->

# 说明

众所周知，RAC很火，有很多崇拜者。本文只是一个新手第一次使用RAC时候所顾忌的一些问题，如果有比较好的解决方案及时告知我，我会及时更改。


# OC简单食用方法

先来个例子代码：

```objc

    RACSignal *RSignal = [[self.R rac_newValueChannelWithNilValue:@0] startWith:@(self.R.value)];
    RACSignal *GSignal = [[self.G rac_newValueChannelWithNilValue:@0] startWith:@(self.G.value)];
    RACSignal *BSignal = [[self.B rac_newValueChannelWithNilValue:@0] startWith:@(self.B.value)];

    NSString*(^valueFormat)(NSNumber *value) = ^(NSNumber *value) {
        return [NSString stringWithFormat:@"%.0f", [value doubleValue]*255];
    };
    
    [RSignal subscribeNext:^(id x) {
        self.RVaule.text = valueFormat(x);
    }];
    [GSignal subscribeNext:^(id x) {
        self.GValue.text = valueFormat(x);
    }];
    [BSignal subscribeNext:^(id x) {
        self.BValue.text = valueFormat(x);
    }];
    
```

是不是超级简单！


## 顾虑

可是我有一个问题：

- OC属于运行时语法，这个里面的`id x`的不确定因素可能会导致类型识别出现错误。如果说项目是多人维护，那么A可能不知道B写的Signal走的类型是什么，所以这个问题就不适用于松散的多人开发。如果需要使用RAC恐怕需要在项目启动时进行规避这些不确定的问题才能引入。


# Swift简单食用方法

在[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)的[README.md](https://github.com/ReactiveCocoa/ReactiveCocoa#objective-c-and-swift)中有这么一段话：

> ## Objective-C and Swift
>
  Although ReactiveCocoa was started as an Objective-C framework, as of [version
  3.0][CHANGELOG], all major feature development is concentrated on the [Swift API][].
>
  RAC’s [Objective-C API][] and Swift API are entirely separate, but there is
  a [bridge][Objective-C Bridging] to convert between the two. This
  is mostly meant as a compatibility layer for older ReactiveCocoa projects, or to
  use Cocoa extensions which haven’t been added to the Swift API yet.
>
  The Objective-C API will continue to exist and be supported for the foreseeable
  future, but it won’t receive many improvements. For more information about using
  this API, please consult our [legacy documentation][].
>
  **We highly recommend that all new projects use the Swift API.**
