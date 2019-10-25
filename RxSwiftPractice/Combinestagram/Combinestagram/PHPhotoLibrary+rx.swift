//
//  PHPhotoLibrary+rx.swift
//  Combinestagram
//
//  Created by 김효원 on 2019/10/25.
//  Copyright © 2019 Underplot ltd. All rights reserved.
//

import Foundation
import Photos

import RxSwift

extension PHPhotoLibrary {
    static var authorized: Observable<Bool> {
        return Observable.create { observer in
            
            DispatchQueue.main.async {
                if authorizationStatus() == .authorized {
                    observer.onNext(true)
                    observer.onCompleted()
                } else {
                    observer.onNext(false)
                    requestAuthorization { newStatus in
                        observer.onNext(newStatus == .authorized)
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
