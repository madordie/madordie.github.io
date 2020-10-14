---
title: iOS的那几个__bridge*究竟做了啥
url: what-happened-to-the-bridge-in-ios
date: 2020-10-10
tags:
    - DEBUG
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

不说了, 运行很完美.

## 一个意外

从上面的分析可以看的出来, 由于对象在`-[NSObject performSelector:withObjects:]`中被添加到`autoreleasepool`导致引用计数不匹配, 但是为什么会在函数解释之后再次调用就立即GG了呢?

来断点看一下.

```lldb
(lldb) breakpoint set -n '-[NSObject performSelector:withObjects:]'
Breakpoint 2: where = PerformDemo`-[NSObject(test) performSelector:withObjects:] + 46 at NSObject+test.m:15:44, address = 0x0000000101e14a0e
(lldb) continue
Process 17773 resuming
(lldb) finish
initABC: 0x6000037ec980
(lldb) next
(lldb) po _teM
<TestModel: 0x6000037ec980>

(lldb) next
(lldb) next
over
(lldb)
```

有没有注意到`over`打印出来了,也就是原本崩溃的`[_teM performSelector:@selector(setAge:) withObject:@1]`执行了...

那是不是问题解决了呢? 当然不是,`continue`之后依旧会在`main`函数报`EXC_BAD_ACCESS`错误.

--分割线---

换个角度, 重写`dealloc`:

```ObjC
- (void)dealloc {
    printf("model dealloc..\n");
}
```

删除所有的断点,并仅保留在`dealloc`的一处断点.得到:

```lldb
initABC: 0x600000e68480
(lldb) frame info
frame #0: 0x000000010b3546b0 PerformDemo`-[TestModel dealloc](self=0x0000600000e68480, _cmd="dealloc") at ViewController.m:31:5
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
  * frame #0: 0x000000010b3546b0 PerformDemo`-[TestModel dealloc](self=0x0000600000e68480, _cmd="dealloc") at ViewController.m:31:5
    frame #1: 0x000000010bb7e7f4 libobjc.A.dylib`objc_object::sidetable_release(bool, bool) + 174
    frame #2: 0x000000010b354919 PerformDemo`-[ViewController viewDidLoad](self=0x00007ffe74d16a60, _cmd="viewDidLoad") at ViewController.m:55:5
    ...
(lldb)
```

![不够清晰,看图](/images/2020-10-14-16-58-33.png)

贴一下相关的伪代码/汇编:
<details>
<summary>void __cdecl -[ViewController viewDidLoad](ViewController *self, SEL a2):</summary>
<pre>
```c
void __cdecl -[ViewController viewDidLoad](ViewController *self, SEL a2)
{
  __int64 v2; // rax
  __int64 v3; // rax
  void *v4; // ST38_8
  void *v5; // rax
  __int64 v6; // rax
  __int64 v7; // ST30_8
  void *v8; // rax
  void *v9; // rax
  __int64 v10; // ST18_8
  void *v11; // [rsp+58h] [rbp-48h]
  ViewController *v12; // [rsp+60h] [rbp-40h]
  __objc2_class *v13; // [rsp+68h] [rbp-38h]
  SEL v14; // [rsp+70h] [rbp-30h]
  ViewController *v15; // [rsp+78h] [rbp-28h]
  const __CFString *v16; // [rsp+80h] [rbp-20h]
  const __CFString *v17; // [rsp+88h] [rbp-18h]
  const __CFString *v18; // [rsp+90h] [rbp-10h]

  v15 = self;
  v14 = a2;
  v12 = self;
  v13 = &OBJC_CLASS___ViewController;
  objc_msgSendSuper2(&v12, "viewDidLoad");
  v2 = NSClassFromString(CFSTR("TestModel"));
  v3 = objc_alloc(v2);
  v16 = CFSTR("1");
  v17 = CFSTR("1");
  v18 = CFSTR("1");
  v4 = (void *)v3;
  v5 = objc_msgSend(&OBJC_CLASS___NSArray, "arrayWithObjects:count:", &v16, 3LL);
  v6 = objc_retainAutoreleasedReturnValue((__int64)v5);
  v7 = v6;
  v8 = objc_msgSend(v4, "performSelector:withObjects:", "initWithA:b:c:", v6);
  v11 = (void *)objc_retainAutoreleasedReturnValue((__int64)v8);
  objc_release(0LL);
  objc_release(v7);
  objc_release(v4);
  v9 = objc_msgSend(&OBJC_CLASS___NSNumber, "numberWithInt:", 1LL);
  v10 = objc_retainAutoreleasedReturnValue((__int64)v9);
  objc_msgSend(v11, "performSelector:withObject:", "setAge:", v10);
  objc_release(v10);
  printf("over\n");
  objc_storeStrong(&v11, 0LL);
}
```
</pre>
</details>

<details>
<summary><汇编> PerformDemo`-[ViewController viewDidLoad]:</summary>
<pre>
```arm
PerformDemo`-[ViewController viewDidLoad]:
    0x10b354810 <+0>:   pushq  %rbp
    0x10b354811 <+1>:   movq   %rsp, %rbp
    0x10b354814 <+4>:   subq   $0xa0, %rsp
    0x10b35481b <+11>:  movq   0x27de(%rip), %rax        ; (void *)0x000000010d3ff0b0: __stack_chk_guard
    0x10b354822 <+18>:  movq   (%rax), %rax
    0x10b354825 <+21>:  movq   %rax, -0x8(%rbp)
    0x10b354829 <+25>:  movq   %rdi, -0x28(%rbp)
    0x10b35482d <+29>:  movq   %rsi, -0x30(%rbp)
    0x10b354831 <+33>:  movq   -0x28(%rbp), %rax
    0x10b354835 <+37>:  movq   %rax, -0x40(%rbp)
    0x10b354839 <+41>:  movq   0x7e58(%rip), %rax        ; (void *)0x000000010b35c700: ViewController
    0x10b354840 <+48>:  movq   %rax, -0x38(%rbp)
    0x10b354844 <+52>:  movq   0x7d65(%rip), %rsi        ; "viewDidLoad"
    0x10b35484b <+59>:  leaq   -0x40(%rbp), %rdi
    0x10b35484f <+63>:  callq  0x10b355210               ; symbol stub for: objc_msgSendSuper2
    0x10b354854 <+68>:  leaq   0x27cd(%rip), %rax        ; @"TestModel"
    0x10b35485b <+75>:  movq   $0x0, -0x48(%rbp)
    0x10b354863 <+83>:  movq   %rax, %rdi
    0x10b354866 <+86>:  callq  0x10b3551d4               ; symbol stub for: NSClassFromString
    0x10b35486b <+91>:  movq   %rax, -0x50(%rbp)
    0x10b35486f <+95>:  movq   -0x50(%rbp), %rdi
    0x10b354873 <+99>:  callq  0x10b3551ec               ; symbol stub for: objc_alloc
    0x10b354878 <+104>: leaq   0x27c9(%rip), %rcx        ; @"'1'"
    0x10b35487f <+111>: movq   0x7d32(%rip), %rdx        ; "initWithA:b:c:"
    0x10b354886 <+118>: movq   %rcx, -0x20(%rbp)
    0x10b35488a <+122>: movq   %rcx, -0x18(%rbp)
    0x10b35488e <+126>: movq   %rcx, -0x10(%rbp)
    0x10b354892 <+130>: movq   0x7dc7(%rip), %rcx        ; (void *)0x000000010c15e720: NSArray
    0x10b354899 <+137>: movq   0x7d20(%rip), %rsi        ; "arrayWithObjects:count:"
    0x10b3548a0 <+144>: leaq   -0x20(%rbp), %rdi
    0x10b3548a4 <+148>: movq   %rdi, -0x58(%rbp)
    0x10b3548a8 <+152>: movq   %rcx, %rdi
    0x10b3548ab <+155>: movq   -0x58(%rbp), %rcx
    0x10b3548af <+159>: movq   %rdx, -0x60(%rbp)
    0x10b3548b3 <+163>: movq   %rcx, %rdx
    0x10b3548b6 <+166>: movl   $0x3, %ecx
    0x10b3548bb <+171>: movq   %rax, -0x68(%rbp)
    0x10b3548bf <+175>: callq  *0x2743(%rip)             ; (void *)0x000000010bb62880: objc_msgSend
    0x10b3548c5 <+181>: movq   %rax, %rdi
    0x10b3548c8 <+184>: callq  0x10b355222               ; symbol stub for: objc_retainAutoreleasedReturnValue
    0x10b3548cd <+189>: movq   0x7cf4(%rip), %rsi        ; "performSelector:withObjects:"
    0x10b3548d4 <+196>: movq   -0x68(%rbp), %rdi
    0x10b3548d8 <+200>: movq   -0x60(%rbp), %rdx
    0x10b3548dc <+204>: movq   %rax, %rcx
    0x10b3548df <+207>: movq   %rax, -0x70(%rbp)
    0x10b3548e3 <+211>: callq  *0x271f(%rip)             ; (void *)0x000000010bb62880: objc_msgSend
    0x10b3548e9 <+217>: movq   %rax, %rdi
    0x10b3548ec <+220>: callq  0x10b355222               ; symbol stub for: objc_retainAutoreleasedReturnValue
    0x10b3548f1 <+225>: movq   -0x48(%rbp), %rcx
    0x10b3548f5 <+229>: movq   %rax, -0x48(%rbp)
    0x10b3548f9 <+233>: movq   %rcx, %rdi
    0x10b3548fc <+236>: callq  *0x270e(%rip)             ; (void *)0x000000010bb7e720: objc_release
    0x10b354902 <+242>: movq   -0x70(%rbp), %rax
    0x10b354906 <+246>: movq   %rax, %rdi
    0x10b354909 <+249>: callq  *0x2701(%rip)             ; (void *)0x000000010bb7e720: objc_release
    0x10b35490f <+255>: movq   -0x68(%rbp), %rdi
    0x10b354913 <+259>: callq  *0x26f7(%rip)             ; (void *)0x000000010bb7e720: objc_release
->  0x10b354919 <+265>: movq   -0x48(%rbp), %rax
    0x10b35491d <+269>: movq   0x7cac(%rip), %rdx        ; "setAge:"
    0x10b354924 <+276>: movq   0x7d3d(%rip), %rcx        ; (void *)0x000000010b91cc68: NSNumber
    0x10b35492b <+283>: movq   0x7ca6(%rip), %rsi        ; "numberWithInt:"
    0x10b354932 <+290>: movq   %rcx, %rdi
    0x10b354935 <+293>: movl   $0x1, %r8d
    0x10b35493b <+299>: movq   %rdx, -0x78(%rbp)
    0x10b35493f <+303>: movl   %r8d, %edx
    0x10b354942 <+306>: movq   %rax, -0x80(%rbp)
    0x10b354946 <+310>: callq  *0x26bc(%rip)             ; (void *)0x000000010bb62880: objc_msgSend
    0x10b35494c <+316>: movq   %rax, %rdi
    0x10b35494f <+319>: callq  0x10b355222               ; symbol stub for: objc_retainAutoreleasedReturnValue
    0x10b354954 <+324>: movq   %rax, %rcx
    0x10b354957 <+327>: movq   0x7c82(%rip), %rsi        ; "performSelector:withObject:"
    0x10b35495e <+334>: movq   -0x80(%rbp), %rdi
    0x10b354962 <+338>: movq   -0x78(%rbp), %rdx
    0x10b354966 <+342>: movq   %rax, -0x88(%rbp)
    0x10b35496d <+349>: callq  *0x2695(%rip)             ; (void *)0x000000010bb62880: objc_msgSend
    0x10b354973 <+355>: movq   -0x88(%rbp), %rcx
    0x10b35497a <+362>: movq   %rcx, %rdi
    0x10b35497d <+365>: movq   %rax, -0x90(%rbp)
    0x10b354984 <+372>: callq  *0x2686(%rip)             ; (void *)0x000000010bb7e720: objc_release
    0x10b35498a <+378>: leaq   0x185a(%rip), %rdi        ; "over\n"
    0x10b354991 <+385>: movb   $0x0, %al
    0x10b354993 <+387>: callq  0x10b355234               ; symbol stub for: printf
    0x10b354998 <+392>: xorl   %r8d, %r8d
    0x10b35499b <+395>: movl   %r8d, %esi
    0x10b35499e <+398>: leaq   -0x48(%rbp), %rcx
    0x10b3549a2 <+402>: movq   %rcx, %rdi
    0x10b3549a5 <+405>: movl   %eax, -0x94(%rbp)
    0x10b3549ab <+411>: callq  0x10b355228               ; symbol stub for: objc_storeStrong
    0x10b3549b0 <+416>: movq   0x2649(%rip), %rcx        ; (void *)0x000000010d3ff0b0: __stack_chk_guard
    0x10b3549b7 <+423>: movq   (%rcx), %rcx
    0x10b3549ba <+426>: movq   -0x8(%rbp), %rdx
    0x10b3549be <+430>: cmpq   %rdx, %rcx
    0x10b3549c1 <+433>: jne    0x10b3549d0               ; <+448> at ViewController.m
    0x10b3549c7 <+439>: addq   $0xa0, %rsp
    0x10b3549ce <+446>: popq   %rbp
    0x10b3549cf <+447>: retq
    0x10b3549d0 <+448>: callq  0x10b3551e6               ; symbol stub for: __stack_chk_fail
    0x10b3549d5 <+453>: ud2
```
</pre>
</details>

<details>
<summary><汇编>libobjc.A.dylib`objc_object::sidetable_release:</summary>
<pre>
```arm
libobjc.A.dylib`objc_object::sidetable_release:
    0x10bb7e746 <+0>:   pushq  %rbp
    0x10bb7e747 <+1>:   movq   %rsp, %rbp
    0x10bb7e74a <+4>:   pushq  %r15
    0x10bb7e74c <+6>:   pushq  %r14
    0x10bb7e74e <+8>:   pushq  %r13
    0x10bb7e750 <+10>:  pushq  %r12
    0x10bb7e752 <+12>:  pushq  %rbx
    0x10bb7e753 <+13>:  subq   $0x28, %rsp
    0x10bb7e757 <+17>:  movl   %esi, %r14d
    0x10bb7e75a <+20>:  movq   %rdi, %r13
    0x10bb7e75d <+23>:  movl   %r13d, %eax
    0x10bb7e760 <+26>:  shrl   $0x9, %eax
    0x10bb7e763 <+29>:  movl   %r13d, %ebx
    0x10bb7e766 <+32>:  shrl   $0x4, %ebx
    0x10bb7e769 <+35>:  xorl   %eax, %ebx
    0x10bb7e76b <+37>:  andl   $0x3f, %ebx
    0x10bb7e76e <+40>:  shlq   $0x6, %rbx
    0x10bb7e772 <+44>:  leaq   0x1bac7(%rip), %r12       ; (anonymous namespace)::SideTablesMap
    0x10bb7e779 <+51>:  leaq   (%r12,%rbx), %r15
    0x10bb7e77d <+55>:  movq   %r15, %rdi
    0x10bb7e780 <+58>:  movl   $0x50000, %esi            ; imm = 0x50000
    0x10bb7e785 <+63>:  callq  0x10bb822d0               ; symbol stub for: os_unfair_lock_lock_with_options
    0x10bb7e78a <+68>:  leaq   0x8(%rbx,%r12), %rsi
    0x10bb7e78f <+73>:  movq   %r13, %rax
    0x10bb7e792 <+76>:  negq   %rax
    0x10bb7e795 <+79>:  leaq   -0x38(%rbp), %rdx
    0x10bb7e799 <+83>:  movq   %rax, (%rdx)
    0x10bb7e79c <+86>:  leaq   -0x30(%rbp), %rcx
    0x10bb7e7a0 <+90>:  movq   $0x2, (%rcx)
    0x10bb7e7a7 <+97>:  leaq   -0x50(%rbp), %r12
    0x10bb7e7ab <+101>: movq   %r12, %rdi
    0x10bb7e7ae <+104>: callq  0x10bb7e820               ; std::__1::pair<objc::DenseMapIterator<DisguisedPtr<objc_object>, unsigned long, (anonymous namespace)::RefcountMapValuePurgeable, objc::DenseMapInfo<DisguisedPtr<objc_object> >, objc::detail::DenseMapPair<DisguisedPtr<objc_object>, unsigned long>, false>, bool> objc::DenseMapBase<objc::DenseMap<DisguisedPtr<objc_object>, unsigned long, (anonymous namespace)::RefcountMapValuePurgeable, objc::DenseMapInfo<DisguisedPtr<objc_object> >, objc::detail::DenseMapPair<DisguisedPtr<objc_object>, unsigned long> >, DisguisedPtr<objc_object>, unsigned long, (anonymous namespace)::RefcountMapValuePurgeable, objc::DenseMapInfo<DisguisedPtr<objc_object> >, objc::detail::DenseMapPair<DisguisedPtr<objc_object>, unsigned long> >::try_emplace<unsigned long>(DisguisedPtr<objc_object>&&, unsigned long&&)
    0x10bb7e7b3 <+109>: cmpb   $0x0, 0x10(%r12)
    0x10bb7e7b9 <+115>: jne    0x10bb7e7d1               ; <+139>
    0x10bb7e7bb <+117>: movq   -0x50(%rbp), %rax
    0x10bb7e7bf <+121>: movq   0x8(%rax), %rcx
    0x10bb7e7c3 <+125>: cmpq   $0x1, %rcx
    0x10bb7e7c7 <+129>: ja     0x10bb7e7f6               ; <+176>
    0x10bb7e7c9 <+131>: orq    $0x2, %rcx
    0x10bb7e7cd <+135>: movq   %rcx, 0x8(%rax)
    0x10bb7e7d1 <+139>: movq   %r15, %rdi
    0x10bb7e7d4 <+142>: callq  0x10bb822d6               ; symbol stub for: os_unfair_lock_unlock
    0x10bb7e7d9 <+147>: movl   $0x1, %r15d
    0x10bb7e7df <+153>: testb  %r14b, %r14b
    0x10bb7e7e2 <+156>: je     0x10bb7e80e               ; <+200>
    0x10bb7e7e4 <+158>: movq   0x169bd(%rip), %rsi       ; "dealloc"
    0x10bb7e7eb <+165>: movq   %r13, %rdi
    0x10bb7e7ee <+168>: callq  *0x1486c(%rip)            ; (void *)0x000000010bb62880: objc_msgSend
->  0x10bb7e7f4 <+174>: jmp    0x10bb7e80e               ; <+200>
    0x10bb7e7f6 <+176>: testq  %rcx, %rcx
    0x10bb7e7f9 <+179>: js     0x10bb7e803               ; <+189>
    0x10bb7e7fb <+181>: addq   $-0x4, %rcx
    0x10bb7e7ff <+185>: movq   %rcx, 0x8(%rax)
    0x10bb7e803 <+189>: movq   %r15, %rdi
    0x10bb7e806 <+192>: callq  0x10bb822d6               ; symbol stub for: os_unfair_lock_unlock
    0x10bb7e80b <+197>: xorl   %r15d, %r15d
    0x10bb7e80e <+200>: movq   %r15, %rax
    0x10bb7e811 <+203>: addq   $0x28, %rsp
    0x10bb7e815 <+207>: popq   %rbx
    0x10bb7e816 <+208>: popq   %r12
    0x10bb7e818 <+210>: popq   %r13
    0x10bb7e81a <+212>: popq   %r14
    0x10bb7e81c <+214>: popq   %r15
    0x10bb7e81e <+216>: popq   %rbp
    0x10bb7e81f <+217>: retq
```
</pre>
</details>

很扎心, 用LLDB运行的结果和实际的并不一样的事情我并不能确定原因.

不过, 我还是上传了源码: [madordie/PerformDemo](https://github.com/madordie/PerformDemo)

希望能找到答案~ 😭

纯猜一下:

关于LLDB曾经有过这么一段讨论:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">It seems that the retain count of the object increases 1 whenever you execute `expression object`. Another workaround is to use frame variable<br><br>(lldb) frame variable object <a href="https://t.co/Y2ghQ3sHzL">pic.twitter.com/Y2ghQ3sHzL</a></p>&mdash; Pofat (@PofatTseng) <a href="https://twitter.com/PofatTseng/status/1057644037107118080?ref_src=twsrc%5Etfw">October 31, 2018</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

会不会和`Debug Area`有关系?