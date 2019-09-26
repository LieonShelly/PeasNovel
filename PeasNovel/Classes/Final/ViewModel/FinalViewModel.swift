//
//  FinalViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxMoya
import Moya
/// 书城 -> 完本
class FinalViewModel: NSObject {
    
    // input
    let viewDidLoad: PublishSubject<Void> = .init()
    let genderAction: PublishSubject<Gender> = .init()
    let itemDidSelected: PublishSubject<BookInfo> = .init()
    let exchangeAction: PublishSubject<Int> = .init()
    let footerRefresh: PublishSubject<Void> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    
    /// output
    let section: Driver<[SectionModel<String, BookInfo>]>
    let toReader: Observable<BookInfo>
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let bag = DisposeBag()

    init(_ provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        let error = ErrorTracker()
        errorDriver = error.asDriver()
        let popularPage = BehaviorRelay<SearchPageInfo>(value: SearchPageInfo())
        let classicPage = BehaviorRelay<SearchPageInfo>(value: SearchPageInfo())
        let classicDataVariable = BehaviorRelay<[BookInfo]>(value: [])
        let acitvity = ActivityIndicator()
        exceptionOuptputDriver = classicDataVariable.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = classicDataVariable.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        activityDriver = acitvity.asDriver()
        
        let popularExchange = exchangeAction
            .filter{ $0 == 0 } // 人气完本换一换
            .withLatestFrom(popularPage.asObservable())
            .map{ ($0.cur_page < $0.total_page) ? $0.cur_page+1 : 1 }
            .withLatestFrom(genderAction, resultSelector: { ($1, $0) })
        
        let popularData = Observable
            .merge(
                genderAction.map{ ($0, 1) },
                popularExchange
            )
            .debug()
            .flatMap{
                provider
                    .rx
                    .request(.popularFinal($0.1, $0.0))
                    .model(FinalResponse.self)
                    .trackError(error)
                    .trackActivity(acitvity)
                    .catchError{_ in Observable.never() }
            }
            .map{ $0.data?.first }
            .unwrap()
            .share(replay: 1)
        
        popularData
            .map{ $0.page_info }
            .unwrap()
            .bind(to: popularPage)
            .disposed(by: bag)
        
        let section0 = popularData
            .filter{ $0.list.count > 0 }
            .map{ ( $0.name ?? "人气完结", $0.list) }
            .map{ [SectionModel<String, BookInfo>(model: $0.0, items: $0.1)] }
            .startWith([])
        
        let classicExchange = exchangeAction
            .filter{ $0 == 1 }  // 经典完本换一换
            .withLatestFrom(classicPage.asObservable())
            .map{ ($0.cur_page < $0.total_page) ? $0.cur_page+1 : 1 }
            .withLatestFrom(genderAction, resultSelector: { ($1, $0) })
        
        let classicData = Observable
            .merge(
                genderAction.map{ ($0, 1) },
                classicExchange,
                exceptionInput.asObservable().withLatestFrom( genderAction.map{ ($0, 1) })
            )
            .debug()
            .flatMap{
                provider
                    .rx
                    .request(.classicFinal($0.1, $0.0))
                    .model(FinalResponse.self)
                    .trackError(error)
                    .trackActivity(acitvity)
                    .catchError{_ in Observable.never() }
            }
            .map{ $0.data?.first }
            .unwrap()
            .share(replay: 1)
        
        classicData
            .map{ $0.list }
            .debug()
            .bind(to: classicDataVariable)
            .disposed(by: bag)
        
        let moreDatRefresh = footerRefresh
            .withLatestFrom(classicPage.asObservable())
            .map{ ($0.cur_page < $0.total_page) ? $0.cur_page+1 : 1 }
            .withLatestFrom(genderAction, resultSelector: { ($1, $0) })
            .flatMap{
                provider
                    .rx
                    .request(.classicFinal($0.1, $0.0))
                    .model(FinalResponse.self)
            }
            .map{ $0.data?.first }
            .unwrap()
            .share(replay: 1)
        /// 更多数据刷新结果
        moreDatRefresh
            .map{ $0.list }
            .withLatestFrom(classicDataVariable.asObservable(), resultSelector: { $1 + $0 })
            .bind(to: classicDataVariable)
            .disposed(by: bag)
        
        endMoreDaraRefresh = classicPage
            .asObservable()
            .map{ $0.cur_page < $0.total_page }
            .asDriver(onErrorJustReturn: false)
        
        Observable
            .merge(classicData, moreDatRefresh)
            .map{ $0.page_info }
            .unwrap()
            .bind(to: classicPage)
            .disposed(by: bag)
        
        let section1 = classicDataVariable
            .asObservable()
            .filter{ $0.count > 0 }
            .withLatestFrom(classicData, resultSelector: { ($1.name, $0)})
            .map{ ( $0.0 ?? "经典完本", $0.1) }
            .map{ [SectionModel<String, BookInfo>(model: $0.0, items: $0.1)] }
            .startWith([])
        
        toReader = itemDidSelected
            .asObservable()
        
        section = Observable
            .combineLatest(section0, section1)
            .map{ $0.0 + $0.1 }
            .asDriver(onErrorJustReturn: [])
        
    }
}
