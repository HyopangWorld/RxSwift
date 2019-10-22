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
import RxSwift

class MainViewController: UIViewController {

  private let bag = DisposeBag()
  private let images = Variable<[UIImage]>([])

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()

    images.asObservable()
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] photos in
        guard let preview = self?.imagePreview else { return }
        preview.image = UIImage.collage(images: photos,
                                        size: preview.frame.size)
      })
      .disposed(by: bag)

    images.asObservable()
      .subscribe(onNext: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
      .disposed(by: bag)
  }

  private func updateUI(photos: [UIImage]) {
    buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
    buttonClear.isEnabled = photos.count > 0
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }

  @IBAction func actionClear() {
    images.value = []
    imageCache = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }

    PhotoWriter.save(image)
      .subscribe(onSuccess: { [weak self] id in
        self?.showMessage("Saved with id: \(id)")
        self?.actionClear()
        }, onError: { [weak self] error in
          self?.showMessage("Error", description: error.localizedDescription)
      })
      .disposed(by: bag)
  }

    
    // FIXME: - 해결해야할 이슈들
//    - 세로방향사진이 들어오면 빈공간 나오는 부분 처리
//    - 옵셔버블을 share해서 기능추가
//    - 같은사진 두번 추가 부분 처리 (가장 좋은 방법은 이미지 데이터나 자산 URL의 해시를 저장하는 것이지만, 이 간단한 연습에서는 이미지의 바이트 길이를 사용한다. 이렇게 하면 이미지 지수의 고유성이 보장되는 것은 아니지만, 구현 세부사항에 너무 깊이 들어가지 않고 작업 솔루션을 구축하는 데 도움이 될 것이다.)
//    - 기본으로 6장의 사진을 추가하면 사진을 더 추가 못하게 되어있지만, 사진 보기 컨트롤러에 있다면 가능하다는 문제 해결
//    - 맨처음 실행해서 + 버튼 누르고 '허락'누르면 사진이 안보여. 한번 메인컨트롤러로 나갔다가 다시 들어와야 보였었어. 그거 해결해야함. 
    
    
    
    
    
  private var imageCache = [Int]()
  @IBAction func actionAdd() {
    //images.value.append(UIImage(named: "IMG_1907.jpg")!)

    let photosViewController = storyboard!.instantiateViewController(
      withIdentifier: "PhotosViewController") as! PhotosViewController

    let newPhotos = photosViewController.selectedPhotos
      .share()

    newPhotos
      .takeWhile { [weak self] image in //특정 조건이 false를 리턴하기 시작하면 그 이후에 배출되는 항목들을 버린다
        return (self?.images.value.count ?? 0) < 6
      }//    참고: 위의 코드에서 당신은 당신의 뷰 컨트롤러의 속성에 직접 접근하는데, 이것은 반응성 프로그래밍에서 다소 논란의 여지가 있는 관행이다.??
      .filter { newImage in
        return newImage.size.width > newImage.size.height
      }
      .filter { [weak self] newImage in
        let len = UIImagePNGRepresentation(newImage)?.count ?? 0
        guard self?.imageCache.contains(len) == false else {
          return false
        }
        self?.imageCache.append(len)
        return true
      }
      .subscribe(onNext: { [weak self] newImage in
        guard let images = self?.images else { return }
        images.value.append(newImage)
      }, onDisposed: {
          print("completed photo selection")
      })
      .disposed(by: bag)

    newPhotos
      .ignoreElements()
      .subscribe(onCompleted: { [weak self] in
        self?.updateNavigationIcon()
      })
      .disposed(by: bag)

    navigationController!.pushViewController(photosViewController, animated: true)
  }

  private func updateNavigationIcon() {
    let icon = imagePreview.image?
      .scaled(CGSize(width: 22, height: 22))
      .withRenderingMode(.alwaysOriginal)

    navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                       style: .done, target: nil, action: nil)
  }

  func showMessage(_ title: String, description: String? = nil) {
    alert(title: title, text: description)
      .subscribe()
      .disposed(by: bag)
  }
}
