//
//  BookSheetChoiceViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import Moya
import RxMoya

class BookSheetChoiceViewModel: NSObject {
    
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let favorAction: PublishSubject<String> = .init()
    let bookItemSelected: PublishSubject<BookSheetListModel> = .init()
    let itemDidSelected: PublishSubject<BookSheetModel> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    let section: Driver<[SectionModel<Void, BookSheetModel>]>
    let bookSheetDetail: Observable<BookSheetDetailViewModel>
    let toReader: Observable<BookSheetListModel>
    let favorEnable: Driver<Bool>
    
    let errorDriver: Driver<HUDValue>
    let activityDriver: Driver<Bool>
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let bag = DisposeBag()
    
    init(_ provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        
        errorDriver = errorTracker.asDriver()
        activityDriver = activityIndicator.asDriver()
        
        let dataVariable = BehaviorRelay<[BookSheetModel]>(value: [])
        exceptionOuptputDriver = dataVariable.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = dataVariable.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        favorEnable = Observable
            .just(false)
            .asDriver(onErrorJustReturn: false)
        
        Observable.merge([exceptionInput.asObservable().mapToVoid(), viewDidLoad.asObservable()])
            .flatMap{
                provider
                    .rx
                    .request(.bookSheetChoice(1))
                    .model(BookSheetResponse.self)
                    .trackActivity(activityIndicator)
                    .catchError { Observable.just(BookSheetResponse.commonError($0))}
            }
            .map{ $0.data }
            .unwrap()
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        section = dataVariable
            .asObservable()
            .map{ list -> [SectionModel<Void, BookSheetModel>] in
                list.map{ SectionModel<Void, BookSheetModel>(model: (), items: [$0]) }
            }
            .asDriver(onErrorJustReturn: [])
        
        favorAction
            .flatMap{
                provider.rx
                    .request(.add($0, 2))
                    .model(BookSheetAddResponse.self)
                    .trackActivity(activityIndicator)
                    .catchError {_ in Observable.never()}
                
            }
            .filter{ $0.status?.code == 0 }
            .map{ $0.data?.book_id }
            .unwrap()
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { ($0, $1) })
            .map{ info -> [BookSheetModel] in
                return info.1.map{ model in
                    if model.id == info.0 {
                        model.is_case = true
                    }
                    return model
                }
            }
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        bookSheetDetail = itemDidSelected
            .map{ BookSheetDetailViewModel($0) }
        
        toReader = bookItemSelected
            .asObservable()
    }
    
    deinit {
        print("BookSheetChoiceViewModel deinit!!!")
    }
}
