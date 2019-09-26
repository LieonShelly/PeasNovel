//
//  RankSubViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import Moya
import RxMoya

class RankSubViewModel: NSObject {
    /// var
    var identify: String
    
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let genderSwitch: BehaviorSubject<Gender> = .init(value: User.shared.sex)
    let itemDidSelected: PublishSubject<RankModel> = .init()
    let footerRefresh: PublishSubject<Void> = .init()
    
    let section: Driver<[SectionModel<String, RankModel>]>
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let gotoReader: Observable<BookInfo>
    let bag = DisposeBag()
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let activityDriver: Driver<Bool>
    
    init(_ identify: String, provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        self.identify = identify
        let pageVariable = BehaviorRelay<(Int, Int)>(value: (1,1))  // curr_page, total_page
        let dataVariable = BehaviorRelay<[RankModel]>(value: [])
        let acitvity = ActivityIndicator()
        exceptionOuptputDriver = dataVariable.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = dataVariable.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        activityDriver = acitvity.asDriver()
        
        let moreDataRefresh = footerRefresh
            .withLatestFrom(pageVariable.asObservable())
            .map{ ($0.0 < $0.1) ? $0.0+1 : 1 }
            .withLatestFrom(genderSwitch, resultSelector: { ($1, $0) })
            .flatMap{
                provider
                    .rx
                    .request(.ranking(identify, $0.0, $0.1))
                    .model(RankResponse.self)
            }
            .share(replay: 1)
        /// 更多数据刷新结果
        moreDataRefresh
            .map{ $0.data }
            .unwrap()
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { $1 + $0 })
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        let defaultRequest = genderSwitch
            .flatMap{
                provider
                    .rx
                    .request(.ranking(identify, $0, 1))
                    .model(RankResponse.self)
                    .trackActivity(acitvity)
            }
            .share(replay: 1)
        
        defaultRequest
            .map{ $0.data }
            .unwrap()
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        Observable
            .merge(defaultRequest, moreDataRefresh)
            .map{ ($0.cur_page, $0.total_page) }
            .bind(to: pageVariable)
            .disposed(by: bag)
        
        section = dataVariable
            .asObservable()
            .map{
                [SectionModel<String, RankModel>(model: identify, items: $0)]
            }
            .share(replay: 1)
            .asDriver(onErrorJustReturn: [])
        
        endMoreDaraRefresh = pageVariable
            .asObservable()
            .map{ $0.0 < $0.1 }
            .asDriver(onErrorJustReturn: false)
        
        gotoReader = itemDidSelected
            .map{
                let info = BookInfo()
                info.book_id = $0.book_id
                info.content_id = $0.content_id
                return info
        }
    }
    
    deinit {
        print("RankSubViewModel deinit!!!")
    }
    
}
