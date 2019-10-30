//
//  ViewController.swift
//  RxSwiftTest
//
//  Created by 김효원 on 2019/10/22.
//  Copyright © 2019 HyowonKim. All rights reserved.
//

import UIKit

///
/// 이건 ViewController의 Summary 입니다.
/// ===
/// ㅇㅇㅇㅇ
///
/// ## 제목효과
///
///  ````
///  let stuck = ""
///  ````
///
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func findMinMoves() -> Int {
        var machines = [1,0,5]
        let total = machines.reduce(0) { $0 + $1 }
        if total % machines.count != 0 { return -1 }
        let dressAvg = total / machines.count
        
        var n = 0
        while !(machines.allSatisfy{ $0 == dressAvg }) {
            move : for i in 0 ..< machines.count {
                var nextMachine = machines[i+1 >= machines.count ? i-1 : i+1]
                if machines[i] > dressAvg && nextMachine > 0 {
                    machines[i] -= 1
                    nextMachine += 1
                }
                else if machines[i] < dressAvg && nextMachine > 0 {
                    machines[i] += 1
                    nextMachine -= 1
                }
                print("\(machines)")
                n += 1
            }
        }
        
        print("\(dressAvg) \(machines)")
        return n
    }
}

