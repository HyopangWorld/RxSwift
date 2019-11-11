/*
 * Copyright (c) 2014-2016 Razeware LLC
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
import CoreLocation
import MapKit

import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var geoLocationButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    let bag = DisposeBag()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style()
        
        
        // MARK: - 검색창 입력 시 날씨 옵져빙
        let searchInput = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map { self.searchCityName.text }
            .filter { ($0 ?? "").count > 0 }
        
        let textSearch = searchInput.flatMapLatest { text in
                // 유저가 search를 탭했을 때만 요청을 하므로 catchErrorJustReturn을 거를 수 있다.
                return ApiController.shared.currentWeather(city: text ?? "Error")
                    .catchErrorJustReturn(ApiController.Weather.empty)
        }
        
        
        // MARK: - 스크롤 뷰 이벤트 감지 해서 map search
        let mapInput = mapView.rx.regionDidChangeAnimated
           .skip(1)
            .map { _ in self.mapView.centerCoordinate }
        
         let mapSearch = mapInput.flatMap { coordinate in
           return ApiController.shared.currentWeather(lat: coordinate.latitude, lon: coordinate.longitude)
               .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        
        // MARK: - 현재 위치 날씨 옵져빙
        let currentLocation = locationManager.rx.didUpDateLocations
            .map { $0[0] } // didUpdateLocations는 array로 현재위치를 방출, 그중 한개 데이터만 가져오기
            .filter { $0.horizontalAccuracy < kCLLocationAccuracyHundredMeters } // 정확도를 위해 현재 위치와 100미터 이내로 설정
        
        let geoInput = geoLocationButton.rx.tap.asObservable()
            .do(onNext: { _ in
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            })
        
        let geoLocation = geoInput.flatMap { _ -> Observable<CLLocation> in
            return currentLocation.take(1)
        }
        
        let geoSearch = geoLocation.flatMap { location -> Observable<ApiController.Weather> in
            return ApiController.shared.currentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                .catchErrorJustReturn(ApiController.Weather.dummy)
        }
        
        
        // MARK: - 온도계 변경 옵져빙
//        let temperature = tempSwitch.rx.controlEvent(.valueChanged).asObservable()
//        let tempSwitch = Observable.just( temperature.map { self.tempLabel.text } )
//            .flatMapLatest {
//                if self.tempSwitch.isOn { return "\(Int(Double($0.temperature) * 1.8 + 32))°F" }
//                else { return "\($0.temperature)°C" }
//            .asDriver(onErrorJustReturn: "Error")
            
        
        // MARK: - 검색 옵져빙
        let search = Observable.from([textSearch, geoSearch, mapSearch])
            .merge()
            .asDriver(onErrorJustReturn: ApiController.Weather.dummy)
        
        
        // MARK: - 검색 결과 나올때까지 indicator 실행
        // 검색 입력과 검색 결과 모두를 합쳐서 running에
        let running = Observable.from([searchInput.map { _ in true },
                                       geoInput.map { _ in true },
                                       mapInput.map { _ in true},
                                       mapSearch.map { _ in false },
                                       search.map { _ in false }.asObservable()])
            .merge()
            //  앱이 시작할 때 모든 label을 수동적으로 숨길 필요가 없게 해주는
            .startWith(true) // 시작하기 전에 먼저 true를 표출해 label을 숨겨준다.
            .asDriver(onErrorJustReturn: false)
        
        // 맨처음 입력하기 전에는 indicator 안돌아가게
        running.skip(1).drive(activityIndicator.rx.isAnimating).disposed(by: bag)
        
        running.skip(1).drive(tempLabel.rx.isHidden).disposed(by: bag)
        running.skip(1).drive(humidityLabel.rx.isHidden).disposed(by: bag)
        running.skip(1).drive(cityNameLabel.rx.isHidden).disposed(by: bag)
        running.skip(1).drive(iconLabel.rx.isHidden).disposed(by: bag)
        
        
        // MARK: - 검색 결과 혹은 온도 스위치 바뀌었을때 라벨 변경
        // - bind는 subscribe와 비슷한데 맞춤형 producer만 값을 보내고 recevier는 값을 받기만 한다.
        //   producer가 만들어 내는 값에 따라 recevier를 data binding 해주는 것이다.
        //   여기서 search Observer가 producer이고, humidityLabel이 recevier이다
        // - driver 에서 bind(to:) 처럼 행동하는 drive()
        search.map {
                if self.tempSwitch.isOn { return "\(Int(Double($0.temperature) * 1.8 + 32))°F" }
                else { return "\($0.temperature)°C" }
        }
        .drive(tempLabel.rx.text)
        .disposed(by: bag)
        
        search.map { "\($0.humidity)%" }.drive(humidityLabel.rx.text).disposed(by: bag)
        search.map { "\($0.cityName)" }.drive(cityNameLabel.rx.text).disposed(by: bag)
        search.map { "\($0.icon)" }.drive(iconLabel.rx.text).disposed(by: bag)
        
        locationManager.rx.didUpDateLocations
            .subscribe(onNext: { locations in
                print("\(locations)")
            })
            .disposed(by: bag)
        
        // MARK : MAP View Overay 옵져빙
        mapButton.rx.tap
            .subscribe({ _ in
                self.mapView.isHidden = !self.mapView.isHidden
            })
            .disposed(by: bag)
        
        mapView.rx.setDelegate(self)
            .disposed(by: bag)
        
        search.map { [$0.overlay()] }
            .drive(mapView.rx.overlays)
            .disposed(by: bag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Appearance.applyBottomLine(to: searchCityName)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Style
    
    private func style() {
        view.backgroundColor = UIColor.aztec
        searchCityName.textColor = UIColor.ufoGreen
        searchCityName.attributedPlaceholder = NSAttributedString(string: "City's Name",
                                                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.cream])
        tempLabel.textColor = UIColor.lightGray
        humidityLabel.textColor = UIColor.lightGray
        iconLabel.textColor = UIColor.lightGray
        cityNameLabel.textColor = UIColor.lightGray
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? ApiController.Weather.Overlay {
            let overlayView = ApiController.Weather.OverlayView(overlay: overlay, overlayIcon: overlay.icon)
            return overlayView
        }
        return MKOverlayRenderer()
    }
}
