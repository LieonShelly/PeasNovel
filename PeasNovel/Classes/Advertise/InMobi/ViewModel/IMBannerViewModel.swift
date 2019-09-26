//
//  CollectionCellBannerViewModel.swift
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


class IMBannerViewModel: NSObject, Advertiseable {
    var nativeAd: IMNative?
    /// input
    let bag = DisposeBag()
    /// output
    let nativeAdOutput: PublishSubject<IMNative> = .init()
    var config: LocalAdvertise?
    
    convenience init(_ config: LocalAdvertise, isAutoRefresh: Bool = false) {
        self.init()
        self.config = LocalAdvertise(config)
        nativeAd = IMNative(placementId: Int64(config.ad_position_id) ?? 0, delegate: self)
        nativeAd?.load()
    
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period:  RxTimeInterval.seconds(30), scheduler: MainScheduler.instance)
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
    
    
    deinit {
        print("deiinit- IMBannerViewModel")
    }
   
}

extension IMBannerViewModel: IMNativeDelegate {
    
    func native(_ native: IMNative!, didFailToLoadWithError error: IMRequestStatus!) {
        debugPrint("ADERROR-IMBannerViewModel-didFailToLoadWithError:\(error.userInfo)")
        errorNotification(config){[weak self] in
            self?.nativeAdOutput.onError(error)
        }
    }
    
    func nativeDidFinishLoading(_ native: IMNative!) {
        print("IMBannerViewModel-nativeDidFinishLoading")
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
           adLoadedNotification(config)
        }
    }
}

