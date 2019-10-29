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


import Foundation
import RxSwift
import RxCocoa

class EONET {
    static let API = "https://eonet.sci.gsfc.nasa.gov/api/v2.1"
    static let categoriesEndpoint = "/categories"
    static let eventsEndpoint = "/events"
    
    static var ISODateReader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
        return formatter
    }()
    
    static func filteredEvents(events: [EOEvent], forCategory category: EOCategory) -> [EOEvent] {
        return events.filter { event in
            return event.categories.contains(category.id) &&
                !category.events.contains {
                    $0.id == event.id
            }
            }
            .sorted(by: EOEvent.compareDates)
    }
    
    static func request(endpoint: String, query: [String: Any] = [:]) -> Observable<[String: Any]> {
        do {
            // URL에 엔드포인트 추가해서 옵셔널 바인딩이 안되면( 주소가 URL양식이 아니거나 하면 ) 에러를 발생
            guard let url = URL(string: API)?.appendingPathComponent(endpoint),
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    throw EOError.invalidURL(endpoint)
            }
            
            // URL이 있으면 query를 추가합니다. 나중에 event request에 사용할 것입니다.
            components.queryItems = try query.compactMap { (key, value) in
                guard let v = value as? CustomStringConvertible else {
                    throw EOError.invalidParameter(key, value)
                }
                return URLQueryItem(name: key, value: v.description)
            }
            
            
            guard let finalURL = components.url else {
                throw EOError.invalidURL(endpoint)
            }
            let request = URLRequest(url: finalURL)
            
            // response json -> Observable<[[String:Any]>로 return
            return URLSession.shared.rx.response(request: request)
                .map { _, data -> [String: Any] in
                    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                        let result = jsonObject as? [String: Any] else {
                            throw EOError.invalidJSON(finalURL.absoluteString)
                    }
                    return result
                }
        } catch {
            return Observable.empty()
        }
    }
    
    static var categories: Observable<[EOCategory]> = {
        // categori endpoint response return
        return EONET.request(endpoint: categoriesEndpoint)
            .map { data in
                let categories = data["categories"] as? [[String: Any]] ?? []
                // Json -> [[String:Any]] 타입의 response를 EOCategiry로 변형
                return categories
                    .compactMap(EOCategory.init)
                    .sorted { $0.name < $1.name } // 이름 순으로 정렬
        }
        .catchErrorJustReturn([])
            // 모든 요소들을 첫 번째 구독자에게 공급 그리고 마지막으로 받은 요소를 데이터 재요청 없이 새로운 구독자에게 리플레이
            .share(replay: 1, scope: .forever) // static이므로 Singletone이라 어쩌피 모두 같은 값을 받으므로 share
    }()
    
    fileprivate static func events(forLast days: Int, closed: Bool, endpoint: String) -> Observable<[EOEvent]> {
        return request(endpoint: eventsEndpoint, query: [
            "days": NSNumber(value: days),
            "status": (closed ? "closed" : "open")
            ])
            .map { json in
                guard let raw = json["events"] as? [[String: Any]] else {
//                    throw EOError.invalidJSON(eventsEndpoint)
                    throw EOError.invalidJSON(endpoint)
                }
                return raw.compactMap(EOEvent.init)
            }
            .catchErrorJustReturn([])
    }
    
    
//    fileprivate static func events(forLast days: Int, closed: Bool) -> Observable<[EOEvent]> {
//        return request(endpoint: eventsEndpoint, query: [
//            "days": NSNumber(value: days),
//            "status": (closed ? "closed" : "open")
//            ])
//            .map { json in
//                guard let raw = json["events"] as? [[String: Any]] else {
//                    throw EOError.invalidJSON(eventsEndpoint)
//                }
//                return raw.flatMap(EOEvent.init)
//            }
//            .catchErrorJustReturn([])
//    }
    
    static func events(forLast days: Int = 360, category: EOCategory) -> Observable<[EOEvent]> {
        let openEvents = events(forLast: days, closed: false, endpoint: category.endpoint)
        let closedEvents = events(forLast: days, closed: true, endpoint: category.endpoint)
        
//        return openEvents.concat(closedEvents)
        return Observable.of(openEvents, closedEvents).merge().reduce([]) { running, new in
            running + new
        }
        
        /*
         1. observable을 보고 있는 Observable을 생성
         2. observable 2개를 취해서 merge() // merge는 순서에 관계없이 시퀸스로 들어오는 값을 방출
         3. merge된 결과는 배열로 reduce 함. // reduce는 시작값과 조건을 받아 collection에서 값을 꺼내 해당 조건으로 작업 후 다시 collection에 담아 반환
         */
    }
}
