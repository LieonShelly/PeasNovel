//
//  BookMallViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import Moya
import RxMoya

class BookMallViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewDidAppear: PublishSubject<Bool> = .init()
    let viewDidDisappear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let recommendPositionMoreInput: PublishSubject<RecommendPosition> = .init()
    let reloadInput: PublishSubject<Void> = .init()
    
    /// output
    let userReaderFavorOutput: Driver<[Category]>
    let indexOutput: PublishSubject<Int> = .init()
    let userCategorylists: BehaviorRelay<[Category]> = BehaviorRelay(value: [])
    let exception: Driver<ExceptionInfo>
    let activity: Driver<Bool>
    
    init() {
      
        let provider = MoyaProvider<ReadFavorService>()
        let indicator = ActivityIndicator()
        activity = indicator.asDriver()
        
        viewDidLoad.flatMap { _ in
            provider.rx.request(.getSeetings)
                .model(UserReadFavorResponse.self)
                .asObservable()
                .catchError { _ -> Observable<UserReadFavorResponse> in
                    let responnse = UserReadFavorResponse()
                    responnse.data = []
                    return Observable.just(responnse)
                }
                .trackActivity(indicator)
            }
            .map {$0.data}
            .unwrap()
            .bind(to: userCategorylists)
            .disposed(by: bag)
        
        
        exception = userCategorylists.asObservable()
                    .skip(1)
            .map { $0.count }
            .map {  ExceptionInfo.commonRetry($0) }
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        reloadInput.asObservable()
            .flatMap { _ in
                provider.rx.request(.getSeetings)
                    .model(UserReadFavorResponse.self)
                    .asObservable()
                    .catchError { _ -> Observable<UserReadFavorResponse> in
                        let responnse = UserReadFavorResponse()
                        responnse.data = []
                        return Observable.just(responnse)
                    }
                 .trackActivity(indicator)
            }
            .map {$0.data}
            .unwrap()
            .bind(to: userCategorylists)
            .disposed(by: bag)
        
        userReaderFavorOutput = userCategorylists.asObservable()
                                 .skip(1)
                                .asDriver(onErrorJustReturn: [])
        
        recommendPositionMoreInput.asObservable()
            .filter {$0.category_id_1 != nil }
            .map { (postion) -> Int? in
               let index = self.userCategorylists.value.lastIndex(where:  {$0.category_id_1 == postion.category_id_1 && $0.category_id_2 == postion.category_id_2})
                return index
            }
            .unwrap()
            .bind(to: indexOutput)
            .disposed(by: bag)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.UIUpdate.readFavorDidChange)
            .flatMap { _ in
                provider.rx.request(.getSeetings)
                    .model(UserReadFavorResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map {$0.data}
            .unwrap()
            .bind(to: userCategorylists)
            .disposed(by: bag)
        
        /// 上报
        viewDidAppear
            .asObservable()
            .map {_ in "YM_POSITION3_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.pageExposure, object: $0)
            })
            .disposed(by: bag)
        
        
        
    }
}
