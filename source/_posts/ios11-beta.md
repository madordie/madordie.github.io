---
title: ios11-beta
date: 2017-06-12 17:20:58
tags:
---

iOS11 预览版安装体验笔记。

<!--more-->

## 写在前面

毕竟beta版，升级需谨慎。目前来看体验上还是有点卡的～～😂

卡顿让我实在无法忍受，并与6.15号重置回iOS10.3.2 。。。

## API

### 失效的`automaticallyAdjustsScrollViewInsets`

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

iOS11 版本中立即失效。