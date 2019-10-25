import RxSwift


/* Filtering operators */


// MARK: - ignoreElements
// next event를 무시합니다. error, complete와 같은 종료 이벤트만 받는다.
example(of: "ignoreElements") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    strikes
        .ignoreElements()
        .subscribe { _ in // <- next & compelte & error 모두 이거 출력
            print("You're out!")
    }
    .disposed(by: disposeBag)
    
    strikes.onNext("X") // 무시
    strikes.onNext("X") // 무시
    strikes.onNext("X") // 무시
    
    strikes.onCompleted() // You're out! 출력
    //    strikes.onError(RxError.err) // You're out! 출력
}

public enum RxError: Error {
    case err
}

// MARK: - elementAt
// Observable에서 방출된 n번째 요소만 처리하려는 경우
example(of: "elementAt") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    
    strikes
        .elementAt(2) // 두번째 index만 방출
        .subscribe(onNext: { _ in  // next
            print("You're out!")
        })
        .disposed(by: disposeBag)
    
    // 3
    strikes.onNext("X") // 무시 (0)
    strikes.onNext("X") // 무시 (1)
    strikes.onNext("X") // You're out! 출력 (2)
    
}


// MARK: - filter
// 요구사항을 넣어 필터링 한다. (요구사항은 한가지 이상이어야한다.)
example(of: "filter") {
    
    let disposeBag = DisposeBag()
    
    // 1
    Observable.of(1,2,3,4,5,6)
        // 2
        .filter { int in
            int % 2 == 0
    }
        // 3
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}


/* Skipping operators */


// MARK: - skip
// 첫번째 요소부터 n개의 요소를 skip한다.
example(of: "skip") {
    let disposeBag = DisposeBag()
    
    Observable.of("A", "B", "C", "D", "E", "F")
        .skip(3) // 3개 요소 skip
        .subscribe(onNext: {
            print($0) // D E F
        })
        .disposed(by: disposeBag)
}


// MARK: - skipWhile
/* skip할 로직을 구성하고, 해당 로직이 false가 되었을 때 값 방출. filter와 반대 개념
 * 한번 false가 되면 그 뒤로는 계속 skip하지 않음.
 * ex) 보험금 청구 앱을 개발한다고 가정해보자. 공제액이 충족될 때까지 보험금 지급을 거부하기 위해 skipWhile을 사용할 수 있다. */
example(of: "skipWhile") {
    let disposeBag = DisposeBag()
    
    Observable.of(2, 2, 3, 4, 4)
        .skipWhile{ $0 % 2 == 0 }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}


// MARK: - skipUntil
/* 다른 observable이 .next이벤트를 방출하기 전까지 기존 observable에서 방출하는 이벤트를 무시하는 것
 * filtering을 dynamic하게 하고싶을 때 사용한다. */
example(of: "skipUntil") {
    let disposeBag = DisposeBag()
    
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    trigger
        .subscribe(onNext: {
            print("trigger) \($0)")
        })
        .disposed(by: disposeBag)
    
    subject
        .skipUntil(trigger) // subject를 구독하는데 그 전에 .skipUnitl을 통해 trigger를 추가한다.
        .subscribe(onNext: {
            print("subject) \($0)")
        })
        .disposed(by: disposeBag)
    
    // trigger가 next 이벤트를 방출하기 전까지 skip
    subject.onNext("A")
    subject.onNext("B")
    
    trigger.onNext("X")
    
    // trigger가 next를 했으므로 subject 도 방출
    subject.onNext("C")
}


/* Taking operators */


// MARK: - take
// 첫번째 요소부터 n개의 요소를 take한다.
example(of: "take") {
    let disposeBag = DisposeBag()
    
    // 1
    Observable.of(1,2,3,4,5,6)
        // 2
        .take(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}


// MARK: - takeWhile
// skipUntil과 작동방식은 같으나, takeWhile은 true일 때 실행한다.

// MARK: - enumerated
// 방출된 요소의 index를 참고하고 싶은 경우, 각 요소의 index와 값을 포함하는 튜플을 생성한다.
example(of: "takeWhile") {
    let disposeBag = DisposeBag()
    
    Observable.of(2,2,4,4,6,6)
        .enumerated() // 아래로 index와 값을 포함하는 튜플을 생성함.
        .takeWhile{ index, value in
            // 값이 짝수이고, index가 3보다 작을 때
            value % 2 == 0 && index < 3
    }
        .map { $0.element } // 튜플 요소의 element, 즉 value 값만 내려보낸다
        .subscribe(onNext: {
            print($0)  // 값 출력
        })
        .disposed(by: disposeBag)
}


/* MARK: - takeUntil
 * skipUntil의 반대 개념, 연결된 observable이 next를 방출될때까지 자신의 요소 방출
 *  RxCocoa 라이브러리의 API를 사용하면 dispose bag에 dispose를 추가하는 방식 대신 takeUntil을 통해 구독을 dispose 할 수 있다. */
example(of: "takeUntil") {
    let disposeBag = DisposeBag()
    
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    
    trigger
        .subscribe(onNext: {
            print("trigger) \($0) 이제 subject는 요소를 방출할 수 없엉")
        })
        .disposed(by: disposeBag)
    
    subject
        .takeUntil(trigger) // trigger에 takeUtil 연결
        .subscribe(onNext: {
            print("subject) \($0)")
        })
        .disposed(by: disposeBag)
    
    // triger가 onNext 이벤트를 방출하기 전까지 element를 방출
    subject.onNext("1")
    subject.onNext("2")
    
    // triger onNext 이벤트를 방출
    trigger.onNext("X")
    
    // 안찍힌다.
    subject.onNext("3")
}


/* Distinct Operator */
// : 중복해서 이어지는 값을 막아주는 연산자


// MARK: - distinctUntilChanged
// 연달아 같은 값이 이어질 때 중복된 값을 막아주는 역할을 한다.
example(of: "distincUntilChanged") {
    let disposeBag = DisposeBag()
    
    Observable.of("A", "A", "B", "B", "A")
        .distinctUntilChanged()
        .subscribe(onNext: {
            print($0) // A B A
        })
        .disposed(by: disposeBag)
}


// MARK: - distinctUntilChanged(_:)
// distinctUntilChanged는 기본적으로 구현된 로직이 같음, 그러나 커스텀한 비교로직을 구현하고 싶다면 이걸 사용
example(of: "distinctUntilChanged(_:)") {
    let disposeBag = DisposeBag()
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    // NSNumbers Observable로 만들기, 이렇게 하면 formatter를 사용할 때 Int를 변환할 필요가 없다.
    Observable<NSNumber>.of(10, 110, 20, 200, 210, 310)
        //  distinctUntilChanged(_:)는  각각의 seuquence 쌍을 받는 클로저
        .distinctUntilChanged { a, b in
            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "),
                let bWords = formatter.string(from: b)?.components(separatedBy: " ") else { return false }
            
            print("\(a) VS \(b)")
            var containsMatch = false
            
            for aWord in aWords {
                for bWord in bWords {
                    print("\(aWord) == \(bWord) ? \(aWord == bWord)")
                    if aWord == bWord {
                        containsMatch = true
                        break
                    }
                }
            }
            print("return \(containsMatch) \n ")
            return containsMatch
    }
    .subscribe(onNext: {
        print($0)
    })
        .disposed(by: disposeBag)
}



// Challenge_1 (전화번호 만들기)
/* skipWhile을 사용: 전화번호는 0으로 시작할 수 없습니다.
 * filter를 사용: 각각의 전화번호는 한자리의 숫자 (10보다 작은 숫자)여야 합니다.
 * take와 toArray를 사용하여, 10개의 숫자만 받도록 하세요. (미국 전화번호처럼) */

example(of: "Challenge_1 (전화번호 만들기)") {
    let disposeBag = DisposeBag()
    
    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
    ]
    
    func phoneNumber(from inputs: [Int]) -> String {
        var phone = inputs.map(String.init).joined()
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 3)
        )
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 7)
        )
        
        return phone
    }
    
    let input = PublishSubject<Int>()
    
    input
        .skipWhile { $0 == 0 } // 0부터 시작하면 skip
        .filter { $0 < 10 } // 10보다 작은거
        .take(10) // 10자리 가져와서
        .toArray() // array(10)으로 만들고
        .asObservable()
        .subscribe(onNext: {
            let phone = phoneNumber(from: $0)
            
            if let contact = contacts[phone] { // 전화번호부에 있으면
                print("Dialog Mr.\(contact) (\(phone))...") // 전화걸기
            } else {
                print("Contact Not Found")
            }
        }).disposed(by: disposeBag)
    
    input.onNext(0) // 걍 skip
    input.onNext(6)
    input.onNext(0)
    input.onNext(3)
    input.onNext(5)
    input.onNext(5)
    input.onNext(5)
    input.onNext(1)
    input.onNext(2)
    input.onNext(1)
    input.onNext(2) // 10개 모아서 array로 만들기
}

