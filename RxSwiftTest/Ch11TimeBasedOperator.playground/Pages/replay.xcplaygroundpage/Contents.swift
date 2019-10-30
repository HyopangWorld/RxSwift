//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
  static func make() -> TimelineView<E> {
    return TimelineView(width: 400, height: 100)
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

let elementsPerSecond = 1 // 반복할때 term을 얼마나 줄건지
let maxElements = 5 // 얼마나 생성할건지
let replayedElements = 2 // replay buffer 크기 설정
let replayDelay:TimeInterval = 6 // 얼마 뒤에 replay 시작할건지


let sourceObservable = Observable<Int>
    .interval(RxTimeInterval(1.0 / Double(elementsPerSecond)), scheduler: MainScheduler.instance)
    .replay(replayedElements)
    // observable에 replay 기능을 추가하자.
    // - 이 연산자는 source observable에 의해 방출된 마지막 "replayedElements"개 만큼에 대한 기록을 새로운 sequence로 생성해낸다.
    //.  == 버퍼를 replayedElements 만큼 가지고 있다가 방출
    // - 매번 새로운 observer가 구독될 때마다, 즉시 (만약 존재한다면) 버퍼에 있는 요소들을 받고,
    //   새로한 요소들이 있다면 마치 일반적인 구독처럼 계속해서 구독을 하게 된다.
    // 반면에 replayAll()을 많은 양의 데이터를 생성하면서 종료도 되지 않는 sequence에 사용하면, 메모리는 금방 막히게 된다. App이 OS를 뒤흔들게 될 수도 있다. 주의할 것!
    .replay(replayedElements)


// replay(:)의 실제 효과를 시각화
let sourceTimeline = TimelineView<Int>.make()
let replayedTimeline = TimelineView<Int>.make()

// 편의를 위해 UIStackView를 사용한다.
let stack = UIStackView.makeVertical([
    UILabel.makeTitle("replay"),
    UILabel.make("Emit \(elementsPerSecond) per second:"),
    sourceTimeline,
    UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"),
    replayedTimeline])

// 상단 timeline을 받아 화면에 띄울 구독자를 준비한다.
_ = sourceObservable.subscribe(sourceTimeline)

// source observable을 다시 구독해보자. 단, 이번에는 약간의 딜레이를 주자.
DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
    _ = sourceObservable.subscribe(replayedTimeline)
}

// .connect() 한다.
// - ConnectableObservable은 observable의 계열의 특별한 클래스이다.
//   이들은 connect() 메소드를 통해 불리기 전까지는 구독자 수와 관계 없이, 아무 값도 방출하지 않는다.
//   이 장에서는 ConnectableObservable<E>(Observable<E> 아님.)를 리턴하는 연산자에 대해서 배우게 될 것이다. 해당 연산자들은 다음과 같다.
//      replay(_:)
//      replayAll()
//      multicast(_:)
//      publish()
_ = sourceObservable.connect()

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
