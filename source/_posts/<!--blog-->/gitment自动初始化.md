---
title: Gitment/Gitalk自动初始化
url: blog-gitment-auto-setup
date: 2018-08-29 16:58:47
tags:
    - gitment
    - gitalk
    - blog
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

## Gitment

关于作者的[初始化评论框方案讨论](https://github.com/imsun/gitment/issues/8)还在讨论中。。。

但是我要用。。等是不可能等的了。

看到[自动初始化 Gitalk 和 Gitment 评论](https://draveness.me/git-comments-initialize)的脚本想着刚好我的也是自动发布、备份，这不是刚好嘛。。

但是存在多次执行就会多次创建的问题。这不是我想要的。

### 第一版：支持多次执行

GitHub提供较为完善的API，用我这水水的rb水平，大致可以完善如下：

```rb
# from : https://madordie.github.io/post/blog-gitment-auto-setup
# 另外，token已放在.git-token文件下，防止泄漏。。

username = "madordie" # GitHub 用户名
token = `cat .git-token`  # GitHub Token
repo_name = "madordie.github.io" # 存放 issues
sitemap_url = "https://raw.githubusercontent.com/madordie/madordie.github.io/master/sitemap.xml" # sitemap 此处由于github.io不是立马生效，但是仓库是立马生效的，所以此处应该更换为仓库的raw
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
  url = url.gsub(/index.html$/, "")

  if commenteds.include?("#{url}\n") == false
    url_key = Digest::MD5.hexdigest(URI.parse(url).path)
    response = conn.get "/search/issues?q=label:#{url_key}+state:open+repo:#{username}/#{repo_name}"

    puts "正在创建: #{url}"
    if JSON.parse(response.body)['total_count'] > 0
      puts "\t↳ 已存在"
      `echo #{url} >> .commenteds`
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

脚本OK，还需要安装一些库用这个就行：

```sh
sudo gem install faraday activesupport sitemap-parser
```

正常情况都会安装成功，那么跑一下脚本吧：

```rb
ruby comment.rb
```

第一次运行请求多，稍微等一会。表急。。

跑完之后如果你的链接总长度都是 `<= 50` 字符，那么真嗨，这就行了。

但是如果以后有可能 `> 50`，或者不确定以后会不会写一个链接贼长的文章，那么你可能还要往下再看一下。。

### 第二版：兼容文章链接很长长长

关于这个的讨论很多，在issues中搜一下大约这样：[Error: Validation Failed](https://github.com/imsun/gitment/issues?utf8=✓&q=is%3Aissue+validation+Failed)。

这个`Error: Validation Failed`就是label太长。

关于这个问题在[API: Create a label](https://developer.github.com/v3/issues/labels/#create-a-label)并未提及。

但是在任何一个仓库下，按照`Issues -> New label`的时候，输入的`Label name`是有限制的，输入超过`50`个自符之后便无法再接收输入。就酱，没找到什么文档。。

看了这个[Validation Failed ID长度问题建议](https://github.com/imsun/gitment/issues/116)之后觉得，MD5一下吧那就。。

为了选择一个KEY去MD5，顺便解决一下[同一个页面，带锚点#more会初始化一条新的issue](https://github.com/imsun/gitment/issues/168)这个问题，

所以KEY使用[关于hexo博客单篇文章初始化两次的问题](https://github.com/imsun/gitment/issues/68)中提出的`window.location.pathname`吧，但是关于`/`的讨论，我这里貌似并没有看到，我的都是有的😂。。如果看到的话再更，或者保险期间，先按照这种方案更新一下。

将上面的做完，现在的rb应该长这个样子:

```rb
# from : https://madordie.github.io/post/blog-gitment-auto-setup
# 另外，token已放在.git-token文件下,并被.gitignore标记，防止泄漏。。

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
require 'digest'

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
  url.gsub!(/index.html$/, "")

  if commenteds.include?("#{url}\n") == false
    url_key = Digest::MD5.hexdigest(URI.parse(url).path)
    response = conn.get "/search/issues?q=label:#{url_key}+state:open+repo:#{username}/#{repo_name}"

    if JSON.parse(response.body)['total_count'] > 0
      `echo #{url} >> .commenteds`
    else
      puts "正在创建: #{url}"
      title = open(url).read.scan(/<title>(.*?)<\/title>/).first.first.force_encoding('UTF-8')
      response = conn.post("/repos/#{username}/#{repo_name}/issues") do |req|
        req.body = { body: url, labels: [kind, url_key], title: title }.to_json
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

同时别忘了修改对应的网页。。我这里使用的是[NexT.Pisces v5.1.4](https://github.com/iissnan/hexo-theme-next)

需要修改`/themes/next/layout/_third-party/comments/gitment.swig`文件，由于JS不支持MD5,所以还需要引入一个JS，于是乎大约这样：

```swig
    {% if theme.gitment.mint %}
        {% set CommentsClass = "Gitmint" %}
        <link rel="stylesheet" href="https://aimingoo.github.io/gitmint/style/default.css">
        <script src="https://aimingoo.github.io/gitmint/dist/gitmint.browser.js"></script>
+       <script src="https://cdn.bootcss.com/blueimp-md5/2.10.0/js/md5.min.js"></script>
    {% else %}
        {% set CommentsClass = "Gitment" %}
        <link rel="stylesheet" href="https://imsun.github.io/gitment/style/default.css">
        <script src="https://imsun.github.io/gitment/dist/gitment.browser.js"></script>
+       <script src="https://cdn.bootcss.com/blueimp-md5/2.10.0/js/md5.min.js"></script>
    {% endif %}
...
        var gitment = new {{CommentsClass}}({
-           id: document.location.href,
+           id: md5(window.location.pathname.replace(/index.html/, "")),
            owner: '{{ theme.gitment.github_user }}',
            repo: '{{ theme.gitment.github_repo }}',
```

至于这个MD5的引入，我是随便搜的一个。。这个`if theme.gitment.mint`我并不知道在哪里配置的，所以俩都加上吧。

执行一下脚本吧，应该齐活了。

## Gitalk

好气啊, [Next主题](https://github.com/next-theme/hexo-theme-next)升级之后不支持Gitment了, 大概是因为上面种种问题吧, 所以,被迫来到了[Gitalk](https://github.com/gitalk/gitalk)

真香警告.

回归本心,诉求就一个: 从`gitment`兼容至`Gitalk`.

脚本需要配置项:

- .git-token = 放置token 切记注意添加`.gitignore`
- username = "madordie" # GitHub 用户名
- token = `cat .git-token`  # GitHub Token
- repo_name = "madordie.github.io" # 存放 issues
- sitemap_url = "https://raw.githubusercontent.com/madordie/madordie.github.io/master/sitemap.xml" # sitemap
- kind = "Gitalk" # "Gitalk" or "gitment"

然后, 脚本会识别`kind`是否已经添加, 如果没有添加会追一个`label`, 以确保能正常执行

```rb
# from : https://madordie.github.io/post/blog-gitment-auto-setup
# 另外，token已放在.git-token文件下，防止泄漏。。

username = "madordie" # GitHub 用户名
token = `cat .git-token`  # GitHub Token
repo_name = "madordie.github.io" # 存放 issues
sitemap_url = "https://raw.githubusercontent.com/madordie/madordie.github.io/master/sitemap.xml" # sitemap
kind = "Gitalk" # "Gitalk" or "gitment"

require 'open-uri'
require 'faraday'
require 'active_support'
require 'active_support/core_ext'
require 'sitemap-parser'
require 'digest'

puts "正在检索URL"

sitemap = SitemapParser.new sitemap_url
urls = sitemap.to_a

puts "检索到文章共#{urls.count}个"

conn = Faraday.new(:url => "https://api.github.com/") do |conn|
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
  url = url.gsub(/index.html$/, "")

  if commenteds.include?("#{url}\n") == false
    url_key = Digest::MD5.hexdigest(URI.parse(url).path)
    response = conn.get "/search/issues?q=label:#{url_key}+state:open+repo:#{username}/#{repo_name}"

    puts "正在创建: #{url} -> [#{url_key}, #{kind}]"
    labels = JSON.parse(response.body)["items"]
      .map { |item|
        item["labels"].map { |label| label["name"] }
      }
      .flatten

    if labels.include?(url_key)
      if labels.include?(kind)
        puts "\t↳ 已存在"
        `echo #{url} >> .commenteds`
      else
        issue_id = JSON.parse(response.body)["items"]
          .map { |item| item["number"] }
          .first

        puts "\t↳ 正在为评论(#{issue_id})增加`#{kind}`标签"
        response = conn.post("/repos/#{username}/#{repo_name}/issues/#{issue_id}/labels") do |req|
          req.body = { labels: [kind] }.to_json
        end
        if response.status == 200
          `echo #{url} >> .commenteds`
          puts "\t\t↳ 已增加成功"
        else
          puts "\t↳ #{response.body}"
        end
      end
    else
      title = open(url).read.scan(/<title>(.*?)<\/title>/).first.first.force_encoding('UTF-8')
      response = conn.post("/repos/#{username}/#{repo_name}/issues") do |req|
        req.body = { body: url, labels: [kind, url_key], title: title }.to_json
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

## 最后

- 文中提到的关于链接`/`飘忽不定的事情我没碰到，我是直接取的[sitemap](https://madordie.github.io/sitemap.xml)，貌似每个文章都带了`/`
- 文中的引用啥的我都标记了链接，如有漏掉、不明白，麻烦告诉我一哈，我去补一下
- 我只是个小小的iOS，对ruby、js懂得不多，rb写的不好的地方轻拍
- 哦对了，这脚本全部在这里：[comment.rb](https://github.com/madordie/madordie.github.io/blob/master/comment.rb)。同时，这个脚本我又放在了自动发布的shell脚本里面，同样shell写的很水。。放在了这里：[deploy.sh](https://github.com/madordie/madordie.github.io/blob/master/deploy.sh)，而且是很早之前就写了的。。
- 如果还有什么问题，可以拉出来讨论一哈 ;)