/*
 * Copyright (c) 2016 Razeware LLC
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
import RxCocoa

class CategoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    var activityIndicator: UIActivityIndicatorView!
    lazy var activityProgress: UIProgressView = {
        let progress = UIProgressView(frame: CGRect(x:0, y:0, width: self.view.frame.width, height:10))
        progress.progressViewStyle = UIProgressViewStyle.bar
        progress.progress = 0.0
        return progress
    }()
    
    let categories = Variable<[EOCategory]>([])
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityProgress)
        
        categories
          .asObservable() // subject categories에 들어오는 observable의 시퀸스로 바꾸고
          .subscribe(onNext: { [weak self] _ in //// 해당 시퀸스로 들어오는 내용을 구독해서 값이 들어오면 tableView를 리로드합니다.
            DispatchQueue.main.async {
              self?.tableView?.reloadData()
            }
          })
          .disposed(by: disposeBag)
        
        startDownload()
    }
    
    func startDownload() {
        let eoCategories = EONET.categories
        let downloadEvents = eoCategories.flatMap{ categories in // 모든 카테고리를 가져와 flatMap을 사용. 각 카테고리에 대한 이벤트를 obervable하는 observable를 생성
            return Observable.from(categories.map { category in
                EONET.events(forLast: 30, category: category)
            })
            }.merge()
        
        
        let updatedCategories = eoCategories.flatMap { categories in
            downloadEvents.scan(categories) { updated, events in        // scan은 observable에 의해 방출된 모든 요소를 클로저를 호출하고 누적 된 값을 방출
                return updated.map { category in
                    let eventsForCategory = EONET.filteredEvents(events: events, forCategory: category)
                    if !eventsForCategory.isEmpty {
                        var cat = category
                        cat.events = cat.events + eventsForCategory
                        return cat
                    }
                    return category
                }
            }
        }.do(onCompleted: { [weak self]  in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
            }
        })
        
        eoCategories.flatMap { (categories) in
            return updatedCategories.scan(0) { count, _ in
                return count + 1
            }
            .startWith(0)
            .map { ($0, categories.count) }
        }
        .subscribe(onNext: { tuple in
            DispatchQueue.main.async { [weak self] in
                let progress = Float(tuple.0) / Float(tuple.1)
                self?.activityProgress.progress = progress
            }
        }, onCompleted: {
            DispatchQueue.main.async { [weak self] in
                self?.activityProgress.isHidden = true
            }
        })
        .disposed(by: disposeBag)
        
        eoCategories
            .concat(updatedCategories)  // eoCategories 시퀸스 다음에 updatedCategories를 가져옵니다. (직렬)
            .bind(to: categories)       // categories에 넘어오는 시퀸스를 묶습니다.
            .disposed(by: disposeBag)   // 사용이 완료되면 disposeBag에 넣습니다.
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        let category = categories.value[indexPath.row]
//        cell.textLabel?.text = category.name
        cell.detailTextLabel?.text = category.description
        
        cell.textLabel?.text = "\(category.name) (\(category.events.count))"
        cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories.value[indexPath.row]
        if !category.events.isEmpty {
            let eventsController = storyboard!.instantiateViewController(withIdentifier: "events") as! EventsViewController
            eventsController.title = category.name
            eventsController.events.value = category.events
            
            navigationController!.pushViewController(eventsController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}

