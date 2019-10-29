//
//  MainViewContorller+rx.swift
//  Combinestagram
//
//  Created by 조장희 on 04/12/2018.
//  Copyright © 2018 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
    func alert(title: String, text: String?) -> Completable {
        return Completable.create(subscribe: {[weak self] completable in
            let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { (_) in
                completable(.completed) // close 누르면 completed 이벤트
            }))
            
            self?.present(alertVC, animated: true, completion: nil)
            return Disposables.create {
                self?.dismiss(animated: true, completion: nil) // dispose 되면 alert dispose
            }
        })
        
    }
}
