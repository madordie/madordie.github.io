---
title: 用CollectionView简化代码，专注于业务和UI
url: ios-tool-collectionview-simplify-business
date: 2017-10-12
tags: 
    - tool
    - UICollectionView
categories:
    - iOS
---

`UITableView`作为高级控件被开发者广泛使用，同样的，`UICollectionView`由于其NB的布局也被广泛使用。但是后者在使用的时候大多数都属于自定义的比较多，前者则相对普通，list基本上都用。

在业务需求中，常规布局，大多数都是采用`UITableView`进行的，但是有痛点：

- 当使在APP内用过一次瀑布流之后，设计师会突然的让你在正常的list中底部追加瀑布流。。虽然是在底部追加，但是要从`UITableView`迁移到`UICollectionView`
- `UITableViewDelegate`、`UITableViewDataSource` 恐怕每处使用都要写繁琐的相同的代码吧～
- 很多人也会对其进行高度缓存啊神马的优化策略
- 不知不觉这些代码堆在一起已经将`UIViewController`堆的相当的高

然后呢，我们现在使用一个`CollectionView`将这些操作包装一下，达到这样一个流程:

1. 自定义Cell、CellModel
```swift
class LabelCell: UICollectionViewCell {
    let info = UILabel()
    ...
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        ...
        return CGSize(width: size.width, height: info.frame.maxY + info.frame.minY)
    }
}
extension LabelCell {
    class Model: ListItemDefaultProtocol {
        var info: String?
        func fillModel(view: LabelCell) {
            view.info.text = info
        }
    }
}
```

2. 请求、处理数据格式化为`LabelCell.Model`这样的类
3. 处理好的数据交给`CollectionView`
```swift
list.sections = model.format(...)
```

4. 休息一会，完工了～

然后，来看看`Collection`里面都做了什么操作

<!--more-->

### CollectionView

为了达到上面效果中的第三步，我们需要自定义一个`CollectionView`来处理刷新数据、设置代理、设置数据源、注册cell、等操作。

需要说明的是，此处使用[`CHTCollectionViewWaterfallLayout`](https://github.com/chiahsien/CHTCollectionViewWaterfallLayout)来处理瀑布流。

创建一个`CollectionViewSection`的类/结构体来保存section信息。比如说：`sectionInset`、`minimumColumnSpacing`、`minimumInteritemSpacing`、`columnCount`、等

在`CollectionView`中设置一个`var sections = [KTJCollectionViewSection]()`用于保存sections

实现`UICollectionViewDataSource`、 `UICollectionViewDelegate`。此处省略约1千字...

### ListItemDefaultProtocol：绑定Cell和Model

上面`省略约1千字`中有一个并没有说：`CollectionViewSection`的`header`、`items`、`footer`如何实现。😂

好了，此处这三个均采用协议`ListItemDefaultProtocol`来实现。（PS：大家都喜欢用父类，但父类只有一个，为了兼容和冲突，这里协议是最好不过的～，特别是swift中的协议）

协议需要给出这么几个信息：
- `reuseIdentifier` 用来复用的重用标识符
- `cellClass` 用来注册用的类名
- `func fillModel(item: AnyObject)` 用来给cell填充model的方法

那么这个协议就出来了：
```swift
protocol KTJListItemProtocol {
    var identifa: String { get }
    var registClass: AnyClass { get }
    func fillModel(item: AnyObject)
}
```

在**swift**协议支持默认实现，于是乎，就可以再写一个:
```swift
protocol ListItemDefaultProtocol: KTJListItemProtocol {
    associatedtype ItemType: UIView
    func fillModel(view: ItemType)
}
extension ListItemDefaultProtocol {
    var identifa: String { return  NSStringFromClass(ItemType.self)}
    var registClass: AnyClass { return ItemType.self }
    func fillModel(item: AnyObject) {
        if let reusableView = item as? ItemType {
            fillModel(view: reusableView)
        }
    }
}
```

然后，就可以愉快的玩耍了～～

最后Cell中的的代码效果就是[这个样子](https://github.com/madordie/collectionview-simplify-business/blob/master/CollectionView-simplify-business/LabelCell.swift)。
再加上[数据填充](https://github.com/madordie/collectionview-simplify-business/blob/master/CollectionView-simplify-business/ViewController.swift)是不是很简单了呢～～

### 以后如何开发

真的如同前面的例子一样，只需要这么几步绕不过去的：

1. 处理接口吐出来的数据。
2. 创建新的UI样式，并做好接口数据中间件。
3. 点击事件在处理数据的时候预先埋好，所有的数据、逻辑和UI数据一起被传递，不需要多次类型判断。

统一使用`CollectionView`还有一个好处：不管前面谁写的一个UI，都能拉过来用。不用做中间层去从`TableViewCell`转`CollectionViewCell`。

开发只需要关心业务，业务。安安心心做一个写业务的程序员吧～

### 关于Cell的跳转处理

乍一看，完美了。不过还有一个巨烦的跳转处理。。。不过，**莫怕**

跳转，有这么几种：
- 支持路由的URL跳转，这个是最简单的，也是最爽的
- 只能复杂的进行创建类、赋值、push啊神马的

由于我们将数据全部处理好后扔给了`cellmodel`，而跳转、打点所需要的参数均在此处为最全的，我们可以将回调作为数据一起传递。。

嗯, 事件需要传递的对象大约这个样子：
```swift
struct Jmp {
    /// 支持URL跳转的URL
    let url: String?
    /// 打点事件名
    let event: String?
    /// 打点参数
    let attr: [AnyHashable: Any]?
    /// 不支持URL的直接回调
    let eventCallback: (() -> Void)?
}
```

然后cell对应的另一个类是这样的：
```swift
class KTJJmp: NSObject {
    var info: Jmp?
    let action = #selector(topVCJmp)
    @objc func topVCJmp() {
        ... // 打点
        KTJURLJump.jumpToViewOnTopVC(jmp: info)
        info?.eventCallback?()
    }
    func tap() -> UITapGestureRecognizer {
        return UITapGestureRecognizer(target: self, action: #selector(topVCJmp))
    }
}
```

两个类共同作用就是：
```swift
class JmpCell: UICollectionViewCell {
    let jmp = JmpCellModel()
    func setup() {
        ...
        jmpBtn.addTarget(jmp, action: jmp.action, for: .touchUpInside)
    }
}
class JmpCellModel: ListItemDefaultProtocol {
    var jmp: Jmp?
    func fillModel(view: JmpCell) {
        view.jmp.info = jmp
    }
}
```
至于这个`JmpCellModel.jmp`怎么生成，这里就不说了。

### 关于算高那点事

#### 算高位置的选择

我也曾纠结过frame的代码应该写在哪里。。有写在初始化的，有单独写一个方法的，还有写在`func sizeThatFits(:) -> CGSize`

由于当年对[UITableView-FDTemplateLayoutCell](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell)中毒较深，所以沿用了最后一种方案。

#### 算高使用的view的选择

在算高的时候，首先需要明确的是：**高度是数据和当前最大宽度共同决定的**，所以在算高的时候需要拿着数据、view然后才能去算高（PS：至于那些拿着数据硬算出一个高度的代码，此处不发表看法😂，早晚会后悔的）

然后就是`UITableView`、`UICollectionView`的算高是通过一个单独的代理去获取的，并不提供view去计算。。这就是矛盾的地方。

虽然`UITableView`、`UICollectionView`在算高的地方不提供View,但是有一个`dequeueReusableCell....`的方法可以获取到缓存池中的`Cell`呀

如果你这样做了，那么你将会付出惨重的代码。这个方案我在[博客园](http://www.cnblogs.com/madordie)2015.03.17的[“iOS 优化性能之TableView”](http://www.cnblogs.com/madordie/p/4344209.html)中已经说了：
> dequeueReusableCellWithIdentifier:此函数的调用要注意以下几点：
    i.此函数的返回值是做为tableView:cellForRowAtIndexPath:的返回值的。这样保证拿出来的完整还给TableView。
    ii.如果此函数的返回值不是为了给tableView:cellForRowAtIndexPath:做返回值，那么你要注意这是在一个拿取别人稀缺资源的操作，需要注意珍惜这个返回值，能不浪费就不要浪费。
    iii.对于AL自动适应的TableView取Cell时候要注意保存。个人建议封装TableView，然后用来计算高度的Cell保存在TableView中。对于多种类型的Cell，则可以使用复用标识符作为Key的字典来存储。这样能够有效节约dequeueReusableCellWithIdentifier:调用次数。

`UICollectionView`也是如此。所以使用`dequeueReusableCell....`方法是**很不靠谱的**。

在[UITableView-FDTemplateLayoutCell](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell/blob/912b3ce4a61198c0b79a3d85b977f8fdacd153ea/Classes/UITableView%2BFDTemplateLayoutCell.m#L134-#L155)中使用了字典保存缓存算高的View，也是比较赞的。

但是现在有了`CollectionView`，我们可以不用OC的`objc_setAssociatedObject(,,,)`去处理而直接使用了`NSCache`去处理就行了～

如果看了[`CollectionView`](https://github.com/madordie/collectionview-simplify-business/blob/master/CollectionView.swift)就会发现，`ListItemProtocol`还有一个get方法`var newItem: AnyObject { get }`这个是用来算高的。

在[CollectionView.swift](https://github.com/madordie/collectionview-simplify-business/blob/master/CollectionView.swift)关于高度的代理设置中可以看到相关获取和设置。

#### 算高的时候变局的控制

高度的计算现在已经可以正常计算，但是对于`columnCount > 1`的时候，牵扯到间隙的计算需要注意一次啊。毕竟`CHTCollectionViewWaterfallLayout`功能更强大。

相关代码在[CollectionView.swift](https://github.com/madordie/collectionview-simplify-business/blob/master/CollectionView.swift)的`func collectionView(:,layout:,sizeForItemAt:) -> CGSize`函数中。

### 关于代理那点事

丫的，需求总是比想的多，但是办法也比问题多。

对于`CollectionView`来说，代理都设置成了self，这样会导致有时候需要`UIScrollViewDelegate`干些事情的时候总是不那么自由。。。实乃新痛点，不过有办法。

下面是几种方案：

#### KVO

直接KVO到`self.contentOffset`，这样一了百了。写什么代理，要什么自行车！（PS：swift提供闭包的代理，也是很好用的）

如果不会，请自行[Google](https://www.google.com)。[ObjC-中国：KVC 和 KVO](https://objccn.io/issue-7-3/)，我只能帮你到这里

#### Rx系

很抱歉，你不能用`self.rx.contentOffset`。原因是[`CHTCollectionViewWaterfallLayout`](https://github.com/chiahsien/CHTCollectionViewWaterfallLayout)中有这么一行断言：

> ```swift
 NSAssert([self.delegate conformsToProtocol:@protocol(CHTCollectionViewDelegateWaterfallLayout)], @"UICollectionView's delegate should conform to CHTCollectionViewDelegateWaterfallLayout protocol");
 ```

**但是**，你可以使用Rx里面的KVO呀～也是贼方便

#### RAC系

抱歉，我不会。原因在此[准备食用RAC(ReactiveCocoa)的顾虑](../reactivecocoa-ready-to-use)

#### 代理传递

当然也可以使用代理进行传递出去。大致这个样子：

```swift
protocol CollectionViewDelegate: NSObjectProtocol {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
}
class CollectionView {
    weak var allDelegate: CollectionViewDelegate?
}
func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.allDelegate?.collectionView(self, didSelectItemAt: indexPath)
}
```
这方案没啥聊的。。

### OC咋办？

这个OC也能用，只不过需要一些手段，比如说：继承、扩展、等

`ListItemProtocol`就是为了给OC使用留的，还有就是`CollectionViewSection`使用了类，而不是结构体。

不过具体没有例子，不想写OC代码，太麻烦了。。主要是这种思路:)

### 填充Cell的数据为什么会在CellModel中？

对于Cell来说，Cell是干净的，没有任何继承、协议来限制Cell如何处理。那么Cell就可以接受来自任何模块的各种风格的Cell，这是我想要的减少侵入。

cellModel中定义了Cell所对应的填充数据格式，在第一次写的时候难免会按照业务逻辑起一些业务逻辑的名字，在复用的时候又不能改名字，会对维护和开发加了一定量的复杂度，这不是我想要的。。

于是乎每个CellModel根据自己的需要绑定需要绑定的Cell，去填充Cell所对应的数据就好。只需要侵入cellModel即可。代价最小，受益最大。

PS.对于同一个List，需要注意cell的复用和多个cellModel同时绑定一个cell时，属性的设置。

### Demo

[Demo](https://github.com/madordie/collectionview-simplify-business)部分没有写跳转相关内容，但是别的都有了😂

### 别的

好像没了吧～，想起来了再补充咯