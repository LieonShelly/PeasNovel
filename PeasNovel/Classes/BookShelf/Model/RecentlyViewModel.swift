//
//  RecentlyViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/5/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxMoya
import Moya
import RxCocoa
import RealmSwift

class RecentlyViewModel {
    
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let itemSelected: PublishSubject<BookInfo> = .init()
    let headerRefresh: PublishSubject<Void> = .init()
    let footerRefresh: PublishSubject<Void> = .init()
    let longPressAction: PublishSubject<IndexPath> = .init()
    
    /// output
    let toReader: Observable<BookInfo>    // cell点击输出
    let handlerViewModel: Observable<BookshelfHandlerViewModel>
    let endRefresh: Driver<Void>            // 下拉刷新结束
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let activityOutput: Driver<Bool>
    let errorOutput: Driver<HUDValue>
    let section: Driver<[SectionModel<Void, BookInfo>]>
    
    let bag = DisposeBag()
    
    init(_ provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {

        let activity = ActivityIndicator()
        let errorActivity = ErrorTracker()
        activityOutput = activity.asDriver()
        errorOutput = errorActivity.asDriver()

        let recentlyUpdate = NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Book.recently, object: nil)
            .mapToVoid()
        
        let pageVariable = BehaviorRelay<(Int, Int)>(value: (1,1))  // curr_page, total_page
        let dataVariable: BehaviorRelay<[BookInfo]> = BehaviorRelay(value: [])
        
        let moreDataRefresh = footerRefresh
            .withLatestFrom(pageVariable.asObservable())
            .map{ ($0.0 < $0.1) ? $0.0+1 : 1 }
            .flatMap{
                provider
                    .rx
                    .request(.recently($0))
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
        
        let defaultRequest = Observable
            .merge(headerRefresh, viewDidLoad, recentlyUpdate)
            .flatMap{
                provider
                    .rx
                    .request(.recently(1))
                    .model(BookshelfListResponse.self)
                    .asObservable()
                    .catchError { Observable.just(BookshelfListResponse.commonError($0))}
            }
            .share(replay: 1)
        
        defaultRequest
            .map{ $0.data }
            .map({ (books) -> [BookInfo]? in
                if let books = books {
                    let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                    let localBooks = realm.objects(ReadRecord.self).filter(NSPredicate(format: "NOT book_id IN %@ AND book_id != %@ AND book_name != %@", books.map { $0.book_id}, "", "")).sorted(byKeyPath: "create_time", ascending: false).toArray() .map { BookInfo($0)}
                    return books + localBooks
                }
                return nil
            })
            .unwrap()
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        Observable
            .merge(defaultRequest, moreDataRefresh)
            .map{ ($0.cur_page, $0.total_page) }
            .bind(to: pageVariable)
            .disposed(by: bag)
        
        endMoreDaraRefresh = pageVariable
            .asObservable()
            .map{ $0.0 < $0.1 }
            .asDriver(onErrorJustReturn: false)
        
        endRefresh = pageVariable
            .asObservable()
            .mapToVoid()
            .asDriver(onErrorJustReturn: ())
        
        toReader = itemSelected
            .asObservable()
        
        section = dataVariable
            .asObservable()
            .map{
                [SectionModel<Void, BookInfo>(model: (), items: $0)]
        }
        .asDriver(onErrorJustReturn: [])
        
        handlerViewModel = longPressAction
            .mapToVoid()
            .withLatestFrom(dataVariable.asObservable())
            .map{ BookshelfHandlerViewModel($0, isRecently: true) }
        
        NotificationCenter.default.rx.notification(Notification.Name.Book.existReader)
            .asObservable()
            .map { $0.object as? ReadRecord }
            .unwrap()
            .subscribe(onNext: {[weak self] (record) in
                guard let weakSelf = self else {
                    return
                }
                var books = dataVariable.value
                /// 刷新阅读记录
                if let index = books.lastIndex(where: { $0.book_id == record.book_id}) {
                    let book = books[index]
                    books.remove(at: index)
                    books.insert(book, at: 0)
                    dataVariable.accept(books)
                } else {
                    weakSelf.headerRefresh.onNext(())
                }
            })
            .disposed(by: bag)
    }

}
