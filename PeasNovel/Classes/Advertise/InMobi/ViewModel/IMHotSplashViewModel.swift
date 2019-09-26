//
//  IMHotSplashViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/18.
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

class IMHotSplashViewModel: NSObject, Advertiseable {
    var nativeAd: IMNative?
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    /// output
    let nativeAdOutput: PublishSubject<IMNative> = .init()
    var config: LocalAdvertise?
    
    convenience init(_ config: LocalAdvertise) {
        self.init()
        self.config = LocalAdvertise(config)
        nativeAd = IMNative(placementId: Int64(config.ad_position_id) ?? 0, delegate: self)
        nativeAd?.load()
    }
    
}

extension IMHotSplashViewModel: IMNativeDelegate {
    
    func native(_ native: IMNative!, didFailToLoadWithError error: IMRequestStatus!) {
        print("IMSplashViewModel-didFailToLoadWithError")
        nativeAdOutput.onError(error)
        errorNotification(config)
    }
    
    func nativeDidFinishLoading(_ native: IMNative!) {
        print("IMSplashViewModel-nativeDidFinishLoading")
        nativeAdOutput.onNext(native)
        adLoadedNotification(config)
        adExposedNotification(config)
    }
    
    func nativeAdIsAvailable(_ native: IMNative!) {
        
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
