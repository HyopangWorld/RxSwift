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
import RxCocoa
import Kingfisher

func cachedFileURL(_ fileName: String) -> URL {
    return FileManager.default
        .urls(for: .cachesDirectory, in: .allDomainsMask)
        .first!
        .appendingPathComponent(fileName)
}

class ActivityController: UITableViewController {
    
    private let repo = "ReactiveX/RxSwift"
    
    private let events = Variable<[Event]>([])
    private let bag = DisposeBag()
    private let eventsFileURL = cachedFileURL("events.plist")
    
    // Mon, 30 May 2017 04:30:00 GMT 같은 단일 문자열 저장에는 .plist 파일이 필요없다.
    // 이러한 놈들은 Last-Modified라는 이름의 헤더 값으로, JSON 리스폰스와 함께 서버가 보내는 놈들이다.
    // (이게 왜 필요하냐면) 이런 리스폰스를 받고 다음 리퀘스트를 보낼 때, 저 헤더와 같은 헤더를 서버에 보내야 한다.
    // 이렇게함으로써 서버가 '아 이놈이 마지막으로 패치한 놈이군' 하고 알게 해주는 것이다.
    // => 이것을 통해 이전에 반입하지 않은 이벤트만 요청하도록 네트워크 트래픽과 처리 능력을 절약한다.
    private let modifiedFileURL = cachedFileURL("modified.txt")
    // Last-Modified 헤더를 추적하기 위해서 Variable을 사용
    private let lastModified = Variable<NSString?>(nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = repo
        
        self.refreshControl = UIRefreshControl()
        let refreshControl = self.refreshControl!
        
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = UIColor.darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        // 파일에서 event 객체읽기
        let eventArray = (NSArray(contentsOf: eventsFileURL) as? [[String : Any]]) ?? []
        events.value = eventArray.compactMap(Event.init) // 객체로 변환, nil은 compactMap이 filteriing 해준당
        
        // 파일에서 가장 최근 헤더 가져오기
        lastModified.value = try? NSString(contentsOf: modifiedFileURL, usedEncoding: nil)
        
        refresh()
    }
    
    @objc func refresh() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.fetchEvents(repo: strongSelf.repo)
        }
    }
    
    
    // MARK: - Event & Header API Request
    func fetchEvents(repo: String) {
        let response = Observable.from(repo)
            // string -> URL
            .map { urlString -> URL in
                return URL(string: "https://api.github.com/repos/\(urlString)/events")!
            }
            // URL -> URLRequest
//            .map { url -> URLRequest in
//                return URLRequest(url: url)
//            }
            // header를 포함한 URLRequset 생성
            .map { [weak self] url -> URLRequest in
                var request = URLRequest(url: url)
                if let modifiedHeader = self?.lastModified.value {
                    request.addValue(modifiedHeader as String, forHTTPHeaderField: "Last-Modified")
                }
                return request
            }
            // 다른 Observable들이 이 request가 끝날 때까지 대기 flatMap 사용, 그동안 다른 연결들은 계속 동작할 수 있다.
            .flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in
                // RxCocoa의 response는 웹 서버를 통해 full response를 받을 때마다 complete되는
                // Observable<(response: HTTPURLResponse, data: Data)>를 반환한다.
                // 인터넷 연결이 없거나, url이 유효하지 않을 때 error 발생
                return URLSession.shared.rx.response(request: request)
            }
             // response 재생성 방지를 위한 것. 기존에 생성 된것을 버퍼에 저장하고, 다음 구독자에게 버퍼를 넘겨준다.
            .share(replay: 1, scope: .whileConnected)
        
        // body response 변형하기
        response
            // 응답이 성공일때만 받는다.
            .filter { response, _ in
                // ~= 같냐고 물어보는거 같으면 true, Observable<(response: HTTPURLResponse, data: Data)>를 내려보내 준다.
                return 200 ..< 300 ~= response.statusCode
            }
            // JSON data parsing
            .map { _, data -> [[String:Any]] in // 리스폰스 객체는 제외하고, 리스폰스 데이터만 받는다
                // JSONSerialization을 통해서 리스폰스 데이터를 디코드하고 결과를 반환한다.
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                    let result = jsonObject as? [[String:Any]] else { return [] }
                return result
            }
            // 어떤 이벤트 객체도 포함하지 않는 res 걸러내기
            .filter { return $0.count > 0 }
            // [[String: Any]] 파라미터를 받아서 [Event] 결과를 내보냄
            // 이 map은 인스턴스에 대한 메소드로 방출하는 각각의 요소에 대해 비동기적으로 작동한다
            .map { objects in
                // 이 map은 Array에 대한 메소드로 동기적으로 array내의 요소들을 Event.init으로 변환
                // nil을 반환하는 Event.init 호출을 flatMap(compactMap)하면 object는 nil 값을 제거
                return objects.compactMap(Event.init)
            }
            .subscribe(onNext: { [weak self] newEvents in
                self?.processEvents(newEvents) // UIUpdate
            })
            .disposed(by: bag)
        
        
        // header response 받아와서 최신 header 정보를 저장한다. -> response할 때 사용
        // 이 작업은 트래픽을 저장하지 않게 해줄 뿐만 아니라, 데이터를 반환하지 않기 때문에 GitHub API의 사용제한수를 증가하지 않는 효과를 보인다.
        response
            .flatMap { response, _ -> Observable<NSString> in
                guard let value = response.allHeaderFields["Last-Modified"] as? NSString else {
                    return Observable.empty()
                }
                return Observable.just(value)
            }
            .subscribe(onNext: { [weak self] modifiedHeader in
                guard let strongSelf = self else { return }
                strongSelf.lastModified.value = modifiedHeader
                try? modifiedHeader.write(to: strongSelf.modifiedFileURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
            })
            .disposed(by: bag)
    }
    
    
    // MARK: - Event Update & UIUpdate
    func processEvents(_ newEvents: [Event]) {
        // 프로퍼티에 repository의 이벤트 리스트 중 최근 50개의 이벤트를 잡아서 저장한다.
        var updatedEvents = newEvents + events.value
        if updatedEvents.count > 50 {
            updatedEvents = Array<Event>(updatedEvents.prefix(upTo: 50))
        }
        
        // 최근의 활동만이 테이블 뷰에 표시되도록 할 수 있다.
        events.value = updatedEvents
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
        
        //  JSON 객체로 변환해 .plist 파일에 event 데이터 저장
        let eventsArray = updatedEvents.map{ $0.dictionary } as NSArray
        eventsArray.write(to: eventsFileURL, atomically: true)
    }
    
    
    // MARK: - Table Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events.value[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = event.name
        cell.detailTextLabel?.text = event.repo + ", " + event.action.replacingOccurrences(of: "Event", with: "").lowercased()
        cell.imageView?.kf.setImage(with: event.imageUrl, placeholder: UIImage(named: "blank-avatar"))
        return cell
    }
}
