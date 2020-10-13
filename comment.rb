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

  md5_key = URI.parse(url).path

  if md5_key.match(/^\/tags\/.+/) || md5_key.match(/^\/categories\/.+/)
  elsif commenteds.include?("#{url}\n") == false
    url_key = Digest::MD5.hexdigest(URI.parse(url).path)
    response = conn.get "/search/issues?q=label:#{url_key}+state:open+repo:#{username}/#{repo_name}"

    puts "正在创建: #{url} (#{URI.parse(url).path}) -> [#{url_key}, #{kind}]"
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