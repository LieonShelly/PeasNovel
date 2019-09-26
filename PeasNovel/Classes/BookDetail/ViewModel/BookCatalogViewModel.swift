//
//  BookCatalogViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxMoya
import Moya
import RxDataSources
import RxCocoa

class BookCatalogViewModel: NSObject {
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let itemSelected: PublishSubject<BookCatalogModel> = .init()
    let sortAction: PublishSubject<Bool> = .init()
    let headerRefresh: PublishSubject<Void> = .init()
    let footerRefresh: PublishSubject<Void> = .init()
    
    let section: Driver<[SectionModel<Void, BookCatalogModel>]>
    let endRefresh: Driver<Void>            // 下拉刷新结束
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let toReader: Observable<BookInfo>
    let isReverse: Driver<Bool>    // 是否倒序
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let bag = DisposeBag()
    
    init(_ bookId: String, provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let dataVariable = BehaviorRelay<[BookCatalogModel]>(value: [])
        let sortVariable = BehaviorRelay<Bool>(value: true)
        
        let activity = ActivityIndicator()
        let error = ErrorTracker()
        
        var page = 1
        
        activityDriver = activity.asDriver()
        errorDriver = error.asDriver()
        
        sortAction
            .bind(to: sortVariable)
            .disposed(by: bag)
        
        isReverse = sortAction
            .not()
            .asDriver(onErrorJustReturn: false)
        
        let dataObser = Observable
            .merge(
                sortVariable.asObservable(),
                viewDidLoad.map{ true },
                headerRefresh.map{ sortVariable.value }
            )
            .flatMap{
                provider
                    .rx
                    .request(.catalog(bookId, page: 1, order: $0))
                    .model(BookCatalogResponse.self)
                    .trackActivity(activity)
                    .trackError(error)
            }
            .share(replay: 1)
        
        let moreDataObser = footerRefresh
            .map{ page }
            .withLatestFrom(sortVariable.asObservable(), resultSelector: { ($0, $1)})
            .flatMap{
                provider
                    .rx
                    .request(.catalog(bookId, page: $0.0, order: $0.1))
                    .model(BookCatalogResponse.self)
                    .trackActivity(activity)
                    .trackError(error)
            }
            .share(replay: 1)
        
        /// 目录页页码
        Observable
            .merge(moreDataObser, dataObser)
            .filter{ $0.cur_page <= $0.total_page }
            .subscribe(onNext: {
                page = $0.cur_page + 1 // 数据请求成功之后，页码+1
            })
            .disposed(by: bag)
        
        dataObser
            .map{ $0.data }
            .unwrap()
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        /// 更多数据刷新结果
        moreDataObser
            .map{ $0.data ?? [] }
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { $1 + $0 })
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        endRefresh = dataObser
            .mapToVoid()
            .asDriver(onErrorJustReturn: ())
        
        endMoreDaraRefresh = moreDataObser
            .debug()
            .map{ $0.cur_page < $0.total_page }
            .debug()
            .asDriver(onErrorJustReturn: true)
        
        section = dataVariable
            .asObservable()
            .map{
                [ SectionModel<Void, BookCatalogModel>(model: (), items: $0)]
            }
            .asDriver(onErrorJustReturn: [])
        
        toReader = itemSelected
            .map{
                let info = BookInfo()
                info.book_id = $0.book_id
                info.content_id = $0.content_id
                return info
        }
        
        
    }

}
