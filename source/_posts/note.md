---
title: 开发小记
date: 2016-07-28 14:52:22
tags: 
categories:
    - 笔记
---


开发中的小笔记。记录开发中的点滴滴点。

<!--more-->

- 批量正则替换的另一种思路
  ```
  #!/base/sh
  find . -name '*.swift' | while read file; do
    perl -i -lpe 's/if \(([^\)].*)\) \{/if $1 \{/g' $file
  done
  ```

- 批量删除空格组成的空行中的空格
  ```
  #!/base/sh
  find . -name '*.swift' | while read file; do
    sed -i '' 's/^[[:space:]][[:space:]]*$//g' $file
  done
  ```

- NAN
  - 当`NSUInteger 0 - 1`时，运算结果为 NAN，iOS中有一个宏`isnan(x)`返回是否为nan。另外这里有一篇文章[Objective-C 中 判断 NaN](http://blog.csdn.net/toss156/article/details/7101885)大致记录了一下
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

```
  
  - 另外，NAN不能直接判断 == 需要调用下面的宏。否则会发生莫名其妙的问题
  ``` objc
    //  math.h  #178

  #define isnan(x)                                                         \
      ( sizeof(x) == sizeof(float)  ? __inline_isnanf((float)(x))          \
      : sizeof(x) == sizeof(double) ? __inline_isnand((double)(x))         \
                                    : __inline_isnanl((long double)(x)))
```

- 论项目架构设计的重要性 
  - 规范化
  - 筛选的坑 
  - 常见布局BUG 
  - 线程安全
  
- 百度地图的坑
  - 设置经纬度缓慢
  - 刷新缓慢

- 选择图片时候默认方法选择不到系统的云端图片，但是默认单张选择器却可以！
  - 16G手机存储空间不够，图片转到了云端，会出现相册中的照片无法选择的情况
  
- 无埋点技术的讨论

- 多个window的显示、删除、操作问题

- 使用HTTP架设日志实时显示系统