//
//  NewBookViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxCocoa
import RxSwift
import RxMoya
import Moya

/// 书城 -> 新书
class NewBookViewModel {
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let itemDidSelected = PublishSubject<BookInfo>()
    let footerRefresh: PublishSubject<Void> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    let sections: Driver<[SectionModel<Void, BookInfo>]>
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let toReader: Observable<BookInfo>
    let activityDriver: Driver<Bool>
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let bag = DisposeBag()
    
    init(_ provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        let activityIndicator = ActivityIndicator()
        let pageVariable = BehaviorRelay<(Int, Int)>(value: (1,1))  // curr_page, total_page
        let dataVariable = BehaviorRelay<[BookInfo]>(value: [])
        
        activityDriver = activityIndicator.asDriver()
        
        exceptionOuptputDriver = dataVariable.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = dataVariable.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        let moreDataRefresh = footerRefresh
            .withLatestFrom(pageVariable.asObservable())
            .map{ ($0.0 < $0.1) ? $0.0+1 : 1 }
            .flatMap{
                provider
                    .rx
                    .request(.newBookList($0))
                    .model(BookshelfListResponse.self)
            }
            .share(replay: 1)
        /// 更多数据刷新结果
        moreDataRefresh
            .map{ $0.data }
            .unwrap()
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { $1 + $0 })
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        let defaultRequest = Observable.merge([viewDidLoad.asObservable(), exceptionInput.asObservable()])
            .mapToVoid()
            .flatMap{
                provider
                    .rx
                    .request(.newBookList(1))
                    .model(BookshelfListResponse.self)
                    .trackActivity(activityIndicator)
                    .catchError {Observable.just(BookshelfListResponse.commonError($0))}
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
        
        sections = dataVariable
            .asObservable()
            .map{
                var sections = [SectionModel<Void, BookInfo>(model: (), items: Array($0.prefix(3)))]
                if $0.count > 3 {
                    sections.append(SectionModel<Void, BookInfo>(model: (), items: Array($0.suffix(from: 3))))
                }
                return sections
            }
            .asDriver(onErrorJustReturn: [])
        
        endMoreDaraRefresh = pageVariable
            .asObservable()
            .map{ $0.0 < $0.1 }
            .asDriver(onErrorJustReturn: false)
        
        toReader = itemDidSelected
            .asObservable()
    }

}
