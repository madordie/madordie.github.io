---
title: class的class-static-func使用Self作为返回值
url: class-static-func-return-self
date: 2020-05-18
tags:
    - DEBUG
    - Swift
categories:
	- iOS
---

# 一个问题

- Xcode: Version 11.4.1 (11E503a)
- swift: Swift 5

```swift
import UIKit
class MDButton: UIButton {
    // 为了更清楚展示问题,代码经过精简
    open class func make() -> Self {
        return MDButton()
    }
}
```

上面的代码无法编译:

```txt
ViewController.swift: error: cannot convert return expression of type 'MDButton' to return type 'Self'
        return MDButton()
               ^~~~~~~~~~
                          as! Self
```

<!--more-->

# 查找关于`Self`的新特性

[Proposal: SE-0068](https://github.com/apple/swift-evolution/blob/master/proposals/0068-universal-self.md)这里有说到关于这个`Self`的问题.

其目的是为了解决:

> - `dynamicType` remains an exception to Swift's lowercased keywords rule. This change eliminates a special case that's out of step with Swift's new standards.
> - `Self` is shorter and clearer in its intent. It mirrors `self`, which refers to the current instance.
> - It provides an easier way to access static members. As type names grow large, readability suffers. `MyExtremelyLargeTypeName.staticMember` is unwieldy to type and read.
> - Code using hardwired type names is less portable than code that automatically knows its type.
> - Renaming a type means updating any `TypeName` references in code.
> - Using `self.dynamicType` fights against Swift's goals of concision and clarity in that it is both noisy and esoteric.

所以说该问题在`struct`中并不存在,也就是下面的代码完全没有问题:

```swift
struct xxx {
    static func make() -> Self {
        return xxx()
    }
}
```

# 究竟如何修改

好吧,上面测试过这几个关键字之后,尝试修改函数内的返回对象吧.此时既然`Self`是`dynamicType`,那么可以使用`self`去调用初始化方法就行了吧, 于是:

```swift
class MDButton2 {
    required init() {}
     class func make() -> Self {
        // 或 return self.init()
        return Self()
    }
}
```

# 一点看法

首先, 整个过程(包括Xcode的提示)不使用`as!`的解决方案, 对,我就是那个坚决不使用`as!`的人(刷题除外).

然后, 可以翻一下这个`Self`的实现[apple/swift#22863](https://github.com/apple/swift/pull/22863),内容比较多.