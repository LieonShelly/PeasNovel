//
//  CommonDataService.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Moya

class CommonDataService {

    static func appConnfig() -> AppConfig? {
        guard let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration) else {
            return nil
        }
        return realm.objects(AppConfig.self).filter(NSPredicate(format: "id = %@", Constant.AppConfig.bundleID)).first
    }
    
    static func updateAppConfig(_ config: AppConfig) {
        guard let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration) else {
            return
        }
      try? realm.write {
            realm.add(config, update: .all)
        }
        
    }
    
    static func loadSogouKeywords() {
        let provider: MoyaProvider<BookReaderService> = MoyaProvider<BookReaderService>()
        let response = Observable.just(0)
            .mapToVoid()
                .flatMap {
                    provider.rx.request(.sogouKewords)
                        .model(SogouKeywordResponse.self)
                        .asObservable()
                        .catchError { _ in Observable.never()}
            }
            .share(replay: 1)
        
        response
            .subscribeOn(MainScheduler.asyncInstance)
            .map { $0.data }
            .unwrap()
            .map { $0?.prepage_num}
            .unwrap()
            .bind(to: CommomData.share.sogouKeywordsPrePageNum)
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
         
        response
            .subscribeOn(MainScheduler.asyncInstance)
            .map { $0.data }
            .unwrap()
            .map { $0?.keywords}
            .unwrap()
            .bind(to: CommomData.share.sogouKeywords)
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
    }
    
    
}
