//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

//timeout연산자의 주된 목적은 타이머를 시간초과(오류) 조건에 대해 구별하는 것이다.
// 따라서 timeout 연산자가 실행되면, RxError.TimeoutError라는 에러 이벤트를 방출한다.
//. 만약 에러가 잡히지 않으면 sequence를 완전 종료한다.
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

// 1
let button = UIButton(type: .system)
button.setTitle("Press me now!", for: .normal)
button.sizeToFit()

// 2
let tapsTimeline = TimelineView<String>.make()

let stack = UIStackView.makeVertical([
    button,
    UILabel.make("Taps on button above"),
    tapsTimeline])

// 3
let _ = button
    .rx.tap
    .map { _ in "●" }
     // 5초 이내에 다시 누르지 않으면 timeout err 발생!
     //    .timeout(5, scheduler: MainScheduler.instance)
     // 아래의 timeout(_:scheduler:) observable을 취하고 타임아웃이 시작되었을 때, 에러대신 취한 Observable을 방출
     .timeout(5, other: Observable.just("X"), scheduler: MainScheduler.instance) //에러대신 다른 observable 방출
    .subscribe(tapsTimeline)

// 4
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
