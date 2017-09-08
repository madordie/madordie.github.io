---
title: 如何正确的连续推新页面
date: 2016-02-17 15:03:12
tags:
    - Debug
categories:
    - iOS
---

## 题记

当使用某个页面还没有进行viewDidAppear:的时候再进行一次推页面是不安全的。苹果在iPhone5C iOS7.1.2中Push时给出的警告：

> “nested push animation can result in corrupted navigation bar. Finishing up a navigation transition in an unexpected state. Navigation Bar subview tree might get corrupted.”

这说明这个不安全的操作可能会导致应用Crash，Crash统计系统统计的原因为：

> “Can't add self as subview”。

本文尝试解决该Crash，实现嵌套安全的去推页面。

<!--more-->

## 问题所在

苹果给出的警告中指出嵌套推页面可能导致导航栏损坏，其导航栏子视图树可能损坏。也就是说当我对VC1进行Push出VC2时候要注意，必须要等到VC1显示周期完全结束，才能进行PushVC2操作。

此问题的发生并不是简单的一个代码块中使用同一个导航控制器进行连续Push操作。回想一下`ViewController`的生命周期。其实标志着`ViewController`完全显示的是`viewDidAppear:`调用，那么在此方法生命周期之前的方法中进行Push均有可能造成“nested push animation can result in corrupted navigation bar”。

由于iOS7.1.2的iPhone5C被升级，无法必现此BUG，所以没有截图。可以自己找个测一下。。

## 解决方案

### 方案一：通过延时避开此时间段。

在很多源码中会看到这样一行代码：

```oc
//  0.1是我随手写的。。是一个根据自己情况估算上一个PUSH的耗时，
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.navigationController pushViewController:vc animated:YES];
});
```

如上代码，在[GitHub中很常见](https://github.com/search?utf8=✓&q=dispatch_after+pushViewController%3A&type=Code&ref=searchresults)，起初并不懂其用意，当遇到这个问题时候我才明白。

还有一种代码：

```oc
//  objccn.io
dispatch_async(dispatch_get_main_queue(), ^{
    // Some UIKit call that had timing issues but works fine
    // in the next runloop.
    [self updatePopoverSize];
});
```
这种代码是切换到下个代码周期，来避开嵌套的时序问题。[objc.io](https://objccn.io/issue-2-4/)有这么个文章说了这个问题的弊端：

> 用 `dispatch_async` 修复时序问题

> 在使用 UIKit 的时候遇到了一些时序上的麻烦？很多时候，这样进行“修正”看来非常完美：

> ```oc
dispatch_async(dispatch_get_main_queue(), ^{
    // Some UIKit call that had timing issues but works fine
    // in the next runloop.
    [self updatePopoverSize];
});
```
千万别这么做！相信我，这种做法将会在之后你的 app 规模大一些的时候让你找不着北。这种代码非常难以调试，并且你很快就会陷入用更多的 dispatch 来修复所谓的莫名其妙的"时序问题"。审视你的代码，并且找到合适的地方来进行调用（比如在 viewWillAppear 里调用，而不是 viewDidLoad 之类的）才是解决这个问题的正确做法。我在自己的代码中也还留有一些这样的 hack，但是我为它们基本都做了正确的文档工作，并且对应的 issue 也被一一记录过。

记住这不是真正的 `GCD` 特性，而只是一个在 `GCD` 下很容易实现的常见反面模式。事实上你可以使用 `performSelector:afterDelay:` 方法来实现同样的操作，其中 `delay` 是在对应时间后的 `runloop`。

其实这样设计很简单，目的就是通过`GCD`的延迟提交来“巧妙”的避开Push的时间，很显然这个时间对于机型、系统版本、当前手机状况来说很难把握。但是不得不说的是确实有些作用，那就是能避开部分问题。所以本来小概率发生的事情，这个再过滤一些，这个BUG就微乎其微了。

### 方案二：强制在`viewDidAppear:`之后进行Push。

不得不说这样的做法我曾经用过一个页面，不多说，麻烦程度自己测一下。

如果说多人合作项目呢，如果说页面比较多、工作比较忙呢？呵呵哒

### 方案三：对`UINavigationController`所Push的VC进行队列化。

对于VC是否已经Push结束，`UINavigationController`最清楚，而这一结果刚好通过代理传递出来。所以可以利用这一点对Push的VCs进行队列化，防止其进行嵌套Push。

那么问题就可以得到很好的解决。

对 方案三 的详细封装

对于该问题的最简单的、便于合作、便于更改的就是方案三了，对方案三进行展开可得如下步骤：

设置`UINavigationController`的代理，并实现`willShowViewController`、`didShowViewController`方法。

拦截到`UINavigationController`的Push方法，通过步骤1的代理判断到是否正在Show,如果不在Show则显示，如果正在Show则把当前的VC入队列。
在didShowViewController中判断队列中是否有数据，如果有则说明发生了重叠，该队列中第一个进行Push。
为了更好的兼容所遇到的Push情况，使用0.5秒作为兜底，对队列进行放开。
结束，就是这样子。

说下我实现的方法，其实重点在于如何拦截Push操作。

我最开始采用了继承`UINavigationController`的方法，因为继承但一，不会干扰其他的类。值得一赞。

对于要解决其问题，所有的都需要进行继承，过于麻烦，于是增加了第二种方案：HOOK。

两种方案为了达到统一的效果，所以拉出其中的代理，就完成了统一。

[代码＋Demo](https://github.com/madordie/KTJPushQueueForNavigation.git)