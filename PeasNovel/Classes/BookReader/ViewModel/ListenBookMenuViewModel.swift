//
//  ListenBookMenuViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import UIKit
import Moya
import RxMoya
import RxCocoa
import RxSwift
import RealmSwift

class ListenBookMenuViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let menuConfig: BehaviorRelay<ListenBookMenuConfig?> = .init(value: nil)
    let bag = DisposeBag()
    let toneBtnInput: PublishSubject<ToneType> = .init()
    let speechRateBtnInput: PublishSubject<SpeechType> = .init()
    let timingBtnInput: PublishSubject<TimingType> = .init()
    
    init() {
        
        viewDidLoad.asObservable()
            .map { _ -> ListenBookMenuConfig in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                if let record = realm.objects(ListenBookMenuConfig.self).first {
                    return record
                } else {
                    let newRecord = ListenBookMenuConfig()
                    try? realm.write {
                        realm.add(newRecord, update: .all)
                    }
                    return newRecord
                }
            }
            .bind(to: menuConfig)
            .disposed(by: bag)
        
        toneBtnInput.asObservable()
            .subscribe(onNext: { (type) in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                if let record = realm.objects(ListenBookMenuConfig.self).first {
                    try? realm.write {
                        record.tone = type.rawValue
                    }
                    SpeechManager.share.reload()
                }
        })
        .disposed(by: bag)
        
        speechRateBtnInput.asObservable()
            .subscribe(onNext: { (type) in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                if let record = realm.objects(ListenBookMenuConfig.self).first {
                    try? realm.write {
                        record.speech_rate = type.rawValue
                    }
                    SpeechManager.share.reload()
                }
            })
            .disposed(by: bag)
        
        timingBtnInput.asObservable()
            .subscribe(onNext: { (type) in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                if let record = realm.objects(ListenBookMenuConfig.self).first {
                    try? realm.write {
                        record.timing = type.rawValue
                    }
                    SpeechManager.share.addTimer()
                }
            })
            .disposed(by: bag)
        
        
    }
}
