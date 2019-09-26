//
//  BookshelfHandlerViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxMoya
import Moya
import RxCocoa
import RealmSwift


class BookshelfHandlerViewModel: NSObject {
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let leftAction: PublishSubject<Void> = .init()
    let deleteAction: PublishSubject<Void> = .init()
    let itemSelected: PublishSubject<BookInfo> = .init()
    
    let sections: Driver<[SectionModel<Void, BookInfo>]>
    let leftButtonTitle: Driver<String>
    let deleteButtonTitle: Driver<String>
    let deleteButtonEnable: Driver<Bool>
    let popController: Observable<Void>
    let bag = DisposeBag()
    
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let tipHud: Driver<HUDValue>
    
    init(_ bookList: [BookInfo], isRecently: Bool = false, provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let errorTracker = ErrorTracker()
        let indicator = ActivityIndicator()
        
        errorDriver = errorTracker.asDriver()
        activityDriver = indicator.asDriver()
        
        let dataVariable = BehaviorRelay<[BookInfo]>(value: bookList)
        
        itemSelected
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { ($0, $1) })
            .map{ arg -> [BookInfo] in
                return arg.1.map({ bookInfo -> BookInfo in
                    if bookInfo.book_id == arg.0.book_id {
                        bookInfo.isSelected = !bookInfo.isSelected
                    }
                    return bookInfo
                })
            }
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        let selectItemObser = dataVariable
            .asObservable()
            .map{ list -> [BookInfo] in
                return list.filter{ $0.isSelected }
            }
            .share(replay: 1)
        
        /// 全选、取消全选
        let allSelected  = selectItemObser
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { $0.count == $1.count })
        
        leftAction
            .withLatestFrom(allSelected)
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { ($0, $1) })
            .map{ arg -> [BookInfo] in
                return arg.1.map({ bookInfo -> BookInfo in
                    bookInfo.isSelected = !arg.0
                    return bookInfo
                })
            }
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        leftButtonTitle = allSelected
            .map{ $0 ? "取消全选": "全选"}
            .asDriver(onErrorJustReturn: "取消全选")
        /// 删除按钮
        deleteButtonTitle = selectItemObser
            .map{ "删除(\($0.count))"}
            .asDriver(onErrorJustReturn: "删除")
        /// 删除按钮是否可用
        deleteButtonEnable = selectItemObser
            .map{ $0.count > 0 }
            .asDriver(onErrorJustReturn: false)
        
        if isRecently {
            let deleteHandler = deleteAction
                .withLatestFrom(selectItemObser)
                .map{ list -> String in
                    list.map{ $0.book_id }.joined(separator: ",")
                }
                .flatMap{
                    provider
                        .rx
                        .request(.recentlyDel($0))
                        .model(NullResponse.self)
                        .trackActivity(indicator)
                        .trackError(errorTracker)
                        .catchError{_ in Observable.never() }
                }
                .map{ $0.status?.code }
                .unwrap()
                .filter{ $0 == 0 }
                .share(replay: 1)
            
            tipHud = deleteHandler
                .map{_ in HUDValue(.label("删除成功")) }
                .asDriver(onErrorJustReturn: HUDValue(.success))
            
            deleteHandler
                .filter{ $0 == 0 }
                .withLatestFrom(dataVariable.asObservable())
                .map{
                    $0.filter{ (book) -> Bool in !book.isSelected }
                }
                .bind(to: dataVariable)
                .disposed(by: bag)
            
            deleteHandler
                .filter{ $0 == 0 }
                .map{ $0 == 0 }
                .subscribe(onNext: { _ in
                    NotificationCenter.default.post(name: NSNotification.Name.Book.recently, object: nil)
                })
                .disposed(by: bag)
        }else{
            let deleteHandler = deleteAction
                .withLatestFrom(selectItemObser)
                .map{ list -> (String, String) in
                    let ids = list.map{ $0.book_id }.joined(separator: ",")
                    let types = list.map{ String($0.book_type) }.joined(separator: ",")
                    return (ids, types)
                }
                .debug()
                .flatMap{
                    provider
                        .rx
                        .request(.delete($0.0, $0.1))
                        .model(NullResponse.self)
                        .trackActivity(indicator)
                        .trackError(errorTracker)
                        .catchError{_ in Observable.never() }
                }
                .map{ $0.status?.code }
                .unwrap()
                .filter{ $0 == 0 }
                .share(replay: 1)
            
            tipHud = deleteHandler
                .map{_ in HUDValue(.label("删除成功")) }
                .asDriver(onErrorJustReturn: HUDValue(.success))
            
            
            deleteHandler
                .filter{ $0 == 0 }
                .withLatestFrom(dataVariable.asObservable())
                .map{
                    $0.filter{ (book) -> Bool in !book.isSelected }
                }
                .bind(to: dataVariable)
                .disposed(by: bag)
            
            deleteHandler
                .filter{ $0 == 0 }
                .map{ $0 == 0 }
                .subscribe(onNext: { _ in
                    NotificationCenter.default.post(name: NSNotification.Name.Book.bookshelf, object: nil)
                })
                .disposed(by: bag)
        }
        
        deleteAction
            .withLatestFrom(selectItemObser)
            .mapMany { $0.book_id }
            .subscribe(onNext: { (bookIds) in
                NotificationCenter.default.post(name: NSNotification.Name.Book.deletes, object: bookIds)
            })
            .disposed(by: bag)
        
        deleteAction
            .withLatestFrom(selectItemObser)
            .mapMany { $0.book_id }
            .subscribe(onNext: { (bookIds) in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                let result = realm.objects(ReadRecord.self).filter(NSPredicate(format: "book_id IN %@", bookIds))
                try? realm.write {
                    realm.delete(result)
                }
            })
            .disposed(by: bag)
        
        sections = Observable
            .combineLatest(viewDidLoad, dataVariable.asObservable())
            .map{
                [SectionModel<Void, BookInfo>(model: (), items: $0.1)]
            }
            .asDriver(onErrorJustReturn: [])
        
        popController = dataVariable
            .asObservable()
            .filter{ $0.count == 0 }
            .mapToVoid()
        
    }
     
    deinit {
        print("BookshelfHandlerViewModel deinit!!!")
    }
}
