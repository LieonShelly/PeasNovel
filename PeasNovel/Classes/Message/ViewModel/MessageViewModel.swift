//
//  MessageViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/20.
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

class MessageViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let items: Driver<[GEPushMessage]>
    let exceptionOutputDriver: Driver<ExceptionInfo>
    let activityOutput: Driver<Bool>
    let itemDidSelect: PublishSubject<GEPushMessage> = .init()
    
    init() {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let messages: BehaviorRelay<[GEPushMessage]> = BehaviorRelay(value: [])
        let activity = BehaviorRelay<Bool>(value: true)
        activityOutput = activity.asDriver()
        let currentBefore30Date = Int(Date().timeIntervalSince1970) - 30 * 24 * 60 * 60
        viewDidLoad
            .flatMap {
                Observable.array(from: realm.objects(GEPushMessage.self).filter(NSPredicate(format: "createtime >= %ld", currentBefore30Date)).sorted(byKeyPath: "createtime", ascending: true))
        }
        .bind(to: messages)
        .disposed(by: bag)
        
        viewDidLoad
            .flatMap {
                Observable.array(from: realm.objects(GEPushMessage.self).filter(NSPredicate(format: "createtime < %ld", currentBefore30Date)).sorted(byKeyPath: "createtime", ascending: true))
            }
            .subscribe(onNext: { (msgs) in
              try?  realm.write {
                     realm.delete(msgs)
                }
                 NotificationCenter.default.post(name: NSNotification.Name.Message.didUpdate, object: nil)
            })
            .disposed(by: bag)
        
        items = messages.asObservable()
            .asDriver(onErrorJustReturn: [])
        
        exceptionOutputDriver = messages.asObservable()
            .skip(1)
            .map { $0.count }
            .map {  ExceptionInfo.commonEmpty($0) }
            .asDriver(onErrorJustReturn: ExceptionInfo.commonEmpty(0))
        
        itemDidSelect.asObservable()
            .map { (msg) -> GEPushMessage in
                let newMsg = GEPushMessage(msg)
                newMsg.status = MessageStatus.read.rawValue
                return newMsg
            }
            .subscribe(onNext: { (msg) in
                try? realm.write {
                    realm.add(msg, update: .all)
                    NotificationCenter.default.post(name: NSNotification.Name.Message.didUpdate, object: nil)
                }
            })
            .disposed(by: bag)
        
        itemDidSelect
            .asObservable()
            .subscribe(onNext: {(msg) in
                if let index = messages.value.first(where: { $0.createtime == msg.createtime}) {
                    let param = [
                        "message_id": "\(msg.createtime)",
                        "position": "\(index)"
                    ]
                    NotificationCenter.default.post(name: NSNotification.Name.Statistic.messageClick, object: param)
                }
            })
            .disposed(by: bag)
        
        messages.asObservable().skip(1)
            .map {_ in false }
            .bind(to: activity)
            .disposed(by: bag)
        
    }
    
}

