//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

let bufferTimeSpan: RxTimeInterval = 4
let bufferMaxCount = 2

let sourceObservable = PublishSubject<String>()

let sourceTimeline = TimelineView<String>.make()
let bufferedTimeline = TimelineView<Int>.make()

let stack = UIStackView.makeVertical([
    UILabel.makeTitle("buffer"),
    UILabel.make("Emitted elements:"),
    sourceTimeline,
    UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) seconds):"),
    bufferedTimeline
    ])

_ = sourceObservable.subscribe(sourceTimeline)

sourceObservable
    .buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
    .map { $0.count }
    .subscribe(bufferedTimeline)

    
    /*
    .buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
     sourceObservalbe에서 element의 배열을 받으려고 합니다.
     각 배열은 bufferMaxCount 만큼 가지고 있을수 있습니다.
     bufferTimeSpan이 만료되기 전에 많은 element를 받으면 operator는 buffering된 element를 내보내고 타이머를 재설정합니다.
     마지막으로 내보낸 그룹 다음의 bufferTimeSapn이 지연되면 buffer가 배열을 방출하고, 이 시간 동안 eleement를 받지 않으면 배열이 비어 있게 됩니다.
    */

let hostView = setupHostView()
hostView.addSubview(stack)
hostView

let elementsPerSecond = 0.7
let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
    sourceObservable.onNext("🐱")
}

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

