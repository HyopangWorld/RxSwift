//
//  ViewController.swift
//  RxSwiftTest
//
//  Created by 김효원 on 2019/10/22.
//  Copyright © 2019 HyowonKim. All rights reserved.
//

import UIKit

import RxSwift

class Ch2ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        challenge1()
        challenge2()
    }
    
    func challenge1(){
        example(of: "never") {
            let observable = Observable<Any>.never()
            
            // 1. 문제에서 요구한 dispose bag 생성
            let disposeBag = DisposeBag()
            
            // 2. 그냥 뚫고 지나간다는 do의 onSubscribe 에다가 구독했음을 표시하는 문구를 프린트하도록 함
            observable.do(
                onSubscribe: { print("Subscribed")}
                ).subscribe(                    // 3. 그리고 subscribe 함
                    onNext: { (element) in
                        print(element)
                },
                    onCompleted: {
                        print("Completed")
                }
            )
            .disposed(by: disposeBag)            // 4. 앞서 만든 쓰레기봉지에 버려줌
        }
    }
    
    func challenge2(){
         example(of: "never") {
             let observable = Observable<Any>.never()
             let disposeBag = DisposeBag()            // 1. 역시 dispose bag 생성
             
             observable
                 .debug("never 확인")            // 2. 디버그 하고
                 .subscribe()                    // 3. 구독 하고
                 .disposed(by: disposeBag)     // 4. 쓰레기봉지에 쏙
         }
     }
    
    public func example(of description: String, action: () -> Void) {
        print("\n--- Example of:", description, "---")
        action()
    }
}

