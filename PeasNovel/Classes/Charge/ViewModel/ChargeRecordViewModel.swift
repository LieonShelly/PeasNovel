//
//  ChargeRecordViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxDataSources

class ChargeRecordViewModel {
    let viewDidLoad: PublishSubject<Void>   = .init()
    let itemDidSelected: PublishSubject<ChargeModel> = .init()
    let items: Driver<[ChargeRecord]>
    let bag = DisposeBag()
    let indexPathSelectInput: PublishSubject<IndexPath> = .init()
    let itemSelectInput: PublishSubject<ChargeModel> = .init()
    let activityDriver: Driver<Bool>
    let openVipInput: PublishSubject<Void> = .init()
    let errorMessageOuput: PublishSubject<String> = .init()
    let refreshInput: PublishSubject<Bool> = .init()
    let excepotionDriver: Driver<ExceptionInfo>
    let refresStatus: BehaviorRelay<RefreshStatus> = .init(value: .none)
    
    init() {
        let refresStatus = self.refresStatus
        let activity = ActivityIndicator()
        let dataLists = BehaviorRelay<[ChargeRecord]>(value: [])
        let provider = MoyaProvider<Payservice>()
        let dataResponse = PublishSubject<ChargeRecordResponse>.init()
        activityDriver = activity.asDriver()
        
        viewDidLoad.flatMap {
            provider.rx.request(.record(1))
                .trackActivity(activity)
                .model(ChargeRecordResponse.self)
                .asObservable()
                .catchError { Observable.just(ChargeRecordResponse.emptyError($0))}
            }.bind(to: dataResponse)
            .disposed(by:  bag)
        
        dataResponse.asObservable()
            .map { $0.data }
            .unwrap()
            .bind(to: dataLists)
            .disposed(by: bag)
        
        dataLists.accept([])
        
        items = dataLists.asObservable()
            .skip(1)
            .asDriver(onErrorJustReturn: [])
        
        excepotionDriver = dataLists.asObservable()
            .skip(1)
            .map { $0.count }
            .map { ExceptionInfo($0, type: .empty("您还没有交易记录"), image: UIImage.noRecordsImage)}
            .asDriver(onErrorJustReturn: ExceptionInfo(0, type: .empty("您还没有交易记录"), image: UIImage.noRecordsImage))
            .debug()
        
        let page = BehaviorRelay(value: 2)
        let moreDataRes = PublishSubject<ChargeRecordResponse>.init()
        
        refreshInput.asObservable()
            .filter { $0 == false }
            .flatMap { _ in
                provider.rx.request(.record(page.value))
                    .model(ChargeRecordResponse.self)
                    .asObservable()
            }
            .bind(to: moreDataRes)
            .disposed(by: bag)
        
        moreDataRes.asObservable()
            .subscribe(onNext: { (respons) in
                if let data = respons.data, !data.isEmpty {
                    refresStatus.accept(RefreshStatus.endFooterRefresh)
                    page.accept(page.value + 1)
                    dataLists.accept(dataLists.value + data)
                } else {
                     refresStatus.accept(RefreshStatus.noMoreData)
                }
            }, onError: { _ in
                refresStatus.accept(RefreshStatus.error)
            })
            .disposed(by: bag)
        
    }
}
