# ReactiveKit

__ReactiveKit__ is a collection of Swift frameworks for reactive and functional reactive programming.

* [ReactiveKit](https://github.com/ReactiveKit/ReactiveKit) - A Swift Reactive Programming Kit.
* [ReactiveFoundation](https://github.com/ReactiveKit/ReactiveFoundation) - NSFoundation extensions like type-safe KVO.
* [ReactiveUIKit](https://github.com/ReactiveKit/ReactiveUIKit) - UIKit extensions that enable bindings.

## Observables

Updating the UI or performing other actions when underlying data changes is such a tedious task. It would be great if it could be done in automatic and safe fashion. `Observable` tries to solve that problem. It wraps mutable state into an object which enables observation of that state. Whenever the state changes, an observer can be notified.

To create the observable, just initialize it with the initial value.

```swift
let name = Observable("Jim")
```

> `nil` is valid value for observables that wrap optional type.

Observables are useful only if they are being observed. To register an observer, use `observe` method. You pass it a closure that accepts one argument - latest value.

```swift
name.observe { value in
  print("Hi \(value)!")
}
```

> When you register the observer, it will be immediately invoked with the current value of the observable so that snippet will print "Hi Jim!".

To change value of the observable afterwards, just set the `value` property.

```swift
name.value = "Jim Kirk" // Prints: Hi Jim Kirk!
```

Setting the value invokes all registered observers automatically. That's why we call this reactive programming.

> Observers registered with `observe` method will be by default invoked on the main thread (queue). You can change default behaviour by passing another [execution context](#threading) to the `observe` method.

Observables cannot fail and they are guaranteed to always have a value. That makes them safe to represent the data that UI displays. To facilitate that use, observables are made to be bindable. They can be bound to any type conforming to `BindableType` protocol - observables being part of that company themselves.

ReactiveUIKit extends various UIKit objects with observable properties. That makes bindings as simple as

```swift
name.bindTo(nameLabel.rText)
```

Actually, because it's only natural to bind text to a label, as simple as:

```swift
name.bindTo(nameLabel)
```

> Observables provided by ReactiveUIKit will update the target object on the main thread (queue) by default. That means that you can update the observable from a background thread without worrying how your UI will be updated - it will always happen on the main thread. You can change default behaviour by passing another exection context to the `bindTo` method.


## Observable Collections

When working with collections knowing that the collection changed is usually not enough. Often we need to know how exactly did the collection change - what elements were updated, what inserted and what deleted. `ObservableCollection` enables exactly that. It wraps a collection in order to provide mechanisms for observation of fine-grained changes done to the collection itself. Events generated by observable collection contain both the new state of the collection (the collection itself) plus the information about what elements were inserted, updated or deleted.

To provide observable collection, just initialize it with the initial value. The type of the value you provide determines the type of the observable collection. You can provide an array, a dictionary or a set.


```swift
let uniqueNumbers = ObservableCollection(Set([0, 1, 2]))
```

```swift
let options = ObservableCollection(["enabled": "yes"])
```

```swift
let names: ObservableCollection(["Steve", "Tim"])
```

When observing observable collection, events you receive will be a structs that contain detailed description of changes that happened.

```swift
names.observe { e in
  print("array: \(e.collection), inserts: \(e.inserts), updates: \(e.updates), deletes: \(e.deletes)")
}
```

You work with the observable collection like you'd work with the collection it encapsulates.

```swift
names.append("John") // prints: array ["Steve", "Tim", "John"], inserts: [2], updates: [], deletes: []
names.removeLast()   // prints: array ["Steve", "Tim"], inserts: [], updates: [], deletes: [2]
names[1] = "Mark"    // prints: array ["Steve", "Mark"], inserts: [], updates: [1], deletes: []
```

Observable collections can be mapped, filtered and sorted. Let's say we have following obserable array:

```swift
let numbers: ObservableCollection([2, 3, 1])
```

When we then do this:

```
let doubleNumbers = numbers.map { $0 * 2 }
let evenNumbers = numbers.filter { $0 % 2 == 0 }
let sortedNumbers = numbers.sort(<)
```

Modifying `numbers` will automatically update all derived arrays:

```swift
numbers.append(4)

Assert(doubleNumbers.collection == [4, 6, 2, 8])
Assert(evenNumbers.collection == [2, 4])
Assert(sortedNumbers.collection == [1, 2, 3, 4])
```

That enables us to build powerful UI bindings. With ReactiveUIKit, observable collection containing an array can be bound to `UITableView` or `UICollectionView`. Just provide a closure that creates cells to the `bindTo` method.

```swift
let posts: ObservableCollection<[Post]> = ...

posts.bindTo(tableView) { indexPath, posts, tableView in
  let cell = tableView.dequeueCellWithIdentifier("PostCell", forIndexPath: indexPath) as! PostCell
  cell.post = posts[indexPath.row]
  return cell
}
```

Subsequent changes done to the `posts` array will then be automatically reflected in the table view.

To bind observable dictionary or set to table or collection view, first you have to convert it to the observable array. Because sorting any collection outputs an array, just do that.

```swift
let sortedOptions = options.sort {
  $0.0.localizedCaseInsensitiveCompare($1.0) == NSComparisonResult.OrderedAscending
}
```

The resulting `sortedOptions` is of type `ObservableCollection<[(String, String)]>` - an observable array of key-value pairs sorted alphabetically by the key that can be bound to a table or collection view.

> Same threading rules apply for observable collection bindings as for observable bindings. You can safely modify the collection from a background thread and be confident that the UI updates occur on the main thread. 

### Array diff

When you need to replace an array with another array, but need an event to contains fine-grained changes (for example to update table/collection view with nice animations), you can use method `replace:performDiff:`. For example, if you have

```swift
let numbers: ObservableCollection([1, 2, 3])
```

and you do

```swift
numbers.replace([0, 1, 3, 4], performDiff: true)
```

then the observed event will contain:

```swift
Assert(event.collection == [0, 1, 3, 4])
Assert(event.inserts == [0, 3])
Assert(event.deletes == [1])
```

If that array was bound to a table or a collection view, the view would automatically animate only the changes from the *merge*. Helpful, isn't it.

## Operation

State change events are not the only events worth reacting upon. We can also react upon work being done. Anything that produces results can be made reactive. To enable that, ReactiveKit provides `Operation` type. Operation wraps a work that produces results into something that can be observed.

To create an operation, pass a closure that performs actual work to the constructor. Closure has one argument - the observer whom you send events regarding operation state. To send one or more results, use `next` method of the observer. When operation successfully completes call `success` method, otherwise send the error using `failure` method.

```swift
func fetchImage(url: NSURL) -> Operation<UIImage, NSError> {
  return Operation { observer in
    let request = Alamofire.request(.GET, url: url).response { request, response, data, error in
      if let error = error {
        observer.failure(error)
      } else {
        observer.next(UIImage(imageWithData: data!))
        observer.success()
      }
    }
    return BlockDisposable {
      request.cancel()
    }
  }
}
```

> Closure should return a disposable that will cancel the operation. If operation cannot be cancelled, return `nil`.

Operation can send any number of `.Next` events followed by one terminating event - either a `.Success` or a `.Failure`. No events will ever be sent (accepted) after the terminating event has been sent.

Creating the operation doesn't do any work by itself. To start producing results, operation has to be started. Operation will be automatically started when you register an observer to it.

```swift
fetchImage(url: ...).observe { event in
  switch event {
    case .Next(let image):
  	  print("Operation produced an image \(image).")
    case .Success:
  	  print("Operation completed successfully.")
    case .Failure(let error):
  	  print("Operation failed with error \(error).")
  }
}
```

> Observers registered with `observe` method will be by default invoked on the main thread (queue). You can change default behaviour by passing another [execution context](#threading) to the `observe` method.

The observer you register with the operation is actually the one that will be passed to the closure that was provided in operation constructor (the one that does the actual work) - just wrapped into a struct that simplifies sending result. You see how the operation is just a light wrapper around a closure, but that abstraction enables powerful paradigm.

### Observing  results

When you're interested in just results of the operation and you don't care when it completes or if it fails, you can use `*Next` family of methods. To observe results of the operation, you would use `observeNext`.

```swift
fetchImage(url: ...).observeNext { image in
  imageView.image = image
}
```

### Bindings

To bind results with ReactiveUIKit, do something like:

```swift
fetchImage(url: ...).bindNextTo(imageView)
```

> `bindNextTo` by default delivers result on the main queue so you don't have to worry about threads.

### Sharing results
Whenever the observer is registered, the operation starts all over again. To share results of a single operation run, use `shareNext` method.

```swift
let image = fetchImage(url: ...).shareNext()
image.bindTo(imageView1)
image.bindTo(imageView2)
```

> Method `shareNext` buffers results of the operation using `ObservableBuffer` type. To learn more about that, continue reading.

### Transformations

Operations can be transformed into another operations. For example, to create an operation that fetches and then blurs the image, we would just map the operation we already have for image fetching.

```swift
func fetchAndBlurImage(url: NSURL) -> Operation<UIImage, NSError> {
  return fetchImage(url: url).map { $0.blurred() }
}
```

If we expect lousy network, we can have our fetch operation retry few times before giving up.

```swift
fetchImage(url: ...).retry(3).bindNextTo(imageView)
```
> The operation will be retried only if it fails.

Operations enable us to model business logic using simple composition. Let's say we have an operation that does the authentication and the one that can fetch current user for the given authentication token.

```swift
func authenticate(username: String, password: String) -> Operation<Token, NSError>
func fetchCurrentUser(token: Token) -> Operation<User, NSError>
```

When we then need to get a user for given login, we do:

```swift
authenticate(username: ..., password: ...)
  .flatMap(.Latest) { token in
    return fetchCurrentUser(token)
  }
  .observeNext { user in
    print("Authenticated as \(user.fullname).")
  }
```

### Cancellation

Observing the operation (or the observable, for that matter) returns a disposable object. When the disposable object gets disposed, it will cancel the operation (and all ancestor operations if our operation was a composition of multiple operations). So, store it in a variable

```swift
let disposable = fetchImage(url: ...).observe(...)
```

and when you later need to cancel the operation, just call `dispose`.

```swift
disposable.dispose()
```

From that point on the operation will not send any more events and the underlying task will be cancelled.

Bindings will automatically dispose themselves (i.e. cancel source operations) when the binding target gets deallocated. For example, if we do 

```swift
fetchImage(url: ...).bindNextTo(imageView)
```

then the image downloading will be automatically cancelled when the image view is deallocated. Isn't that cool!


## Streams

Observable, observable collection and operation are all streams that conform to `StreamType` protocol. Basic requirement of a stream is that it produces events that can be observed.

```swift
public protocol StreamType {
  typealias Event
  func observe(on context: ExecutionContext, sink: Event -> ()) -> DisposableType
}
```

Observable, observable collection and operation differ in events they generate and whether their observation can cause side-effects or not.

Observable generates events of the same type it encapsulates. 

```swift
Observable<Int>(0).observe { (event: Int) in ... }
```

On the other hand, observable collection generates events of `ObservableCollectionEvent` type. It's a struct that contains both the collection itself plus the change-set that describes performed operation.

```swift
ObservableCollection<[Int]>([0, 1, 2]).observe { (event: ObservableCollectionEvent<[Int]>) in ... }
```

```swift
public struct ObservableCollectionEvent<Collection: CollectionType> {
  
  public let collection: Collection

  public let inserts: [Collection.Index]
  public let deletes: [Collection.Index]
  public let updates: [Collection.Index]
}
```


Both observable and observable collection represent so called *hot streams*. It means that observing them does not perform any work and no side effects are generated. They are both subclasses of `ActiveStream` type. The type represents a hot stream that can buffer events. In case of the observable and observable collection it buffers only one (latest) event, so each time you register an observer, it will be immediately called with the latest event - which is actually the current value of the observable.

`Operation` is a bit different. It's built upon `Stream` type. It represents *cold stream*. Cold streams don't do any work until they are observed. Once you register an observer, the stream executes underlying operation and side effect might be performed.

Operation generates events of `OperationEvent` type.

```swift
Operation<Int, NSError>(...).observe { (event: OperationEvent <Int, NSError>) in ... }
```

It's an enum defined like this:

```swift
public enum OperationEvent<Value, Error: ErrorType> {
  case Next(Value)
  case Failure(Error)
  case Succes
```

## <a name="threading"></a> Threading

ReactiveKit uses simple concept of execution contexts inspired by [BrightFutures](https://github.com/Thomvis/BrightFutures) to handle threading.

When you want to receive events on the same thread on which they were generated, just pass `nil` for the execution context parameter. When you want to receive them on a specific dispatch queue, just use `context` extension of dispatch queue wrapper type `Queue`, for example: `Queue.main.context`.

## Why another FRP framework?

With Swift Bond I tried to make Model-View-ViewModel architecture for iOS apps as simple as possible, but as the framework grow it was becoming more and more reactive. That conflicted with its premise of being simple binding library.

ReactiveKit is a continuation of that project, but with different approach. It's based on streams inspired by ReactiveCocoa and RxSwift. It then builds upon those streams reactive types optimized for specific domains - `Operation` for asynchronous operations, `Observable` for observable variables and `ObservableCollection` for observable collections - making them simple and intuitive.

Main advantages over some other frameworks are clear separation of types that can cause side effects vs. those that cannot, less confusion around hot and cold streams (signals/producers), simplified threading and provided observable collection types with out-of-the box bindings for respective UI components.


## Requirements

* iOS 8.0+ / OS X 10.9+ / tvOS 9.0+ / watchOS 2.0+
* Xcode 7.1+

## Communication

* If you need help, use Stack Overflow. (Tag '**ReactiveKit**')
* If you'd like to ask a general question, use Stack Overflow.
* If you found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request (include unit tests).

## Installation

### CocoaPods

```
pod 'ReactiveKit', '~> 1.0'
pod 'ReactiveUIKit', '~> 1.0'
pod 'ReactiveFoundation', '~> 1.0'
```

### Carthage

```
github "ReactiveKit/ReactiveKit" 
github "ReactiveKit/ReactiveUIKit"
github "ReactiveKit/ReactiveFoundation"
```

## License

The MIT License (MIT)

Copyright (c) 2015 Srdan Rasic (@srdanrasic)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
