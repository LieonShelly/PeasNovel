//
//  StatisticHandler.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import UIKit
import Moya
import RxSwift
import RxCocoa
import RxRealm
import Realm
import RealmSwift

class StatisticHandler {
    
    static var userReadActionParam: [String: String] = [:]
    
    static func initialize() {
        report(BehaviorRelay<StatisticService>(value: .lanunchTime))
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.bookShareSuccess)
            .map { $0.object as? [String: Any]}
            .unwrap()
            .subscribe(onNext: { (reporParam) in
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.shareBook(reporParam)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        

        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.buyVIP)
            .map { $0.object as? [String: Any]}
            .unwrap()
            .subscribe(onNext: { (reporParam) in
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.buyVip(reporParam)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.didClickCharge)
            .subscribe(onNext: { (_) in
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.charge))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.goodBookRecommend)
            .map { $0.object as? [String: Any]}
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.goodBookRecommend($0)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.search)
            .map { $0.object as? String}
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.search($0)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.advertise)
            .map { $0.object as? [String: Any]}
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.advertise($0)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.pageExposure)
            .map { $0.object as? String}
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.pageExposure($0)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.clickEvent)
            .map { $0.object as? String}
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.click($0)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.messageClick)
            .map { $0.object as? [String: String]}
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.messageClick($0)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.readerFiveChapterNoAd)
            .mapToVoid()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: StatisticService.reader5ChapterNoAd))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Statistic.userReadAction)
            .map { $0.object as? [String: String]}
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.report(BehaviorRelay<StatisticService>(value: .userReadAction($0)))
            })
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        
    
    }
    
    static func report(_ router: BehaviorRelay<StatisticService>) {
        
        autoreleasepool {
            let provider =  MoyaProvider<StatisticService>()
            _ =  router.asObservable()
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .flatMap {
                    provider.rx.request($0)
                    .model(NullResponse.self)
                    .asObservable()
                }
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { (_) in
                    debugPrint("report - Thread:\(Thread.current)")
                })
        }
    }
}
