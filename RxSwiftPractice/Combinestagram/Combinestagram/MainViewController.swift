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
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    private let bag = DisposeBag()
    private let images = Variable<[UIImage]>([])
    
    private var imageCache = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        images.asObservable()
            // 주어진 시간 내에 뒤 따라오는 요소들을 필터링 (주어진 시간내에 탭되는 것 중 마지막꺼 방출)
            // 만약 사용자가 5개의 사진을 선택간격 0.5초 이내로 빠르게 탭하였다면, throttle은 첫 4개를 필터하고 5번째 요소 출력
            // ex) 현재의 텍스트를 서버 API에 보내는 검색 텍스트 필드를 구독할 때, 사용자가 빠르게 타이핑 한다는 가정이 있다면
            //     타이핑을 완전히 마쳤을 때의 텍스트를 서버에 보내도록 throttole을 이용할 수 있다.
            // ex) 사용자가 bar 버튼을 눌러 view controller를 present modal 할 때, present modal이 여러번 되지 않도록 더블/트리플 탭을 방지할 수 있다.
            // ex) 사용자가 손가락을 이용해 화면을 드래그할 때, 드래그가 끝나는 지점에만 관심이 있을 수 있다.
            //     드래그 중일 때의 터치 위치는 무시하고 터치 위치가 변경을 멈추었을 때의 요소만 고려할 수 있다.
            // => throttle은 너무 많은 데이터를 한번에 입력받고 있을때 유용하게 쓸 수 있다.
            .throttle(0.5, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] photos in
                guard let preview = self?.imagePreview else { return }
                preview.image = UIImage.collage(images: photos, size: preview.frame.size)
            }).disposed(by: bag)
        
        images.asObservable()
            .subscribe(onNext: { [weak self] photos in
                self?.updateUI(photos: photos)
            }).disposed(by: bag)
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
            .subscribe(onSuccess: {[weak self] id in
                self?.showMessage("Saved with id: \(id)")
                self?.actionClear()
                }, onError: {[weak self] error in
                    self?.showMessage("Error", description: error.localizedDescription)
            }).disposed(by: bag)
    }
    
    @IBAction func actionAdd() {
        let photosViewContorller = storyboard!.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        navigationController?.pushViewController(photosViewContorller, animated: true)
        
        let newPhotos = photosViewContorller.selectedPhotos.share()
        
        newPhotos
            .takeWhile { [weak self] image in
                return (self?.images.value.count ?? 0) < 6
            }
            .filter { $0.size.width > $0.size.height }
            .filter { [weak self] newImage in
                let len = UIImagePNGRepresentation(newImage)?.count ?? 0
                guard self?.imageCache.contains(len) == false else { return false }
                self?.imageCache.append(len)
                return true
            }
            .subscribe(onNext: { [weak self] newImage in
                guard let images = self?.images else { return }
                images.value.append(newImage)
                }, onDisposed: { print("completed photo selection") }).disposed(by: bag)
        
        newPhotos
            .ignoreElements()
            .subscribe(onCompleted: { [weak self] in
                self?.updateNavigationIcon()
            })
            .disposed(by: photosViewContorller.bag)
    }
    
    private func updateNavigationIcon() {
        let icon = imagePreview.image?
            .scaled(CGSize(width: 22, height: 22))
            .withRenderingMode(.alwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        //        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        //        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
        //        present(alert, animated: true, completion: nil)
        alert(title: title, text: description).subscribe().disposed(by: bag)
        
    }
}
