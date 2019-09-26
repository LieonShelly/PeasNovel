//
//  ListenBookAlertViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class ListenBookAlertViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let videoAdInput: PublishSubject<Void> = .init()
    let hiddenAdOutput: BehaviorRelay<Bool> = .init(value: false)
    let bag = DisposeBag()
    
    init() {
        /// 判断是否能够看广告
        let listen_book_ad_ad_num = CommomData.share.switcherConfig.value?.listen_book_ad_ad_num ?? 0
        viewDidLoad.asObservable()
        .map {
            if let todayAdWatchNum = ListenBookAdModel.todayAdWatchNum(), todayAdWatchNum >= listen_book_ad_ad_num {
                return true
            }
            return false
        }
        .bind(to: hiddenAdOutput)
        .disposed(by: bag)
            
    }
    
}
