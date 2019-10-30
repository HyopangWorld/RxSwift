//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

let elementsPerSecond = 1
let delayInSeconds = 1.5

let sourceObservable = PublishSubject<Int>()

let sourceTimeline = TimelineView<Int>.make()
let delayedTimeline = TimelineView<Int>.make()

let stack = UIStackView.makeVertical([
  UILabel.makeTitle("delay"),
  UILabel.make("Emitted elements (\(elementsPerSecond) per sec.):"),
  sourceTimeline,
  UILabel.make("Delayed elements (with a \(delayInSeconds)s delay):"),
  delayedTimeline])

var current = 1
let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
  sourceObservable.onNext(current)
  current = current + 1
}

_ = sourceObservable.subscribe(sourceTimeline)


// Setup the delayed subscription
// ADD CODE HERE

// 구독을 시작한 후 요소를 받기 시작하는 시점을 지연하는 역할을 한다.
// "cold" observable들은 요소를 등록할 때, 방출이 시작된다.
// "hot" observable들은 어떤 시점에서부터 영구적으로 작동하는 것이다. Notifications 같은
// 구독을 지연시켰을 때, "cold" observable이라면 지연에 따른 차이가 없다. "hot" observable이라면 예제에서와 같이 일정 요소를 건너뛰게 된다.
// => 정리하면, "cold" observable은 구독할 때만 이벤트를 방출하지만, "hot" observable은 구독과 관계없이 이벤트를 방출
_ = sourceObservable
   .delaySubscription(RxTimeInterval(delayInSeconds), scheduler: MainScheduler.instance)
   .subscribe(delayedTimeline)

// RxSwift에서 또 다른 종류의 delay는 전체 sequence를 뒤로 미루는 작용을 한다.
// 구독을 지연시키는 대신, source observable을 즉시 구독한다. 다만 요소의 방출을 설정한 시간만큼 미룬다는 것이다.
_ = sourceObservable
    .delay(RxTimeInterval(delayInSeconds), scheduler: MainScheduler.instance)
    .subscribe(delayedTimeline)



_ = Observable<Int>
    .timer(3, scheduler: MainScheduler.instance)
    .flatMap { _ in
        sourceObservable.delay(RxTimeInterval(delayInSeconds), scheduler: MainScheduler.instance)
    }
    .subscribe(delayedTimeline)


let hostView = setupHostView()
hostView.addSubview(stack)
hostView


// Support code -- DO NOT REMOVE
class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    let view = TimelineView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
    view.setup()
    return view
  }
  public func on(_ event: Event<E>) {
    switch event {
    case .next(let value):
      add(.Next(String(describing: value)))
    case .completed:
      add(.Completed())
    case .error(_):
      add(.Error())
    }
  }
}
/*:
 Copyright (c) 2014-2017 Razeware LLC
 
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
 */

