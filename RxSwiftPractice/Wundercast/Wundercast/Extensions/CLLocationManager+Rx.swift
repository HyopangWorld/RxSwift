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

import Foundation
import CoreLocation

import RxSwift
import RxCocoa


/// NSObject를 상속한 모든 클래스가 rx를 받게 할 수 있다.
extension NSObject: ReactiveCompatible { }

extension CLLocationManager: HasDelegate {
    public typealias Delegate = CLLocationManagerDelegate
}

/*
 RxCLLocationMaagerDelegateProxy는 observable이 생성되고 subscription한 직후에
 CLLocationManager 인스턴스에 연결하는 프록시(대리,위임자)가 됩니다. 이것은 HasDelegate protocol에 의해 단순화됩니다.
 여기서 proxy delegate의 초기화를 추가하고 참조해야 한다.
 */
class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
    
    public weak private(set) var locationManager: CLLocationManager?
    
    // 이 두가지 함수를 이용해서, delegate를 초기화하고, 모든 구현을 등록할 수 있다.
    // 이 구현은 CLLocationManager 인스턴스에서 연결된 observable로 데이터를 이동시키는데 사용되는 proxy이다.
    // 이는 RxCoca에서 delegate proxy 패턴을 쓰기위해 클래스를 확장하는 방법이다.
    // 이렇게 proxy delegate를 생성함으로써 장소 이동을 관찰하기 위한 observable이 생성되었다.
    public init(locationManager: ParentObject) {
        self.locationManager = locationManager
        super.init(parentObject: locationManager,
                   delegateProxy: RxCLLocationManagerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register{
            RxCLLocationManagerDelegateProxy(locationManager: $0)
        }
    }
    
}

// Reactive extension은 rx 키워드를 통해 CLLocationManager 인스턴스의 method들을 펼쳐놓을 것이다.
// 이제 모든 CLLocationManager 인스턴스에서 rx 키워드를 쓸 수 있다. 하지만, 아직 진짜 observable은 진짜 데이터를 받고 있지 않다.
extension Reactive where Base: CLLocationManager {
    public var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        return RxCLLocationManagerDelegateProxy.proxy(for: base)
    }
    
    // 이를 고치기 위해 함수를 추가했다.
    // 이 함수를 사용하면 proxy로 사용된 delegate는 didUpdateLocations의 모든 호출을 수신하고 데이터를 가져와서 CLLocation.methodInvoked(_:)의 array로 캐스팅 한다.
    // 이는 Objective-C 코드의 일부로, RxCocoa 및 기본적으로 delegate에 대한 낮은 수준의 observer다.
    // methodInvoked(_:)는 지정된 method가 호출될 때마다 next 이벤트를 보내는 observable을 리턴한다.
    // 이러한 이벤트레 포함된 요소는 method가 호출된 parameter의 array이다. 이 array를 parameters[1]로 접근하여 CLLocation의 array에 캐스팅한다.
    var didUpDateLocations: Observable<[CLLocation]> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:)))
            .map{ parameters in
                return parameters[1] as! [CLLocation]
        }
    }
}
