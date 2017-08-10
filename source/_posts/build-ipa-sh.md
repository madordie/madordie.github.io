---
title: Xcode8打包脚本
date: 2016-09-26 14:55:09
tags:
categories:
    - 工具
---

Jenkins自动构建脚本解决方案。

<!--more-->

## 写在前面
  2017.1.13更新：
  好吧，其实有更加强悍的打包工具，虽然早有耳闻但是没弄。然后最近搭建了一下，这打包脚本也不用了，毕竟有成套工具嘛。嘿嘿
  不过最后上传osc的脚本还是很可以的。
  传送门：[Fastlane自动化笔记](https://madordie.github.io/fastlane-note/#more)

  2017.6.14更新:
  [xcpretty](https://github.com/supermarin/xcpretty)格式化输出日志。很溜，输出效果和 `fastlane` 差不多哈哈

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


## 手动上传
  ```
  #!/bin/bash

  #   追上fir API token 自动上传
  #   基于当前代码进行打包打包目录：xxxx/build/xxxx_ent.ipa

  workspace_name=xxxx
  scheme_name=xxxx_ent


  cd $workspace_name

  rm -rf ./build/*

  xcodebuild -archivePath "./build/xxx.xcarchive" -workspace $workspace_name.xcworkspace -sdk iphoneos -scheme $scheme_name -configuration "Release Inhouse" archive


  cat << EOF > ./build/exportOptionsPlist.plist
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
      <dict>
          <key>method</key>
          <string>enterprise</string>
          <key>compileBitcode</key>
              <false/>
      </dict>
  </plist>
  EOF

  xcodebuild -exportArchive -archivePath "./build/xxx.xcarchive" -exportOptionsPlist "./build/exportOptionsPlist.plist" -exportPath "./build/"

  cd build/


  git log -10 > git.log

  #拷贝ipa到临时文件夹中
  cp ./$scheme_name.ipa ./tmp.zip
  #将ipa解压
  unzip tmp.zip

  #app文件中Info.plist文件路径
  app_infoplist_path=$(pwd)/Payload/*.app/Info.plist
  #取bundleIdentifier
  bundleIdentifier=$(/usr/libexec/PlistBuddy -c "print CFBundleIdentifier" ${app_infoplist_path})
  #取build值
  bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_infoplist_path})
  #显示名称
  ipa_name=$workspace_name

  #ipa下载url
  ipa_download_url="https://***/install_ipa/raw/master/xxxx_ent.ipa"
  #itms-services协议串
  ios_install_url="itms-services://?action=download-manifest&url=https://***/install_ipa/raw/master/xxxx_ent.plist"

  #生成install.html文件

  cat << EOF > index.html
  <!DOCTYPE HTML>
  <html>
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <title>安装</title>
    </head>
    <body>
      <br>
      <br>
      <br>
      <br>
      <p align=center>
          <font size="8">
              <a href="${ios_install_url}">点击这里安装</a>
          </font>
      </p>

      </div>
    </body>
  </html>
  EOF

  #生成plist文件
  cat << EOF > ${workspace_name}.plist
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
     <key>items</key>
     <array>
         <dict>
             <key>assets</key>
             <array>
                 <dict>
                     <key>kind</key>
                     <string>software-package</string>
                     <key>url</key>
                     <string>${ipa_download_url}</string>
                 </dict>
                 <dict>
                     <key>kind</key>
                     <string>display-image</string>
                     <key>needs-shine</key>
                     <true/>
                     <key>url</key>
                     <string>http://git.oschina.net/logo.svg</string>
                 </dict>
             <dict>
                     <key>kind</key>
                     <string>full-size-image</string>
                     <key>needs-shine</key>
                     <true/>
                     <key>url</key>
                     <string>http://git.oschina.net/logo.svg</string>
                 </dict>
             </array><key>metadata</key>
             <dict>
                 <key>bundle-identifier</key>
                 <string>${bundleIdentifier}</string>
                 <key>bundle-version</key>
                 <string>${bundleVersion}</string>
                 <key>kind</key>
                 <string>software</string>
                 <key>subtitle</key>
                 <string>${ipa_name}</string>
                 <key>title</key>
                 <string>${ipa_name}</string>
             </dict>
         </dict>
     </array>
  </dict>
  </plist>
  EOF

  fir i $scheme_name.ipa
  ```

## 手动上传到OSC脚本
  ```
  #!/bin/bash

  root_path=$(pwd)
  workspace_name=Fangduoduo
  scheme_name=XXX

  # 编译
  cd $root_path
  cd $workspace_name

  rm -rf ./build/*

  xcodebuild -archivePath ./build/$scheme_name.xcarchive -workspace $workspace_name.xcworkspace -sdk iphoneos -scheme $scheme_name -configuration "Release Inhouse" archive

  echo "<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>method</key><string>enterprise</string><key>compileBitcode</key><false/></dict></plist>" > ./build/exportOptionsPlist.plist

  xcodebuild -exportArchive -archivePath ./build/$scheme_name.xcarchive -exportOptionsPlist "./build/exportOptionsPlist.plist" -exportPath "./build/"


  cd build/

  if [ ! -f $scheme_name.ipa ]; then
      echo "*** 无法打包 ***"
      exit -1
  fi

  fir i ./$scheme_name.ipa

  git log -10 > git.log
  git_log=$(cat git.log)
  # fir 上传
  if [ -n "$1" ]; then
      fir p ./$scheme_name.ipa -T $1 -c git.log
  fi


  # 校验HTML并上传

  public_git_path=$root_path/public_ipa_tmp/
  public_git_root="install_ipa"
  public_git="https://***/install_ipa.git"
  #ipa下载url
  ipa_download_url="https://***/install_ipa/raw/master/XXX.ipa"
  #itms-services协议串
  ios_install_url="itms-services://?action=download-manifest&url=https://***/install_ipa/raw/master/XXX.plist"


  cd $root_path/
  # checkout path is OK
  if [ ! -e $public_git_path ]; then
      mkdir $public_git_path
  fi

  if [ -n $public_git_path ]; then
      rm -rf $public_git_path
  fi
  mkdir $public_git_path
  cd $public_git_path
  git init
  git remote add origin $public_git


  cd $root_path/$workspace_name/build/

  #拷贝ipa到临时文件夹中
  cp ./$scheme_name.ipa ./tmp.zip
  rm -rf Payload
  #将ipa解压
  unzip tmp.zip

  #app文件中Info.plist文件路径
  app_infoplist_path=$(pwd)/Payload/*.app/Info.plist
  #取bundleIdentifier
  bundleIdentifier=$(/usr/libexec/PlistBuddy -c "print CFBundleIdentifier" ${app_infoplist_path})
  #取build值
  bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_infoplist_path})
  #取shortVersionbuild值
  shortVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${app_infoplist_path})
  #显示名称
  ipa_name=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName" ${app_infoplist_path})
  nowTime=$(date +%Y-%m-%d\ %H:%M)
  log_url="https://madordie.github.io/uploads/avatar.png"

  #生成install.html文件

  cat << EOF > index.html
  <!DOCTYPE HTML>
  <html>
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=1,user-scalable=0">
  <title>${ipa_name}安装</title>
  <style>
  .containor {
      position: relative;
      top: 0;
      left: 0;
      right: 0;
      margin: 0 auto;
      width: 100%;
      max-width: 640px;
      text-align: center;
  }
  .logo {
      width: 120px;
      margin-top: 30px;
  }
  .title,
  .version_history,
  .update_time {
      text-align: center;
      color: #999;
      font-size: 16px;
  }
  .title {
      margin-top: 10px;
  }
  .version_history,
  .update_time {
      margin-top: 5px;
  }
  .download {
      display: block;
      width: 150px;
      height: 30px;
      line-height: 30px;
      margin: 0 auto;
      margin-top: 20px;
      border: 1px solid #eee;
      border-radius: 20px;
      text-decoration: none;
      color: #999;
  }
  .log_title {
      margin-top: 20px;
      font-size: 18px;
      color: #333;
  }
  .log {
      color: #aaa;
      padding: 20px;
      text-align: left;
      font-size: 12px;
      line-height: 15px;
      white-space: pre-wrap;
      word-wrap: break-word;
      overflow: hidden;
  }
  </style>
  </head>
  <body>
  <div class="containor">
      <img class="logo" src=${log_url} />
      <div class="title">$ipa_name</div>
      <div class="version_history">${shortVersion}(bundle:${bundleVersion})</div>
      <div></div>
      <div class="update_time">${nowTime}</div>
      <a class="download" href="${ios_install_url}">点击这里安装</a>
      <div class="log_title">更新日志</div>
      <div class="log"> ${git_log} </div>
  </div>
  </body>
  </html>
  EOF

  #生成plist文件
  cat << EOF > ${scheme_name}.plist
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
     <key>items</key>
     <array>
         <dict>
             <key>assets</key>
             <array>
                 <dict>
                     <key>kind</key>
                     <string>software-package</string>
                     <key>url</key>
                     <string>${ipa_download_url}</string>
                 </dict>
                 <dict>
                     <key>kind</key>
                     <string>display-image</string>
                     <key>needs-shine</key>
                     <true/>
                     <key>url</key>
                     <string>http://git.oschina.net/logo.svg</string>
                 </dict>
             <dict>
                     <key>kind</key>
                     <string>full-size-image</string>
                     <key>needs-shine</key>
                     <true/>
                     <key>url</key>
                     <string>http://git.oschina.net/logo.svg</string>
                 </dict>
             </array><key>metadata</key>
             <dict>
                 <key>bundle-identifier</key>
                 <string>${bundleIdentifier}</string>
                 <key>bundle-version</key>
                 <string>${bundleVersion}</string>
                 <key>kind</key>
                 <string>software</string>
                 <key>subtitle</key>
                 <string>${ipa_name}</string>
                 <key>title</key>
                 <string>${ipa_name}</string>
             </dict>
         </dict>
     </array>
  </dict>
  </plist>
  EOF

  #fir i $scheme_name.ipa
  cp $scheme_name.ipa $public_git_path
  cp $scheme_name.plist $public_git_path
  cp index.html $public_git_path

  cd $public_git_path
  ls -l > README.md
  if [ ! -e "./.git/" ]; then
      echo "*** OSC的git目录不完整，无法上传，请联系开发! ***"
      exit -1
  fi
  echo "commit and pushing ..."
  git add .
  git commit -am $bundleVersion
  git push -f origin master
  ```
