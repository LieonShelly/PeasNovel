//
//  ExchangeJDCodeViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya

class ExchangeJDCodeViewModel {
    let viewDidLoad: PublishSubject<Void>   = .init()
    let enterBtninput: PublishSubject<String> = .init()
    let bag = DisposeBag()
    let exchangeResult: PublishSubject<NullResponse> = .init()
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    
    init() {
        let provider = MoyaProvider<Payservice>.init()
        let activity = ActivityIndicator()
        let errorTracttor = ErrorTracker()
        activityDriver = activity.asDriver()
        errorDriver = errorTracttor.asDriver()
        
        enterBtninput.flatMap {
            provider.rx.request(.jdExchange(["code": $0]))
                .model(NullResponse.self)
                .asObservable()
                .trackActivity(activity)
                .trackError(errorTracttor)
                .catchError { Observable.just(NullResponse.commonError($0))}
                }
            .debug()
            .bind(to: exchangeResult)
            .disposed(by: bag)
       
        exchangeResult
            .map { $0.status?.code == 0}
            .subscribe(onNext: { (user) in
                NotificationCenter.default.post(name: NSNotification.Name.Account.needUpdate, object: nil, userInfo: nil)
            })
            .disposed(by: bag)
        
        
    }
}
