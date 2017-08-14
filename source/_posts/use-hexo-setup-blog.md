---
title: hexo的博客让百度收录
date: 2016-07-05 18:03:31
tags:
    - SEO
categories: 
    - 工具
---

这个github.io搭建的过程参考，以及向百度推送的python、js脚本。

<!--more-->

# 参考博客
    
感谢 [岁月如歌](http://lovenight.github.io) 的这个[《Hexo 3.1.1 静态博客搭建指南》](http://lovenight.github.io/2015/11/10/Hexo-3-1-1-静态博客搭建指南/)同时感谢这个[《向百度推送hexo博客所有链接的Python脚本》](http://lovenight.github.io/2015/11/18/向百度推送hexo博客所有链接的Python脚本/)(别问我为啥点不开，这个要问博主，不过要看这个文章也不是没办法的😂，因为这个博客也用git管理的。。。你懂)

另外还有一个[soul](http://emufan.com)的[百度主动推送hexo生成的文章](http://emufan.com/2016/02/18/百度主动推送hexo生成的文章/)

# python自动推送脚本修改

上面说的博主大约用的是windows，所以脚本并不能立马的运行在Mac上，需要做些修改：故修改为：

```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Author: LoveNight
# @Date:   2015-11-16 20:45:59
# @Last Modified by:   LoveNight
# @Last Modified time: 2015-11-18 18:07:19

# @Last Modified by:   Keith
# @Last Modified time: 2016-07-06 16:22:45
import os
import sys
import json
from bs4 import BeautifulSoup as BS
import requests
#import msvcrt

"""
hexo 博客专用，向百度站长平台提交所有网址

本脚本必须放在hexo博客的根目录下执行！需要已安装生成百度站点地图的插件。
百度站长平台提交链接：http://zhanzhang.baidu.com/linksubmit/index
主动推送：最为快速的提交方式，推荐您将站点当天新产出链接立即通过此方式推送给百度，以保证新链接可以及时被百度收录。
从中找到自己的接口调用地址

python环境：
pip install beautifulsoup4
pip install requests
xcode-select --install	
pip install lxml 

"""

# ❌❌❌ 抄的需要更改这个URL！！这是我的！！❌❌❌
url = 'http://data.zz.baidu.com/urls?site=https://madordie.github.io&token=j33t0VEPFl24tJ8N'
baidu_sitemap = os.path.join(sys.path[0], 'public', 'baidusitemap.xml')
google_sitemap = os.path.join(sys.path[0], 'public', 'sitemap.xml')
sitemap = [baidu_sitemap, google_sitemap]

assert (os.path.exists(baidu_sitemap) or os.path.exists(
    google_sitemap)), "没找到任何网站地图，请检查！"


# 从站点地图中读取网址列表
def getUrls():
    urls = []
    for _ in sitemap:
        if os.path.exists(_):
            with open(_, "r") as f:
                xml = f.read()
        soup = BS(xml, "xml")
        tags = soup.find_all("loc")
        urls += [x.string for x in tags]
        if _ == baidu_sitemap:
            tags = soup.find_all("breadCrumb", url=True)
            urls += [x["url"] for x in tags]
    return urls


# POST提交网址列表
def postUrls(urls):
    urls = set(urls)  # 先去重
    print("一共提取出 %s 个网址" % len(urls))
    print(urls)
    data = "\n".join(urls)
    return requests.post(url, data=data).text


if __name__ == '__main__':

    urls = getUrls()
    result = postUrls(urls)
    print("提交结果：")
    print(result)
#    msvcrt.getch()
```

# js脚本

这个脚本是我在[soul](http://emufan.com)的[百度主动推送hexo生成的文章](http://emufan.com/2016/02/18/百度主动推送hexo生成的文章/)发现的，感觉也很赞。


>  ## github
  [脚本地址](https://github.com/Relsoul/bdwork/tree/master/soul/hexo百度主动上传)
  ## 推送
  今天发现百度没收录我的站..主要是我的站点换来换去的..估计被ban了..然后想用sitemap来推送一下..结果发现github禁用了百度爬虫..没办法只能主动推送了.
  ## 利用插件
  这里利用到了一款插件
  [hexo-generator-baidu-sitemap](https://github.com/coneycode/hexo-generator-baidu-sitemap)
  设置很简单 只需要在.config.yml添加一些数据即可, 下面附上我的添加数据 theme这个可以随意更改 下面的copy即可
  ```
  # Extensions
  ## Plugins: http://hexo.io/plugins/
  ## Themes: http://hexo.io/themes/
  theme: yilia
  baidusitemap:
  path: baidusitemap.xml
  ```
>  ## 运行
  然后hexo g 生成一下数据 会在public下面发现一个文件名为baidusitemap.xml
  ## 脚本
  这里用nodejs写了一款脚本 大概流程是 获取baidusitemap.xml里面的内容 然后读取本地的一个site_file.json这个文件 这个文件存储的是上一次数据 与上一次数据进行对比 如果对比发现新数据那么就上传新数据 否则全部上传.
  ## 运行脚本
  把ActivePush.js脚本放在hexo文件夹主目录 然后用nodejs ActivePush.js一下即可 这里还支持一个参数nodejs ActivePush.js all 则是不对比直接上传数据
