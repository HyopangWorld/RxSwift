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

class EventsViewController : UIViewController, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var daysLabel: UILabel!
    
    let events = Variable<[EOEvent]>([])
    let disposeBag = DisposeBag()
    
    let days = Variable<Int>(360)
    let filteredEvents = Variable<[EOEvent]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        events.asObservable().subscribe(onNext:{[weak self] _ in
            self?.tableView.reloadData()
        })
            .disposed(by: disposeBag)
        
        // combineLatest : 들어오는 순서대로 방출 하는데, 전체가 completed 될대까지 방출
        Observable.combineLatest(days.asObservable(), events.asObservable()) { (days, events) -> [EOEvent] in
            let maxInterval = TimeInterval(days * 24 * 3600)
            return events.filter{ event in
                if let date = event.closeDate {
                    return abs(date.timeIntervalSinceNow) < maxInterval // 절대값을 리턴
                }
                return true
            }
            }.bind(to: filteredEvents)  // 새로운 구독을 만들고 element를 변수에 보냅니다.
            .disposed(by: disposeBag)
        
        filteredEvents.asObservable().subscribe(onNext:{[weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        days.asObservable().subscribe(onNext: {[weak self] days in
            self?.daysLabel.text = "Last \(days) days"
            }).disposed(by: disposeBag)
        
    }
    
    @IBAction func sliderAction(slider: UISlider) {
        days.value = Int(slider.value)
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return events.value.count
        return filteredEvents.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventCell
//        let event = events.value[indexPath.row]
        let event = filteredEvents.value[indexPath.row]
        cell.configure(event: event)
        return cell
    }
    
}
