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
    let categories = Variable<[EOCategory]>([])
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startDownload()
    }
    
    func startDownload() {
        let eoCategories = EONET.categories
        let downloadEvents = eoCategories.flatMap{ categories in // 모든 카테고리를 가져와 flatMap을 사용 각 카테고리에 대한 이벤트를 obervable하는 observable를 생성
            return Observable.from(categories.map { category in
                EONET.events(forLast: 30, category: category)
            })
            }.merge()
//            }.merge(maxConcurrent: 2)       // 그런 다음 만들어진 모든 Observable을 단일 스트림으로 병합
        
//        let downloadEvents = EONET.events(forLast: 360)
        
        //        eoCategories
        //            .bind(to: categories)       // 새로운 구독을 만들고 요소를 변수로 보냅니다. 여기서는 categories를 바인딩 해서 새로운 구독을 만들고 categories로 보냅니다.categories를 폐기합니다.
        //            .disposed(by: disposeBag)
        
        
        categories
            .asObservable()             // subject categories에 들어오는 observable의 시퀸스로 바꾸고
            .subscribe(onNext: { [weak self] _ in       // 해당 시퀸스로 들어오는 내용을 구독해서 값이 들어오면 tableView를 리로드합니다.
                DispatchQueue.main.async {
                    self?.tableView?.reloadData()
                }
            })
            .disposed(by: disposeBag)                   // 구독이 완료되면 disposeBag에 넣습니다.
        
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
        }
        
//        let updatedCategories =
//            Observable
//                .combineLatest(eoCategories, downloadEvents) { (categories, events) -> [EOCategory] in
//                    return categories.map { category in
//                        var cat = category
//                        cat.events = events.filter {
//                            $0.categories.contains(category.id)
//                        }
//                        return cat
//                    }
//        }
        
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

