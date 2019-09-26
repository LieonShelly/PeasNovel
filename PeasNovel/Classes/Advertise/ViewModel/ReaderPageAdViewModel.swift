//
//  ReaderPageAdViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Realm
import RealmSwift

class ReaderPageAdViewModel: Advertiseable {
    var loadAdInput: PublishSubject<Void> = .init()
    var adViewModels: Advertiseable?
    let adOutput: PublishSubject<LocalTempAdConfig> = .init()
    let bag = DisposeBag()
    var adConfig: LocalAdvertise!
    let adUIConfig = ReaderPageAdUIConfig()
    
    init(_ config: LocalAdvertise) {
        self.adConfig = config
        let temConfig = TempAdvertise(config)
        let adUIConfig = self.adUIConfig
        self.loadAdInput.asObservable()
            .flatMap {[weak self] in
                AdvertiseService.createInfoStreamAdOutput(config, adUIConfigure: adUIConfig, configure: { (viewModel) in
                    if let weakSelf = self {
                        weakSelf.adViewModels = viewModel
                    }
                })
            }
            .bind(to:  self.adOutput)
            .disposed(by:  self.bag)
        
        /// 广告加载（首选position_id）失败， 加载second_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter({ (oldConfig) -> Bool in
                return oldConfig.ad_position == temConfig.ad_position
            })
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(temConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .flatMap { [weak self] in
                AdvertiseService.createInfoStreamAdOutput($0, adUIConfigure: adUIConfig, configure: { [weak self] (viewModel) in
                    if let weakSelf = self {
                        weakSelf.adViewModels = viewModel
                    }
                })
            }
            .bind(to:  self.adOutput)
            .disposed(by: self.bag)

        /// 广告加载（second_postion_id）失败, 加载third_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter({ (oldConfig) -> Bool in
                 return oldConfig.ad_position == temConfig.ad_position
            })
            .map { (oldConfig) -> LocalAdvertise in
                  let newConfig = LocalAdvertise(temConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .flatMap { [weak self] in
                AdvertiseService.createInfoStreamAdOutput($0, adUIConfigure: adUIConfig, configure: { [weak self] (viewModel) in
                    if let weakSelf = self {
                        weakSelf.adViewModels = viewModel
                    }
                })
            }
            .bind(to:  self.adOutput)
            .disposed(by:  self.bag)
    }
    
    deinit {
        debugPrint("deinit-ReaderPageAdViewModel")
    }
    
   
}

struct ReaderPageAdUIConfig: AdvertiseUIInterface {
    
    func infoAdSize(_ type: AdvertiseType?) -> CGSize {
        guard let type = type else {
            return .zero
        }
        switch type {
        case .inmobi:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 100)
        case .GDT:
            return CGSize(width: UIScreen.main.bounds.width - 16 * 2, height: (UIScreen.main.bounds.width - 16 * 2) * 2.0 / 3.0 + 100)
        case .todayHeadeline:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 80)
        default:
            return .zero
        }
    }
    
    func adClickHandler(_ config: LocalAdvertise?) -> Bool {
        NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
        return true
    }
}



