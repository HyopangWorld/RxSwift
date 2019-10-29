import RxSwift

let one = 1
let two = 2
let three = 3


example(of: "never") {
    let observable = Observable<Any>.never()
    let disposeBag = DisposeBag()            // 1. 역시 dispose bag 생성
    
    observable
        .debug("never 확인")            // 2. 디버그 하고
        .subscribe()                    // 3. 구독 하고
        .disposed(by: disposeBag)     // 4. 쓰레기봉지에 쏙
}
