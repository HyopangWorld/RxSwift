import RxSwift
import RxSwiftExt
//
///* Transtorming Operator */
//
//
///* 변환연산자의 요소들 */
//
//
//// MARK: - toArray
//// Observable의 독립적인 요소들을 Array에 넣는다.
//example(of: "toArray"){
//    let disposeBag = DisposeBag()
//
//    Observable.of("A", "B", "C")
//        .toArray()
//        .subscribe({
//            print($0)
//        })
//        .disposed(by: disposeBag)
//
//    // observable.onNext() 왜 애러나????
//    // subject만 되네... 왜지??
//    // TODO : subject와 Observable의 차이 제대로 이해하기
//
//}
//
//
//// MARK: - map
//// Swift Map 연산과 동일하다.
//// [x1, x2, ... xn].map(f) -> [f(x1), f(x2), ... , f(xn)]
//example(of: "map") {
//    let disposeBag = DisposeBag()
//
//    let formatter = NumberFormatter()
//    formatter.numberStyle = .spellOut //숫자 spell로 읽기 , 110 = one hundred, ten
//
//    Observable<NSNumber>.of(123, 4, 56)
//        // [x] -> map(f) -> [f(x)]
//        .map {
//            formatter.string(from: $0) ?? "" // observable의 결과 값을 formatter로 변환
//    }
//    .subscribe(onNext: {
//        print($0)
//    })
//        .disposed(by: disposeBag)
//}
//
//
//// MARK: - enumerated
//// 요소들의 index와 value를 tuple로 만든다.
//example(of: "emumerated and map") {
//    let disposeBag = DisposeBag()
//
//    Observable.of(1,2,3,4,5,6)
//        // 요소들의 index와 value를 tuple로 만든다.
//        .enumerated()
//        .map { index, value in
//            index > 2 ? value * 2 : value
//    }
//    .subscribe(onNext: {
//        print($0)
//    })
//        .disposed(by: disposeBag)
//}
//
//
///* 내부의 Observable 변환하기 : Observable의 Observable  */
//
//
//// MARK: - flatMap
///* Observable sequence(flatMap을 사용하는 Observable과 그 외에 다른 Observable들.)의 각 요소를
// * Observable sequence(방금 말했던 모든 Observable)에 투영하고
// * Observable sequence를 Observable sequence로 병합 (모두 한개로!)
// * 요약하자면, flatMap은 각 Observable의 변화를 계속 지켜본다. */
//// 쓰이는 것은 Observable 속의 Observable 속성 값에 접근해 subscribe 하고 싶을 때 사용한다.
//
//struct Student {
//    var score: BehaviorSubject<Int>
//}
//
//example(of: "flatMap") {
//    let disposeBag = DisposeBag()
//
//    // 두개의 student score subject 생성
//    let ryan = Student(score: BehaviorSubject(value: 80))
//    let charlotte = Student(score: BehaviorSubject(value: 90))
//
//    //  Student struct를 PublishSubject로 생성
//    // PublishSubject(student) > BehviorSubject(score) 형태
//    let student = PublishSubject<Student>()
//
//    // flatMap을 통해 PublishSubject가 갖는 BehaviorSubject에 접근한다.
//    student
//        .flatMap{
//            $0.score
//    }
//        // 구독할때는 출력되지 않는다. PublishSubject 이기 때문에.
//        .subscribe(onNext: {
//            print($0) // score 출력
//        })
//        .disposed(by: disposeBag)
//
//    // publishSubject를 통해 ryan BehaviorSubject 요소 방출 (flatMap에게 해당 element를 준것.)
//    student.onNext(ryan)    // Printed: 80
//
//    // 이번엔 ryan 객체의 BehaviorSubject에 직접 접근해서 요소를 방출해 본다.
//    ryan.score.onNext(85)   // Printed: 80 85 // behavior라 이전 것까지 다 출력
//
//    // publishSubject를 통해 charlotte BehaviorSubject 요소 방출 (flatMap에게 해당 element를 준것.)
//    student.onNext(charlotte)   // Printed: 80 85 90 // ?? ryan과 charlotte의 요소가 병합되었다 !
//
//    // 다시 ryan 객체의 BehaviorSubject에 직접 접근해서 요소를 방출해 본다.
//    ryan.score.onNext(95)   // Printed: 80 85 90 95 // 아직까지 ryan이 병합되어있군
//
//    // 이번엔 charlotte 객체의 BehaviorSubject에 직접 접근해서 요소를 방출해 본다.
//    charlotte.score.onNext(100) // Printed: 80 85 90 95 100 // 역시나 charlotte도 마찬가지
//}
//
//
//// MARK: - flatMapLatest
////  'observable sequence의 각 요소들을 observable sequence들의 새로운 순서로 투영한 다음,
//// observable sequence들의 observable sequence 중 가장 최근의 observable sequence 에서만 값을 생성한다.'
///* flatMap에서 가장 최신의 값만을 확인하고 싶을 때 사용한다. (flatMapLatest = map + switchLatest)
// * + switchLatest란? 가장 최근의 observable 에서 값을 생성하고 이전 observable을 구독 해제한다.
// * == 즉, 아까는 모두 각각 같은 값을 가진 상태 였다면, 모두 같은 값을 가진 상태에서 최근 것으로 다 합쳐서 한개만 사용한다. */
//
//// ex) flatMapLatest는 네트워킹 조작에서 가장 흔하게 쓰일 수 있다.
//// ex) 사전으로 단어를 찾는 것을 생각해보자. 사용자가 각 문자 s, w, i, f, t를 입력하면 새 검색을 실행하고,
//// 이전 검색 결과 (s, sw, swi, swif로 검색한 값)는 무시해야할 때 사용할 수 있을 것이다. wow,,,, is so good...
//example(of: "flatMapLatest") {
//    let disposeBag = DisposeBag()
//
//    let ryan = Student(score: BehaviorSubject(value: 80))
//    let charlotte = Student(score: BehaviorSubject(value: 90))
//
//    let student = PublishSubject<Student>()
//
//    student
//        .flatMapLatest {
//            $0.score
//    }
//    .subscribe(onNext: {
//        print($0)
//    })
//        .disposed(by: disposeBag)
//
//    student.onNext(ryan) // 가장 최신은 ryan 80
//
//    ryan.score.onNext(85)  // 가장 최신은 ryan 85
//
//    student.onNext(charlotte)  // 가장 최신은 charlotte 90
//
//    ryan.score.onNext(95) // 이미 해제 됨
//
//    charlotte.score.onNext(100) // 가장 최신은 charlotte 100
//}
//
//
///* 이벤트 관찰하기 */
//// observable을 observable의 이벤트로 변환해야할 수 있다. (?? 먼 말이냐)
//// 보통 observable 속성을 가진 observable 항목을 제어할 수 없고,
//// 외부적으로 observable이 종료되는 것을 방지하기 위해 error 이벤트를 처리하고 싶을 때 사용할 수 있다.
//example(of: "기본형") {
//    enum MyError: Error {
//        case anError
//    }
//
//    let disposeBag = DisposeBag()
//
//    let ryan = Student(score: BehaviorSubject(value: 80))
//    let charlotte = Student(score: BehaviorSubject(value: 100))
//
//    // 이번엔 ryan을 기본값으로 갖는 BehaviorSubject
//    let student = BehaviorSubject(value: ryan)
//
//    // studentScore는 Observable<Int>타입
//    let studentScore = student
//        .flatMapLatest{ // Observable을 return 한당 그니까 observable안의 속성 Observable를 retrun
//            $0.score
//    }
//
//    studentScore
//        .subscribe(onNext: {
//            print($0) // 구독하자마자 최신 Observable ryan의 score 80 출력
//        })
//        .disposed(by: disposeBag)
//
//    ryan.score.onNext(85) // 80 85
//    // student에 말고 ryan에 error를 발생
//    ryan.score.onError(MyError.anError)
//    ryan.score.onNext(90) // error로 종료되어 출력 안됨
//
//    // 최신 Observable ryan이 error를 일으켰으므로 student도 종료 됬다.
//    student.onNext(charlotte)
//
//    /* Prints:
//     80
//     85
//     Unhandled error happened: anError
//     */
//}
//
//
//// MARK: - materialize
//// 각각의 방출되는 이벤트를 이벤트의 observable로 만들 수 있다. 하지만 이는 event는 받을 수 있지만 요소들은 받을 수 없다.
//example(of: "materialize") {
//    enum MyError: Error {
//        case anError
//    }
//
//    let disposeBag = DisposeBag()
//
//    let ryan = Student(score: BehaviorSubject(value: 80))
//    let charlotte = Student(score: BehaviorSubject(value: 100))
//
//    let student = BehaviorSubject(value: ryan)
//
//    // studentScore의 타입은 Observable<Event<Int>>
//    let studentScore = student
//        .flatMapLatest{
//            $0.score.materialize() // flatMapLatest가 방출하는 요소가 EVENT Observable인거임, 값이 아니고 이러면 event만 알고 event에 영향을받지 않는다 !!!!
//    }
//
//    studentScore
//        .subscribe(onNext: {
//            print($0)
//        })
//        .disposed(by: disposeBag)
//
//    ryan.score.onNext(85) // 85
//    ryan.score.onError(MyError.anError) // error 발생
//    ryan.score.onNext(90) // 출력 안됨 ryan은 종료
//
//    student.onNext(charlotte) // 100 student는 종료되지 않았다.
//
//    /* Prints:
//     next(80)
//     next(85)
//     error(anError)
//     next(100)
//     */
//}
//
//
//// MARK: - dematerialize
//// event도 받고 요소도 받을 수 있다. 기존의 모양으로 되돌려주는 역할을 한다.
//example(of: "dematerialize") {
//    enum MyError: Error {
//        case anError
//    }
//
//    let disposeBag = DisposeBag()
//
//    let ryan = Student(score: BehaviorSubject(value: 80))
//    let charlotte = Student(score: BehaviorSubject(value: 100))
//
//    let student = BehaviorSubject(value: ryan)
//
//    // studentScore의 타입은 Observable<Event<Int>>
//    let studentScore = student
//        .flatMapLatest{
//            $0.score.materialize()
//    }
//
//    studentScore
//        .filter {
//            guard $0.error == nil else {
//                print($0.error!)
//                return false
//            }
//
//            return true
//    }
//        // studentScore observable을 원래의 모양으로 리턴하고, 점수와 정지 이벤트를 방출할 수 있도록 한다.
//        .dematerialize()
//        .subscribe(onNext: {
//            print($0)
//        })
//        .disposed(by: disposeBag)
//
//    ryan.score.onNext(85) // 85
//    ryan.score.onError(MyError.anError) // error 발생
//    ryan.score.onNext(90) // 출력 안됨 ryan은 종료
//
//    student.onNext(charlotte) // 100 student는 종료되지 않았다.
//
//    /* Prints:
//     80
//     85
//     anError
//     100
//     */
//}


/* 어김없이 찾아온 찰리찰리 Challenges */

//MARK: - Ch.5의 Challenge를 수정하여 영숫자 문자 가져오기
example(of: "Challenge (Ch.5의 Challenge를 수정하여 영숫자 문자 가져오기)") {
    let disposeBag = DisposeBag()
    
    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
    ]
    
    let convert: (String) -> UInt? = { value in
        if let number = UInt(value),
            number < 10 {
            return number
        }
        let keyMap: [String: UInt] = [
            "abc": 2, "def": 3, "ghi": 4,
            "jkl": 5, "mno": 6, "pqrs": 7,
            "tuv": 8, "wxyz": 9
        ]
        
        let converted = keyMap
            .filter { $0.key.contains(value.lowercased()) }
            .map { $0.value }
            .first
        
        return converted
    }
    
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
    
    let format: ([UInt]) -> String = {
        var phone = $0.map(String.init).joined()
        print(phone)
        
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
    
    let dial: (String) -> String = {
        if let contact = contacts[$0] {
            return "Dialing \(contact) (\($0))..."
        } else {
            return "Contact not found"
        }
    }
    
    
    let input = PublishSubject<String>()
    
    input
        .map(convert) //
        .unwrap()
//        .flatMap {
//            $0 == nil ? Observable.empty() : Observable.just($0!)
//        } // 이 부분을, RxSwiftExe 라이브러리의 .unwrap()으로 대체할 수 있다.
        .skipWhile { $0 == 0 } // 앞자리 0 무시 (== 처음일때만 0 무시)
        .take(10) // 10자리 가져와서
        .toArray() // array(10)으로 만들고
        .map(format) // key
        .map(dial)
        .subscribe({
            print($0)
        })
        .disposed(by: disposeBag)
    
    
    input.onNext("")    // 숫자가 아니므로 무시됨
    input.onNext("0")    // 첫번째가 0이므로 무시됨
    input.onNext("408")    // 하나의 숫자가 아니므로 무시됨
    
    input.onNext("6")    // 입력됨 (6)
    input.onNext("")    // 숫자가 아니므로 무시됨
    input.onNext("0")    // 입력됨 (6 0)
    input.onNext("3")   // 입력됨 (6 0 3)
    
    "JKL1A1B".forEach {
        // "JKL1A1B"를 한 글자씩 입력하는 것인데, JKL1A1B는 표준 숫자 키패드에 의해서 5551212로 변환된다
        input.onNext("\($0)") // 입력됨 (5 5 5 1 2 1 2)
    }    // == (6 0 3 5 5 5 1 2 1 2)
    
    input.onNext("9") // 10개 안되서 안됨
}
