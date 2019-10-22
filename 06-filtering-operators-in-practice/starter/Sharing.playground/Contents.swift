
import RxSwift

var start = 0
func getStartNumber() -> Int {
    start += 1
    return start
}

let numbers = Observable<Int>.create { observer in
    let start = getStartNumber()
    print("start :", start)
    observer.onNext(start)
    observer.onNext(start+1)
    observer.onNext(start+2)
    observer.onCompleted()
    return Disposables.create()
}


numbers
    .subscribe(onNext: { el in
        print("element [\(el)]")
    }, onCompleted: {
        print("-------------")
    })

numbers
    .subscribe(onNext: { el in
        print("element [\(el)]")
    }, onCompleted: {
        print("-------------")
    })



let numbers2 = Observable<Int>.create { observer in
    let start = getStartNumber()
    print("start :", start)
    observer.onNext(start)
    observer.onNext(start+1)
    observer.onNext(start+2)
    observer.onCompleted()
    return Disposables.create()
}.share(replay: 3, scope: .forever)

numbers2
    .subscribe(onNext: { el in
        print("element [\(el)]")
    }, onCompleted: {
        print("-------------")
    })

numbers2
    .subscribe(onNext: { el in
        print("element [\(el)]")
    }, onCompleted: {
        print("-------------")
    })


