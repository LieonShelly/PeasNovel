//
//  MyFeedbackViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxMoya

class MyFeedbackViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    let messageOutput: PublishSubject<HUDValue> = .init()
    let datas: Driver<[SectionModel<String, MyFeedback>]>
    
    let exceptionOutputDriver: Driver<ExceptionInfo>
    let activityOutput: Driver<Bool>
    
    init() {
        let lists = BehaviorRelay<[MyFeedback]>.init(value: [])
        let activity = BehaviorRelay<Bool>(value: true)
        activityOutput = activity.asDriver()
        let provider = MoyaProvider<FeedbackService>()
        viewDidLoad.asObservable()
            .flatMap {
                provider.rx.request(.myFeedback)
                    .model(MyFeedbackResponse.self)
                    .asObservable()
                    .catchError {Observable.just(MyFeedbackResponse.commonError($0)) }
            }
            .map { $0.data }
            .unwrap()
            .bind(to: lists)
            .disposed(by: bag)
        
        datas = lists.asObservable().skip(1)
            .map {[SectionModel<String, MyFeedback>(model: "", items: $0)]}
            .asDriver(onErrorJustReturn: [])
        
        exceptionOutputDriver = lists.asObservable()
            .skip(1)
            .map { $0.count }
            .map {  ExceptionInfo.commonEmpty($0) }
            .asDriver(onErrorJustReturn: ExceptionInfo.commonEmpty(0))
        
        lists.asObservable().skip(1)
            .map {_ in false }
            .bind(to: activity)
            .disposed(by: bag)
    }
    
    

}
