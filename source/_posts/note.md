---
title: 开发小记
date: 2016-07-28 14:52:22
tags:
    - 笔记
categories:
    - iOS
---


开发中的小笔记。记录开发中的点滴滴点。

<!--more-->

- 获取代码执行时间
```swift
#import <mach/mach_time.h>
static NSMutableDictionary *__times;
static inline void debug_start_of(NSString *key)
{
    __times = __times ?: [NSMutableDictionary new];

    uint64_t start = mach_absolute_time();
    __times[key] = @(start);
}
static inline void debug_stop_of(NSString *key)
{
    if (__times) {
        uint64_t end = mach_absolute_time();
        uint64_t start = [__times[key] unsignedLongLongValue];
        if (start != 0) {
            uint64_t elapsed = end - start;
            mach_timebase_info_data_t info;
            if (mach_timebase_info(&info) != KERN_SUCCESS) {
                printf("mach_timebase_info failed\n");
            }
            uint64_t nanosecs = elapsed * info.numer / info.denom;
            uint64_t millisecs = nanosecs / 1000000;

            printf("[DEBUG code rt] %s:%llu ms\n", [key cStringUsingEncoding:NSUTF8StringEncoding], millisecs);
        } else {
            printf("[DEBUG code rt] %s error: no start\n", [key cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
}
```

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
  - `A`对`B`除余时，如果`B == 0` 则会造成NAN，`truncatingRemainder(dividingBy:)`是`swift`的方法，也会造成此问题
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
