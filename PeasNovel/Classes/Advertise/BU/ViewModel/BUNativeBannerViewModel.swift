//
//  BUNativeBannerViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/28.
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
import InMobiSDK


class BUNativeBannerViewModel: NSObject {
    var nativeAd: BUNativeAd?
    /// input
    let bag = DisposeBag()
    /// output
    let nativeAdOutput: PublishSubject<BUNativeAd> = .init()
    var config: LocalAdvertise?
    weak var holderVC: UIViewController!
    
    convenience init(_ config: LocalAdvertise,
                     isAutoRefresh: Bool = false,
                     viewController: UIViewController) {
        self.init()
        self.config = LocalAdvertise(config)
        self.holderVC = viewController
        reloadAd(viewController)
        
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period: RxTimeInterval.seconds(30), scheduler: MainScheduler.instance)
            .filter {_ in isAutoRefresh }
            .skip(1)
            .subscribe(onNext: {[weak self]_ in
                guard let weakSelf = self else {
                    return
                }
                NotificationCenter.default.post(name: NSNotification.Name.Advertise.bannerNeedRefresh, object: weakSelf.config)
            })
            .disposed(by: bag)

    }
    
    func reloadAd(_ holderVC: UIViewController) {
        if let config = self.config {
            nativeAd = nil
            let imageSze = BUSize()
            imageSze.width = 1080
            imageSze.height = 1920
            let slot = BUAdSlot()
            slot.id = config.ad_position_id
            slot.adType = .banner
            slot.position = .top
            slot.imgSize = imageSze
            slot.isOriginAd = true
            slot.isSupportDeepLink = true
            nativeAd = BUNativeAd(slot: slot)
            nativeAd?.rootViewController = holderVC
            nativeAd?.delegate = self
            nativeAd?.loadData()
        }
        
    }
    deinit {
        debugPrint("deinit- BUNativeBannerViewModelViewModel")
    }
    
}

extension BUNativeBannerViewModel: BUNativeAdDelegate {
    
    func nativeAd(_ nativeAd: BUNativeAd, didFailWithError error: Error?) {
        debugPrint("ADERROR-BUNativeBannerViewModel-didFailToLoadWithError:\(error?.localizedDescription ?? "")")
        nativeAdOutput.onError(error ?? AppError(message: "", code: ErrorCode.addError))
        errorNotification(config){[weak self] in
            self?.nativeAdOutput.onError(error ?? AppError(message: "", code: ErrorCode.addError))
        }
    }
    
    
    func nativeAdDidLoad(_ nativeAd: BUNativeAd) {
        debugPrint("BUNativeBannerViewModel-nativeDidFinishLoading")
        nativeAdOutput.onNext(nativeAd)
        adLoadedNotification(config)
        adExposedNotification(config)
    }
    
    func nativeAdDidClick(_ nativeAd: BUNativeAd, with view: UIView?) {
        adClickNotification(config)
    }
    
    func nativeAd(_ nativeAd: BUNativeAd, dislikeWithReason filterWords: [BUDislikeWords]) {
        
    }
    
    func nativeAdDidCloseOtherController(_ nativeAd: BUNativeAd, interactionType: BUInteractionType) {
        if let holderVC = self.holderVC {
             reloadAd(holderVC)
        }
    }
}


extension BUNativeBannerViewModel: Advertiseable {}
