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

## 粗略分析

先打开`Zombie Objects`再跑一次:

```lldb
*** -[TestModel performSelector:withObject:]: message sent to deallocated instance 0x6000039ec630
```

哦,`_teM<0x6000039ec630>`已经被释放了. 那是谁释放的呢?

回到崩溃的问题上: `message sent to deallocated instance 0x6000039ec630`

那么实现`-[TestModel dealloc]`即可找到什么时候释放的呗~

```lldb
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 2.1
  * frame #0: 0x000000010ec8a770 PerformDemo`-[TestModel dealloc](self=0x0000600003c847d0, _cmd="dealloc") at ViewController.m:31:5
    frame #1: 0x00007fff2018f7f4 libobjc.A.dylib`objc_object::sidetable_release(bool, bool) + 174
    frame #2: 0x000000010ec8a949 PerformDemo`-[ViewController viewDidLoad](self=0x00007ff403614fc0, _cmd="viewDidLoad") at ViewController.m:46:5
    ...
```

是不是很没头绪? 如果没头绪的话就被我~~这一顿粗略分析~~给带沟里了...

## 看点别的

我们先看下`-[NSObject performSelector:withObjects:]`中的返回值获取的逻辑:

```ObjC
    id callBackObject = NULL;
    if(methodSignature.methodReturnLength) {
        [invocation getReturnValue:&callBackObject];
    }
```

关于`NSInvocation`我用的比较少,但是看过[唯敬](https://github.com/Awhisper)大佬的[VKMsgSend](https://github.com/Awhisper/VKMsgSend)库, 这几行代码是真的短..

先看下这几行的汇编伪代码:

```c
  v15 = 0LL;
  if ( objc_msgSend(v24, "methodReturnLength") )
    objc_msgSend(v23, "getReturnValue:", &v15);
  v12 = objc_retain(v15);   // +1
  objc_storeStrong(&v15, 0LL);  // -1
  objc_storeStrong(&v23, 0LL);
  objc_storeStrong(&v24, 0LL);
  return (id)objc_autoreleaseReturnValue(v12);  // --> append autoreleasepool
```

所以此时关于该对象的生命周期操作大概如下:

- v12 = objc_retain(v15);   // +1
- objc_storeStrong(&v15, 0LL);  // -1
- return (id)objc_autoreleaseReturnValue(v12);  // --> append autoreleasepool

这个对象从`-[NSInvocation getReturnValue:]`获取出来之后在没有增加引用计数的情况下反而给人家加到了`autoreleasepool`里面.

中所周知`autoreleasepool`在释放的时候会对其进行一次`release`, 而这次不对等的`release`就是这个崩溃发生的究极原因.

## 怎么解决

`ObjC`的`ARC`下除了能用个`@autoreleasepool{}`让其提前`objc_release`,基本上没有能干预得了.

不过这个`-[NSInvocation getReturnValue:]`API的返回值是地址直接传递的, API也是属于`CoreFounction`中, 其与`ARC`对象之间还有`__bridge*`可用.

再看下[小抄](https://github.com/Awhisper/VKMsgSend/blob/master/VKMsgSend/VKMsgSend.m#L214-#L227), 嗯,确实缺少了`__bridge*`:

然后问题来了: 重写的`init`应该用`__bridge_transfer`还是`__bridge`?

这个问题其实也很简单, 试一下子撒~~ (答案是`__bridge` :)

先看下[官方文档](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFDesignConcepts/Articles/tollFreeBridgedTypes.html)原文

> The compiler does not automatically manage the lifetimes of Core Foundation objects. You tell the compiler about the ownership semantics of objects using either a cast (defined in objc/runtime.h) or a Core Foundation-style macro (defined in NSObject.h):
> - __bridge transfers a pointer between Objective-C and Core Foundation with no transfer of ownership.
> - __bridge_retained or CFBridgingRetain casts an Objective-C pointer to a Core Foundation pointer and also transfers ownership to you.
> You are responsible for calling CFRelease or a related function to relinquish ownership of the object.
> - __bridge_transfer or CFBridgingRelease moves a non-Objective-C pointer to Objective-C and also transfers ownership to ARC.
> ARC is responsible for relinquishing ownership of the object.

然后, 我想说点在网上目前还搜不到的.

### `__bridge_transfer`为什么不行

如原文说了`a pointer between Objective-C and Core Foundation with no transfer of ownership`, 并不会发生所有权的转移.

然后`__bridge_transfer`究竟做了什么呢? 对比一下汇编伪代码吧,简单直接:

```c
v15 = 0LL;
if ( objc_msgSend(v24, "methodReturnLength") )
  objc_msgSend(v23, "getReturnValue:", &v15);
v12 = v15;
objc_storeStrong(&v23, 0LL);
objc_storeStrong(&v24, 0LL);
return (id)objc_autoreleaseReturnValue(v12);
```

`v12 = v15`, 是的,就是这么彪悍. 直接赋值的, 比不加`__bridge_transfer`少了一次`objc_retain(v15)`和`objc_storeStrong(&v15, 0LL)`, 理论来讲速度更加快了,毕竟两者效果是一样的.

### `__bridge`为什么行

原文中说会讲所有权移交给ARC, 也就是ARC要负责释放该对象, 等价于将引用计数加一.

再来看一下汇编伪代码:

```c
v15 = 0LL;
if ( objc_msgSend(v24, "methodReturnLength") )
  objc_msgSend(v23, "getReturnValue:", &v15);
v12 = objc_retain(v15);
objc_storeStrong(&v23, 0LL);
objc_storeStrong(&v24, 0LL);
return (id)objc_autoreleaseReturnValue(v12);
```

注意此时关于`v15/v12`的内存管理, 就只剩下了`objc_retain(v15)`与`objc_autoreleaseReturnValue(v12)`.

不说了, 很完美.