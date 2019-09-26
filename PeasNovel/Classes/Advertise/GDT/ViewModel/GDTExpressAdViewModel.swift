//
//  GDTExpressAdViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//  GDT原生模板广告

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


class GDTExpressAdViewModel: NSObject, Advertiseable {
    var nativeExpressAd: GDTNativeExpressAd!
    /// input
    let bag = DisposeBag()
    /// output
    let nativeAdOutput: PublishSubject<GDTNativeExpressAdView> = .init()
    let nativeAdCloseOutput: PublishSubject<GDTNativeExpressAdView> = .init()
    var config: LocalAdvertise?
    weak var holderVC: UIViewController!
    fileprivate var adView: GDTNativeExpressAdView?
    var handler: AdvertiseUIInterface?
    var adUIConfig: AdvertiseUIInterface?
    
    convenience init(_ config: LocalAdvertise,
                     adUIConfig: AdvertiseUIInterface) {
        self.init()
        DispatchQueue.main.async {
            self.holderVC = adUIConfig.holderVC
            self.config = LocalAdvertise(config)
            self.adUIConfig = adUIConfig
            self.nativeExpressAd = GDTNativeExpressAd.init(appId: Constant.GDT.appID, placementId: config.ad_position_id, adSize:adUIConfig.infoAdSize(AdvertiseType(rawValue: config.ad_type)))
            self.nativeExpressAd.delegate = self
            DispatchQueue.main.async {
                self.nativeExpressAd.load(1)
            }
            self.handler = adUIConfig
        }
    }
    
    deinit {
        debugPrint("deinit- GDTExpressAdViewModel")
    }
    
}

extension GDTExpressAdViewModel: GDTNativeExpressAdDelegete {
    
    func nativeExpressAdSuccess(toLoad nativeExpressAd: GDTNativeExpressAd!, views: [GDTNativeExpressAdView]!) {
        if let adView = views.last {
            adView.controller = self.holderVC
            adView.render()
            self.adView = adView
        }
    }
    
    func nativeExpressAdFail(toLoad nativeExpressAd: GDTNativeExpressAd!, error: Error!) {
        debugPrint("GDTExpressAdViewModel-didFailToLoadWithError:\(error.localizedDescription)")
        errorNotification(config, userInfo: adUIConfig?.userInfo) {[weak self] in
            self?.nativeAdOutput.onError(error)
        }
    }
    
    func nativeExpressAdViewExposure(_ nativeExpressAdView: GDTNativeExpressAdView!) {
        adExposedNotification(config)
    }
    
    func nativeExpressAdViewClicked(_ nativeExpressAdView: GDTNativeExpressAdView!) {
        if let config = self.config {
           adClickNotification(config)
        }
    }

    func nativeExpressAdViewWillPresentVideoVC(_ nativeExpressAdView: GDTNativeExpressAdView!) {
        nativeExpressAd.load(1)
    }
    
    
    func nativeExpressAdViewClosed(_ nativeExpressAdView: GDTNativeExpressAdView!) {
        if !handler!.adClickHandler(config) {
            navigator.pushChargeVC()
        }
    }
    
    func nativeExpressAdViewRenderSuccess(_ nativeExpressAdView: GDTNativeExpressAdView!) {
        nativeAdOutput.onNext(nativeExpressAdView)
        adLoadedNotification(config)
    }
    
    func nativeExpressAdViewWillPresentScreen(_ nativeExpressAdView: GDTNativeExpressAdView!) {
         nativeExpressAd.load(1)
    }

}
