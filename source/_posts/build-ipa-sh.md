---
title: Xcode8打包脚本
date: 2016-09-26 14:55:09
tags:
---

## Xcode8

  好悲催，Xcode8更新之后Jenkins打包失败了。。由于代码库中使用了swift3语法，故必须使用Xcode8。。
  
  先来重点：可用脚本：

  ```bash
  #!/bin/bash

  #   追上fir API token 自动上传
  #   基于当前代码进行打包打包目录：MyProject/build/MyProject_ent.ipa

  cd MyProject

  rm -rf ./build/*

  xcodebuild -archivePath "./build/xxx.xcarchive" -workspace MyProject.xcworkspace -sdk iphoneos -scheme "MyProject_ent" -configuration "Release Inhouse" archive

  echo "<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>method</key><string>enterprise</string><key>compileBitcode</key><string>YES</string></dict></plist>" > ./build/exportOptionsPlist.plist

  xcodebuild -exportArchive -archivePath "./build/xxx.xcarchive" -exportPath "./build/" -exportOptionsPlist ./build/exportOptionsPlist.plist


  cd build/

  fir i ./MyProject_ent.ipa


  if [ -n "$1" ]; then
      git log -10 > git.log
      fir p ./MyProject_ent.ipa -T $1 -c git.log
  fi

  ```
  
  之前漏掉了一个错误：`The flag -exportFormat cannot be specified along with -exportOptionsPlist` 导致了最终包签名错误，而无法安装。

  exportOptionsPlist参考的[iOS 打包总结](https://testerhome.com/topics/4619)
