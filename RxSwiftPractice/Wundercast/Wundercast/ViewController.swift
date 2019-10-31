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
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var searchCityName: UITextField!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var tempSwitch: UISwitch!
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style()
            
        // 기본 데이터
        ApiController.shared.currentWeather(city: "RxSwift")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { data in
                self.tempLabel.text = "\(data.temperature)°C"
                self.iconLabel.text = data.icon
                self.humidityLabel.text = "\(data.humidity)%"
                self.cityNameLabel.text = data.cityName
            }).disposed(by: bag)
        
        
        let searchText = searchCityName.rx.controlEvent(.editingDidEndOnExit).asObservable()
        let temperature = tempSwitch.rx.controlEvent(.valueChanged).asObservable()
        
        // 도시 검색창에 옵져버 걸기
        // 검색 입력창에 입력이 끝나면 검색이 시작하도록 contolEvent 추가한다.
        // => 이렇게 하면 빈칸이 넘어올 수 없음
        let search = Observable.from([searchText, temperature])
            .merge()
            .map { self.searchCityName.text }
            // 빈 텍스트 거르고
//            .filter { ($0 ?? "").count > 0 }
            // 텍스트로 ApiController 호출해서 검색
            // API에서 받은 에러 때문에(observable 에러가 아닌) observable이 dispose 되는 것을 막기 위해 catchError
            .flatMapLatest { text in
                // 유저가 search를 탭했을 때만 요청을 하므로 catchErrorJustReturn을 거를 수 있다.
                return ApiController.shared.currentWeather(city: text ?? "Error")
                    .catchErrorJustReturn(ApiController.Weather.empty)
            }
            // Traits framework의 Driver로 전환
            // : 에러를 방출하지 않는 특별한 observable이다. 모든 과정은 UI 변경이 background 쓰레드에서 이뤄지는 것을 방지하기 위해 메인 쓰레드에서 이뤄진다.
            //.  observable이 에러를 방출할 때 어떻게 할 것인지 기본값을 정의하고 있다. 그러므로 driver는 스스로 방출된 에러를 떼어내는게 가능하다.
            .asDriver(onErrorJustReturn: ApiController.Weather.empty)
        
        // - bind는 subscribe와 비슷한데 맞춤형 producer만 값을 보내고 recevier는 값을 받기만 한다.
        //   producer가 만들어 내는 값에 따라 recevier를 data binding 해주는 것이다.
        //   여기서 search Observer가 producer이고, humidityLabel이 recevier이다
        
        // - driver 에서 bind(to:) 처럼 행동하는 drive()
        search
            .map {
                if self.tempSwitch.isOn {
                    return "\(Int(Double($0.temperature) * 1.8 + 32))°F"
                }
                else {
                    return "\($0.temperature)°C"
                }
            }
            .drive(tempLabel.rx.text)
            .disposed(by: bag)

        search.map { "\($0.humidity)%" }
            .drive(humidityLabel.rx.text)
            .disposed(by: bag)

        search.map { "\($0.cityName)" }
            .drive(cityNameLabel.rx.text)
            .disposed(by: bag)

        search.map { "\($0.icon)" }
            .drive(iconLabel.rx.text)
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
        tempLabel.textColor = UIColor.cream
        humidityLabel.textColor = UIColor.cream
        iconLabel.textColor = UIColor.cream
        cityNameLabel.textColor = UIColor.cream
    }
}

