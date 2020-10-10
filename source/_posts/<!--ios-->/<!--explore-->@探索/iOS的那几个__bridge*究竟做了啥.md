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

## 一个坑

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

还是在`-[ViewController viewDidLoad]`中,看下汇编所在的位置的伪代码:

```c
void -[ViewController viewDidLoad](ViewController *self, SEL a2)
{
  v3 = objc_alloc(NSClassFromString(CFSTR("TestModel")););
  v11 = (void *)objc_retainAutoreleasedReturnValue(objc_msgSend(v3, "performSelector:withObjects:", "initWithA:b:c:", @[@1, @1, @1]););
  objc_release(0LL);
  objc_release(v3);
  objc_msgSend(v11, "performSelector:withObject:", "setAge:", @1);
  printf("over\n");
  objc_storeStrong(&v11, 0LL);
}
id -[NSObject performSelector:withObjects:](NSObject *self, SEL a2, SEL a3, id a4)
{
  ...
  v15 = 0LL;
  if ( objc_msgSend(v24, "methodReturnLength") )
    objc_msgSend(v23, "getReturnValue:", &v15);
  v12 = objc_retain(v15);
  objc_storeStrong(&v15, 0LL);
  objc_storeStrong(&v23, 0LL);
  objc_storeStrong(&v24, 0LL);
  return (id)objc_autoreleaseReturnValue(v12);
}
```

所以此时关于该对象的生命周期操作大概如下:

- alloc +1
- --> objc_retain +1
- --> objc_storeStrong -1
- --> objc_autoreleaseReturnValue ===> append autorelease pool
- objc_retainAutoreleasedReturnValue +1
- autoreleasepool -1
- objc_release -1  `<-- dealloc`
- printf
- objc_storeStrong -1

至此, 崩溃的原委分析完了...

## 怎么解决

先看下[小抄](https://github.com/Awhisper/VKMsgSend/blob/master/VKMsgSend/VKMsgSend.m#L214-#L227), 嗯,缺少了`__bridge*`:

然后问题来了: 重写的`init`应该用`__bridge_transfer`还是`__bridge`?

< 容我回家吃个饭.. >