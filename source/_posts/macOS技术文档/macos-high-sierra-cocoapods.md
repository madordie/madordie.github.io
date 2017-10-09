---
title: mac10.13 pods 命令错误
url: macos-high-sierra-cocoapods
date: 2017-09-29 14:03:58
tags:
    - cocoapods
categories:
    - macOS
---

每逢升级大版本总要过搞点事情。

```sh
$ pod env
-bash: /usr/local/bin/pod: /System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/bin/ruby: bad interpreter: No such file or directory
```

不论是`pod env`、`pod update` 等等均报上面的错误。

如果Google发现：

- [ruby - CocoaPods not working in macOS High Sierra - Stack Overflow](https://stackoverflow.com/questions/44396215/cocoapods-not-working-in-macos-high-sierra)
- [CocoaPods CLI fails in High Sierra due to change of Ruby version #6778](https://github.com/CocoaPods/CocoaPods/issues/6778)
- [High Sierra: bad interpreter #6898](https://github.com/CocoaPods/CocoaPods/issues/6898#issuecomment-332060096)

事情的缘由就是这样。

[#6898](https://github.com/CocoaPods/CocoaPods/issues/6898#issuecomment-332060096)中道出了简单直接的解决方案：

> for all others:

> `gem install -n /usr/local/bin cocoapods`

> fixes it

**综合起来**解决这个问题是这样的：

```sh
$ gem update --system
$ gem uninstall cocoapods
$ echo 'gem: --bindir /usr/local/bin' >> ~/.gemrc
$ sudo gem install cocoapods
```

愉快的使用cocoapods吧～
