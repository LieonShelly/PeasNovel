//
//  BookCollectionViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import Moya
import RxMoya
import Alamofire

class BookCollectionViewModel {

    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let itemSelected: PublishSubject<BookInfo> = .init()
    let headerRefresh: PublishSubject<Void> = .init()
    let footerRefresh: PublishSubject<Void> = .init()
    let longPressAction: PublishSubject<IndexPath> = .init()
    
    /// output
    let handlerViewModel: Observable<BookshelfHandlerViewModel>
    let endRefresh: Driver<Void>            // 下拉刷新结束
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let activityOutput: Driver<Bool>
    let errorOutput: Driver<HUDValue>
    let section: Driver<[SectionModel<Void, BookInfo>]>
    let itemOutput: Observable<BookInfo>    // cell点击输出
    let bag = DisposeBag()
    let sheetViewModel: Observable<BookSheetViewModel>
    let exceptionDriver: Driver<ExceptionInfo>
    let sogouViewModel: Observable<SogouWebViewModel>
    
    init(_ provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let activity = ActivityIndicator()
        let errorActivity = ErrorTracker()
        activityOutput = activity.asDriver()
        errorOutput = errorActivity.asDriver()
        
        let addbookshelfNoti = NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Book.addbookshelf, object: nil)
            .mapToVoid()
        
        let removeBookshelfNoti = NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Book.bookshelf, object: nil)
            .mapToVoid()
        
        let pageVariable = BehaviorRelay<(Int, Int)>(value: (1,1))  // curr_page, total_page
        let dataVariable: BehaviorRelay<[BookInfo]> = BehaviorRelay(value: [])
           /// 收藏列表
        let moreDataRefresh = footerRefresh
            .withLatestFrom(pageVariable.asObservable())
            .map{ ($0.0 < $0.1) ? $0.0+1 : 1 }
            .flatMap{
                provider
                    .rx
                    .request(.bookshelf(page: $0))
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
            .merge(headerRefresh, viewDidLoad, addbookshelfNoti, removeBookshelfNoti)
            .flatMap {_ in
                provider
                    .rx
                    .request(.bookshelf(page: 1))
                    .model(BookshelfListResponse.self)
                    .trackActivity(activity)
                    .asObservable()
                    .catchError { Observable.just(BookshelfListResponse.commonError($0))}
            }
            .share(replay: 1)
        
        defaultRequest
            .map{ $0.data }
            .unwrap()
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        exceptionDriver = dataVariable.asObservable()
            .skip(1)
            .map { $0.count }
            .map { ExceptionInfo($0, type: ExceptionType.empty(nil), image: nil)}
            .asDriver(onErrorJustReturn: ExceptionInfo(0, type: .empty(nil), image: nil))
        
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
        
        section = dataVariable
            .asObservable()
            .map{
                [SectionModel<Void, BookInfo>(model: (), items: $0)]
            }
            .asDriver(onErrorJustReturn: [])
        
        handlerViewModel = longPressAction
            .mapToVoid()
            .withLatestFrom(dataVariable.asObservable())
            .map{ BookshelfHandlerViewModel($0, isRecently: false) }
        
        // 阅读器、详情页
        itemOutput = Observable.merge(itemSelected.asObservable())
            .filter { !$0.book_id.isEmpty }
            .filter{ $0.book_type == 0 }    // 书籍type
        
        sheetViewModel = Observable.merge(itemSelected.asObservable())
            .filter{ $0.book_type == 2 }    // 书单type
            .debug()
            .map{  BookSheetModel.deserialize(from: $0.toJSONString()) }
            .unwrap()
            .debug()
            .map{ BookSheetViewModel($0) }
        
        sogouViewModel = Observable.merge(itemSelected.asObservable())
            .filter{ $0.book_type == 3 }    // 网页类型
            .map{ SogouWebViewModel(URL(string: $0.link ?? ""), title: $0.book_title ?? "")}
        
        
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
