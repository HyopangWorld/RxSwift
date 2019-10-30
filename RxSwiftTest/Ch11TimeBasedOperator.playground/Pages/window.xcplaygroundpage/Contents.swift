//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

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
// buffer(timeSpan:count:scheduler:)와 아주 밀접하다. 대충 보면 거의 같아보인다. 유일하게 다른 점은 array 대신 Observable을 방출한다는 것이다.

// 1
let elementsPerSecond = 3
let windowTimeSpan:RxTimeInterval = .seconds(4)
let windowMaxCount = 10
let sourceObservable = PublishSubject<String>()

// 2
let sourceTimeline = TimelineView<String>.make()

let stack = UIStackView.makeVertical([
    UILabel.makeTitle("window"),
    UILabel.make("Emitted elements (\(elementsPerSecond) per sec.):"),
    sourceTimeline,
    UILabel.make("Windowed observables (at most \(windowMaxCount) every \(windowTimeSpan) sec):")])

// 3
let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
    sourceObservable.onNext("🐱")
}

// 4
_ = sourceObservable.subscribe(sourceTimeline)

// flatMap(-:)이 새로운 observable을 받을 때 마다, 새로운 타임라인 뷰를 삽입한다.
// 내부의 observable이 일단 완료되면, concat(_:)으로 하나의 튜플을 연결한다. 이를 통해 타임라인이 완료되었음을 표시할 수 있게 된다.
_ = sourceObservable
    // windowed observable당 최대 windowMaxCount개 요소를 가지고 windowTimeSpan초마다 window 되도록 했다.
    // => ource observable이 window 될 동안 4개보다 많은 요소를 방출하면, 새로운 observable이 생성되고, 다시 이 과정을 반복하게 된다.
    .window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance)
    .flatMap { windowedObservable -> Observable<(TimelineView<Int>, String?)> in
        let timeline = TimelineView<Int>.make()
        stack.insert(timeline, at: 4)
        stack.keep(atMost: 8)
        return windowedObservable
            .map { value in (timeline, value)}
            .concat(Observable.just((timeline, nil)))
    }
    // 6
    .subscribe(onNext: { tuple in
        let (timeline, value) = tuple
        if let value = value {
            timeline.add(.Next(value))
        } else {
            timeline.add(.Completed(true))
        }
    })

// 7
let hostView = setupHostView()
hostView.addSubview(stack)
hostView

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

