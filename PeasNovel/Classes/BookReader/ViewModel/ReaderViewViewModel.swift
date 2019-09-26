//
//  ReaderViewViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//
/// 每一页对应的ViewModel

import Foundation
import Moya
import RxMoya
import RxCocoa
import RxSwift
import RealmSwift
import Alamofire

class ReaderViewViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let viewDidDisappear: PublishSubject<Bool> = .init()
    let bag: DisposeBag = DisposeBag()
    
    init() {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let startTimeStamp = BehaviorRelay(value:Date().timeIntervalSince1970)
        
        viewWillAppear
            .asObservable()
            .map {_ in Date().timeIntervalSince1970 }
            .bind(to: startTimeStamp)
            .disposed(by: bag)
        
        /// 记录APP在当前阅读器内的有效阅读时长
        viewWillDisappear
            .asObservable()
            .map {_ in  Date().timeIntervalSince1970 }
            .map { $0 - startTimeStamp.value }
            .filter { $0 > 5 }
            .map { (time) -> OneBookReadingTime in
                guard let record = realm.objects(OneBookReadingTime.self).first else {
                    let record = OneBookReadingTime()
                    record.readingDuration = time
                    return record
                }
                let newRecord = OneBookReadingTime()
                var newTime = time
                if time > 60 {
                    newTime = 60
                }
                print("记录APP在当前阅读器内的有效阅读时长newRecord: \(record.readingDuration) - time: \(newTime)")
                newRecord.readingDuration =  record.readingDuration + newTime
                return newRecord
            }
            .subscribe(onNext: { (record) in
                print("记录APP在当前阅读器内的有效阅读时长record: \(record.readingDuration)")
                try? realm.write {
                    realm.add(record, update: .all)
                }
            })
            .disposed(by: bag)
        
        
        viewWillDisappear
            .asObservable()
            .map {_ in  Date().timeIntervalSince1970 }
            .map { $0 - startTimeStamp.value }
            .filter { $0 > 5 }
            .map { (time) -> FullScreenBookReadingTime in
                guard let record = realm.objects(FullScreenBookReadingTime.self).first else {
                    let record = FullScreenBookReadingTime()
                    record.readingDuration = time
                    return record
                }
                let newRecord = FullScreenBookReadingTime()
                var newTime = time
                if time > 60 {
                    newTime = 60
                }
                print("记录APP在当前阅读器内的有效阅读时长newRecord: \(record.readingDuration) - time: \(newTime)")
                newRecord.readingDuration =  record.readingDuration + newTime
                return newRecord
            }
            .subscribe(onNext: { (record) in
                print("记录APP在当前阅读器内的有效阅读时长record: \(record.readingDuration)")
                try? realm.write {
                    realm.add(record, update: .all)
                }
            })
            .disposed(by: bag)
        
        
        /// 阅读器在被点击，被翻页时
        viewWillAppear.asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Event.readerIsWorking, object: nil)
            })
            .disposed(by: bag)
        
      
        
    }
    
    deinit {
        debugPrint("ReaderViewViewModel deinit!!")
    }
    
    
}
