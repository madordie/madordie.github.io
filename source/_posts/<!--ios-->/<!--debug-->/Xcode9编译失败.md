---
title: Xcode9编译失败
url: debug-xcode9-build-ipa
date: 2017-09-26 14:16:32
tags:
    - 构建
    - debug
categories:
    - iOS
---

## 错误输出

> error: exportArchive: "Fangduoduo_ent.app" requires a provisioning profile with the Push Notifications and Associated Domains features.

> Error Domain=IDEProvisioningErrorDomain Code=9 ""Fangduoduo_ent.app" requires a provisioning profile with the Push Notifications and Associated Domains features." UserInfo={NSLocalizedDescription="Fangduoduo_ent.app" requires a provisioning profile with the Push Notifications and Associated Domains features., NSLocalizedRecoverySuggestion=Add a profile to the "provisioningProfiles" dictionary in your Export Options property list.}

<!--more-->

## 错误原因

在升级Xcode9正式版之后，Jenkins也就升级了，于是乎用原来的套路打包之后就是上面的错误 5555...

如果使用`xcodebuild`进行处理，那么这个会发生在选择证书的步骤，错误大致就是这样。

`$xcodebuild --help` 可以看到一些信息，而且在最后还特意提出了一个“-exportOptionsPlist”参数。具体内容见`xcodebuild --help`

## 解决问题才是关键

1. 使用xcode9进行一次`archive`

2. 选择相关证书啊神马的，保持`thinning`不变就好

3. 导出

4. 导出目录有一个`ExportOptionsPlist.plist`，这个就是打包时候需要的plist

## 脚本构建

`ipa`即为目标变量，具体的参看[打包脚本](../build-ipa-sh)

```sh
rm -rf ./build/*
cat << EOF > ./build/exportOptionsPlist.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>compileBitcode</key>
    <true/>
    <key>method</key>
    <string>enterprise</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>ershoufanglzg.fangdd.com</key>
        <string>ershoufanglzg_dis</string>
    </dict>
    <key>signingCertificate</key>
    <string>iPhone Distribution</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>J3B467DURT</string>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

xcodebuild -archivePath "./build/xxx.xcarchive" -workspace Fangduoduo.xcworkspace -sdk iphoneos -scheme "Fangduoduo_ent" -configuration "Release Inhouse" archive
xcodebuild -exportArchive -archivePath "./build/xxx.xcarchive" -exportPath "./build/" -exportOptionsPlist ./build/exportOptionsPlist.plist

ipa=$(pwd)/$(ls ./build/*.ipa)
```

## xcodebuild --help

> Available keys for -exportOptionsPlist:

> compileBitcode : Bool

> For non-App Store exports, should Xcode re-compile the app from bitcode? Defaults to YES.

> embedOnDemandResourcesAssetPacksInBundle : Bool

> For non-App Store exports, if the app uses On Demand Resources and this is YES, asset packs are embedded in the app bundle so that the app can be tested without a server to host asset packs. Defaults to YES unless onDemandResourcesAssetPacksBaseURL is specified.

> iCloudContainerEnvironment : String

> If the app is using CloudKit, this configures the "com.apple.developer.icloud-container-environment" entitlement. Available options vary depending on the type of provisioning profile used, but may include: Development and Production.

> installerSigningCertificate : String

> For manual signing only. Provide a certificate name, SHA-1 hash, or automatic selector to use for signing. Automatic selectors allow Xcode to pick the newest installed certificate of a particular type. The available automatic selectors are "Mac Installer Distribution" and "Developer ID Installer". Defaults to an automatic certificate selector matching the current distribution method.

> manifest : Dictionary

> For non-App Store exports, users can download your app over the web by opening your distribution manifest file in a web browser. To generate a distribution manifest, the value of this key should be a dictionary with three sub-keys: appURL, displayImageURL, fullSizeImageURL. The additional sub-key assetPackManifestURL is required when using on-demand resources.

> method : String

> Describes how Xcode should export the archive. Available options: app-store, package, ad-hoc, enterprise, development, developer-id, and mac-application. The list of options varies based on the type of archive. Defaults to development.

> onDemandResourcesAssetPacksBaseURL : String

> For non-App Store exports, if the app uses On Demand Resources and embedOnDemandResourcesAssetPacksInBundle isn't YES, this should be a base URL specifying where asset packs are going to be hosted. This configures the app to download asset packs from the specified URL.

> provisioningProfiles : Dictionary

> For manual signing only. Specify the provisioning profile to use for each executable in your app. Keys in this dictionary are the bundle identifiers of executables; values are the provisioning profile name or UUID to use.

> signingCertificate : String

> For manual signing only. Provide a certificate name, SHA-1 hash, or automatic selector to use for signing. Automatic selectors allow Xcode to pick the newest installed certificate of a particular type. The available automatic selectors are "Mac App Distribution", "iOS Developer", "iOS Distribution", "Developer ID Application", and "Mac Developer". Defaults to an automatic certificate selector matching the current distribution method.

> signingStyle : String

> The signing style to use when re-signing the app for distribution. Options are manual or automatic. Apps that were automatically signed when archived can be signed manually or automatically during distribution, and default to automatic. Apps that were manually signed when archived must be manually signed during distribtion, so the value of signingStyle is ignored.

> stripSwiftSymbols : Bool

> Should symbols be stripped from Swift libraries in your IPA? Defaults to YES.

> teamID : String

> The Developer Portal team to use for this export. Defaults to the team used to build the archive.

> thinning : String

> For non-App Store exports, should Xcode thin the package for one or more device variants? Available options: <none> (Xcode produces a non-thinned universal app), <thin-for-all-variants> (Xcode produces a universal app and all available thinned variants), or a model identifier for a specific device (e.g. "iPhone7,1"). Defaults to <none>.

> uploadBitcode : Bool

> For App Store exports, should the package include bitcode? Defaults to YES.

> uploadSymbols : Bool

> For App Store exports, should the package include symbols? Defaults to YES.

