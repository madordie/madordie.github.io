---
title: iOS的那几个__bridge*究竟做了啥
url: what-happened-to-the-bridge-in-ios
date: 2020-10-10
tags:
    - __bridge*
categories:
    - iOS
---

## 抛出问题

群友(@闲人)贴了这么一个**会崩溃**的代码:

```ObjC
@implementation NSObject (test)
- (id)performSelector:(SEL)aSelector withObjects:(NSArray *)objects {

    NSMethodSignature *methodSignature = [[self class] instanceMethodSignatureForSelector:aSelector];
    // ...
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    // ...
    [invocation invoke];
    //返回值处理
    id callBackObject = NULL;
    if(methodSignature.methodReturnLength) {
        [invocation getReturnValue:&callBackObject];
    }
    return callBackObject;
}
@end

@interface TestModel: NSObject
@property (nonatomic, strong) NSNumber *age;
@end
@implementation TestModel
- (instancetype)initWithA:(NSString *)a b:(NSString *)b c:(NSString *)c {
    if (self = [super init]) {
        printf("initABC\n");
    }
    return self;
}
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    TestModel *_teM;
    Class class = NSClassFromString(@"TestModel");
    _teM = [[class alloc] performSelector:@selector(initWithA:b:c:) withObjects:@[@"1",@"1",@"1"]];
    [_teM performSelector:@selector(setAge:) withObject:@1]; /*  <- EXC_BAD_ACCESS  */
    printf("over\n");
}
@end
```

对,段错误,代码挂在了`[_teM performSelector:@selector(setAge:) withObject:@1]`

<!--more-->

## 挖一个坑

先打开`Zombie Objects`再跑一次:

```lldb
*** -[TestModel performSelector:withObject:]: message sent to deallocated instance 0x6000039ec630
```

哦,`_teM<0x6000039ec630>`已经被释放了. 那是谁释放的呢?

我们可以在`[invocation getReturnValue:&callBackObject];`之后断点:

```lldb
(lldb) po callBackObject
<TestModel: 0x600000bf05b0>

(lldb) finish
(lldb) po _teM
 nil
(lldb) next
(lldb) po _teM
<TestModel: 0x600000bf05b0>

(lldb) next
(lldb) next
over
(lldb)
```

**卧槽, 一行代码没改不崩溃了:<**

传闻`po`有`retain`的功效,可是`frame variable`依旧会出现此诡异的问题.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">It seems that the retain count of the object increases 1 whenever you execute `expression object`. Another workaround is to use frame variable<br><br>(lldb) frame variable object <a href="https://t.co/Y2ghQ3sHzL">pic.twitter.com/Y2ghQ3sHzL</a></p>&mdash; Pofat (@PofatTseng) <a href="https://twitter.com/PofatTseng/status/1057644037107118080?ref_src=twsrc%5Etfw">October 31, 2018</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

那就着重看一下`-[NSObject performSelector:withObject:]`中的返回值逻辑:

```ObjC
    id callBackObject = NULL;
    if(methodSignature.methodReturnLength) {
        [invocation getReturnValue:&callBackObject];
    }
    return callBackObject;
```

这代码不得不说着实有点简单, 对比之前[唯敬](https://github.com/Awhisper)大佬的[VKMsgSend](https://github.com/Awhisper/VKMsgSend)库,是真的短.

## 先粗略分析一下

再回到崩溃的问题上: `message sent to deallocated instance 0x6000039ec630`

那么实现`-[TestModel dealloc]`即可找到什么时候释放的呗~

```lldb
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 2.1
  * frame #0: 0x000000010ec8a770 PerformDemo`-[TestModel dealloc](self=0x0000600003c847d0, _cmd="dealloc") at ViewController.m:31:5
    frame #1: 0x00007fff2018f7f4 libobjc.A.dylib`objc_object::sidetable_release(bool, bool) + 174
    frame #2: 0x000000010ec8a949 PerformDemo`-[ViewController viewDidLoad](self=0x00007ff403614fc0, _cmd="viewDidLoad") at ViewController.m:46:5
    ...
```

还是在`-[NSObject performSelector:withObjects:]`中,看下汇编最后的几行伪代码:

```c
id -[NSObject performSelector:withObjects:](NSObject *self, SEL a2, SEL a3, id a4) {
  ...
  v15 = 0LL;
  if ( objc_msgSend(v24, "methodReturnLength") )
    objc_msgSend(v23, "getReturnValue:", &v15);
  v12 = objc_retain(v15);   // +1
  objc_storeStrong(&v15, 0LL);  // -1
  objc_storeStrong(&v23, 0LL);
  objc_storeStrong(&v24, 0LL);
  return (id)objc_autoreleaseReturnValue(v12);  // --> append autoreleasepool
}
```

所以此时关于该对象的生命周期操作大概如下:

- v12 = objc_retain(v15);   // +1
- objc_storeStrong(&v15, 0LL);  // -1
- return (id)objc_autoreleaseReturnValue(v12);  // --> append autoreleasepool

这个对象从`-[NSInvocation getReturnValue:]`获取出来之后在没有增加引用计数的情况下反而给人家加到了`autoreleasepool`里面.

## 怎么解决

`ObjC`的`ARC`下除了能用个`@autoreleasepool{}`让其提前`objc_release`,基本上没有能干预得了.

不过这个`-[NSInvocation getReturnValue:]`API的返回值并非是`ObjC`格式,而是地址直接传递的, 所以这个应该属于`C`的范畴, 其于`ARC`对象之间是有`__bridge*`可用的.

再看下[小抄](https://github.com/Awhisper/VKMsgSend/blob/master/VKMsgSend/VKMsgSend.m#L214-#L227), 嗯,确实缺少了`__bridge*`:

然后问题来了: 重写的`init`应该用`__bridge_transfer`还是`__bridge`?

这个问题其实也很简单, 试一下子撒~~ (答案是`__bridge` :)

然后, 我想说点在网上目前还搜不到的, 先看下[官方文档](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFDesignConcepts/Articles/tollFreeBridgedTypes.html)原文

> The compiler does not automatically manage the lifetimes of Core Foundation objects. You tell the compiler about the ownership semantics of objects using either a cast (defined in objc/runtime.h) or a Core Foundation-style macro (defined in NSObject.h):
> - __bridge transfers a pointer between Objective-C and Core Foundation with no transfer of ownership.
> - __bridge_retained or CFBridgingRetain casts an Objective-C pointer to a Core Foundation pointer and also transfers ownership to you.
> You are responsible for calling CFRelease or a related function to relinquish ownership of the object.
> - __bridge_transfer or CFBridgingRelease moves a non-Objective-C pointer to Objective-C and also transfers ownership to ARC.
> ARC is responsible for relinquishing ownership of the object.



### __bridge


