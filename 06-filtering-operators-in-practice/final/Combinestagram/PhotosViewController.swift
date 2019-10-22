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

import UIKit
import Photos

import RxSwift

class PhotosViewController: UICollectionViewController {
  private let bag = DisposeBag()

  // MARK: public properties
  var selectedPhotos: Observable<UIImage> {
    return selectedPhotosSubject.asObservable()
  }

  // MARK: private properties
  private let selectedPhotosSubject = PublishSubject<UIImage>()

  private lazy var photos = PhotosViewController.loadPhotos()
  private lazy var imageManager = PHCachingImageManager()

  private lazy var thumbnailSize: CGSize = {
    let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    return CGSize(width: cellSize.width * UIScreen.main.scale,
                  height: cellSize.height * UIScreen.main.scale)
  }()

  static func loadPhotos() -> PHFetchResult<PHAsset> {
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    return PHAsset.fetchAssets(with: allPhotosOptions)
  }

  // MARK: View Controller
  override func viewDidLoad() {
    super.viewDidLoad()
    let authorized = PHPhotoLibrary.authorized
      .share()

//    이 특정한 순서에서 true는 항상 마지막 요소여서 take(1)를 사용할 필요가 없다. 그러나 테이크(1)를 사용하면 사용자의 의도를 명확하게 나타낼 수 있으며, 나중에 사용권 메커니즘이 변경되더라도 가입은 여전히 원하는 대로 수행될 것이다.
    
    authorized
      .skipWhile { $0 == false } //특정 조건이 false를 리턴하기 전까지 Observable이 배출한 항목들을 버린다
      .take(1) //Observable이 배츨한 처음 n개의 항목들만 배출한다
      .subscribe(onNext: { [weak self] _ in
        self?.photos = PhotosViewController.loadPhotos()
        DispatchQueue.main.async {
          self?.collectionView?.reloadData()
//            requestAuthorization(_:)은 완료 폐쇄가 실행될 스레드를 보장하지 않으므로 백그라운드 스레드에 떨어질 수 있다. 귀하는 Next(_:)를 호출하여 동일한 스레드에 있는 관측 가능한 에 대한 모든 구독 코드를 호출한다. 마지막으로, 당신의 구독에서 당신은 셀프라고 하는가?collectionView? 컬렉션뷰?데이터()를 다시 로드하고, 여전히 백그라운드 스레드에 있는 경우 UIKit이 충돌한다. UI를 업데이트할 때는 메인 스레드에 있는지 확인해야 한다.
        }
      })
      .disposed(by: bag)

    authorized
      .skip(1) //Observable이 배출한 처음 n개의 항목들을 숨긴다
      .takeLast(1) //Observable이 배출한 마지막 n개의 항목들만 배출한다
      .filter { $0 == false }
      .subscribe(onNext: { [weak self] _ in
        guard let errorMessage = self?.errorMessage else { return }
        DispatchQueue.main.async(execute: errorMessage)
      })
      .disposed(by: bag)
  }

  private func errorMessage() {
    alert(title: "No access to Camera Roll",
          text: "You can grant access to Combinestagram from the Settings app")
      .asObservable()
      .take(5.0, scheduler: MainScheduler.instance)
      .subscribe(onCompleted: { [weak self] in
        self?.dismiss(animated: true, completion: nil)
        _ = self?.navigationController?.popViewController(animated: true)
      })
      .disposed(by: bag)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    selectedPhotosSubject.onCompleted()
  }

  // MARK: UICollectionView

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let asset = photos.object(at: indexPath.item)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell

    cell.representedAssetIdentifier = asset.localIdentifier
    imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
      if cell.representedAssetIdentifier == asset.localIdentifier {
        cell.imageView.image = image
      }
    })

    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let asset = photos.object(at: indexPath.item)

    if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
      cell.flash()
    }

    imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
      guard let image = image, let info = info else { return }

      if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as? Bool, !isThumbnail {
        self?.selectedPhotosSubject.onNext(image)
      }
    })
  }
}
