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

![效果图](/images/ios11-beta-1.jpg)

还有就是如果没有使用这个`automaticallyAdjustsScrollViewInsets`，为了达到那种戳进去的代码直接设置`frame.y = 0`。这种操作不但会出现导航栏莫名其妙的戳出来，还有`UITableView.section.header`莫名错位的问题。

![效果图](/images/ios11-beta-2.gif)

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
### `decisionHandler(.allow)` was called more than once

崩溃信息：

```
#0 Thread
NSInternalInconsistencyException
Completion handler passed to -[WKWebViewJavascriptBridge webView:decidePolicyForNavigationAction:decisionHandler:] was called more than once
```
这是[WebViewJavascriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge)在iOS11上的一个[Issues#302](https://github.com/marcuswestin/WebViewJavascriptBridge/issues/302)。

据同事说可以通过如下代码解决：
```swift
if WebViewJavascriptBridgeBase().isWebViewJavascriptBridgeURL(url) {
    return
}
decisionHandler(.allow)
```

测试了一下确实不崩溃了，但是具体的解决方案还要看作者的在[Issues#302](https://github.com/marcuswestin/WebViewJavascriptBridge/issues/302)中的回复。


### WKWebView

