---
title: iOS11-beta
date: 2017-06-12 17:20:58
tags:
categories:
    - iOS
---

iOS11 预览版安装体验笔记。

<!--more-->

## 写在前面

毕竟beta版，升级需谨慎。目前来看体验上还是有点卡的～～😂

卡顿让我实在无法忍受，并与6.15号重置回iOS10.3.2 。。。

9.13 GM出来了，再安装～～

适配有先后，iOS11马上就要发了，而iPhoneX还需要等一小段时间。所以iOS11的适配比iPhoneX有更高的优先级～

## API

### 失效的`automaticallyAdjustsScrollViewInsets`

iOS11 版本中 __立即失效__。

最容易出问题的就是无导航的顶部刷新会莫名其妙的缩不进去～～

API 声明：

``` swift
@available(iOS 2.0, *)
open class UIViewController : UIResponder, ... {
	...
	@available(iOS, introduced: 7.0, deprecated: 11.0)
	open var automaticallyAdjustsScrollViewInsets: Bool // Defaults to YES
	...
}
```

相应的的替换方案：

```swift
@available(iOS 2.0, *)
open class UIScrollView : UIView, ... {
	...
    /* Configure the behavior of adjustedContentInset.
     Default is UIScrollViewContentInsetAdjustmentAutomatic.
     */
    @available(iOS 11.0, *)
    open var contentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentBehavior
    ...
}
```
### 筛选view

### WKWebView

