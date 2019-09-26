//
//  BookSheetDetailViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import Moya
import RxMoya

class BookSheetDetailViewModel: NSObject {
    
    let router: String
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let cellAction: PublishSubject<(Int, BookSheetListModel)> = .init() // cell 事件，index，书籍id
    let itemDidSelected: PublishSubject<BookSheetListModel> = .init()
    let addBookshelfAction: PublishSubject<Void> = .init() // cell 事件，index，书籍id
    let exceptionInput: PublishSubject<Void> = .init()
    let isBookshelf: Driver<Bool>
    let dataSource: Observable<BookSheetModel>
    let toReader: Observable<BookSheetListModel>
    let section: Driver<[SectionModel<Void, BookSheetListModel>]>
    
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    
    let bag = DisposeBag()
    
    init(_ bookSheet: BookSheetModel, provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        
        activityDriver = activityIndicator.asDriver()
        errorDriver = errorTracker.asDriver()
        
        let dataVariable = BehaviorRelay<BookSheetModel>(value: bookSheet)
      
        
        let bookSheetRequest = Observable.merge([viewDidLoad.asObservable(), exceptionInput.asObservable()])
            .flatMap{
                provider
                    .rx
                    .request(.bookSheetDetail(bookSheet.id))
                    .model(BookSheetDetailResponse.self)
                    .trackActivity(activityIndicator)
                    .catchError { Observable.just(BookSheetDetailResponse.commonError($0))}
            }
            .map{ $0.data }
            .unwrap()
            .share(replay: 1)
        
        bookSheetRequest
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        isBookshelf = dataVariable
            .asObservable()
            .debug()
            .map{ $0.is_case || ($0.join_time != nil) }
            .debug()
            .asDriver(onErrorJustReturn: true)
        
        let addBookshelf = cellAction
            .filter{ $0.0 == 1 }
            .flatMap{
                provider
                    .rx
                    .request(.add($0.1.book_id, 0))
                    .model(BooksheetAddResponse.self)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .catchError {_ in Observable.never()}
            }
            .share(replay: 1)
        
         let addBooksheetToShelf = addBookshelfAction
            .map{ bookSheet }
            .flatMap{
                provider
                    .rx
                    .request(.add($0.id, 2))
                    .model(BooksheetAddResponse.self)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .catchError {_ in Observable.never()}
            }
            .share(replay: 1)
        /// 添加书架通知
        Observable.merge(addBooksheetToShelf, addBookshelf)
            .filter{ $0.status?.code == 0 }
            .subscribe(onNext: { _ in
                NotificationCenter.default.post(name: NSNotification.Name.Book.bookshelf, object: nil)
            })
            .disposed(by: bag)
        
        addBooksheetToShelf
            .filter{ $0.status?.code == 0 }
            .withLatestFrom(dataVariable.asObservable())
            .map{
                $0.is_case = true
                return $0
            }
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        addBookshelf
            .filter{ $0.status?.code == 0 }
            .map{ $0.data?.book_id }
            .unwrap()
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { ($0, $1) })
            .map{ info -> BookSheetModel in
                let dataSource = info.1
                let list = info.1.book_lists ?? []
                dataSource.book_lists = list.map{ model in
                    if model.book_id == info.0 {
                        model.is_case = true
                    }
                    return model
                }
                return dataSource
            }
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        toReader = Observable
            .merge(
                cellAction
                    .filter{ $0.0 == 0 }
                    .map{ $0.1 },
                itemDidSelected
            )
            .asObservable()
        
        dataSource = dataVariable
            .asObservable()
        
        section = dataVariable
            .asObservable()
            .map{ $0.book_lists }
            .unwrap()
            .map{
                [SectionModel<Void, BookSheetListModel>(model: (), items: $0)]
            }
            .asDriver(onErrorJustReturn: [])
        
        if let jump_url = bookSheet.jump_url, jump_url.length > 0 {
            router = jump_url
        }else{
            router = "client://kanshu/book_menu_horizontal_list"
        }
        
        exceptionOuptputDriver = section.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = section.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
    }

}
