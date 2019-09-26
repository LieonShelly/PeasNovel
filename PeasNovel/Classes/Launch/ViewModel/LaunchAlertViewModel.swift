//
//   LaunchAlertViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
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
import UIKit

class LaunchAlertViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let imageDone: PublishSubject<UIImage> = .init()
    let imageTapInput: PublishSubject<Void> = .init()
    let dataOutput: BehaviorRelay<LaunchAlert> = .init(value: LaunchAlert())
    let imageTapOutput: PublishSubject<URL> = .init()
    
    init(_ model: LaunchAlert) {
        
        viewDidLoad
            .asObservable()
            .map { model.jump_url }
            .unwrap()
            .map { URL(string: $0)}
            .unwrap()
            .map { $0.queryParameters["book_id"]}
            .unwrap()
            .subscribe(onNext: {
                var reportParam = [String: String]()
                reportParam["from_type"] = "8"
                reportParam["book_id"] = $0
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.goodBookRecommend, object: reportParam)
            })
            .disposed(by: bag)
        
        imageTapInput.asObservable()
            .map { model.jump_url }
            .unwrap()
            .map { URL(string: $0)}
            .unwrap()
            .map { $0.queryParameters["book_id"]}
            .unwrap()
            .subscribe(onNext: {
                var reportParam = [String: String]()
                reportParam["from_type"] = "9"
                reportParam["book_id"] = $0
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.goodBookRecommend, object: reportParam)
            })
            .disposed(by: bag)

        imageTapInput.asObservable()
            .debug()
            .filter { model.jump_url != nil}
            .map { model.jump_url }
            .debug()
            .unwrap()
            .map { URL(string: $0)}
            .debug()
            .unwrap()
            .bind(to: imageTapOutput)
            .disposed(by: bag)
        
        viewDidLoad.asObservable()
            .map { model }
            .bind(to: dataOutput)
            .disposed(by: bag)
        
        viewWillDisappear.asObservable()
            .mapToVoid()
            .subscribe(onNext: { (_) in
                let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
                let record = LaunchAlertTime()
                /// 弹框之后写入当前时间
                record.modify_time = Date().timeIntervalSince1970
               try? realm?.write {
                    realm?.add(record, update: .all)
                }
            })
            .disposed(by: bag)
    }
}
