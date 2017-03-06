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
  
  [2017.1.18更新]：
  新版rss版本可能自动启动连接成功无法上网。服务器日志会出现`tcprelay.py:935 can not parse header when handling connection from`的错误，这个是由于在启动的时候默认才用了混淆。在配置的时候需要注意一下。也可直接在`user-config.json`中修改或者删除。[配置说明](https://github.com/breakwa11/shadowsocks-rss/wiki/config.json)
  
## 优化
  - [官方优化方案](http://shadowsocks.org/en/config/advanced.html)
  - [Net Speeder](https://www.dou-bi.co/netspeeder-jc1/) `wget http://linux.linzhihao.cn/shell/netspeeder.sh & bash netspeeder.sh`

## history
  chacha20的插件忘记了按照哪种方式安装的了。将我安装的历史命令放出来：

  ```
    1  yum install git
    2  git clone -b manyuser https://github.com/breakwa11/shadowsocks.git
    3  cd ~/shadowsocks
    4  bash initcfg.sh
    5  cd ~/shadowsocks/shadowsocks
    6  python server.py -p 443 -k password -m chacha20
    7  python server.py -p 443 -k password -m aes-256-cfb 
    8  python server.py -p 443 -k password -m rc4-md5
    9  yum install epel-release
   10  yum install libsodium
   11  python server.py -p 443 -k password -m chacha20
   12  yum install libsodium
   13  python server.py -p 443 -k password -m chacha20
   14  yum install libsodium
   15  yum install libsodium update
   16  yum update
   17  yum install libsodium
   18  yum -y groupinstall "Development Tools"
   19  wget https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz
   20  tar xf libsodium-1.0.10.tar.gz && cd libsodium-1.0.10
   21  ./configure && make -j2 && make install
   22  echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
   23  ldconfig
   24  yum install libsodium
   25  cd ../
   26  ls
   27  python server.py -p 443 -k password -m chacha20
   28  echo "python server.py -p 443 -k password -m chacha20 -d start"
   29  echo "python server.py -p 443 -k password -m chacha20 -d start" >> /etc/rc.local 
   30  reboot
   31  cd //
   32  cd ~/
   33  cd shadowsocks/
   34  ls
   35  cd shadowsocks/
   36  ls
   37  cd ../
   38  ls
   39  pwd
   40  vim /etc/rc.local 
   41  reboot
   42  cd shadowsocks/
   43  python server.py -p 443 -k password -m chacha20 -d start
   44  python ~/shadowsocks/shadowsocks/server.py -p 443 -k password -m chacha20 -d start
   45  vim /etc/rc.local 
   46  reboot
   47  rm -f /sbin/modprobe
   48  ln -s /bin/true /sbin/modprobe
   49  rm -f /sbin/sysctl
   50  ln -s /bin/true /sbin/sysctl
   51  vi /etc/sysctl.conf
   52  sysctl -p
   53  reboot
   54  wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.i386.rpm
   55  vim /etc/rc.local 
   56  reboot
   57  python server.py status
   58  cd shadowsocks/shadowsocks/
   59  python server.py status
   60  exit
   61  vim /etc/rc.local 
   62  reboot
   63  ls
   64  rpm -ivh http://soft.91yun.org/ISO/Linux/CentOS/kernel/kernel-firmware-2.6.32-504.3.3.el6.noarch.rpm
   65  rpm -ivh http://soft.91yun.org/ISO/Linux/CentOS/kernel/kernel-2.6.32-504.3.3.el6.x86_64.rpm --force
   66  rpm -qa | grep kernel
   67  wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/code/master/vm_check.sh && bash vm_check.sh
   68  ls
   69  reboot
   70  vi /etc/security/limits.conf
   71  vim /etc/rc.local 
   72  vim /etc/sysctl.conf
   73  sysctl -p
   74  reboot
   75  ls
   76  wget https://github.com/snooda/net-speeder/archive/master.zip
   77  unzip master.zip
   78  ls
   79  rm -rf master.zip virt-what-1.12*
   80  ls
   81  wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
   82  rpm -ivh epel-release-6-8.noarch.rpm
   83  yum install libnet libpcap libnet-devel libpcap-devel
   84  sh build.sh -DCOOKED
   85  ls
   86  cd net-speeder-master/
   87  ls
   88  sh build.sh -DCOOKED
   89  ifconfig
   90  ./net_speeder venet0 "ip"
   91  service netspeederd start
   92  wget –no-check-certificate https://raw.githubusercontent.com/tennfy/debian_netspeeder_tennfy/master/debian_netspeeder_tennfy.sh
   93  chmod a+x debian_netspeeder_tennfy.sh
   94  wget http://linux.linzhihao.cn/shell/netspeeder.sh
   95  bash netspeeder.sh
   96  service netspeederd start
   97  service netspeederd status
   98  reboot
  ```


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
  
__2017-2-7更新__: [一个SSH登录服务器的shell脚本](https://github.com/jiangxianli/SSHAutoLogin)

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