---
title: 科学上网之搬瓦工ss搭建笔记
date: 2016-12-19 20:37:11
tags:
---

原来吧，用用goagent、Lantern、XX-Net，确实，这玩意只能Google出来结果，但是有的站点打不开才是最骚的。。
同事搞了个搬瓦工挺便宜，于是乎就也搞了一个。不过强迫症犯了，尝试了各种SS版本以及各种优化，目的是找个流畅点的版本进行__科学上网__。

<!--more-->

# 写在前面
  - 红线越不得！红线越不得！红线越不得！重要的事情说3遍。
  - 参看第一条
  - 参看第一条
  - 参看第一条
  
# 目前安装的 rss
  尝试了各种版本的系统，各种ss分支，最后用了rss，然后又花了一下，觉得速度可以了，延迟的问题无解。ping过去就是那么慢。。
  注意：为了重启不配置，要把里面没有自启动的添加到启动项。具体方法 Google一下。我加在了 `/etc/rc.local`

## shadowsocks-rss
  - [wiki](https://github.com/breakwa11/shadowsocks-rss/wiki)
  - [ShadowsocksR 服务端安装教程](https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup)
  - [macOS](https://github.com/shadowsocksr/ShadowsocksX-NG/releases)
  - [iOS](https://itunes.apple.com/cn/app/id1178584911)
  
## 优化
  - [官方优化方案](http://shadowsocks.org/en/config/advanced.html)
  - [Net Speeder](https://www.dou-bi.co/netspeeder-jc1/) `wget http://linux.linzhihao.cn/shell/netspeeder.sh & bash netspeeder.sh`

## 本地访问VPS脚本
  我比较懒，密码都是随机的也不想改，所以做了一个脚本用来直接ssh登陆。
  后来我发现我需要下载一些文件，于是乎我增加了两个参数。。
  安装系统的时候修改一下，将`password`修改为随机生成的密码，这样也不用记录，直接复制粘贴。。
  同时将`12345`替换为端口号。
  将`1.2.3.4`替换为服务器IP，这个只需要写一次就好，基本上也不会改。。
  这样搞完之后在`~/.profile`中增加`alias vps="/Users/Madordie/shell/Mac_shell/ss.sh"`，然后执行`source ~/.profile`即可。
  
  这样就可以使用下面的简写：
    - SSH登陆`vps`
    - 下载文件`vps /server_path /local_path`，自行修改后面俩参数
  
  ```
  $ cat ~/shell/Mac_shell/ss.sh 
  
  #!/bin/bash

  echo 'password'
  port=12345
  ip=1.2.3.4
  usr=root

  if [ $# -eq 0 ]; then
      ssh $usr@$ip -p $port
  elif [ $# -eq 2 ]; then 
      scp -P $port $usr@$ip:$1 $2
  else
      echo "($*)你要干嘛。。"
  fi

  ```
  

# 尝试的时候各种用的环境搭建
  很显然上面的已经足够了，这个只是留个笔记，用来快速搭建某个环境啥的。。

## CentOS

### git
  1. 直接安装
    ```
    yum install git
    ```

### go

  1. 下载二进制文件：
    ```
    wget https://storage.googleapis.com/golang/go1.7.3.linux-amd64.tar.gz
    ```
  2. 解压并创建工作目录：
    ```
    tar -zxf go1.7.3.linux-amd64.tar.gz -C /usr/local/
    ```
  3. 设置环境变量：
    在 /etc/profile 添加：
    ```
    export GOROOT=/usr/local/go 
    export GOBIN=$GOROOT/bin
    export GOPKG=$GOROOT/pkg/tool/linux_amd64 
    export GOARCH=amd64
    export GOOS=linux
    export GOPATH=/Golang
    export PATH=$PATH:$GOBIN:$GOPKG:$GOPATH/bin
    ```
    4. 使之生效或者重新登录Linux也可
    ```
    source /etc/profile
    ```
  
## scp
  
  `scp -P 8888 root@127.0.0.10:/root/my_key/ca.cert.pem .`


## Ubuntu

### 更新
  ```
    sudo apt-get update
  ```

### git
  ```
  sudo apt-get install git  
  ```
### go
  ```
  sudo apt-get install golang
  ```