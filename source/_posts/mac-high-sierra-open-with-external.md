---
title: mac10.13依旧让Xcode支持打开终端
date: 2017-09-28 19:06:47
tags:
---

在macOS10.13以前是支持Xcode中直接打开终端的，步骤呢就是下面这样子：

![效果图](/images/mac-high-sierra-open-with-external-1.gif)

1. 右击工程
2. Open With External Editor
3. 终端弹出来了。。

如果没有生效，就是你的电脑上装了什么可以打开`xx.xcodeproj`的应用程序，也就是在`Finder`下右击可以看到如下样式：

![效果图](/images/mac-high-sierra-open-with-external-2.jpg)

呐～ Xcode为默认，备忘录为默认下面的第一个～～

对，如果这样的话，那么按照上面3步，得到的结果是：这个文件被莫名其妙的保存在了备忘录～～  

这不是我们要的🤷‍♂️，下面我们通过修改`备忘录.app`的配置文件来达到我们的效果。

<!--more-->

### 成因

macSO10.13加强了备忘录，嗯的确变强了，可是并没有Xcode和终端常用。

备忘录增加了导入的功能，支持了一些文件的打开(只是导入而已。。)，但是并不适合我。于是改一下吧～～

### 操作

1. 在`应用程序`中找到`备忘录`
2. 显示包内容
3. 找到 我们要修改的plist文件： `Contents/Info.plist`
4. 做一下备份：复制一下。。
5. 确保 <4> 已完成
6. 直接修改`Info.plist`会提示没有权限，使用`sudo vim Info.plist`修改
7. 不管你用什么方法，删除下面的这些代码
```xml
<dict>
    <key>CFBundleTypeName</key>
    <string>General files and folders</string>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>LSItemContentTypes</key>
    <array>
        <string>public.data</string>
        <string>public.directory</string>
    </array>
</dict>
```
8. `:wq`
9. 重启一下 （目的：重建索引）

### 至于我做了什么

讲道理，用Xcode的都知道吧？这个是注册的app支持的文件类型。 删除之后就可以了，就这么多😂

### 注意一下

`操作`中的`步骤9`可以有脚本，但是还是老实重启一下吧，有的脚本会使部分图标失效，巨烦。。还是重启一下比较靠谱。毕竟不着急
