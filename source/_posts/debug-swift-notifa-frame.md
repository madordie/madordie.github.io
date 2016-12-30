---
title: DEBUG - swift中取出通知中的frame
date: 2016-12-01
tags: 
categories:
    - DEBUG
---

swift中获取OC存储的Frame两种获取方案。

<!--more-->

# Swift下在Notification.userInfo取Frame，Debug和Release情况下还不一样。。
  -->更新于2016.12.1
  
  __ Version 8.1 (8B62) __

  ``` swift
    func keyboardShow(sender: Notification) {
        var endFrame = CGRect.zero        
        if let frame = sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            endFrame = frame
            //  *** Debug是可以通过的。但是Release无法通过。
            NSLog("<<<INFO>>>: as CGRect")
        } else if let value = sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            endFrame = value.cgRectValue
            //  *** Release会取出NSValue
            NSLog("<<<INFO>>>: as NSValue")
        }

  ```

  由于Release无法调试，所以费了不少劲。首先Swift中的字典已经可以存放值类型，其本身也是值类型。所以我首先选择了第一种写法`let frame = sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect`, 但是Release情况下却发生解包失败的情况。所以采用OC的传统写法`let value = sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue`。就能解析出来。但是总感觉OC的方法不够swift😂。。。

  有同事直接强制转换为NSValue是没有问题的，于是乎试了一下，发现直接校验NSValue就可以。但是swift中感觉不应该有这个转换了，毕竟本身就可以存储CGRect..

  猜测原因：目前阶段Swift的字典和OC的字典数据结构还并未完全一致。。

