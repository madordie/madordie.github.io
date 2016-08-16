---
title: 开发小记
date: 2016-07-28 14:52:22
tags: 
categories:
    - 笔记
---


开发中的小笔记。记录开发中的点滴滴点。



- NAN: 当`NSUInteger 0 - 1`时，运算结果为 NAN，iOS中有一个宏`isnan(x)`返回是否为nan。另外这里有一篇文章[Objective-C 中 判断 NaN](http://blog.csdn.net/toss156/article/details/7101885)大致记录了一下
```objc
//  math.h  #56

#if defined(__GNUC__)
#   define    HUGE_VAL     __builtin_huge_val()
#   define    HUGE_VALF    __builtin_huge_valf()
#   define    HUGE_VALL    __builtin_huge_vall()
#   define    NAN          __builtin_nanf("0x7fc00000")
#else
#   define    HUGE_VAL     1e500
#   define    HUGE_VALF    1e50f
#   define    HUGE_VALL    1e5000L
#   define    NAN          __nan()
#endif

//  另外，NAN不能直接判断 == 需要调用下面的宏。否则会发生莫名其妙的问题
#define isnan(x)                                                         \
    ( sizeof(x) == sizeof(float)  ? __inline_isnanf((float)(x))          \
    : sizeof(x) == sizeof(double) ? __inline_isnand((double)(x))         \
                                  : __inline_isnanl((long double)(x)))

```


- 论项目架构设计的重要性
- 百度地图的坑
- 筛选的坑