//
//  ChapterTailBookViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//  每个章节结尾

import Foundation
import RxCocoa
import RxSwift
import Moya
import PKHUD

class ChapterTailBookViewModel {
    let loadInput: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let bookInfo: PublishSubject<BookInfo> = .init()
    let addBookShlefInput: PublishSubject<Bool> = .init()
    let tapBtnInput: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    let isAddedStatus: Driver<Bool>
    let message: PublishSubject<HUDValue> = .init()
    let smallViewModel: PublishSubject<SmallReaderVewModel> = .init()
    
    init(_ bookId: String) {
        let provider = MoyaProvider<BookReaderService>()
        loadInput.flatMap {
            provider.rx
                .request(.getPerChapterRecommendBook(["book_id": bookId]))
                .model(ChapterTailBookResponse.self)
                .asObservable()
            }
            .map { $0.data }
            .debug()
            .unwrap()
            .debug()
            .bind(to: bookInfo)
            .disposed(by: bag)
        
        let bookProvider = MoyaProvider<BookInfoService>()
        let addBookshelf = addBookShlefInput
            .asObservable()
            .filter { $0 == false }
            .withLatestFrom(bookInfo)
            .map { $0.book_id}
            .unwrap()
            .flatMap {
                bookProvider.rx
                    .request(.add($0, 0))
                    .model(NullResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.status?.code }
            .unwrap()
            .share(replay: 1)
        
        let removeBookshelf = addBookShlefInput
            .asObservable()
            .filter { $0 == true }
            .withLatestFrom(bookInfo)
            .map { $0.book_id}
            .unwrap()
            .flatMap {
                bookProvider
                    .rx
                    .request(.delete($0, "0"))
                    .model(NullResponse.self)
                     .asObservable()
                    .catchError{_ in Observable.never() }
                
            }
            .map{ $0.status?.code }
            .unwrap()
            .share(replay: 1)
        
       
        Observable.merge(addBookshelf, removeBookshelf)
            .filter{ $0 == 0 }
            .subscribe(onNext: { _ in
                NotificationCenter.default.post(name: NSNotification.Name.Book.bookshelf, object: nil)
            })
            .disposed(by: bag)
        
        
        let bookDetail = BehaviorRelay<BookDetailModel>(value: BookDetailModel())
       Observable.merge(NotificationCenter.default.rx.notification(Notification.Name.Book.smallReaderAddCollect).mapToVoid().withLatestFrom(bookInfo),
                         bookInfo.asObservable())
            .flatMap {
                bookProvider
                    .rx
                    .request(.detail($0.book_id))
                    .model(BookDetailResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.data }
            .unwrap()
            .bind(to: bookDetail)
            .disposed(by: bag)
        
        // 是否加入书架
        let joinBookshelf = bookDetail
            .asObservable()
            .map{ $0.book_info?.join_bookcase }
            .unwrap()
            .map{ $0 }
        
        isAddedStatus = Observable
            .merge(joinBookshelf,
                   addBookshelf.map{ $0 == 0 },
                   removeBookshelf.filter{ $0 == 0 }.map { _ in false } )
            .asDriver(onErrorJustReturn: false)
        
        addBookshelf.asObservable()
            .observeOn(MainScheduler.instance)
            .filter { $0 == 0 }
            .map { _ in HUDValue(.label("添加书架成功"))}
            .bind(to: message)
            .disposed(by: bag)
        
        removeBookshelf.asObservable()
            .observeOn(MainScheduler.instance)
            .filter { $0 == 0 }
            .map { _ in HUDValue(.label("移除书架成功"))}
            .bind(to: message)
            .disposed(by: bag)
        
        
       
    }
    
    deinit {
        debugPrint("ChapterTailBookViewModel - deinit")
    }
}
