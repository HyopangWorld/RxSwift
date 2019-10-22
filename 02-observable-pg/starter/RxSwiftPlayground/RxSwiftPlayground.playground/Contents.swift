import RxSwift

example(of: "just, of, from") {
    // 1
    let one = 1
    let two = 2
    let three = 3
    
    // 2
//    let observable: Observable<Int> = Observable<Int>.just(one)
//    let observable2 = Observable.of(one, two, three)
//    let observable3 = Observable.of([one, two, three])
//    let observable4 = Observable.from([one, two, three])
    
//    let observable = Observable.of(one, two, three)
//    observable.subscribe({ (event) in
//        print(event)
//    })
    
    let observable = Observable.of(one, two, three)
    observable.subscribe (onNext: { (element) in
        print(element)
    })
    
}


// MARK : - empty
example(of: "empty") {
    let observable = Observable<Void>.empty()
    
    observable.subscribe(
        
        // 1
        onNext: { (element) in
            print(element)
    },
        
        // 2
        onCompleted: {
            print("Completed")
    }
    )
}


// MARK : - never
example(of: "never") {
    let observable = Observable<Any>.never()
    let disBag = DisposeBag()
    
    observable
        .debug("testHyowon", trimOutput: true)  // 
        .subscribe()
        .disposed(by: disBag)
}


// MARK : - range
example(of: "range") {
    
    //1
    let observable = Observable<Int>.range(start: 1, count: 10)
    
    observable
        .subscribe(onNext: { (i) in
            
            //2
            let n = Double(i)
            let fibonacci = Int(((pow(1.61803, n) - pow(0.61803, n)) / 2.23606).rounded())
            print(fibonacci)
        })
}


// MARK : - dispose
example(of: "dispose") {
    
    // 1
    let observable = Observable.of("A", "B", "C")
    
    // 2
    let subscription = observable.subscribe({ (event) in
        
        // 3
        print(event)
    })
    
    subscription.dispose()
}


// MARK : - create
example(of: "create") {
    let disposeBag = DisposeBag()
    
    Observable<String>.create({ (observer) -> Disposable in
        // 1
        observer.onNext("1")
        
        // 2
        observer.onCompleted()
        
        // 3
        observer.onNext("?")
        
        // 4
        return Disposables.create()
    })
}

enum MyError: Error {
    case anError
}

example(of: "create") {
    let disposeBag = DisposeBag()
    
    Observable<String>.create({ (observer) -> Disposable in
        // 1
        observer.onNext("1")
        
        // 5
        observer.onError(MyError.anError)
        
        // 2
        observer.onCompleted()
        
        // 3
        observer.onNext("?")
        
        // 4
        return Disposables.create()
    })
        .subscribe(
            onNext: { print($0) },
            onError: { print($0) },
            onCompleted: { print("Completed") },
            onDisposed: { print("Disposed") }
    ).disposed(by: disposeBag)
}


// MARK : - deferred
example(of: "deferred") {
    let disposeBag = DisposeBag()
    
    // 1
    var flip = false
    
    // 2
    let factory: Observable<Int> = Observable.deferred{
        
        // 3
        flip = !flip
        
        // 4
        if flip {
            return Observable.of(1,2,3)
        } else {
            return Observable.of(4,5,6)
        }
    }
    
    for _ in 0...3 {
        factory.subscribe(onNext: {
            print($0, terminator: "")
        })
            .disposed(by: disposeBag)
        
        print()
    }
}


// MARK : - Single
example(of: "Single") {
    
    // 1
    let disposeBag = DisposeBag()
    
    // 2
    enum FileReadError: Error {
        case fileNotFound, unreadable, encodingFailed
    }
    
    // 3
    func loadText(from name: String) -> Single<String> {
        // 4
        return Single.create{ single in
            // 4 - 1
            let disposable = Disposables.create()
            
            // 4 - 2
            guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
                single(.error(FileReadError.fileNotFound))
                return disposable
            }
            
            // 4 - 3
            guard let data = FileManager.default.contents(atPath: path) else {
                single(.error(FileReadError.unreadable))
                return disposable
            }
            
            // 4 - 4
            guard let contents = String(data: data, encoding: .utf8) else {
                single(.error(FileReadError.encodingFailed))
                return disposable
            }
            
            // 4 - 5
            single(.success(contents))
            return disposable
        }
    }
}
