//
//  ReaderFullPicAdViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import UIKit
import Moya
import RxMoya
import RxCocoa
import RxSwift
import InMobiSDK
import RealmSwift

class ReaderFullPicAdViewModel: BaseReaderAdViewModel, Advertiseable {
    var infoAdViewModel: Advertiseable?
    let adUIConfigInput: BehaviorRelay<ReaderFullScreenAdUIConfig?> = .init(value: nil)
    let clearLogInput: PublishSubject<Void> = .init()
    /// output
    let infoAdOutput = PublishSubject<LocalTempAdConfig>.init()
    let dismissAction = PublishSubject<Void>.init()
    
    override init(_ config: LocalAdvertise) {
        super.init(config)
        Observable.merge(clearLogInput.asObservable(), viewDidLoad.asObservable())
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.clearErrorLog(config)
            })
            .disposed(by: bag)

        /// 信息流广告
        let infoAdConfig: BehaviorRelay<LocalAdvertise?> = .init(value: config)
        adUIConfigInput.asObservable()
            .unwrap()
            .withLatestFrom(infoAdConfig.asObservable().unwrap(), resultSelector: { ($0, $1)})
            .flatMap { [weak self] config in
                return AdvertiseService.createInfoStreamAdOutput(config.1, adUIConfigure: config.0, configure: { (viewModel) in
                    if let weakSelf = self {
                        weakSelf.infoAdViewModel = viewModel
                    }
                }).catchError { _ in Observable.never() }
            }
            .debug()
            .bind(to: infoAdOutput)
            .disposed(by: bag)
        
        /// 信息流广告加载（首选position_id）失败， 加载second_type
        let ad_position = config.ad_position
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == ad_position}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .withLatestFrom(adUIConfigInput.asObservable().unwrap(), resultSelector: { ($0, $1)})
            .flatMap { [weak self] config in
                return AdvertiseService.createInfoStreamAdOutput(config.0, adUIConfigure: config.1, configure: { (viewModel) in
                    if let weakSelf = self {
                        weakSelf.infoAdViewModel = viewModel
                    }
                }).catchError { _ in Observable.never() }
            }
            .bind(to: infoAdOutput)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == ad_position}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .withLatestFrom(adUIConfigInput.asObservable().unwrap(), resultSelector: { ($0, $1)})
            .flatMap { [weak self] config in
                return AdvertiseService.createInfoStreamAdOutput(config.0, adUIConfigure: config.1, configure: { (viewModel) in
                    if let weakSelf = self {
                        weakSelf.infoAdViewModel = viewModel
                    }
                }).catchError { _ in Observable.never() }
            }
            .bind(to: infoAdOutput)
            .disposed(by: bag)
        
        viewDidLoad.asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Advertise.show, object: nil)
            })
            .disposed(by: bag)
        
        
    }
    
    deinit {
        debugPrint("ReaderFullPicAdViewModel - deinit")
    }
}
