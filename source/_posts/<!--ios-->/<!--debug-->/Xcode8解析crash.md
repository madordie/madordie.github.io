---
title: DEBUG - Xcode解析.crash
url: debug-xcode8-analysis-crash-file
date: 2016-11-14 12:43:22
tags:
    - DEBUG
categories:
    - iOS
---

5步解析`.crash`文件

<!--more-->

# Xcode中解析.crash文件
  
  1. 导出`x.crash`文件，放置在`目录A`下
  2. 复制`工程名.app.dSYM`到`目录A`
  3. 配置环境变量，运行`export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
  4. 拷贝脚本文件，运行`cp /Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash 目录A`
  5. 到`目录A`解析，运行`./symbolicatecrash x.crash 工程名.app.dSYM > 自定义输出结果文件名`

# 注

- 这里最重要的是`symbolicatecrash`文件，`symbolicatecrash`在手解析不愁。