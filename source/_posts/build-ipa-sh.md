---
title: Xcode8打包脚本
date: 2016-09-26 14:55:09
tags:
---

Xcode8下的打包脚本

<!--more-->

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
ipa_download_url="https://git.oschina.net/madordie/install_ipa/raw/master/xxxx_ent.ipa"
#itms-services协议串
ios_install_url="itms-services://?action=download-manifest&url=https://git.oschina.net/madordie/install_ipa/raw/master/xxxx_ent.plist"

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