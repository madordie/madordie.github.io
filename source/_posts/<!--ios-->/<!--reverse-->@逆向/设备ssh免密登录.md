---
title: iOS逆向-设备ssh免密登录
url: reverse-ios-ssh
date: 2017-08-09 15:31:30
tags:
    - 逆向
categories:
    - iOS
---

## 前提条件

- 已越狱设备
- 越狱设备安装OpenSSH(⚠️记得修改默认的'alpine'登录密码)
- 电脑和设备同局域网。（我这里设备IP：10.11.12.13，并且设置成静态IP了😂）

<!--more-->

## 步骤

### 生成RSA证书

我这里生成的证书为:`ipad`，可自己需要定义。（注意如果直接回车会覆盖`~/.ssh/id_rsa`）

执行命令`ssh-keygen`，如下：
```shell
$ cd ~/.ssh/
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/Madordie/.ssh/id_rsa): ipad
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in ipad.
Your public key has been saved in ipad.pub.
The key fingerprint is:
SHA256:GpQBeAf+oqUzWlUhtItDcVyVFz2wd0EcIgD+BZLPK8U Madordie@Bingo.local
The key's randomart image is:
+---[RSA 2048]----+
|  .+*+*++o++.o+. |
|  .+o+o=...oo... |
|  ..o.=+ .o ...  |
| . . = .E. . .   |
|  o = o.S.       |
|   * ..o.        |
|  *   ..         |
| o o             |
|.                |
+----[SHA256]-----+

$ ls ~/.ssh/ipad*
/Users/Madordie/.ssh/ipad     /Users/Madordie/.ssh/ipad.pub
```

### 将公钥推送至越狱设备

默认是没有`~/.ssh`目录的，暂时放置在`/var/root`下。

```shell
$ scp ~/.ssh/ipad.pub root@10.11.12.13:/var/root
```

`scp` 默认端口为`22` 如果需要自定义端口可以在路径前添加`-P 端口号`参数。

### 配置本机`~/.ssh/config`文件

使用顺手的工具编辑`~/.ssh/config`文件。（没有就新建一个啦～

按照如下格式填写。默认`ssh`登录端口为`22`可以不写。
```
Host ipad
    Hostname 10.11.12.13
    User root
    Port 22
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/ipad
```

### 配置越狱设备

先用`ssh root@10.11.12.13`登录进设备。刚才我们将`ipad.pub`通过`scp`放在了`/var/root`下。

一般情况下`/var/root/.ssh`是不存在的，使用命令`mkdir -p /var/root/.ssh`即可创建。

```shell
$ cat ipad.pub >> /var/root/.ssh/authorized_keys
```

然后强迫症的可以使用`rm -rf ipad.pub`删除啦～

对了，退出`ssh`登录的设备使用：

```shell
$ exit
logout
Connection to 10.11.12.13 closed.
```

### 赶紧测试一下远程登录效果

```shell
$ ssh ipad
```

然后你会发现你已经完成了免密码登录越狱设备。

## 总结

其实这并不是只有越狱iOS设备才能使用的免登录，而是`ssh`所支持的。用途也很方便～
