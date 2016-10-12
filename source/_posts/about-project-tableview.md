---
title: 项目中的UITableView
tags:
  - iOS
  - 架构
---

# 论项目架构设计的重要性

前两天听到有人说多人合作的项目并不需要处理很多事情，只需要处理好自己的那部分业务逻辑就好了。感觉这是一个很不负责任的说法。作为一个APP的开发者，自己负责的事其中的一个模块，但是都是这个APP的开发者，也要往里面塞代码，如果每个人都用不同的逻辑风格去组织代码。那么整个项目就是一坨坨坨，这个坨会影响项目的演进、日后的发展。当然有的是看不出来的，比如说：当一个请假的人写的代码出现一个BUG，需要修复上线的时候，对于不同的代码风格，需要找到问题的关键代码，这个过程是撕心裂肺的，但是如果同一套代码风格，心中就会有一个大致的位置，去修改时候就会比较快速的定位问题。

对于无法接受通用的代码风格，只钟爱自己一种代码风格的程序员来说：如果你是刚转行过来的，那么你要走的路还有很长，踩的坑还有很多。积极主动的踩坑，才能不会掉队。


# 从协议入手

`UITableView`是项目中非常常见的iOS高级控件，在页面中所有相似的页面几乎都是由该控件进行完成。其广泛运用的不止是使用方便，最主要的是内部的复用优化也是相当给力的。



## 协议模式下的UITableView

`UITableView`是典型的 __协议-代理模式__ ，比例`id <UITableViewDataSource> dataSource`和`id <UITableViewDelegate> delegate`，所以使用对于这种比较规整的列表来说把协议继续扩展到下一级也是可以的。

为了统一`UITableView.dataSource`和`UITableView.delegate`，构建如下协议：
```objc
//  直接填充Cell的cellModel
@protocol CellModelProtocol <NSObject>

- (NSString *)cellClassName;  //  cellModel绑定的类名
- (void)cellModelForCell:(UITableViewCell *)cell; //  cellModel填充上面绑定的cell

@end

```


那么只需要在代理中做如下设置:

```objc
#pragma mark <UITableViewDelegate, UITableViewDataSource>
- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.viewModel.dataSource.count;
}
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
      id<CellModelProtocol> cellModel = self.viewModel.dataSource[indexPath.row];
      UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[cellModel cellClassName]];
      cell.frame = tableView.bounds;
      [cellModel cellModelForCell:cell];
      [cell sizeToFit];
      return cell;
}
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
      id<CellModelProtocol> cellModel = self.viewModel.dataSource[indexPath.row];
      UITableViewCell* cell = [tableView ktj_cacheHeightCellForReuseIDFA:[cellModel cellClassName]];
      [cellModel cellModelForCell:cell];
      return [cell sizeThatFits:tableView.bounds.size].height;
}

```

而在cell中，默认在`sizeThatFits:`中进行布局的设置和算高即可。如下：

```objc
//  xxxCell.m

- (CGSize)sizeThatFits:(CGSize)size {
    
    CGRect frame = CGRectZero;
    //  根据Cell的实际内容进行布局并设置高度
    frame.origin = CGPointMake(10, 15);
    frame.size = [self.infoLabel sizeThatFits:CGSizeMake(size.width-frame.origin.x*2, size.height)];
    self.infoLabel.frame = frame;
    
    size.height = CGRectGetMaxY(self.infoLabel.frame)+frame.origin.y;
    return size;
}

```

如果cell采用autolayout，则计算采用[UITableView-FDTemplateLayoutCell](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell/blob/e3ee86ce419d18d3ff735056f1474f2863e43003/Classes/UITableView%2BFDTemplateLayoutCell.m)的计算方法。

```objc
@implementation UITableViewCell (KTJCellAutoLayoutForSize)
//  autolout布局计算高度
- (CGSize)ktj_ALCellSizeThatFits:(CGSize)size {
    // Add a hard width constraint to make dynamic content views (like labels) expand vertically instead
    // of growing horizontally, in a flow-layout manner.
    NSLayoutConstraint *tempWidthConstraint =
    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0
                                  constant:size.width];
    [self.contentView addConstraint:tempWidthConstraint];
    // Auto layout engine does its math
    size = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    size.height += 1;
    [self.contentView removeConstraint:tempWidthConstraint];
    return size;
}
@end

```

另外在`<UITableViewDelegate, UITableViewDataSource>`中只写了1组，只有cell，没有header、footer的情况，如果需要，炮制即可。

说一下这个其中的`ktj_cacheHeightCellForReuseIDFA:`类别方法。这个方法是为了算高进行缓存的一个cell，这个cell保存在 `NSCache`中。所以为了统一，需要在数据初始化时候注册所有的cell。当然你也可以根据类名直接生成，这个自主决定。

说到算高，需要说一下这其中的`dequeueReusableCellWithIdentifier:`方法。该方法是从tableView的缓存池中取出指定ID的cell。请注意是 __取出__ ，并且`UITableView`并没有暴露出如何放进缓存池，也没有必要暴露出放进缓存池的方法。而且`UITableView`只有一个地方能够接收Cell那就是`tableView:cellForRowAtIndexPath:`。所以请保证`dequeueReusableCellWithIdentifier:`取出的方法 __需要通过`tableView:cellForRowAtIndexPath:`返回给`UITableView`__ 。这就是我上面说的`ktj_cacheHeightCellForReuseIDFA:`方法为何要做一个 cache去缓存我取出的cell，目的是为了减少cell的浪费。


同理，对于`UITableView`的`headerView`、`footerView`来说，可以炮制以上协议、方法。不再赘述


PS.
  1. [UITableView-FDTemplateLayoutCell](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell): [sunnyxx](https://github.com/sunnyxx)打造的优化UITableView的一个库，6000的star，很赞。
  

# 规范化的代码风格

对于多人开发，最崩溃的事情就要数去读别人的代码。就算不是多人开发，接手别人的代码也是让人最崩溃的事情。如果有不用考虑这件事的叫我！

不同的公司可以有不同的代码风格，但是一个公司的代码风格需要保持一致，这样就不会出现一人请假，无人能接受项目的尴尬局面，就算能接，也是需要为了加一个逻辑判断，需要花费很大的精力去处理。

至于其中的代码不统一的坑，恐怕要等踩过才知道吧😂。


# 业务逻辑的拆分

对于复杂的业务逻辑，对其拆分是非常重要的，不拆分很可能写出来的代码一个文件 >1000 行。复杂的业务逻辑对于写出来需要一气呵成，修改起来也就出现了牵一发动全身(虽然拆分完成之后可能也会关键逻辑代码不可拆分，但是会好很多)。


## 筛选重构

筛选主要处理的是筛选项，针对众多筛选条件拆分为不同的业务逻辑模块是必须的。遵照拆分的原则，于是乎根据UI划分出来位置、价格、户型、筛选、排序这么几个模块。针对每个模块自行处理选中数据、UI展示。对外只暴露选中项输入和选中回调。

对于每个数据大致都可分为一个列表，然后可选中1项或多项。于是乎，这个代码如果不拉出来是要写好多次的，拉出来，但是选中需要把选中的逻辑扔出来，方便自定义。



## 地图踩坑