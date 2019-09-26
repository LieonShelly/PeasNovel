//
//  WebViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/5/15.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import WebKit
import RxCocoa
import PKHUD


class WebViewModel {
    
    let viewDidLoad: PublishSubject<Void> = .init()
    
    let request: Observable<URLRequest>
    var bannerAdConfigOutput: BehaviorRelay<LocalAdvertise?> = BehaviorRelay(value: nil)
    var bannerViewModel: Advertiseable?
    let bannerOutput = PublishSubject<LocalTempAdConfig>.init()
    let bag = DisposeBag()
    
    init(_ url: URL?) {
        
        request = viewDidLoad
            .map{ url }
            .unwrap()
            .map{ URLRequest(url: $0) }
        
        viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.loadAd()
            })
            .disposed(by: bag)
        
        loadAd()
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate)
            .subscribe(onNext: { [weak self](_) in
                self?.loadAd()
            })
            .disposed(by: bag)
    }
    
    func loadAd() {

        viewDidLoad.map { AdvertiseService.advertiseConfig(AdPosition.webPageSearch) }
            .unwrap()
            .bind(to: bannerAdConfigOutput)
            .disposed(by: bag)
        
        bannerAdConfigOutput.asObservable()
            .unwrap()
            .filter { !$0.is_close }
            .filter { $0.ad_type == AdvertiseType.inmobi.rawValue }
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                let imWebPageBannerViewModel = IMBannerViewModel(config)
                imWebPageBannerViewModel.nativeAdOutput
                    .map {  LocalTempAdConfig(config, adType:.inmobi($0))}
                    .bind(to: weakSelf.bannerOutput)
                    .disposed(by: weakSelf.bag)
                weakSelf.bannerViewModel = imWebPageBannerViewModel
            })
            .disposed(by: bag)
        
        /// banner 广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.webPageSearch.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: bannerAdConfigOutput)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.webPageSearch.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .bind(to: bannerAdConfigOutput)
            .disposed(by: bag)
    }
}
