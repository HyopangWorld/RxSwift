import RxSwift

/*다양한 방법으로 sequence들을 모으고, 각각의 sequence내의 데이터들을 병합하는 방법*/


/* 앞에 붙이기 */


// MARK: - startWith(_:)
// 현재 상태와 함께 초기값을 붙일 수 있다.
example(of: "startWith(_:)"){
    let numbers = Observable.of(2, 3, 4)

    // 기존의 sequence에 초기값 1 추가
    let observable = numbers.startWith(1)
    observable.subscribe(onNext: {
        print($0)
    })
}


// MARK: - Observable.concat(_:)
// 두개의 sequence를 묶을 수 있다.
// 반드시 두 observable의 요소들이 같은 타입일 때 가능
example(of: "Observable.concat") {
    let first = Observable.of(1, 2, 3)
    let second = Observable.of(4, 5, 6)

    // first + second를 차례대로 이어 붙인다.
    let observable = Observable.concat([first, second])

    // 첫 번째 콜렉션의 sequence의 각 요소들이 완료될 떄까지 구독하고, 이어서 다음 sequence를 같은 방법으로 구독한다.
    // 내부의 observable의 어떤 부분에서 에러가 방출되면, concat된 observable도 에러를 방출하며 완전 종료
    observable.subscribe(onNext: {
        print($0)
    })
}


// MARK: - concat(_:)
// 기존 observable이 완료될 때까지 기다린 다음, observable에 등록
// 인스턴스 생성과는 별도로, 상기 코드는 Observable.concat과 똑같이 작동
// 반드시 두 observable의 요소들이 같은 타입일 때 가능
example(of: "concat") {
    let germanCities = Observable.of("Berlin", "Münich", "Frankfurt")
    let spanishCities = Observable.of("Madrid", "Barcelona", "Valencia")

    let observable = germanCities.concat(spanishCities)
    observable.subscribe(onNext: { print($0) })
}


// MARK: - concatMap(_:)
// 각각의 sequence가 다음 sequence가 구독되기 전에 합쳐진다는 것을 보증
example(of: "concatMap") {
    let sequences = ["Germany": Observable.of("Berlin", "Münich", "Frankfurt"),
                     "Spain": Observable.of("Madrid", "Barcelona", "Valencia")]

    let observable = Observable.of("Germany", "Spain")
        .concatMap{ country in
            sequences[country] ?? .empty() } // Germany sequence와 Spain sequence가 observable에 합쳐진다

    _ = observable.subscribe(onNext: {
        print($0) // "Germany", "Spain" 이건 왜 출력이 안되지??
    })
}


/* 합치기 */


// MARK: - merge()
// 여러 sequence들을 합치기
// merge()는 source sequence와 모든 내부 sequence들이 완료되었을 때 끝난다.
// 내부 sequence 들은 서로 아무런 관계가 없다.
// 만약 어떤 sequence라도 에러를 방출하면 merge()는 즉시 에러를 방출하고 종료된다.
example(of: "merge") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let source = Observable.of(left.asObservable(), right.asObservable())

    let observable = source.merge() // left, right 합쳐서 하나로 병합 구독
    let disposable = observable.subscribe(onNext: {
        print($0)
    })

    var leftValues = ["Berlin", "Münich", "Frankfurt"]
    var rightValues = ["Madrid", "Barcelona", "Valencia"]

    // 각의 observable에서 랜덤으로 값을 뽑는 로직을 작성한다. leftValue와 rightValue에서 모든 값을 출력한 후 종료
    repeat {
        if arc4random_uniform(2) == 0 {
            if !leftValues.isEmpty {
                left.onNext("Left: " + leftValues.removeFirst())
            }
        } else if !rightValues.isEmpty {
            right.onNext("Right :" + rightValues.removeFirst())
        }
    } while !leftValues.isEmpty || !rightValues.isEmpty
    

    disposable.dispose() // subject left&right 종료
}


// MARK: - merge(maxConcurrent:)
// 합칠 수 있는 sequence의 수를 제한
// 네트워크 요청이 많아질 때 리소스를 제한하거나 연결 수를 제한하기 위해


/*요소 결합하기*/


// MARK: - combineLatest(::resultSelector:)
// 내부(결합된) sequence들은 값을 방출할 때마다, 제공한 클로저를 호출하며 우리는 각각의 내부 sequence들의 최종값을 받는다.
example(of: "combineLast") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()

    // left, right subject 중 하나라도 next 이벤트가 발생하면 두개의 가장 최신의 값을 return
    // 클로저의 리턴타입으로 observable을 생성 -> type을 변환할 수 있다.
    let observable = Observable.combineLatest(left, right, resultSelector: { lastLeft, lastRight in
        "\(lastLeft) \(lastRight)"
    })

    let disposable = observable.subscribe(onNext: {
        print($0)
    })

    print("> Sending a value to Left")
    left.onNext("Hello,")   // right의 값이 없으므로 출력 x
    print("> Sending a value to Right")
    right.onNext("world")   // Hello, world 출력
    print("> Sending another value to Right")
    right.onNext("RxSwift") // Hello, RxSwift 출력
    print("> Sending another value to Left")
    left.onNext("Have a good day,") // Have a good day, RxSwift 출력

    disposable.dispose()
}


// MARK: - combineLatest(,,resultSelector:)
// sequence 요소의 타입이 같지 않은 경우
example(of: "combine user choice and value") {
    let choice: Observable<DateFormatter.Style> = Observable.of(.short, .long)
    let dates = Observable.of(Date())

    // DateFormatter와 Date 형태를 합쳐 String Type 으로 변환
    let observable = Observable.combineLatest(choice, dates, resultSelector: { (format, when) -> String in
        let formatter = DateFormatter()
        formatter.dateStyle = format
        return formatter.string(from: when)
    })

    observable.subscribe(onNext: { print($0) })
}


// MARK: - combineLatest([],resultSelector:)
// array 내의 최종 값들을 결합하는 형태
example(of: "combineLast with array") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()

    // left, right subject 중 하나라도 next 이벤트가 발생하면 두개의 가장 최신의 값을 return
    // 클로저의 리턴타입으로 observable을 생성 -> type을 변환할 수 있다.
    let observable = Observable.combineLatest([left, right]) { strings in
           strings.joined(separator: " ")
    }

    let disposable = observable.subscribe(onNext: {
        print($0)
    })

    print("> Sending a value to Left")
    left.onNext("Hello,")   // right의 값이 없으므로 출력 x
    print("> Sending a value to Right")
    right.onNext("world")   // Hello, world 출력
    print("> Sending another value to Right")
    right.onNext("RxSwift") // Hello, RxSwift 출력
    print("> Sending another value to Left")
    left.onNext("Have a good day,") // Have a good day, RxSwift 출력

    disposable.dispose()
}


// MARK: - zip
// 결합한 observable 둘다 새로운 next 이벤트가 발생하면 값을 return
// 이렇게 sequence에 따라 단계별로 작동하는 방법을 'indexed sequencing'이라고 한다.
example(of: "zip") {
    enum Weatehr {
        case cloudy
        case sunny
    }

    let left:Observable<Weatehr> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
    let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")

    // left 와 right 요소 모두 새로 값이 방출 되어야 값을 return 한다.
    let observable = Observable.zip(left, right, resultSelector: { (weather, city) in
        return "It's \(weather) in \(city)"
    })

    observable.subscribe(onNext: {
        print($0)
    })

    /* Prints:
     It's sunny in Lisbon
     It's cloudy in Copenhagen
     It's cloudy in London
     It's sunny in Madrid
     */
}


/*Triggers*/


// MARK: - withLatestFrom(_:)
// 다른 observable들로부터 데이터를 받는 동안 어떤 observable은 단순히 방아쇠 역할
// withLatestFrom(_:)을 가지고 sample(_:)처럼 작동하게 하려면 구독할때 distinctUntilChanged()와 함께 사용
example(of: "withLatestFrom") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()

    let observable = button.withLatestFrom(textField)
    _ = observable.subscribe(onNext: { print($0) })

    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(()) // textField의 최종 값인 Paris 출력
    button.onNext(()) // textField의 최종 값인 Paris 출력
}


// MARK: - sample(_:)
// withLatestFrom(_:)과 거의 똑같이 작동하지만, 한 번만 방출한다. 즉 여러번 새로운 이벤트를 통해 방아쇠 당기기를 해도 한번만 출력
example(of: "sample") {
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()

    let observable = textField.sample(button)
    _ = observable.subscribe(onNext: { print($0) })

    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    button.onNext(()) // textField의 최종 값인 Paris 출력
    button.onNext(()) // 한번만 출력이라 출력 ㄴ
}


/*Switches*/


// MARK: - amb(_:)
// amb(_:)에서 amb는 ambiguous모호한 이라 생각하면 된다.
// 두 가지 sequence의 이벤트 중 어떤 것을 구독할지 선택할 수 있게 한다.
example(of: "amb") {
   let left = PublishSubject<String>()
   let right = PublishSubject<String>()

   // left와 right를 사이에서 모호하게 작동할 observable
   // 그리고 두 개중 어떤 것 먼저 하나가 방출을 시작하면 나머지에 대해서는 구독을 중단
   let observable = left.amb(right)
   let disposable = observable.subscribe(onNext: { value in
       print(value)
   })

   // right 먼저 시작하면 left는 구독 중단 됨
   right.onNext("Copenhagen")
   left.onNext("Lisbon")
   left.onNext("London")
   left.onNext("Madrid")
   right.onNext("Vienna")

   disposable.dispose()
}


// MARK: - switchLatest()
// observable로 들어온 마지막 sequence의 아이템만 구독, flatMapLatest(_:)와 유사
example(of: "switchLatest") {
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()

    let source = PublishSubject<Observable<String>>()

    let observable = source.switchLatest()
    let disposable = observable.subscribe(onNext: { print($0) })

    source.onNext(one)
    one.onNext("Some text from sequence one") // next가 발생하기 이전 마지막 아이템이 one이므로 one 출력
    two.onNext("Some text from sequence two")

    source.onNext(two)
    two.onNext("More text from sequence two") // two 출력
    one.onNext("and also from sequence one")

    source.onNext(three)
    two.onNext("Why don't you see me?")
    one.onNext("I'm alone, help me")
    three.onNext("Hey it's three. I win") // three 출력

    source.onNext(one)
    one.onNext("Nope. It's me, one!") // one 출력

    disposable.dispose()

    /* Prints:
     Some text from sequence one
     More text from sequence two
     Hey it's three. I win
     Nope. It's me, one!
     */
}


/*sequence내의 요소들간 결합*/


// MARK: - reduece(::)
// 제공된 초기값(예제에서는 0)부터 시작해서 source observable이 값을 방출할 때마다 그 값을 가공한다.
example(of: "reduce") {
    let source = Observable.of(1, 3, 5, 7, 9)

    // 0 + 1 + 3 + 5 + 7 + 9
    let observable = source.reduce(0, accumulator: +)
    observable.subscribe(onNext: { print($0) } )

    // 주석 1은 다음과 같은 의미다.
    // summary 이전 값 + newValue 새롭게 들어온 값
    let observable2 = source.reduce(0, accumulator: { summary, newValue in
        return summary + newValue
    })
    observable2.subscribe(onNext: { print($0) })
}


// MARK: - scan(_:accumulator:)
// reduece와 같지만 리턴값이 Observable이라 값이 가공될때마다 출력됨
example(of: "scan") {
    let source = Observable.of(1, 3, 5, 7, 9)

    let observable = source.scan(0, accumulator: +)
    observable.subscribe(onNext: { print($0) })
    
    /* Prints:
     1
     4
     9
     16
     25
    */
}


/* 또또 어김없이 돌아온 촬리촬리 촬린지*/

// MARK: - Challenge
// zip 연산자를 사용해서 상기의 scan(_:accumulator:) 예제에서 현재값과 현재 총합을 동시에 나타내도록 해보자
example(of: "Challenge1 - The zip case") {
    let source = Observable.of(1, 3, 5, 7, 9)
    let observable1 = source.scan(0, accumulator: +)
    
    let observable2 = Observable.zip(source, observable1, resultSelector: { (curValue, talValue) in
        return "current : \(curValue), total : \(talValue)"
    })
    observable2.subscribe(onNext: { print($0) })
}

example(of: "Challenge2 - The zip case") {
    let source = Observable.of(1, 3, 5, 7, 9)
    let observable = source.scan((0,0), accumulator: { (total, current) in
        return (current, current + total.1)
    })
    observable
        .map { return "current : \($0), total : \($1)" }
        .subscribe(onNext: { print($0) })
}
