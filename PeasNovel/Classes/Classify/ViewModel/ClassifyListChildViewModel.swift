//
//  ClassifyListChildViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import RxSwift
import RxMoya
import Moya

class ClassifyListChildViewModel: NSObject {
    
    let identify: String?
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let itemDidSelected: PublishSubject<BookInfo> = .init()
    let footerRefresh: PublishSubject<Void> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    let section: Driver<[SectionModel<Void, BookInfo>]>
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let gotoReader: Observable<BookInfo>
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let activityDriver: Driver<Bool>
    let bag = DisposeBag()
    
    init(_ model: ClassifyModel, provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        self.identify = model.name
        
        let pageVariable = BehaviorRelay<(Int, Int)>(value: (1,1))  // curr_page, total_page
        let dataVariable = BehaviorRelay<[BookInfo]>(value: [])
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
            .flatMap{
                provider
                    .rx
                    .request(.classifyBookList(model.parent_id ?? "", model.category_id ?? "", $0))
                    .model(ClissifyListChildResponse.self)
                
            }
            .share(replay: 1)
        /// 更多数据刷新结果
        moreDataRefresh
            .map{ $0.data }
            .unwrap()
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { $1 + $0 })
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        let defaultRequest = Observable.merge(viewDidLoad.asObservable(), exceptionInput.asObservable())
            .flatMap{
                provider
                    .rx
                    .request(.classifyBookList(model.parent_id ?? "", model.category_id ?? "", 1))
                    .model(ClissifyListChildResponse.self)
                    .trackActivity(acitvity)
            }
            .share(replay: 1)
        
        defaultRequest
            .map{ $0.data ?? [] }
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
                [SectionModel<Void, BookInfo>(model: (), items: $0)]
            }
            .asDriver(onErrorJustReturn: [])
        
        endMoreDaraRefresh = pageVariable
            .asObservable()
            .map{ $0.0 < $0.1 }
            .asDriver(onErrorJustReturn: false)
        
        gotoReader = itemDidSelected
            .asObservable()
    }

}
