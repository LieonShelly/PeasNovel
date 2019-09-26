//
//  BUNativeFeedAdViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/2.
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

class BUNativeFeedAdViewModel: NSObject, Advertiseable {
    var nativeAd: BUNativeAdsManager?
    /// input
    let bag = DisposeBag()
    /// output
    let nativeAdOutput: PublishSubject<BUNativeAd> = .init()
    let nativeAdCloseOutput: PublishSubject<BUNativeAd> = .init()
    var config: LocalAdvertise?
    var imageSize: CGSize = .zero
    var adUIConfig: AdvertiseUIInterface?
    
    convenience init(_ config: LocalAdvertise,
                     adUIConfig: AdvertiseUIInterface) {
        self.init()
        self.config = LocalAdvertise(config)
        self.adUIConfig = adUIConfig
        self.imageSize = adUIConfig.infoAdSize(AdvertiseType.todayHeadeline)
        reloadAd(imageSize)
    }
    
    func reloadAd(_ imageSize: CGSize) {
        if let config = self.config {
            nativeAd = nil
            let imageSze = BUSize()
            imageSze.width = Int(imageSize.width)
            imageSze.height = Int(imageSize.height)
            let slot = BUAdSlot()
            slot.id = config.ad_position_id
            slot.adType = .feed
            slot.position = .top
            slot.imgSize = imageSze
            slot.isOriginAd = true
            slot.isSupportDeepLink = true
            nativeAd = BUNativeAdsManager()
            nativeAd!.adslot = slot
            nativeAd?.delegate = self
            nativeAd!.loadAdData(withCount: 1)
        }
        
    }
    deinit {
        debugPrint("deinit- BUNativeBannerViewModelViewModel")
    }
    
}

extension BUNativeFeedAdViewModel: BUNativeAdsManagerDelegate, BUNativeAdDelegate {
    
    func nativeAdsManagerSuccess(toLoad adsManager: BUNativeAdsManager, nativeAds nativeAdDataArray: [BUNativeAd]?) {
        if let nativeAd = nativeAdDataArray?.last {
            nativeAd.delegate = self
            nativeAd.rootViewController = adUIConfig?.holderVC // UIViewController.current()
            nativeAd.loadData()
            
        }
    }
    
    func nativeAdsManager(_ adsManager: BUNativeAdsManager, didFailWithError error: Error?) {
        debugPrint("BUNativeFeedAdViewModel-didFailToLoadWithError:\(error?.localizedDescription ?? "")")
        errorNotification(config, userInfo: adUIConfig?.userInfo) {[weak self] in
            self?.nativeAdOutput.onError(error ?? AppError(message: "", code: ErrorCode.addError))
        }
    }

    
    func nativeAdDidCloseOtherController(_ nativeAd: BUNativeAd, interactionType: BUInteractionType) {
        reloadAd(self.imageSize)
    }

    func nativeAdDidClick(_ nativeAd: BUNativeAd, with view: UIView?) {
        if let config = self.config {
            adClickNotification(config)
        }
    }
    
    func nativeAd(_ nativeAd: BUNativeAd, didFailWithError error: Error?) {
      
    }
    
    func nativeAdDidBecomeVisible(_ nativeAd: BUNativeAd) {
          adExposedNotification(config)
    }
    
    func nativeAdDidLoad(_ nativeAd: BUNativeAd) {
        debugPrint("BUNativeFeedAdViewModel-nativeDidFinishLoading-interationType:\(nativeAd.data?.interactionType.rawValue ?? -1)")
        nativeAdOutput.onNext(nativeAd)
        adLoadedNotification(config)
      
    }

    func nativeAd(_ nativeAd: BUNativeAd, dislikeWithReason filterWords: [BUDislikeWords]) {
        nativeAdCloseOutput.onNext(nativeAd)
       
    }
}
