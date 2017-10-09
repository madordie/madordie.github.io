---
title: 优雅的使用SwiftLint
url: elegant-to-use-swiftlint
date: 2016-12-23 11:59:57
tags:
    - 构建
    - SwiftLint
categories:
    - iOS
---

接入了SwiftLine，修改2000+的warning、300+error的一点笔记心得。

<!--more-->

# SwiftLint

  > ## [SwiftLint](https://github.com/realm/SwiftLint)
  > A tool to enforce Swift style and conventions, loosely based on GitHub's Swift Style Guide.
  SwiftLint hooks into Clang and SourceKit to use the AST representation of your source files for more accurate results.
  SwiftLint 是一个用于强制检查 Swift 代码风格和规定的一个工具，基本上以 GitHub's Swift 代码风格指南为基础。
  SwiftLint Hook 了 Clang 和 SourceKit 从而能够使用 AST 来表示源代码文件的更多精确结果。
  
## 对原有代码格式化

### 自动格式化
  ```bash
  swiftlint autocorrect
  ```

### TrailingWhitespaceRule

#### 现象
  > xxx.swift:34: warning: Trailing Whitespace Violation: Lines should not have trailing whitespace. (trailing_whitespace)
  
  规则实现：[TrailingWhitespaceRule.swift](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/TrailingWhitespaceRule.swift)
  
#### 原因
  Xcode中的"空白行"。其实并不空白，含有空的字符。最明显的表现为git提交的时候会有明显的黄色警告。

#### 解决办法
  Xcode中有选项可以直接控制，具体路径为
  ```
  Xcode 
  -> Preferences
  -> Text Editing
  -> While editing
  -> [V] Including whitespace-only lines
  ```
  
### ColonRule

#### 现象
  > xxx.swift:13:71: warning: Colon Violation: Colons should be next to the identifier when specifying a type. (colon)
  
#### 原因
  变量方法的 `: ` 的右边应该有一个空格才能识别出来，且左侧不能留空格。所以写代码的时候随手写上还是比较好的。。
  栗子：
  ```
  //  OK:
  var responseData: [String : Any]? = nil // 返回结果，请求之前为nil

  //  warning: 第一个':'处左侧有空格
  var responseData : [String : Any]? = nil // 返回结果，请求之前为nil
  
  //  warning: 第一个':'处右侧无空格
  var responseData:[String : Any]? = nil // 返回结果，请求之前为nil
  ```

#### 解决办法
  规范书写
  
### LineLengthRule

#### 现象
  > xxx.swift:90: warning: Line Length Violation: Line should be 100 characters or less: currently 101 characters (line_length)
  
#### 原因
  行数超了呗。。
  
#### 解决办法
  - 方法名字写的简单易懂
  
### ControlStatementRule

#### 现象
  > xxx.swift:169:21: warning: Control Statement Violation: if,for,while,do statements shouldn't wrap their conditionals in parentheses. (control_statement)
  
  规则实现[ControlStatementRule](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/ControlStatementRule.swift)
  
#### 原因
  swift中`if,for,while,do` 语句不应该用`()`


### UnusedClosureParameterRule

#### 现象
  > xxx.swift:103:62: warning: Unused Closure Parameter Violation: Unused parameter "response" in a closure should be replaced with _. (unused_closure_parameter)

  规则实现[UnusedClosureParameterRule](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/UnusedClosureParameterRule.swift)

#### 原因
  `response` 没有使用，建议替换为 `_`。
  
### CyclomaticComplexityRule

#### 现象
  > xxx.swift:69:5: warning: Cyclomatic Complexity Violation: Function should have complexity 10 or less: currently complexity equals 14 (cyclomatic_complexity)
  
  规则实现[CyclomaticComplexityRule](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/CyclomaticComplexityRule.swift)

#### 原因
  😂，他说你这函数写的太复杂了。看实现是说不能有过多的`if {}`
  

### OpeningBraceRule

#### 现象
  > xxx.swift:221:34: warning: Opening Brace Spacing Violation: Opening braces should be preceded by a single space and on the same line as the declaration. (opening_brace)
  
  规则实现[OpeningBraceRule](https://github.com/realm/SwiftLint/blob/master/Source/SwiftLintFramework/Rules/OpeningBraceRule.swift)
  
#### 解决
  `{}`的前面要有空格隔开
