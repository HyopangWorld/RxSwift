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

// 1
let bufferTimeSpan: RxTimeInterval = .seconds(4) // 4초가 지나면 source 요소 중 buffer에 담기지 못한 마지막 요소들을 담은 array 이다.
let bufferMaxCount = 3

// 짧은 이모찌를 입력하게 될텐데, 이를 위해 PublishSubject를 선언한다
let sourceObservable = PublishSubject<String>()

// 위쪽 타임라인에서 구독할 이벤트를 위해 코드를 작성한다. replay 예제해서 했던 것과 같다.
let sourceTimeline = TimelineView<String>.make()
let bufferedTimeline = TimelineView<Int>.make()

let stack = UIStackView.makeVertical([
    UILabel.makeTitle("buffer"),
    UILabel.make("Emitted elements:"),
    sourceTimeline,
    UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) seconds:"),
    bufferedTimeline])

// 버퍼된 타입라인은 각각의 버퍼어레이에 있는 요소들의 개수를 보여줄 것이다.
_ = sourceObservable.subscribe(sourceTimeline)

// source observable의 array에 있는 요소들을 받고 싶다. 또한 각각의 array들은 많아야 bufferMaxCount만큼의 요소들을 가질 수 있다.
// 만약 이 많은 요소들이 bufferTimeSpan이 만료되기 전에 받아졌다면, 연산자는 버퍼 요소들을 방출하고 타이머를 초기화 할 것이다.
// 마지막 그룹 방출 이후 bufferTimeSpan의 지연에서, buffer는 하나의 array를 방출할 것이다.
// 만약 이 지연시간동안 받은 요소가 없다면 array는 비게 될 것이다.
sourceObservable
    .buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
    .map { $0.count }
    .subscribe(bufferedTimeline)

let hostView = setupHostView()
hostView.addSubview(stack)
hostView

//DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//    sourceObservable.onNext("🐱")
//    sourceObservable.onNext("🐱")
//    sourceObservable.onNext("🐱")
//    sourceObservable.onNext("🐱")
//    sourceObservable.onNext("🐱")
//}
let elementsPerSecond = 0.7
let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
    sourceObservable.onNext("🐱")
}
/*각각의 박스는 방출된 array들마다 몇개의 요소를 가지고 있는지 보여준다.
최초에 버퍼 타임라인은 빈 array를 방출한다. - 왜냐하면 source observable에는 아직 아무런 요소가 없기 때문이다.
이 후 세개의 요소가 source observable에 푸시 된다.
버퍼 타임라인은 즉시 2개의 요소를 가진 하나의 array를 갖게 된다. 왜냐하면 bufferMaxCount에 2개라고 선언해놓았기 때문이다.
4초가 지나고, 하나의 요소만을 가진 array가 방출된다. 이 것은 방출되어 source observable에 푸시된 3개의 요소중 마지막 요소이다*/

//버퍼는 전체용량full capacity에 다다랐을 때 요소들의 array를 즉시 방출한다.
// 그리고 명시된 지연시간만큼 기다리거나 다시 전체용량이 채워질 때까지 기다린다.

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

