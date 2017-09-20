---
title: 如何实现AppStore查看更多的方法
date: 2016-12-23 16:37:37
tags:
    - 效果
categories:
      - iOS
---

看到AppStore的`更多`效果，做的不错哎，本文尝试采用`exclusionPaths`进行实现。不过有瑕疵。。来年用追加的方式在实现一下。感觉追加的方式比较简单。，

<!--more-->

# 效果
<img src="https://github.com/madordie/UITextView-More/blob/master/Untitled.gif?raw=true" alt="效果图">

# 简要说明
  App Store中的查看更多动画是不是很给力？可是做起来确不知道如何下手？这里我提供一种UITextKit的方法来简单的实现一下。
  
  为了让例子简单，我就直接写了个more，那个view是自定义的，随便添加的，和本身的文本展示的并没有什么关系。
  
  为了让最后的那个moreView更加好用，增加了已经展开显示全部是否隐藏的控制。
  
  
# 代码

  先看下Demo中调用吧：
  ```swift
  let info = KTJExclusionLabel()
  info.exclusionView = more
  info.isAutoHidenExclusionView = isAutoHiden.isOn
  info.numberOfLines = Int.init(line.text ?? "") ?? 0
  info.sizeToFit()
  ```

  然后KTJExclusionLabel的实现：
  ```swift
  //
  //  KTJExclusionLabel.swift
  //  UITextKit-AppStore-more
  //
  //  Created by 孙继刚 on 2016/12/24.
  //  Copyright © 2016年 madordie. All rights reserved.
  //

  import UIKit

  class KTJExclusionLabel: UITextView {

      /// 行数
      public var numberOfLines: Int {
          set {
              textContainer.maximumNumberOfLines = newValue
          }
          get {
              return textContainer.maximumNumberOfLines
          }
      }

      public var isAutoHidenExclusionView: Bool = false

      /// 避让的view
      public weak var exclusionView: UIView? {
          didSet {
              setNeedsLayout()
          }
      }

      override init(frame: CGRect, textContainer: NSTextContainer?) {
          super.init(frame: frame, textContainer: textContainer)
          setup()
      }

      required init?(coder aDecoder: NSCoder) {
          super.init(coder: aDecoder)
          setup()
      }

      func setup() {
          isEditable = true
          textContainer.lineBreakMode = .byTruncatingTail
      }

      override func sizeToFit() {
          //  对其API还不熟悉，还没有找到如何一次判断出是否已经展示完全。。找到后再更

          let originLines = numberOfLines
          numberOfLines = 0
          let maxHeight = resizeThatFits(frame.size).height
          numberOfLines = originLines
          frame.size = resizeThatFits(frame.size)

          exclusionView?.isHidden = false
          if frame.height == maxHeight {
              frame.size = resizeThatFits(frame.size, isOver: true)
              if isAutoHidenExclusionView {
                  exclusionView?.isHidden = true
              }
          }
      }

      func resizeThatFits(_ size: CGSize, isOver: Bool = false) -> CGSize {
          var frame = CGRect.zero
          frame.size = size

          textContainer.exclusionPaths.removeAll()

          var ovalPaths = [UIBezierPath]()
          if let exclusionView = exclusionView {
              var lastLineFrame = CGRect.zero
              var lineIdx = 0
              var lastFrame = CGRect.zero
              layoutManager.enumerateLineFragments(forGlyphRange: NSMakeRange(0, text.characters.count)) { (rect1, rect2, textContainer, range, pointer) in
                  if lineIdx < textContainer.maximumNumberOfLines {
                      lastLineFrame = rect2
                  }
                  lineIdx += 1
                  lastFrame = rect2
              }

              if lastLineFrame == CGRect.zero {
                  lastLineFrame = lastFrame
              }
              //  矫正
              lastLineFrame.origin.x += textContainerInset.left
              lastLineFrame.origin.y += textContainerInset.top

              //  为末尾算出最大的frame
              lastLineFrame.origin.x = lastLineFrame.maxX
              lastLineFrame.origin.y = lastLineFrame.minY
              lastLineFrame.size.width = frame.width - lastLineFrame.minX
              lastLineFrame.size = exclusionView.sizeThatFits(lastLineFrame.size)
              if lastLineFrame.maxX >= frame.width {

                  if isOver == false {
                      lastLineFrame.origin.x -= lastLineFrame.maxX - frame.width + max(textContainerInset.bottom, textContainerInset.right)
                  } else {
                      lastLineFrame.origin.x = lastFrame.minX + textContainerInset.left + 5
                      lastLineFrame.origin.y += lastFrame.height
                  }
              }
              exclusionView.frame = convert(lastLineFrame, to: exclusionView.superview)

              var ovalFrame = convert(exclusionView.bounds, from: exclusionView)
              ovalFrame.origin.x += 5 + textContainerInset.left
              ovalPaths.append(UIBezierPath(rect: ovalFrame))

              if isOver, isAutoHidenExclusionView {
                  frame.size.height = lastFrame.maxY + textContainerInset.bottom
              } else {
                  frame.size.height = ovalFrame.maxY + textContainerInset.bottom
              }
          } else {
              frame.size = super.sizeThatFits(size)
          }
          textContainer.exclusionPaths = ovalPaths

          return CGSize(width: frame.maxX, height: frame.maxY)
      }
  }

  ```
  代码只是简单的做了一个DEMO，并没有仔细的调试，如果使用的话可能看需要根据自己的需求进行简单的调试吧。比如说偏移量、布局之类的。
  
