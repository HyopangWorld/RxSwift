/*
 * Copyright (c) 2016-present Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import UIKit
import Photos

import RxSwift

class PhotoWriter {
  enum Errors: Error {
    case couldNotSavePhoto
  }
    /* Single.create은 observer가 아닌 클로저를 파라미터로 받는다는 것이다.
    * Observable.create는 observer를 파라미터로 받는다. 따라서 여러개의 값을 방출하고 이벤트를 종료할 수 있다.
    * Single.create는 .success(T) 또는 .error(E) 값을 출력할 수 있는 클로저를 파라미터로 받는다.
    * 따라서 이 문제에서는 single(.success(id)) 와 같은 방식으로 호출할 수 있다.
     */
    
    static func save(_ image: UIImage) -> Single<String> {
        return Single.create(subscribe: { (observer) in
            var savedAssetId: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
                
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    if success, let id = savedAssetId {
                        observer(.success(id))
//                        observer.onNext(id)
//                        observer.onCompleted()
                    } else {
                        observer(.error(error ?? Errors.couldNotSavePhoto))
//                        observer.onError(error ?? Errors.couldNotSavePhoto)
                    }
                }
            })
            return Disposables.create()
        })
    }
    
//    static func save(_ image: UIImage) -> Observable<String> {
//        return Observable.create({ (observer) in
//            var savedAssetId: String?
//            PHPhotoLibrary.shared().performChanges({
//                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
//                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
//            }, completionHandler: { (success, error) in
//                DispatchQueue.main.async {
//                    if success, let id = savedAssetId {
//                        observer.onNext(id)
//                        observer.onCompleted()
//                    } else {
//                        observer.onError(error ?? Errors.couldNotSavePhoto)
//                    }
//                }
//            })
//            return Disposables.create()
//        })
//    }
 


}
