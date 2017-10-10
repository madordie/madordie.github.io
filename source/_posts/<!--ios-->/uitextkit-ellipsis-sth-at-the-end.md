---
title: 如何实现AppStore查看更多的方法
url: uitextkit-ellipsis-sth-at-the-end
date: 2016-12-23 16:37:37
tags:
    - 效果
categories:
      - iOS
---

-- 2017.9.20 更新 --
看到AppStore的`更多`效果，做的不错哎，本文尝试采用`UITextKit`进行实现。

 <img src="https://github.com/madordie/UITextView-More/blob/master/Untitled.gif?raw=true" alt="效果图">

<!--more-->

App Store中的查看更多动画是不是很给力？可是做起来确不知道如何下手？这里我提供一种UITextKit的方法来简单的实现一下。

为了让例子简单，我就直接写了个more，那个view是自定义的，随便添加的，和本身的文本展示的并没有什么关系。

为了让最后的那个moreView更加好用，增加了已经展开显示全部是否隐藏的控制。
  

### 主要代码

#### 获取最后一行Rect

  ```swift
  var lastRect = CGRect.zero
  layoutManager.enumerateEnclosingRects(forGlyphRange: NSRange(location: 0, length: textStorage.string.characters.count), withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: textContainer, using: { [weak self] (rect, isStop) in
  guard let _self = self else { return }
  var newRect = rect
  newRect.origin.y += _self.textContainerInset.top
  lastRect = newRect
  })
  print(lastRect)
```

#### 增加 `exclusionPaths`

  ```swift
  textContainer.exclusionPaths = [UIBezierPath.init(rect: rect)]
```

### 备注

- [github](https://github.com/madordie/UITextView-More)
- `UITextView`默认携带左右边距，通过`UITextView.textContainer.lineFragmentPadding`获取
- `UITextView`默认携带上下左右边距(`UITextView.textContainerInset`)，其中左右和`lineFragmentPadding`相加
- 此处并没有对[TruncateTextView](https://github.com/madordie/UITextView-More/blob/master/TruncateTextView.swift)进行过多的设置，主要是因为继承在UITextView下，[GIF](https://github.com/madordie/UITextView-More/blob/master/Untitled.gif)中的这部分设置放在了[ViewController.swift](https://github.com/madordie/UITextView-More/blob/master/Demo-AppStore-More/ViewController.swift)中
- 此处使用的是`frame`，可以在`UIView.sizeToFit()`之后获取到`UIView`的`Size`。约束也大抵如此

----

- 感谢[乐逍遥](https://github.com/lexiaoyao20)提供的例子，才找到了`open func truncatedGlyphRange(inLineFragmentForGlyphAt glyphIndex: Int) -> NSRange`方法😂
