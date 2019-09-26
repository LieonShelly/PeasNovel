//
//  DownloadCenterViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/24.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation

import Moya
import RxMoya
import RxCocoa
import RxSwift
import Realm
import RxRealm
import RealmSwift
import HandyJSON

class DownloadCenterViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let addBookshelfAction: PublishSubject<Void> = .init()
    let bookDetailInput: PublishSubject<Void> = .init()
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let itemSelectInput: PublishSubject<DownloadLocalBook> = .init()
    let deleteInput: PublishSubject<DownloadLocalBook> = .init()
    let reloadInput: PublishSubject<Int> = .init()
    let clearAllInput: PublishSubject<Void> = .init()
    
    /// output
    let dataDriver: Driver<[DownloadLocalBook]>
    let itemSelectOutput: Driver<ChooseChapterViewModel>
    let reloadOutput: Driver<ChooseChapterViewModel>
    let exception: Driver<ExceptionInfo>
    
    init() {
        let realm =  try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let activity = BehaviorRelay<Bool>(value: true)
        let errorTracker = ErrorTracker()
        let bookList: BehaviorRelay<[DownloadLocalBook]> = .init(value: [])
        
        /// 清除过期的书籍
//        viewDidLoad.asObservable()
//            .subscribe(onNext: { (_) in
//                let endTime = Date().timeIntervalSince1970 - 24 * 60 * 60 
//                let invalidBooks = realm.objects(DownloadLocalBook.self).filter(NSPredicate(format: "create_time <= %lf", endTime))
//                try? realm.write {
//                    invalidBooks.setValue("0", forKeyPath: "status")
//                }
//            })
//            .disposed(by: bag)
        
        
        exception = bookList.asObservable()
            .skip(1)
            .map { $0.count }
            .map {  ExceptionInfo.commonEmpty($0) }
            .asDriver(onErrorJustReturn: ExceptionInfo.commonEmpty(0))
        
        
        errorDriver = errorTracker.asDriver()
        activityDriver = activity.asDriver()
        
        viewDidLoad
            .asObservable()
            .map { _ in  realm.objects(DownloadLocalBook.self).toArray() }
            .map { $0 }
            .debug()
            .bind(to: bookList)
            .disposed(by: bag)
        
        bookList.asObservable().skip(1)
            .map {_ in false }
            .bind(to: activity)
            .disposed(by: bag)
        
        dataDriver = bookList.asObservable().skip(1).asDriver(onErrorJustReturn: [])
        
        deleteInput.asObservable()
            .subscribe(onNext: { (book) in
                var data = bookList.value
                data.removeAll(where: {book.book_id == $0.book_id })
                bookList.accept(data)
            })
            .disposed(by: bag)
        
        clearAllInput.asObservable()
            .subscribe(onNext: { (_) in
                bookList.accept([])
            })
            .disposed(by: bag)
        
        // 改变本地的状态 -- 删除书籍,  删除章节信息
        clearAllInput.asObservable()
            .subscribe(onNext: { (_) in
                let localBook = realm.objects(DownloadLocalBook.self)
                let localGroup = realm.objects(DownloadLocalChapterGroupInfo.self)
                try? realm.write {
                    realm.delete(localBook)
                    realm.delete(localGroup)
                }
            })
            .disposed(by: bag)
        
        deleteInput.asObservable()
            .subscribe(onNext:{ (book)  in
                let localGroup = realm.objects(DownloadLocalChapterGroupInfo.self).filter({ (filtergroup) -> Bool in
                    return filtergroup.book_id == book.book_id 
                })
                try? realm.write {
                    realm.delete(localGroup)
                    realm.delete(book)
                }
            })
            .disposed(by: bag)
        
        
        reloadOutput =  reloadInput.asObservable()
            .map { bookList.value[$0]}
            .map { $0.book_id }
            .unwrap()
            .map { ChooseChapterViewModel($0)}
            .asDriverOnErrorJustComplete()
        
        /// 接受章节下载的通知发出的书籍信息
        NotificationCenter.default.rx
            .notification(Notification.Name.Book.downloadInfo)
            .map { $0.userInfo as? [String: Any]}
            .unwrap()
            .map {JSONDeserializer<DownloadLocalBook>.deserializeFrom(dict: $0)}
            .unwrap()
            .subscribe(onNext: { (localBook) in
                if let idex = bookList.value.index(where: { $0.book_id == localBook.book_id}) {
                    var data = bookList.value
                    data[idex] = localBook
                    bookList.accept(data)
                }
            })
            .disposed(by: bag)
        
        itemSelectOutput = itemSelectInput.asObservable()
            .map { $0.book_id }
            .unwrap()
            .map { ChooseChapterViewModel($0)}
            .asDriverOnErrorJustComplete()
    }
}
