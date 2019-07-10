---
title: Ubuntu使用SakuraFrp实现内网穿透
url: ubuntu-sakura-frp
date: 2019-07-09
tags:
    - 内网穿透
categories:
    - Linux
---

记录将一台吃灰的笔记本改装成服务器，并暴露在公网下的过程。

<!--more-->

# 准备

- 一个 ubuntu-18.04.2-desktop-amd64.iso
- 一台陈旧的Gateway笔记本
- 一台主战MBP

iso: 如果从[官网](https://ubuntu.com/download/desktop)下载速度比较慢，可以考虑上`wget`、迅雷。我这里使用了`wget`并且使用了[清华的镜像](https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu/releases/)

Gateway: 还是个win10，于是乎顺手就把`ubuntu-18.04.2-desktop-amd64.iso`制作成了U盘，此处我就不说了，反正能引导进去就行啊哈哈哈

MBP: 主要工作在这里。比如远程win桌面用的是[Microsoft Remote Desktop](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)

# 开始

注意，Ubuntu会将硬盘 **所有分区全部格式化** ，请先妥善备份。

经过安装提示以及笔记本的疯狂发热很快就安装完事了。

PS. 安装Wi-Fi驱动，记得重启哦：

```sh
sudo apt install bcmwl-kernel-source
```

## 设置Ubuntu软件源

这里还是用清华大学的镜像，其[Ubuntu 镜像使用帮助](https://mirror.tuna.tsinghua.edu.cn/help/ubuntu/)也是相当的详细：

> Ubuntu 的软件源配置文件是 /etc/apt/sources.list。将系统自带的该文件做个备份，将该文件替换为下面内容，即可使用 TUNA 的软件源镜像。
>
> 选择你的ubuntu版本: 18.04 LTS
```
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
```

## 更新

`apt`已经相当完善，此处不再赘述。

```sh
sudo apt update
sudo apt dist-upgrade
```

当然，别忘了安装`wget`:

```sh
sudo apt install wget
```

此处如果按照上面的步骤已经设置了清华大学的镜像源，那速度将会很快。要不然就很慢慢慢。。

# 内网穿透

将`内网穿透`放在Google里面搜索一下会有很多方案，我的VPS被邻居连累之后就没有再买，所以我没有域名、公网IP。。。其中搜索结果的大部分都不适合我。

其中大部分提到一个`DDNS`的概念：[维基百科:动态DNS](https://zh.wikipedia.org/wiki/%E5%8B%95%E6%85%8BDNS)

> 动态DNS（英语：Dynamic DNS，简称DDNS）是域名系统（DNS）中的一种自动更新名称服务器（Name server）内容的技术。根据互联网的域名订立规则，域名必须跟从固定的IP地址。但动态DNS系统为动态网域提供一个固定的名称服务器（Name server），透过即时更新，使外界用户能够连上动态用户的网址。

了解玩这个之后就可以搜索并选择DDMS方案了。

再明确一下目标：在外网ssh进内网我们刚建好的Ubuntu。

## TPDDNS

不过我家里的路由是[TP-LINK](https://www.tp-link.com.cn/)的，TP-LINK是可以参考[TPDDNS的使用方法介绍](https://service.tp-link.com.cn/detail_article_2978.html)可以直接使用的。

不过坑比的事情是[TPDDNS]支持的硬件版本是4.0。参考[如何查看产品型号与硬件版本？](https://service.tp-link.com.cn/detail_article_1420.html)，也就是其`ver 4.0`之上是可以的。

最好是问一下`TP-LINK 在线客服`，一般 某猫、某狗上面的客服是不懂这个的。

很显然我家里的路由是V3.0 啊哈哈哈 此方案我这里不适用。不过看上面的教程已经很详尽了，应该比较好搞。

## Sakura Frp

这个据[官网](https://www.natfrp.org/)介绍是这样的：

> 简单方便
> 客户端基于 Fatedier Frp 修改，免去了配置文件，改为从网络读取配置，您只需要在网站上简单操作即可添加映射。
>
> 完全免费
> 您不必再为了内网穿透多花一分钱，Sakura Frp 是永远免费的，我们只为了让更多人能体验到免费、好用的内网穿透。
>
> 自由使用
> 我们非常欢迎您将 Sakura Frp 集成到自己的软件中，并且我们提供了多种 API 接口以供使用，完全没有使用限制。

好了，适合我这种不愿意花钱的穷屌丝，来[注册](https://openid.natfrp.org/?action=register&src=www.natfrp.com)吧。。

登录进去才发现，好多文字。没有明显的新手教程，对我这种不是很懂`FRP`的人来说简直一脸懵逼。

## 创建映射

[映射列表](https://www.natfrp.com/page/panel/)中的`示例映射 - Linux SSH`正合我意，然后只需要再点一下`随机端口`就可以不用输入直接点添加了。

![Linux SSH 并随机端口](/images/2019-07-09-13-43-31.png)

![已添加的隧道列表](/images/2019-07-09-13-44-25.png)

至此第一个映射已经创建了，然后需要去Ubuntu上开启代理吧

## 开启代理

在[客户软件](https://www.natfrp.com/page/panel/)中找到适合自己的`Linux x64 (64位操作系统)`包并下载至Ubuntu:

此处将包下载至`/opt/natfrp`(该路径将在后面的配置中使用)

```sh
sudo mkdir -p /opt/natfrp && cd /opt/natfrp
sudo wget https://cdn.tcotp.cn:4443/client/Sakura_frpc_linux_amd64.tar.gz
sudo tar zxvf Sakura_frpc_linux_amd64.tar.gz
```

解压完成后，就会得到一个可执行文件`Sakura_frpc_linux_amd64`(该文件名将在后面的配置中使用)

根据[Linux 将 Sakura Frp 设置为服务，开机自动启动](https://www.zerobbs.net/?s=viewpost&tid=5)的教程操作如下：

### 创建service

```sh
sudo vi /etc/systemd/system/sakurafrp.service
```

### 根据自己的配置写入service

`/opt/natfrp/`: Sakura_frpc_linux_amd64的全路径
`/opt/natfrp/Sakura_frpc_linux_amd64`: 解压之后的Sakura_frpc_linux_amd64全路径
`--sid=`: 服务器列表中左侧的数字

```sh
[Unit]
Description=Sakura Frp Client
Wants=network-online.target
After=network-online.target
[Service]
User=root
WorkingDirectory=/opt/natfrp/
LimitNOFILE=4096
PIDFile=/var/run/sakurafrp/client.pid
ExecStart=/opt/natfrp/Sakura_frpc_linux_amd64 --su=你的账号 --sp=你的密码 --sid=你要选择的服务器的ID(就是服务器列表左侧的数字)
Restart=on-failure
StartLimitInterval=600
[Install]
WantedBy=multi-user.target
```

sid信息[2019.7.9:14:10]:
```
|======================================================================================================
| ID	名称		状态		介绍
|======================================================================================================
| 1	宁波电信	√ 在线		高防线路，适合搭 Minecraft 服务器，使用人数较多 (官方服务器)
| 2	宁波联通	√ 在线		联通线路，防御 20G，适合部分移动联通/用户使用 (官方服务器)
| 3	徐州电信	√ 在线		徐州高防电信，适合开服，月流量固定 500G，请合理使用 (官方服务器)
| 4	贵州电信	× 离线		贵州电信节点，无防御，适合小流量传输服务[超流量停机] (官方服务器)
| 6	罗马尼亚	× 离线		罗马尼亚不限内容无视 DMCA 版权服务器，免备案 (官方服务器)
| 7	日本千兆	√ 在线		日本千兆服务器，适合建站，免备案 (官方服务器)
| 8	台湾百兆	√ 在线		台湾谷歌云 100M 服务器，适合建站，延迟较低，免备案 (官方服务器)
| 9	香港线路1 √ 在线		香港 StarryDNS 100M 服务器，适合建站 (官方服务器)
| 10	江苏镇江	√ 在线		江苏镇江 100M 服务器，BGP 全国优化线路，适合开服 (官方服务器)
| 12	河南电信	√ 在线		河南电信线路服务器，适合开服以及小流量服务 (官方服务器)
| 13	香港线路2 √ 在线		香港谷歌云 100M 服务器，适合建站，免备案 (官方服务器)
| 30	洛杉矶01	√ 在线		美国洛杉矶千兆服务器，适合建站，免备案 线路 1 (官方服务器)
| 31	洛杉矶02	√ 在线		美国洛杉矶千兆服务器，适合建站，免备案 线路 2 (官方服务器)
| 32	洛杉矶03	√ 在线		美国洛杉矶千兆服务器，适合建站，免备案 线路 3 (官方服务器)
| 33	洛杉矶04	√ 在线		美国洛杉矶千兆服务器，适合建站，免备案 线路 4 (官方服务器)
| 34	洛杉矶05	√ 在线		美国洛杉矶千兆服务器，适合建站，免备案 线路 5 (官方服务器)
| 38	新加坡01	× 离线		新加坡阿里云 30M 服务器，适合建站，免备案 (官方服务器)
| 39	蒙特利尔	√ 在线		加拿大蒙特利尔谷歌云 100M 服务器，适合建站，免备案 (官方服务器)
| 43	香港移动	× 离线		香港 UOvZ 100M 移动服务器，适合建站，免备案[机房断网维护中] (官方服务器)
| 45	美国纽约1 √ 在线		美国纽约百兆服务器，适合建站，免备案 线路1 (官方服务器)
| 46	美国纽约2 √ 在线		美国纽约百兆服务器，适合建站，免备案 线路2 (官方服务器)
| 47	日本长野	× 离线		日本长野百兆服务器，适合建站，免备案 (官方服务器)
|======================================================================================================
```

### 启动service

```sh
systemctl daemon-reload
```

服务就创建成功了，接下来启动服务：
```sh
systemctl start sakurafrp
```

将服务设置为开机启动
```sh
systemctl enable sakurafrp
```

如果要停止运行客户端，只需要输入
```sh
systemctl stop sakurafrp
```

如果要禁止开机启动，输入
```sh
systemctl disable sakurafrp
```

至此，来让我们看一下当前的状态：
```sh
╰─>$ sudo systemctl status sakurafrp
● sakurafrp.service - Sakura Frp Client
   Loaded: loaded (/etc/systemd/system/sakurafrp.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2019-07-09 11:07:19 CST; 3h 13min ago
 Main PID: 3301 (Sakura_frpc_lin)
    Tasks: 10 (limit: 4915)
   Memory: 5.9M
   CGroup: /system.slice/sakurafrp.service
           └─3301 /opt/natfrp/Sakura_frpc_linux_amd64 --su=xxxxxxxx --sp=xxxxxxxx --sid=xxx

7月 09 11:07:20 madordie-NV47H Sakura_frpc_linux_amd64[3301]: >配置文件载入成功
7月 09 11:07:20 madordie-NV47H Sakura_frpc_linux_amd64[3301]: 2019/07/09 11:07:20 [I] [proxy_manager.go:322] 增加代理: [xxx.natfrp.org:22941        29795-87248]
7月 09 11:07:20 madordie-NV47H Sakura_frpc_linux_amd64[3301]: 2019/07/09 11:07:20 [I] [control.go:242] [d54792913cdac17d] 登录成功, 获取到运行ID [d54792913cdac17d], server udp port [7001]
7月 09 11:07:20 madordie-NV47H Sakura_frpc_linux_amd64[3301]: 2019/07/09 11:07:20 [I] [control.go:167] [d54792913cdac17d] [xxx.natfrp.org:22941        29795-87248] 启动代理成功
```

可以看到`[xxx.natfrp.org:22941        29795-87248] 启动代理成功`

需要注意的是选用的sid不一样其代理的域名也不一样。这个是很显然的，但是是容易忽略的。

# 验证

在MBP上验证一下`xxx.natfrp.org:22941`

```sh
╰─>$ ssh -p 22941 madordie@xxx.natfrp.org
Welcome to Ubuntu 19.04 (GNU/Linux 4.18.0-15-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage


12 updates can be installed immediately.
6 of these updates are security updates.

Last login: Tue Jul  9 14:19:33 2019 from 127.0.0.1
```

`Sakura Frp`已通，愉快的玩耍吧！

括弧：一旦其暴露出去别忘了考虑安全，比如你的这个SSH账号、密码是否足够复杂，或者是否关闭了账号密码登陆。

# 其他方案

还有一些其他的方案可以选择，比如：

- [花生壳](https://hsk.oray.com/)
- [no-ip](https://www.noip.com)
- [开源的frp](https://github.com/fatedier/frp)
