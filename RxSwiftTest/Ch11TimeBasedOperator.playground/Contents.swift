import RxSwift

/* Buffering operators */


// 1. 과거 요소들 리플레이
let elementsPerSecond = 1
let maxElements = 5
let replayedElements = 1
let replayDelay:TimeInterval = 3

// 1 elementsPerSecond에서 요소들을 방출할 observable을 만들어야 한다.
// 또한 방출된 요소의 개수와, 몇개의 요소를 새로운 구독자에게 "다시재생"할지 제어할 필요가 있다.
// 이러한 observable을 방출하기 위해서 Observable<T>와 create 메소드를 사용해보자
let sourceObservable = Observable<Int>.create { observer in
    var value = 1
    // DispatchSource.timer 함수는 playground 내 Sources 폴더에 정의된 DispatchSource의 extension이다.
    // 이 함수를 통해 반복 타이머 생성을 단순화 할 수 있다.
    let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main, handler: {
    
       // 
        if value <= maxElements {
            observer.onNext(value)
            value += 1
        }
    })
    return Disposables.create {
        timer.suspend()
    }
}
   // 3
    .replay(replayedElements)

// 4
let sourceTimeline = TimelineView<Int>.make()
let replayedTimeline = TimelineView<Int>.make()

// 5
let stack = UIStackView.makeVertical([
    UILabel.makeTitle("replay"),
    UILabel.make("Emit \(elementsPerSecond) per second:"),
    sourceTimeline,
    UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"),
    replayedTimeline])

// 6
_ = sourceObservable.subscribe(sourceTimeline)

// 7
DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
    _ = sourceObservable.subscribe(replayedTimeline)
}

// 8
_ = sourceObservable.connect()
    
// 9
let hostView = setupHostView()
hostView.addSubview(stack)
hostView
