---
title: gitment自动初始化
url: blog-gitment-auto-setup
date: 2018-08-29 16:58:47
tags:
    - gitment
categories: 
    - 工具
---

一个ruby脚本解放你双手啪啪啪的敲键盘三分钟～

PS.

- ruby新手，轻拍。。
- 三是虚指。。

<!--more-->

## 起因

之前看到人家的私站都是用的[GitHub](https://github.com)做的评论系统。。很想要，但是人家没有用[pages](https://pages.github.com)这样的玩意。。

今天看到[味精](http://awhisper.github.io)大佬的RSS跪了，然后看到人家用的是GitHub的评论。。顿时觉得想要，23333

然后看了一哈 是这个：[gitment](https://github.com/imsun/gitment)

## 配置

这个我就不说了，作者有写中文文档，看一眼就明白了。

列一下我的使用[NexT主题](https://github.com/iissnan/hexo-theme-next)的配置：
```yml
# Gitment
# Introduction: https://imsun.net/posts/gitment-introduction/
gitment:
  enable: true
  mint: true # RECOMMEND, A mint on Gitment, to support count, language and proxy_gateway
  count: true # Show comments count in post meta area
  lazy: false # Comments lazy loading with a button
  cleanly: false # Hide 'Powered by ...' on footer, and more
  language: # Force language, or auto switch by theme
  github_user: xxxxxx # MUST HAVE, Your Github ID
  github_repo: xxxxxx # MUST HAVE, The repo you use to store Gitment comments
  client_id: xxxxxx # MUST HAVE, Github client id for the Gitment
  client_secret: xxxxxx # EITHER this or proxy_gateway, Github access secret token for the Gitment
  proxy_gateway: # Address of api proxy, See: https://github.com/aimingoo/intersect
  redirect_protocol: # Protocol of redirect_uri with force_redirect_protocol when mint enabled
```

## 自动初始化

关于作者的[初始化评论框方案讨论](https://github.com/imsun/gitment/issues/8)还在讨论中。。。

但是我要用。。等是不可能等的了。

看到[自动初始化 Gitalk 和 Gitment 评论](https://draveness.me/git-comments-initialize)的脚本想着刚好我的也是自动发布、备份，这不是刚好嘛。。

跑了一下发现并不行，如果创建成功的话多次运行会创建多个。脑袋瓜子一热，判断一下。。于是就有了下面的版本。。

```rb
# from : https://draveness.me/git-comments-initialize
# 另外，token已放在.git-token文件下，防止泄漏。。

username = "madordie" # GitHub 用户名
token = `cat .git-token`  # GitHub Token
repo_name = "madordie.github.io" # 存放 issues
sitemap_url = "https://madordie.github.io/sitemap.xml" # sitemap
kind = "gitment" # "Gitalk" or "gitment"

require 'open-uri'
require 'faraday'
require 'active_support'
require 'active_support/core_ext'
require 'sitemap-parser'

puts "正在检索URL"

sitemap = SitemapParser.new sitemap_url
urls = sitemap.to_a

puts "检索到文章共#{urls.count}个"

conn = Faraday.new(:url => "https://api.github.com") do |conn|
  conn.basic_auth(username, token)
  conn.headers['Accept'] = "application/vnd.github.symmetra-preview+json"
  conn.adapter  Faraday.default_adapter
end

commenteds = Array.new
`
  if [ ! -f .commenteds ]; then
    touch .commenteds
  fi
`
File.open(".commenteds", "r") do |file|
  file.each_line do |line|
    commenteds.push line
  end
end

urls.each_with_index do |url, index|

  if commenteds.include?("#{url}\n") == false
    response = conn.get "/search/issues?q=label:#{url}+state:open+repo:#{username}/#{repo_name}"

    if JSON.parse(response.body)['total_count'] > 0
      `echo #{url} >> .commenteds`
    else
      puts "正在创建: #{url}"
      title = open(url).read.scan(/<title>(.*?)<\/title>/).first.first.force_encoding('UTF-8')

      response = conn.post("/repos/#{username}/#{repo_name}/issues") do |req|
        req.body = { body: url, labels: [kind, url], title: title }.to_json
      end
      if JSON.parse(response.body)['number'] > 0
        `echo #{url} >> .commenteds`
        puts "\t↳ 已创建成功"
      else
        puts "\t↳ #{response.body}"
      end
    end
  end
end
```

如果你的文章链接都比较短，恭喜你，已经完成了～～

但是我的文章链接普遍比较长。。