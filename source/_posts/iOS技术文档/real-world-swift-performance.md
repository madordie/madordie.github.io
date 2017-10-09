---
title: 「转」真实世界中的 Swift 性能优化
url: real-world-swift-performance
date: 2017-01-17 19:14:57
tags:
    - 优化
categories:
    - iOS
---

原文链接：[真实世界中的 Swift 性能优化](https://realm.io/cn/news/real-world-swift-performance/)

<!--more-->

------

有太多的因素会导致您的应用变得缓慢。在本次讲演中，我们将自底向上地来探索应用的性能优化。来看一看在真实世界中进行数据解析、数据映射和数据存储的时候，Swift 的特性（协议、泛型、结构体和类）是如何影响应用性能的，我们将确定影响性能提升的瓶颈所在，并体验 Swift 带来的「迅捷」体验。

## 概述

今天我打算同大家谈论 Swift 性能优化方面的内容。当我们构建软件的时候，特别是移动软件，由于人们的精力、时间有限，人们往往更喜欢有一个流畅的用户体验，而不是等着您的应用在那加载。如果应用运行速度过慢，并且不能给用户带来他们所想要的结果的话，那么这会让人们感到不爽。因此，让您的代码能够快速运行是无比重要的一件事。

那么有什么因素会导致代码运行缓慢呢？当您在编写代码并选择架构的时候，深刻认识到这些架构所带来的影响是非常重要的。我将首先谈一谈：如何理解内联、动态调度与静态调度之间的权衡，以及相关结构是如何分配内存的，还有怎样选择最适合的架构。

## 内存分配

对象的内存分配 (allocation) 和内存释放 (deallocation) 是代码中最大的开销之一，同时通常也是不可避免的。Swift 会自行分配和释放内存，此外它存在两种类型的分配方式。

第一个是基于栈 (stack-based) 的内存分配。Swift 会尽可能选择在栈上分配内存。栈是一种非常简单的数据结构；数据从栈的底部推入 (push)，从栈的顶部弹出 (pop)。由于我们只能够修改栈的末端，因此我们可以通过维护一个指向栈末端的指针来实现这种数据结构，并且在其中进行内存的分配和释放只需要重新分配该整数即可。

第二个是基于堆 (heap-based) 的内存分配。这使得内存分配将具备更加动态的生命周期，但是这需要更为复杂的数据结构。要在堆上进行内存分配的话，您需要锁定堆当中的一个空闲块 (free block)，其大小能够容纳您的对象。因此，我们需要找到未使用的块，然后在其中分配内存。当我们需要释放内存的时候，我们就必须搜索何处能够重新插入该内存块。这个操作很缓慢。主要是为了线程安全，我们必须要对这些东西进行锁定和同步。

## 引用计数

我们还有引用计数 (reference counting) 的概念，这个操作相对不怎么耗费性能，但是由于使用次数很多，因此它带来的性能影响仍然是很大的。引用计数是 Objective-C 和 Swift 中用于确定何时该释放对象的安全机制。目前，Swift 当中的引用计数是强制自动管理的，这意味着它很容易被开发者们所忽略。然而，当您打开 Instrument 查看何处影响了代码运行的速度的时候，您会发现 20,000 多次的 Swift 持有 (retain) 和释放 (release)，这些操作占用了 90% 的代码运行时间！
```swift
func perform(with object: Object) {
    object.doAThing()
}
```
这是因为如果有这样一个函数接收了一个对象作为参数，并且执行了这个对象的 doAThing() 方法，编译器会自动插入对象持有和释放操作，以确保在这个方法的生命周期当中，这个对象不会被回收掉。
```swift
func perform(with object: Object) {
    __swift_retain(object)
    object.doAThing()
    __swift_release(object)
}
```
这些对象持有和释放操作是原子操作 (atomic operations)，所以它们运转缓慢就很正常了。或者，是因为我们不知道如何让它们能够运行得更快一些。

## 调度与对象

此外还有调度 (dispatch) 的概念。Swift 拥有三种类型的调度方式。Swift 会尽可能将函数内联 (inline)，这样的话使用这个函数将不会有额外的性能开销。这个函数可以直接调用。静态调度 (static dispatch) 本质上是通过 V-table 进行的查找和跳转，这个操作会花费一纳秒的时间。然后动态调度 (dynamic dispatch) 将会花费大概五纳秒的时间，如果您只有几个这样的方法调用的话，这实际上并不会带来多大的问题，问题是当您在一个嵌套循环或者执行上千次操作当中使用了动态调度的话，那么它所带来的性能耗费将成百上千地累积起来，最终影响应用性能。

Swift 同样也有两种类型的对象。
```swift
class Index {
    let section: Int
    let item: Int
}

let i = Index(section: 1,
                item: 1)
```
这是一个类，类当中的数据都会在堆上分配内存。您可以在此处看到，这里我们创建了一个名为 Index 的类。其中包含了两个属性，一个 section 和一个 item。当我们创建了这个对象的时候，堆上便创建了一个指向此 Index 的指针，因此在堆上便存放了这个 section 和 item 的数据和空间。

如果我们对其建立引用，就会发现我们现在有两个指向堆上相同区域的指针了，它们之间是共享内存的。
```swift
class Index {
    let section: Int
    let item: Int
}

let i = Index(section: 1,
                item: 1)

let i2 = i
```
这个时候，Swift 会自动插入对象持有操作。
```swift
class Index {
    let section: Int
    let item: Int
}

let i = Index(section: 1,
                item: 1)

__swift_retain(i)
let i2 = i
```
## 结构体

很多人都会说：要编写性能优异的 Swift 代码，最简单的方式就是使用结构体了，结构体通常是一个很好的结构，因为结构体会存储在栈上，并且通常会使用静态调度或者内联调度。

存储在栈上的 Swift 结构体将占用三个 Word 大小。如果您的结构体当中的数据数量低于三种的话，那么结构体的值会自动在栈上内联。Word 是 CPU 当中内置整数的大小，它是 CPU 所工作的区块。
```swift
struct Index {
    let section: Int
    let item: Int
}

let i = Index(section: 1, item: 1)
```
在这里您可以看到，当我们创建这个结构体的时候，带有 section 和 item 值得 Index 结构体将会直接下放到栈当中，这个时候不会有额外的内存分配发生。那么如果我们在别处将其赋值到另一个变量的时候，会发生什么呢？
```swift
struct Index {
    let section: Int
    let item: Int
}

let i = Index(section: 1, item: 1)
let i2 = i
```
如果我们将 i 赋给 i2，这会将我们存储在栈当中的值直接再次复制一遍，这个时候并不会出现引用的情况。这就是所谓的「值类型」。

那么如果结构体当中存放了引用类型的话又会怎样呢？持有内联指针的结构体。
```swift
struct User {
    let name: String
    let id: String
}

let u = User(name: "Joe", id: "1234")
```
当我们将其赋值给别的变量的时候，我们就持有了共享两个结构体的相同指针，因此我们必须要对这两个指针进行持有操作，而不是在对象上执行单独的持有操作。
```swift
struct User {
    let name: String
    let id: String
}

let u = User(name: "Joe",
             id: "1234")
__swift_retain(u.name._textStorage)
__swift_retain(u.id._textStorage)
let u2 = u
```
如果其中包含了类的话，那么性能耗费会更大。

## 抽象类型

正如我们此前所述，Swift 提供了许多不同的抽象类型 (abstraction)，从而允许我们自行决定代码该如何运行，以及决定代码的性能特性。现在我们来看一看抽象类型是如何在实际环境当中使用的。这里有一段很简单的代码：
```swift
struct Circle {
    let radius: Double
    let center: Point
    func draw() {}
}

var circles = (1..<100_000_000).map { _ in Circle(...) }

for circle in circles {
    circle.draw()
}
```
这里有一个带有 radius 和 center 属性的 Circle 结构体。它将占用三个 Word 大小的空间，并存储在栈上。我们创建了一亿个 Circle，然后我们遍历这些 Circle 并调用这个函数。在我的电脑上，这段操作在发布模式下耗费了 0.3 秒的时间。那么当需求发生变更的时候，会发生什么事呢？

我们不仅需要绘圆，还需要能够处理多种类型的形状。让我们假设我们还需要绘线。我非常喜欢面向协议编程，因为它允许我在不使用继承的情况下实现多态性，并且它允许我们只需要考虑这个「抽象类型」即可。
```
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    let radius: Double
    let center: Point
    func draw() {}
}

let drawables: [Drawable] = (1..<100_000_000).map { _ in Circle(...) }

for drawable in drawables {
    drawable.draw()
}
```
我们需要做的，就是将这个 draw 方法析取到协议当中，然后将数组的引用类型变更为这个协议，这样做导致这段代码花费了 4.0 秒的时间来运行。速率减慢了 1300%，这是为什么呢？

这是因为此前的代码可以被静态调度，从而在没有任何堆应用建立的情况下仍能够执行。这就是协议是如何实现的。

例如，如大家所见，这里是我们此前的 Circle 结构体。在这个 for 循环当中，Swift 编译器所做的就是前往 V-table 进行查找，或者直接将 draw 函数内联。

```
struct Circle {
    let radius: Double
    let center: Point
    func draw() {}
}

var circles = (1..<100_000_000).map { _ in Circle(...) }

for circle in circles {
    circle.draw()
}
```
当我们用协议来替代的时候，此时它并不知道这个对象是结构体还是类。因为这里可能是任何一个实现此协议的类型。

```
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    let radius: Double
    let center: Point

    func draw() {}
}

var drawables: [Drawable] = (1..<100_000_000).map { _ in return Circle(...) }

for drawable in drawables {
    drawable.draw()
}
```
那么我们该如何去调度这个 draw 函数呢？答案就位于协议记录表 (protocol witness table，也称为虚函数表) 当中。它其中存放了您应用当中每个实现协议的对象名，并且在底层实现当中，这个表本质上充当了这些类型的别名。

```
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    let radius: Double
    let center: Point

    func draw() {}
}

var drawables: [Drawable] = (1..<100_000_000).map { _ in
    return Circle(...)
}

for drawable in drawables {
    drawable.draw()
}
```
在这里的代码当中，我们该如何获取协议记录表呢？答案就是从这个既有容器 (existential container) 当中获取，这个容器目前拥有一个三个字大小的结构体，并且存放在其内部的值缓冲区当中，此外还与协议记录表建立了引用关系。

```
struct Circle: Drawable {
    let radius: Double
    let center: Point

    func draw() {}
}
```
这里 Circle 类型存放在了三个字大小的缓冲区当中，并且不会被单独引用。

```
struct Line: Drawable {
    let origin: Point
    let end: Point

    func draw() {}
}
```
举个例子，对于我们的 Line 类型来说，它其中包含了四个字的存储空间，因为它拥有两个点类型。这个 Line 结构体需要超过四个字以上的存储空间。我们该如何处理它呢？这会对性能有影响么？好吧，它的确会：

```
protocol Drawable {
    func draw()
}

struct Line: Drawable {
    let origin: Point
    let end: Point
    func draw() {}
}

let drawables: [Drawable] = (1..<100_000_000).map { _ in Line(...) }

for drawable in drawables {
    drawable.draw()
}
```
这需要花费 45 秒钟的时间来运行。为什么这里要花这么久的时间呢，发生了什么事呢？

绝大部分的时间都花费在对结构体进行内存分配上了，因为现在它们无法存放在只有三个字大小的缓冲区当中了。因此这些结构会在堆上进行内存分配，此外这也与协议有一点关系。由于既有容器只能够存储三个字大小的结构体，或者也可以与对象建立引用关系，我们同样需要某种名为值记录表 (value witness table)。这就是我们用来处理任意值的东西。

因此在这里，编译器将创建一个值记录表，对每个���缓冲区、内敛结构体来说，都有三个字大小的缓冲区，然后它将负责对值或者类进行内存分配、拷贝、销毁和内存释放等操作。

```
func draw(drawable: Drawable) {
    drawable.draw()
}

let value: Drawable = Line()
draw(local: value)

// Generates
func draw(value: ECTDrawable) {
    var drawable: ECTDrawable = ECTDrawable()
    let vwt = value.vwt
    let pwt = value.pwt
    drawable.vwt = value.vwt
    drawable.pwt = value.pwt
    vwt.allocateBuffAndCopyValue(&drawable, value)
    pwt.draw(vwt.projectBuffer(&drawable)
}
```
这里是一个例子，这就是这个过程的中间产物。如果我们只有一个 draw 函数，那么它将会接受我们创建的 Line 作为参数，因此我们将它传递给这个 draw 函数即可。

实际情况时，它将这个 Drawable 协议传递到既有容器当中，然后在函数内部再次进行创建。这会对值和协议记录表进行赋值，然后分配一个新的缓冲区，然后将其他结构、类或者类似对象的值拷贝进这个缓冲区当中。然后就使用协议记录表当中的 draw 函数，把真实的 Drable 对象传递给这个函数。

您可以看到，值记录表和协议记录表将会存放在栈上，而 Line 将会被存放在堆上，从而最后将线绘制出来。

## 结论

对我们进行数据建模的方式进行简单的更改将会对性能造成巨大的影响。让我们来看一看该如何来避免这些情况的发生。

首先让我们来说一说泛型。大家可能会说了，我给各位展示了协议会导致性能的下降，那么我们为什么还要使用泛型呢？答案在于：泛型允许我们做什么。

```
struct Stack<T: Type> {
...
}
```
假设我们这里有一个带有泛型 T 的 Stack 结构体，它受到一个协议类型的约束。编译器所要做的，就是将这个 T 提换成相应的协议，或者替换为我们传入的具体类型。这些操作会一直沿着函数链 (function chain) 执行，并且编译器会创建直接对此类型进行操作的专用版本。

这样我们就无需再使用值记录表或者协议记录表了，并且还移除了既有容器，这可能是一个非常好的解决方式，这使得我们仍然能够写出真正快速运行的泛型代码，并且还具备 Swift 所提供的良好多态性。这就是所谓的静态多态性 (static polymorphism)。

您还可以通过使用枚举来改进数据模型，而不是从服务器中获取大量的字符串。例如，假设您正在构建一个社交应用，您需要对账户建立状态的管理，以前您可能会使用字符串来进行控制。

```
enum AccountStatus: String, RawRepresentable {
case .banned, .verified, incomplete
}
```
如果我们改用枚举的话，那么我们就无需进行内存分配了，当我们传递这个类型的时候，我们只是将枚举值进行传递，这是一个加快代码运行速度的好方法，同时也可以为整个应用程序提供更安全、更可读的代码。

此外，使用 u-模型或者演示者 (Presenter) 或者不同的抽象类型的形式，来构建特定类型的模型也是非常有用的，这使得我们能够精简掉应用当中许多不必要的部分。

好的，我的讲演到此结束，内容很短，感谢诸位的参与！


