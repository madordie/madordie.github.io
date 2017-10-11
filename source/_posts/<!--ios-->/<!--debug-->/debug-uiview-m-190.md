---
title: DEBUG - UIView.h#190
url: debug-uiview-m-190
date: 2016-10-11 12:43:22
tags:
    - DEBUG
categories:
    - iOS
---

CRASH:
`void UIViewReportBrokenSuperviewChain(UIView *__strong, UIView *__strong, BOOL)()`

<!--more-->

# UIView.m:190 - UIViewReportBrokenSuperviewChain

## 异常信息：
  ```
  *** Assertion failure in void UIViewReportBrokenSuperviewChain(UIView *__strong, UIView *__strong, BOOL)(), /BuildRoot/Library/Caches/com.apple.xbs/Sources/UIKit/UIKit-3599.6.1/UIView.m:190
  invalid mode 'kCFRunLoopCommonModes' provided to CFRunLoopRunSpecific - break on _CFRunLoopError_RunCalledWithInvalidMode to debug. This message will only appear once per execution.
  libc++abi.dylib: terminate_handler unexpectedly threw an exception
  ```

## 异常分析
  APP crash在
  ```
  [keyWindow addSubview:weakSelf];
  ```
  [错误堆栈信息](#错误堆栈)。


  但是真正造成crash的代码为：

  ```
  [self.layer insertSublayer:xxxView.layer atIndex:0];
  ```
  
  
  解决方案：
  ```
  [self layoutIfNeeded];
  [self.layer insertSublayer:xxxView.layer atIndex:0];
  ```
  
  原因分析：
  下面这个说的很在理
  > http://stackoverflow.com/questions/39565424/swift-uiviewreportbrokensuperviewchain-cause-by-layer-manipulation
  >
  > I had this issue with a library when moving over to Xcode 8 (Material-Controls-For-iOS - MDTextField). I found that the problem was coming from where the layer of one view (which had no superview) was being added to another.
  >
  > It looks like this may be the case for yourself also - your toolbar being created has not been added to a superview first. The fix I used was to add the view as a subview of the view that the layer was being added to, so in your case adding the toolbar as a subview of myModelView should stop the error.
  

## 碰到该问题的还有
  - [Google出来的一个，但是并未看到相关回复。。。](http://technology.ezeenow.com/Posts/119474/Unity_Prime31_prompt_for_photo_is_crashing_on_iOS_10_and_XCode_8)
  - [IOS10上崩溃错误“View has lost track of its superview, most (并未找到原贴)](http://www.th7.cn/Program/IOS/201609/975582.shtml)
  - [stackoverflow(这个分析的很到位)](http://stackoverflow.com/questions/39565424/swift-uiviewreportbrokensuperviewchain-cause-by-layer-manipulation)

## <a name="错误堆栈">错误堆栈 <脱敏></a>

  ```
  *** Assertion failure in void UIViewReportBrokenSuperviewChain(UIView *__strong, UIView *__strong, BOOL)(), /BuildRoot/Library/Caches/com.apple.xbs/Sources/UIKit/UIKit-3599.6.1/UIView.m:190
  invalid mode 'kCFRunLoopCommonModes' provided to CFRunLoopRunSpecific - break on _CFRunLoopError_RunCalledWithInvalidMode to debug. This message will only appear once per execution.
  libc++abi.dylib: terminate_handler unexpectedly threw an exception

  (lldb) bt
  * thread #1: tid = 0x87c18, 0x000000018238c524 libobjc.A.dylib`objc_exception_throw, queue = 'com.apple.main-thread', stop reason = breakpoint 1.2
      frame #0: 0x000000018238c524 libobjc.A.dylib`objc_exception_throw
      frame #1: 0x0000000183954094 CoreFoundation`+[NSException raise:format:arguments:] + 104
      frame #2: 0x00000001843de898 Foundation`-[NSAssertionHandler handleFailureInFunction:file:lineNumber:description:] + 88
      frame #3: 0x0000000189a7cf9c UIKit`UIViewReportBrokenSuperviewChain + 472
      frame #4: 0x0000000189a7d658 UIKit`_UIViewTopDownSubtreeTraversal + 1496
      frame #5: 0x000000018a0f3390 UIKit`-[UIView(UIConstraintBasedLayout_EngineDelegate) _invalidateSystemLayoutSizeFittingSizeAtEngineDelegateLevel] + 232
      frame #6: 0x00000001843832ac Foundation`-[NSISEngine tryToAddConstraintWithMarker:expression:integralizationAdjustment:mutuallyExclusiveConstraints:] + 920
      frame #7: 0x0000000184382dcc Foundation`-[NSLayoutConstraint _addLoweredExpression:toEngine:integralizationAdjustment:lastLoweredConstantWasRounded:mutuallyExclusiveConstraints:] + 284
      frame #8: 0x00000001843809e0 Foundation`-[NSLayoutConstraint _addToEngine:integralizationAdjustment:mutuallyExclusiveConstraints:] + 272
      frame #9: 0x000000018989cfdc UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke_2 + 396
      frame #10: 0x0000000184380510 Foundation`-[NSISEngine withBehaviors:performModifications:] + 168
      frame #11: 0x000000018989cde8 UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke + 564
      frame #12: 0x00000001897995e0 UIKit`-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:] + 224
      frame #13: 0x000000018989cf14 UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke_2 + 196
      frame #14: 0x0000000184380510 Foundation`-[NSISEngine withBehaviors:performModifications:] + 168
      frame #15: 0x000000018989cde8 UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke + 564
      frame #16: 0x00000001897995e0 UIKit`-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:] + 224
      frame #17: 0x000000018989cf14 UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke_2 + 196
      frame #18: 0x0000000184380510 Foundation`-[NSISEngine withBehaviors:performModifications:] + 168
      frame #19: 0x000000018989cde8 UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke + 564
      frame #20: 0x00000001897995e0 UIKit`-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:] + 224
      frame #21: 0x000000018989cf14 UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke_2 + 196
      frame #22: 0x0000000184380510 Foundation`-[NSISEngine withBehaviors:performModifications:] + 168
      frame #23: 0x000000018989cde8 UIKit`__57-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:]_block_invoke + 564
      frame #24: 0x00000001897995e0 UIKit`-[UIView(AdditionalLayoutSupport) _switchToLayoutEngine:] + 224
      frame #25: 0x00000001898a4bb0 UIKit`-[UIWindow(UIConstraintBasedLayout) _switchToLayoutEngine:] + 72
      frame #26: 0x00000001898a4b04 UIKit`-[UIWindow(UIConstraintBasedLayout) _initializeLayoutEngine] + 256
      frame #27: 0x00000001898a4910 UIKit`-[UIView(UIConstraintBasedLayout) _layoutEngine_windowDidChange] + 132
      frame #28: 0x00000001897996dc UIKit`-[UIView(Internal) _didMoveFromWindow:toWindow:] + 200
      frame #29: 0x0000000189798d90 UIKit`__45-[UIView(Hierarchy) _postMovedFromSuperview:]_block_invoke + 156
      frame #30: 0x0000000189798be8 UIKit`-[UIView(Hierarchy) _postMovedFromSuperview:] + 792
      frame #31: 0x00000001897a4ad0 UIKit`-[UIView(Internal) _addSubview:positioned:relativeTo:] + 1788
      frame #32: 0x00000001897a43bc UIKit`-[UIView(Hierarchy) addSubview:] + 828
    * frame #33: 0x00000001004f78ec Project_ent`__31-[EsfCommentReportView show]_block_invoke((null)=<unavailable>) + 228 at EsfCommentReportView.m:293
      frame #34: 0x00000001897d2b88 UIKit`+[UIView(UIViewAnimationWithBlocks) _setupAnimationWithDuration:delay:view:options:factory:animations:start:animationStateGenerator:completion:] + 660
      frame #35: 0x00000001897d28e8 UIKit`+[UIView(UIViewAnimationWithBlocks) animateWithDuration:animations:] + 56
      frame #36: 0x00000001004f77a0 Project_ent`-[EsfCommentReportView show](self=0x000000015fe32020, _cmd="show") + 492 at EsfCommentReportView.m:291
      frame #37: 0x0000000100858a04 Project_ent`__53-[BuyerAdviserProfileViewController reportAction:]_block_invoke((null)=<unavailable>) + 308 at BuyerAdviserProfileViewController.m:174
      frame #38: 0x00000001003f93e4 Project_ent`+[MyLoginViewController ifShouldLoginFromViewController:sourceType:afterCheckOrLogin:cancelLogin:](self=MyLoginViewController, _cmd="ifShouldLoginFromViewController:sourceType:afterCheckOrLogin:cancelLogin:", viewController=0x000000015fd2e320, sourceType=2, afterCheckOrLogin=0x00000001008588d0, cancelLogin=(null)) + 236 at MyLoginViewController.m:123
      frame #39: 0x00000001003f92b0 Project_ent`+[MyLoginViewController ifShouldLoginFromViewController:afterCheckOrLogin:cancelLogin:](self=MyLoginViewController, _cmd="ifShouldLoginFromViewController:afterCheckOrLogin:cancelLogin:", viewController=0x000000015fd2e320, afterCheckOrLogin=0x00000001008588d0, cancelLogin=(null)) + 156 at MyLoginViewController.m:114
      frame #40: 0x00000001003f9124 Project_ent`+[MyLoginViewController ifShouldLoginFromViewController:afterCheckOrLogin:](self=MyLoginViewController, _cmd="ifShouldLoginFromViewController:afterCheckOrLogin:", viewController=0x000000015fd2e320, afterCheckOrLogin=0x00000001008588d0) + 120 at MyLoginViewController.m:104
      frame #41: 0x0000000100858870 Project_ent`-[BuyerAdviserProfileViewController reportAction:](self=0x000000015fd2e320, _cmd="reportAction:", button=0x000000015fe26650) + 452 at BuyerAdviserProfileViewController.m:156
      frame #42: 0x00000001897d27b0 UIKit`-[UIApplication sendAction:to:from:forEvent:] + 96
      frame #43: 0x00000001897d2730 UIKit`-[UIControl sendAction:to:forEvent:] + 80
      frame #44: 0x00000001897bcbe4 UIKit`-[UIControl _sendActionsForEvents:withEvent:] + 452
      frame #45: 0x00000001897d201c UIKit`-[UIControl touchesEnded:withEvent:] + 584
      frame #46: 0x00000001897d1b44 UIKit`-[UIWindow _sendTouchesForEvent:] + 2484
      frame #47: 0x00000001897ccd8c UIKit`-[UIWindow sendEvent:] + 2988
      frame #48: 0x000000018979d858 UIKit`-[UIApplication sendEvent:] + 340
      frame #49: 0x0000000189f8acb8 UIKit`__dispatchPreprocessedEventFromEventQueue + 2736
      frame #50: 0x0000000189f84720 UIKit`__handleEventQueue + 784
      frame #51: 0x0000000183902278 CoreFoundation`__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 24
      frame #52: 0x0000000183901bc0 CoreFoundation`__CFRunLoopDoSources0 + 524
      frame #53: 0x00000001838ff7c0 CoreFoundation`__CFRunLoopRun + 804
      frame #54: 0x000000018382e048 CoreFoundation`CFRunLoopRunSpecific + 444
      frame #55: 0x00000001852b1198 GraphicsServices`GSEventRunModal + 180
      frame #56: 0x0000000189808628 UIKit`-[UIApplication _run] + 684
      frame #57: 0x0000000189803360 UIKit`UIApplicationMain + 208
      frame #58: 0x0000000100a3db78 Project_ent`main + 460 at main.swift:24
      frame #59: 0x00000001828105b8 libdyld.dylib`start + 4
  (lldb) 
  ```
