---
title: 如何快速查找ipa内的符号引用
url: how-to-quickly-find-symbol-references-in-ipa
date: 2020-07-22
tags:
    - DEBUG
    - tool
categories:
	- iOS
	- macOS
---

> ITMS-90809: Deprecated API Usage - Apple will stop accepting submissions of apps that use UIWebView APIs . See https://developer.apple.com/documentation/uikit/uiwebview for more information.

熟悉不?

<!--more-->

## 源码级别引用

有些时候, 我们需要查找我们的`.ipa`里面什么地方使用了某个API, 而常规操作是在Xcode的`Navigation -> Find`里面直接search一下就可以查到源码上哪些地方直接调用了该API.

而往往这种情况下可以解决问题的话就不会跑去`Google`了.

## 二进制级别引用

APP总会通过各种手段集成些别人的第三方库, 而此库究竟干了什么我们一般并不能十分了解(如果能了解大概人家就开源了吧). 这个时候要如何查找这些库有没有使用某API该咋办呢?

### 定位究竟有谁在包含

我们提交`App Store`都是打包成`.ipa`提交,所以我们先将`.ipa`重命名`.zip`并解压. 然后假设我们需要找的是`UIWebView`, `Terminal`搞开,到解压后的目录.

```sh
╭─Bingo@madordie xxx.app
╰─>$ find . -print0 | xargs -0 grep -s 'UIWebView'
```

便得到`xxx.app`内所有包含`UIWebView`字符的文件(包括Mach-O). 这个时候输出的行`Binary file ./XXXX/YYYY matches`即为匹配到了.

此时定位到`XXXX/YYYY`内含有`UIWebView`.

另外: 上述命令在项目主目录执行也可以搜索到, 只不过除了`Navigation -> Find`里search的还有其他的, 内容如果多的话可以再用`grep`过滤一次.

比如只关心`Binary file`:

```sh
╭─Bingo@madordie project-main-path
╰─>$ find . -print0 | xargs -0 grep -s 'UIWebView' | grep '^Binary'
```

### 这个API在Mach-O中是什么

#### 有字符串吗

```sh
╭─Bingo@madordie xxx.app
╰─>$ strings ./XXXX/YYYY | grep 'UIWebView'
T@"UIWebView",R,N,V_webView
UIWebViewDelegate
B40@0:8@"UIWebView"16@"NSURLRequest"24q32
v24@0:8@"UIWebView"16
v32@0:8@"UIWebView"16@"NSError"24
@"UIWebView"
```

#### 有symbol吗

```sh
╭─Bingo@madordie xxx.app
╰─>$ nm ./XXXX/YYYY | grep 'UIWebView'
                 U _OBJC_CLASS_$_UIWebView
```

### 值得说一下

通过上面的操作基本上可以检索出来App Store查到的API, 但是说其他的字符串拼接/加密的方案去绕过的话,那么就问问作者吧...

真不行使用逆向分析工具去分析也可以. 但是个人觉得稍微有点大材小用 :)

上面使用的命令的文档均可通过`man xxx`、`xxx --help`、Google等方式查询就不啰嗦了.

### UIWebView的废弃通告

[更新使用网页视图的 App](https://developer.apple.com/cn/news/?id=12232019b)

> 更新使用网页视图的 App
> 2019 年 12 月 23 日
>
>如果您的 app 仍在使用已弃用的 UIWebView API 嵌入网络内容，我们强烈建议您尽快更新为 WKWebView 以提升安全性和稳定性。WKWebView 可将网页处理限制在 app 的网页视图中，从而确保不安全的网站内容不会影响到 app 的其他部分。此外，iOS、macOS 和 Mac Catalyst 均支持 WKWebView。
>
>2020 年 4 月起 App Store 将不再接受使用 UIWebView 的新 app，2020 年 12 月起将不再接受使用 UIWebView 的 app 更新。