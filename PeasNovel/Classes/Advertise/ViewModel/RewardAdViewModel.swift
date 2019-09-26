//
//  RewardAdViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class RewardAdViewModel {
    var viewDidLoad: PublishSubject<Void> = .init()
    var adViewModels: Advertiseable?
    let adOutput: PublishSubject<LocalTempAdConfig> = .init()
    let bag = DisposeBag()
    var config: LocalAdvertise
    
    init(_ config: LocalAdvertise) {
        self.config = config
        let uiconfig = RewardAdViewUIConfig()
        viewDidLoad.asObservable()
            .flatMap {[weak self] in
                AdvertiseService.createRewardAdOutput(config, adUIConfigure: uiconfig, configure: { [weak self] (viewModel)  in
                    if let weakSelf = self {
                        weakSelf.adViewModels = viewModel
                    }
                })
            }
            .bind(to: adOutput)
            .disposed(by: bag)
        
         /// 广告加载（首选position_id）失败， 加载second_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == config.ad_position }
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .flatMap { [weak self] in 
                AdvertiseService.createRewardAdOutput($0, adUIConfigure: uiconfig, configure: { [weak self] (viewModel) in
                    if let weakSelf = self {
                        weakSelf.adViewModels = viewModel
                    }
                })
            }
            .bind(to: adOutput)
            .disposed(by: bag)
        
        /// 广告加载（second_postion_id）失败, 加载third_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position  == config.ad_position }
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .flatMap { [weak self] in
                AdvertiseService.createRewardAdOutput($0, adUIConfigure: uiconfig, configure: { [weak self] (viewModel) in
                    if let weakSelf = self {
                        weakSelf.adViewModels = viewModel
                    }
                })
            }
            .bind(to: adOutput)
            .disposed(by: bag)
        
    }
    
    deinit {
        debugPrint("deinit-RewardAdViewModel")
    }
}

struct RewardAdViewUIConfig: AdvertiseUIInterface { }
