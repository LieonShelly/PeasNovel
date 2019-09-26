//
//  BoutiqueViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxMoya
import Moya
import RxDataSources
import RxCocoa

class BoutiqueViewModel: NSObject {
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewDidAppear: PublishSubject<Bool> = .init()
    let cellBtnAction: PublishSubject<String> = .init()
    let searchAction: PublishSubject<Void> = .init()
    let exception: PublishSubject<Void> = .init()
    let itemDidSelected: PublishSubject<BoutiqueModel?> = .init()
    
    let section: Driver<[SectionModel<String, Any>]>
    let searchViewModel: Observable<SearchViewModel>
    let bookSheetDetail: Observable<BookSheetDetailViewModel>
    let exceptionDriver: Driver<ExceptionInfo>
    let router: Observable<String>
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    
    let bag = DisposeBag()
    
    init(_ provider: MoyaProvider<BoutiqueService> = MoyaProvider<BoutiqueService>()) {
        
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        
        let reloadAction = PublishSubject<Void>()
        let retry = ExceptionType.retry(btnTitle: NSLocalizedString("reload", comment: ""),desc:NSLocalizedString("requestFail", comment: ""))
        
        activityDriver = activityIndicator.asDriver()
        errorDriver = errorTracker.asDriver()
        
        let activeObser = Observable
            .merge(viewDidLoad, reloadAction)
            .flatMap{
                provider
                    .rx
                    .request(.boutiqueActive)
                    .model(BoutiqueActiveResponse.self.self)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .catchError{_ in Observable.never() }
            }
            .map{ $0.data }
            .unwrap()
            .map{ [SectionModel<String, Any>(model: "", items: [$0])] }   // 只有一个section
            .startWith([])
        
        let listObser = Observable
            .merge(viewDidLoad, reloadAction)
            .flatMap{
                provider
                    .rx
                    .request(.boutiqueList)
                    .model(BoutiqueResponse.self)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .catchError{_ in Observable.never() }
            }
            .map{ $0.data }
            .unwrap()
            .map{ list -> [SectionModel<String, Any>] in
                list.map{
                    SectionModel<String, Any>(model: "", items: [$0])
                }
            }
            .startWith([])
        
        section = Observable
            .combineLatest(activeObser, listObser)
            .map{ $0.0 + $0.1 }
            .asDriver(onErrorJustReturn: [])
        
        searchViewModel = searchAction
            .map{ SearchViewModel() }
        
        router = cellBtnAction
            .asObservable()
        
        bookSheetDetail = itemDidSelected
            .unwrap()
            .map{ $0.toJSON() }
            .debug()
            .unwrap()
            .map{ BookSheetModel.deserialize(from: $0) }
            .debug()
            .unwrap()
            .map{ BookSheetDetailViewModel($0) }
        
        exception
            .asObservable()
            .debug()
            .bind(to: reloadAction)
            .disposed(by: bag)
        
        exceptionDriver = section
            .asObservable()
            .map{ $0.count }
            .map{ ExceptionInfo($0,
                                type: retry,
                                image: UIImage.noContentImage) }
            .asDriver(onErrorJustReturn: ExceptionInfo(0,type: retry, image: UIImage.noContentImage))
        
        /// 上报
        viewDidAppear
            .asObservable()
            .map {_ in "YM_POSITION2_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.pageExposure, object: $0)
            })
            .disposed(by: bag)

    }
}
