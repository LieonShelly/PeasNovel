//
//  IMNativeViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/7.
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


extension ObservableType where Element == LocalAdvertise {
    func inmobiNativeHandler() -> Observable<IMNativeViewModel> {
        return map {
            IMNativeViewModel($0)
        }
    }
}



class IMNativeViewModel: NSObject, Advertiseable {
    var nativeAd: IMNative?
    /// input
    let bag = DisposeBag()
    /// output
    let nativeAdOutput: PublishSubject<IMNative> = .init()
    var config: LocalAdvertise?
    var adUIConfig: AdvertiseUIInterface?
    
    convenience init(_ config: LocalAdvertise,  adUIConfig: AdvertiseUIInterface? = nil) {
        self.init()
        self.config = LocalAdvertise(config)
        self.adUIConfig = adUIConfig
        nativeAd = IMNative(placementId: Int64(config.ad_position_id) ?? 0, delegate: self)
        nativeAd?.load()
    }

    func reload(_ config: LocalAdvertise? = nil) {
        var adConfig = config
        if adConfig == nil {
            adConfig = self.config
        }
        guard let config = adConfig else {
            return
        }
        nativeAd?.recyclePrimaryView()
        nativeAd = IMNative(placementId: Int64(config.ad_position_id) ?? 0, delegate: self)
        nativeAd?.load()        
    }
    
    
    deinit {
        print("deinit- IMNativeViewModel: \(self.description)")
    }
    
}

extension IMNativeViewModel: IMNativeDelegate {
    
    func native(_ native: IMNative!, didFailToLoadWithError error: IMRequestStatus!) {
        print("IMNativeViewModel-didFailToLoadWithError-:\(error.userInfo)")
        errorNotification(config, userInfo: adUIConfig?.userInfo){[weak self] in
            self?.nativeAdOutput.onError(error)
        }
    }
    
    func nativeDidFinishLoading(_ native: IMNative!) {
        print("IMNativeViewModel-nativeDidFinishLoading")
        nativeAdOutput.onNext(native)
        adLoadedNotification(config)
        adExposedNotification(config)
    }
    
    func nativeWillPresentScreen(_ native: IMNative!) {
        
    }
    
    func nativeDidPresentScreen(_ native: IMNative!) {
        
    }
    
    func nativeWillDismissScreen(_ native: IMNative!) {
        
    }
    
    func nativeDidFinishPlayingMedia(_ native: IMNative!) {
        
    }
    
    func userDidSkipPlayingMedia(from native: IMNative!) {
        
    }
    
    func nativeAdImpressed(_ native: IMNative!) {
        
    }
    
    func userWillLeaveApplication(from native: IMNative!) {
        if let config = self.config {
            nativeAd?.recyclePrimaryView()
            nativeAd = IMNative(placementId: Int64(config.ad_position_id) ?? 0, delegate: self)
            nativeAd?.load()
            adClickNotification(config)
        }
    }
    
}

