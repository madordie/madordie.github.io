---
title: iOS逆向-砸壳
date: 2017-08-09 20:31:50
tags:
categories:
    - iOS
    - 逆向
---

## 前提

- 越狱设备
- `Cydia`中搜索`cycript`并安装

<!--more-->

## 步骤


### 制作并上传`dumpdecrypted.dylib` （已经OK的可忽略

#### 制作

目前我制作目录暂时在`~/Desktop`。

```shell
$ git clone https://github.com/stefanesser/dumpdecrypted.git ~/Desktop
$ cd ～／Desktop/dumpdecrypted
$ make
$ ls dumpdecrypted.dylib
```

没什么错误的话，即得`dumpdecrypted.dylib`。

#### 上传

将`dumpdecrypted.dylib`放在越狱设备的`/var/root/`下

```shell
$ ls dumpdecrypted.dylib
$ scp dumpdecrypted.dylib root@10.12.14.16:/var/root/
root@10.12.14.16's password:
dumpdecrypted.dylib                           100%  193KB   3.0MB/s   00:00
$
```

### 登录进越狱设备

可以使用`ssh root@IP`进行登录。

当然也可以使用`ssh ipad`，这样免密登录登录。 [配置传送门](https://madordie.github.io/reverse-ios-ssh/)

### 找到可执行文件路径

这里以`WeChat`为例子啦～

记得先打开呀～～～

`ps -e`： 显示所有程序
`grep`: 这里是过滤一下。。具体用法Google。所有的程序有点多，我知道名字，所以直接过滤一下。也可忽略

```shell
$ ps -e | grep WeChat
705 ??         0:02.20 /var/mobile/Containers/Bundle/Application/3AE519BF-2FD2-43FC-A14B-2893190B8E1E/WeChat.app/WeChat
707 ttys000    0:00.01 grep WeChat
$ cycript -p 705
$ cycript -p 705
cy# [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0]
#"file:///var/mobile/Containers/Data/Application/54EF9A70-8E3A-4B6D-B7F4-554AB256C48B/Documents/"
cy# exit(0)
MS:Error: _krncall(mach_vm_read_overwrite(task, data, sizeof(*baton), reinterpret_cast<mach_vm_address_t>(baton), &error)) =4
*** _assert(status == 0):../Inject.cpp(143):InjectLibrary
$
```

此处获得两个目录：

- `/var/mobile/Containers/Bundle/Application/3AE519BF-2FD2-43FC-A14B-2893190B8E1E/WeChat.app/WeChat`
- `/var/mobile/Containers/Data/Application/54EF9A70-8E3A-4B6D-B7F4-554AB256C48B/Documents/`

### 开砸

```shell
$ cd ~
$ cp dumpdecrypted.dylib /var/mobile/Containers/Data/Application/54EF9A70-8E3A-4B6D-B7F4-554AB256C48B/Documents/
$ cd /var/mobile/Containers/Data/Application/54EF9A70-8E3A-4B6D-B7F4-554AB256C48B/Documents/
$ DYLD_INSERT_LIBRARIES=dumpdecrypted.dylib /var/mobile/Containers/Bundle/Application/3AE519BF-2FD2-43FC-A14B-2893190B8E1E/WeChat.app/WeChat
mach-o decryption dumper

DISCLAIMER: This tool is only meant for security research purposes, not for application crackers.

[+] detected 64bit ARM binary in memory.
[+] offset to cryptid found: @0x1000c0ca8(from 0x1000c0000) = ca8
[+] Found encrypted data at address 00004000 of length 51200000 bytes - type 1.
[+] Opening /private/var/mobile/Containers/Bundle/Application/3AE519BF-2FD2-43FC-A14B-2893190B8E1E/WeChat.app/WeChat for reading.
[+] Reading header
[+] Detecting header type
[+] Executable is a plain MACH-O image
[+] Opening WeChat.decrypted for writing.
[+] Copying the not encrypted start of the file
[+] Dumping the decrypted data into the file
[+] Copying the not encrypted remainder of the file
[+] Setting the LC_ENCRYPTION_INFO->cryptid to 0 at offset ca8
[+] Closing original file
[+] Closing dump file
$ ls
00000000000000000000000000000000  LocalInfo.lst  MMResourceMgr    MMappedKV  MemoryStat  SMReport.dat  SafeMode.dat  WeChat.decrypted  dumpdecrypted.dylib  heavy_user_id_mapping.dat
$ ls WeChat.decrypted
WeChat.decrypted
$ pwd
/var/mobile/Containers/Data/Application/54EF9A70-8E3A-4B6D-B7F4-554AB256C48B/Documents
```
最后得到文件:

- `/var/mobile/Containers/Data/Application/54EF9A70-8E3A-4B6D-B7F4-554AB256C48B/Documents/WeChat.decrypted`

### 将`*.decrypted`拷贝出来

我这里直接使用`scp`吧～。

```shell
$ cd /Users/Madordie/Desktop/Madordie/iOS/xxx
$ scp root@10.12.14.16:/var/mobile/Containers/Data/Application/54EF9A70-8E3A-4B6D-B7F4-554AB256C48B/Documents/WeChat.decrypted .
root@10.12.14.16's password:
WeChat.decrypted                              100%   61MB   4.7MB/s   00:12
$ ls WeChat.decrypted
WeChat.decrypted
```
至此在主机上得到：

- `/Users/Madordie/Desktop/Madordie/iOS/xxx/WeChat.decrypted`

## 总结

- 为什么将`dumpdecrypted.dylib`  `copy` 至`*/Documents/`下？
    ：别的目录没有权限～～（`dumpdecrypted.dylib: stat() failed with errno=1` ）
