//
//  ChapterConnectionAdViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/9.
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


class BaseReaderAdViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let config: LocalAdvertise
    let noAdBtnInput: PublishSubject<Void> = .init()
    let chargeOutput: PublishSubject<ChargeViewModel> = .init()
    let chargeAlertOutput: PublishSubject<ChargeAlertViewModel> = .init()
    
    init(_ config: LocalAdvertise) {
        self.config =  LocalAdvertise(config)
       
        let record = noAdBtnInput.asObservable()
            .map { ReaderFiveChapterNoAd.isShowAlert() }
        
        /// 没有记录 -- 弹框
           record
            .filter { $0 == true }
            .map { _ in ChargeAlertViewModel()}
            .debug()
            .bind(to: chargeAlertOutput)
            .disposed(by: bag)
        
        /// 有记录在当天 -- 跳充值页
        record
            .filter { $0 == false }
            .debug()
            .map {_ in ChargeViewModel() }
            .bind(to: chargeOutput)
            .disposed(by: bag)
        

    }
}


class ChapterConnectionAdViewModel: BaseReaderAdViewModel, Advertiseable {
    var titleOutput: Observable<String>?
    var bannerViewModel: Advertiseable?
    var infoAdViewModel: Advertiseable?
    let adUIConfigInput: BehaviorRelay<ChapterConnectionAdUIConfig?> = .init(value: nil)
    
    /// output
    let infoAdOutput = PublishSubject<LocalTempAdConfig>.init()
    let bannerOutput = PublishSubject<LocalTempAdConfig>.init()
    let bannerConfigOutput: BehaviorRelay<LocalAdvertise?> = BehaviorRelay<LocalAdvertise?>.init(value: nil)
    
   init(_ config: LocalAdvertise, title: String) {
        super.init(config)
        titleOutput = Observable.just(title)
        
        viewDidLoad.asObservable()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.clearErrorLog(config)
            })
            .disposed(by: bag)
        
        /// 外部传入底部banner的配置
        bannerConfigOutput.asObservable()
            .unwrap()
            .filter { !$0.is_close }
            .filter { $0.ad_type ==  AdvertiseType.inmobi.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let imnativeViewModel = IMBannerViewModel(config)
                imnativeViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .inmobi($0))}
                    .bind(to: weakSelf.bannerOutput)
                    .disposed(by: weakSelf.bag)
                weakSelf.bannerViewModel = imnativeViewModel
            })
            .disposed(by: bag)
        
        /// banner 广告加载（首选position_id）失败， 加载second_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerBottomBanner.rawValue || $0.ad_position == AdPosition.readerPer5PgeBottomBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)
        
        /// banner 广告加载（second_postion_id）失败, 加载third_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerBottomBanner.rawValue || $0.ad_position == AdPosition.readerPer5PgeBottomBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .bind(to: bannerConfigOutput)
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
            .bind(to: infoAdConfig)
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
            .bind(to: infoAdConfig)
            .disposed(by: bag)
        
        viewDidLoad.asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Advertise.show, object: nil)
            })
            .disposed(by: bag)
    }
    
    deinit {
        debugPrint("ChapterConnectionAdViewModel - deinit")
    }
}

struct ChapterConnectionAdUIConfig: AdvertiseUIInterface {
    var holderVC: UIViewController?
    
    init() {
       
    }
    
    func adClickHandler(_ config: LocalAdvertise?) -> Bool {
        NotificationCenter.default.post(name: NSNotification.Name.Advertise.clickClose, object: config)
        return true
    }
    
    func infoAdSize(_ type: AdvertiseType?) -> CGSize {
        guard let type = type else {
            return .zero
        }
        switch type {
        case .inmobi:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 120)
        case .GDT:
            return CGSize(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width - 16 * 2) * 2.0 / 3.0 + 110)
        case .todayHeadeline:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 80)
        default:
            return .zero
        }
    }
}

