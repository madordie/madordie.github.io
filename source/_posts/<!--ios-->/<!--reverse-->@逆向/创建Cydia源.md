---
title: iOS逆向-创建Cydia源
url: reverse-ios-creat-cydia-sources
date: 2018-01-02
tags: 
    - 逆向
categories:
    - iOS
---

搭建自己的cydia源。

<!--more-->

### 环境

- Ubuntu 16.04 LTS

### 安装工具

#### dpkg-dev
```sh
$ apt-get update
$ apt-get install dpkg-dev
$ dpkg-scanpackages --help
```

#### nginx
```sh
apt-get install nginx
```

### 开工

#### 准备deb

此处目录为`/opt/cydia/debs`，可以为别的，但是建议你也这样做:)。

#### 生成依赖

```sh
$ cd /opt/cydia
$ dpkg-scanpackages -m . /dev/null > Packages
$ bzip2 Packages
```

#### 添加sources.list

```sh
$ echo "deb file:///opt/cydia ./debs/" >> /etc/apt/sources.list
```

ps. 注意路径信息

#### 更新一下

```sh
$ apt-get update
```

#### 扔出去

```sh
$ ln -s /opt/cydia cydia
$ /etc/init.d/nginx start
```

### 参考
- http://www.saurik.com/id/7
- https://bbs.feng.com/read-htm-tid-8052646.html