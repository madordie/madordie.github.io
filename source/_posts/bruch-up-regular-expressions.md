---
title: 正则表达式学习笔记
date: 2016-12-19 15:03:09
tags:
categories:
    - 正则表达式
---

正则表达式基础学习笔记。

<!--more-->

# 前面
  上次找了个很好的文章，可是手残没保存。。找不到了😭，现在重新找了一个文章：[正则表达式30分钟入门教程](https://luke0922.gitbooks.io/learnregularexpressionin30minutes/content/index.html)
  正如作者说的：
  > # 声明
  > 本文非原创，是改编自[《正则表达式30分钟入门教程》](http://deerchao.net/tutorials/regex/regex.htm#mission)，因为原作者的排版个人不是很喜欢，而且内容上个人觉得有些地方需要改进，所以在 gitbook 上开了一本书。
  
  OSC的[在线正则表达式测试](http://tool.oschina.net/regex)
  
# 开搞

## 元字符
  - `\` : 转义
  - `\b` : 单词开始或结束
  - `^` : 字符串开始
  - `$` : 字符串结束
  - `\d` : 一个数字
  - `\s` : 任意空白字符：空格、制表符、换行符、中文全角空格、等
  - `\w` : 字母/数字/下划线/汉字 可见字符
  - `.` : 除换行符以外的任意字符

## 重复
  - `{n}` : 前置位重复匹配 [n] 次
  - `{n,m}` : 前置位重复匹配 [n-m] 次
  - `{n,}` : 前置位重复匹配 [n-∞] 次
  - `*` : 数量区间：[0-N]
  - `+` : 数量区间：[1-N]
  - `?` : 数量区间：[0-1]
  
## 字符类
  - `[nml]` : 可以匹配到 n/m/l
  
## 条件
  - `|` : __或__语句。存在逻辑短路
  - `(m)` : __分组__语句。子式，可以指定重复什么的
  
## 反义
  - `\W` : 任意__不是__（字符、数字、下划线、汉字）
  - `\S` : 任意__不是__ 空白符
  - `\D` : 任意__不是__ 数字
  - `\B` : 任意__不是__ 单词开头或结尾
  - `\^x` : 除x以外的任意字符
  - `[\^abc]` : 除abc这几个字母以外的任意字符
  
## 后向引用
  `(\w+)`这样用`()`的部分称为一个分组，其匹配到的内容可以使用`\n`来表示，`n`代表该分组为第n个分组。分组下标从`1`开始。
  也可以自定义子表达式组名: `(?<Word>M) \k<Word>` : 或 `(?'Word'M) \k'Word'`，其中M为子式。
  
## 常用分组语法

### 捕获
  - `(exp)` : 匹配exp,并捕获文本到自动命名的组里
  - `(?exp)` : 匹配exp,并捕获文本到名称为name的组里，也可以写成(?'name'exp)
  - `(?:exp)` : 匹配exp,不捕获匹配的文本，也不给此分组分配组号

### 零宽断言
  - `(?=exp)` : 匹配exp前面的位置
  - `(?<=exp)` : 匹配exp后面的位置
  - `(?!exp)` : 匹配后面跟的不是exp的位置
  - `(?<!exp)` : 匹配前面不是exp的位置

### 注释
  - `(?#comment)` : 这种类型的分组不对正则表达式的处理产生任何影响，用于提供注释让人阅读
  
## 贪婪与懒惰
  贪婪：匹配的尽可能长
  懒惰：匹配的尽可能短
  
  - `*?` : 重复任意次，但尽可能少重复
  - `+?` : 重复1次或更多次，但尽可能少重复
  - `??` : 重复0次或1次，但尽可能少重复
  - `{n,m}?` : 重复n到m次，但尽可能少重复
  - `{n,}?` : 重复n次以上，但尽可能少重复
  
## 平衡组/递归匹配
  \# 我开始看不懂了😂
  
## 其他
  - `\a` : 报警字符(打印它的效果是电脑嘀一声)
  - `\b` : 通常是单词分界位置，但如果在字符类里使用代表退格
  - `\t` : 制表符，Tab
  - `\r` : 回车
  - `\v` : 竖向制表符
  - `\f` : 换页符
  - `\n` : 换行符
  - `\e` : Escape
  - `\0nn` : ASCII代码中八进制代码为nn的字符
  - `\xnn` : ASCII代码中十六进制代码为nn的字符
  - `\unnnn` : Unicode代码中十六进制代码为nnnn的字符
  - `\cN` : ASCII控制字符。比如\cC代表Ctrl+C
  - `\A` : 字符串开头(类似^，但不受处理多行选项的影响)
  - `\Z` : 字符串结尾或行尾(不受处理多行选项的影响)
  - `\z` : 字符串结尾(类似$，但不受处理多行选项的影响)
  - `\G` : 当前搜索的开头
  - `\p{name}` : Unicode中命名为name的字符类，例如\p{IsGreek}
  - `(?>exp)` : 贪婪子表达式
  - `(?<x>-<y>exp)` : 平衡组
  - `(?im-nsx:exp)` : 在子表达式exp中改变处理选项
  - `(?im-nsx)` : 为表达式后面的部分改变处理选项
  - `(?(exp)yes|no)` : 把exp当作零宽正向先行断言，如果在这个位置能匹配，使用yes作为此组的表达式；否则使用no
  - `(?(exp)yes)` : 同上，只是使用空表达式作为no
  - `(?(name)yes|no)` : 如果命名为name的组捕获到了内容，使用yes作为表达式；否则使用no
  - `(?(name)yes)` : 同上，只是使用空表达式作为no
  
  
## 栗子
  - 5-12位QQ：`^\d{5,12}$`
  - IPv4地址：`((2[0-4]\d|25[0-5]|[01]?\d\d?)\.){3}(2[0-4]\d|25[0-5]|[01]?\d\d?)`
  - `go go`、`kitty kitty`这样的叠词：`\b(\w+)\b\s+\1\b`
  - 后向引用：`\b(\w+)\b\s+\1\b` == `\b(?<Word>\w+)\b\s+\k<Word>\b` == `\b(?'Word'\w+)\b\s+\k'Word'\b`
  
# 最后
  知识研究了一下语法，还未详细测试。思考：这玩意真心厉害😂。