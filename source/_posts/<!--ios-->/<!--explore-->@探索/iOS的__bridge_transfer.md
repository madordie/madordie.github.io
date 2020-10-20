---
title: iOS的__bridge_retained可以做什么
url: what-happened-on-the-bridge-in-ios-2
date: 2020-10-20
tags:
    - DEBUG
    - __bridge*
categories:
    - iOS
---

## 抛出问题

群友(@止一)昨晚上发了一个问题:

```ObjC
typedef struct Test {
    NSArray *arr;
} Test;
- (void)test {
    Test test = {};
    test.arr = @[@1, @2, @3];
    self.var = test;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self test];
    for (int i = 0; i < 1000; i++) {
        NSLog(@"%@", self.var.arr);
    }

}
```

> xcode12这样写会崩溃

<!--more-->

## 大佬提供的一些资料

- [Xcode 12 ReactNativeART Crash](https://lengmolehongyan.github.io/blog/2020/09/19/xcode-12-reactnativeart-crash/)
- [WWDC2018 Session409: What’s New in LLVM ](https://devstreaming-cdn.apple.com/videos/wwdc/2018/409t8zw7rumablsh/409/409_whats_new_in_llvm.pdf)

## 还原一下场景

打开`Zombie Objects`时场景如下:

![Xcode12-Zombie-Objects](/images/2020-10-20-10-35-52.png)

当不打开的时候是这样的:

![Xcode12-No-Zombie-Objects](/images/2020-10-20-10-39-08.png)

`Xcode11`并不崩溃:

![Xcode11](/images/2020-10-20-10-41-28.png)

## 对比一下汇编伪代码

仔细对比了一下代码,发现`test`函数完全一样:

```ObjC
- (void)test {
    Test test = {};
    test.arr = @[@1, @2, @3];
    self.var = test;
}
// 汇编伪代码
void __cdecl -[XX test](XX *self, SEL a2)
{
  v14 = self;
  v13 = a2;
  v8 = @[@1, @2, @3];
  v12 = objc_retainAutoreleasedReturnValue(v8);
  objc_release(0LL);
  __copy_constructor_8_8_s0(&v11, &v12);
  v9 = v14;
  __copy_constructor_8_8_s0(&v10, &v11);
  -[XX setVar:](v9, "setVar:", v10);
  __destructor_8_s0(&v12);
}
```

然后, 关联的`for-NSLog`:

```ObjC
- (void)main {
    [self test];
    for (int i = 0; i < 1000; i++) {
        NSLog(@"%@", self.var.arr);
    }
}
// Xcode12下汇编伪代码
void __cdecl -[XX main](XX *self, SEL a2)
{
  void *v2; // [rsp+10h] [rbp-20h]
  int i; // [rsp+1Ch] [rbp-14h]
  SEL v4; // [rsp+20h] [rbp-10h]
  void *v5; // [rsp+28h] [rbp-8h]

  v5 = self;
  v4 = a2;
  -[XX test](self, "test");
  for ( i = 0; i < 1000; ++i )
  {
    v2 = objc_msgSend(v5, "var");
    NSLog(CFSTR("%@"), v2);
    __destructor_8_s0((__int64)&v2);
  }
}
// Xcode12下汇编伪代码
void __cdecl -[XX main](XX *self, SEL a2)
{
  Test v2; // ST10_8
  signed int i; // [rsp+1Ch] [rbp-14h]

  -[XX test](self, "test");
  for ( i = 0; i < 1000; ++i )
  {
    v2.var0 = -[XX var](self, "var").var0;
    NSLog(CFSTR("%@"), v2.var0);
  }
}
```

所以Xcode12比Xcode11多了一行`__destructor_8_s0((__int64)&v2);`, 再看下这个是啥:

```ObjC
__int64 __fastcall __destructor_8_s0(__int64 a1)
{
  return objc_storeStrong(a1, 0LL);
}
```

结案, Xcode12下`self.var.arr`之后会将返回值进行一次`release`

## Xcode12的这种情境下如何修正

- 此处只是作为[iOS的__bridge、__bridge_transfer究竟做了啥](./what-happened-on-the-bridge-in-ios)的补充去讨论`__bridge_retained`, 至于真正的场景应该如何修复, 或许只是一个Xcode12的BUG, 请继续Google :>

按照[iOS的__bridge、__bridge_transfer究竟做了啥](./what-happened-on-the-bridge-in-ios)的思路来: 我们需要加一下`__bridge*`的标记, `struct`虽然不是`CoreFounction`的东西,但是可以用的

从对比来看, 我们应该修改的是`for-NSLog`中的代码, 这样才不至于引出其他的问题, 然后从[上文](./what-happened-on-the-bridge-in-ios)可以得知, 此处我们应该用`__bridge`, 来试验一下:

![Xcode12-__bridge](/images/2020-10-20-11-10-46.png)

GG, 我们注意到`__destructor_8_s0`函数在`test`中也出现过, 作用是释放`@[@1, @2, @3]`临时变量, 难道作用是`将ObjC对象交给C处理之后清理ObjC对象临时引用`? 按照这个思路我们应该试一下`__bridge_retained`, 目的是伪造一个从Objc对象移交给`CoreFounction`的假象,试一下:

![Xcode12-__bridge_retained](/images/2020-10-20-11-20-14.png)

不崩溃了~~

看下伪代码:

```ObjC
- (void)main {
    [self test];
    for (int i = 0; i < 1000; i++) {
        NSLog(@"%@", (__bridge_retained void*)(self.var.arr));
    }
    printf("over\n");
}
// Xcode12伪代码
void __cdecl -[XX main](XX *self, SEL a2)
{
  void *v2; // rax
  __int64 v3; // rax
  void *v4; // [rsp+10h] [rbp-20h]
  int i; // [rsp+1Ch] [rbp-14h]
  SEL v6; // [rsp+20h] [rbp-10h]
  void *v7; // [rsp+28h] [rbp-8h]

  v7 = self;
  v6 = a2;
  -[XX test](self, "test");
  for ( i = 0; i < 1000; ++i )
  {
    v2 = objc_msgSend(v7, "var");
    v4 = v2;
    v3 = objc_retain(v2);
    NSLog(CFSTR("%@"), v3);
    __destructor_8_s0((__int64)&v4);
  }
}
```

## 最后

从`__bridge`、`__bridge_transfer`到`__bridge_retained`, 而没有一处是关于`CoreFounction`的东西, 却看到了ARC下对引用计数的干预...

愿世界再无BUG~