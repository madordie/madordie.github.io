---
title: debug-_SwiftValue-unsignedIntegerValue
date: 2017-04-17 14:05:09
tags:
categories:
	- DEBUG
---

crash:
```
let attr = try? NSMutableAttributedString(data: data,
                                          options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                    NSCharacterEncodingDocumentAttribute: String.Encoding.utf8],
                                          documentAttributes:nil)
// log:
2017-04-17 14:04:38.140 [41275:463875] -[_SwiftValue unsignedIntegerValue]: unrecognized selector sent to instance 0x608000256620
```

<!--more-->



WTF! 这个方法启动时不能直接调用，要异步？