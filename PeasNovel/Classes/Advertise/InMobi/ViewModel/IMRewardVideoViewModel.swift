//
//  IMRewardVideoViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/13.
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

class IMRewardVideoViewModel: NSObject, Advertiseable {
    var interstitial: IMInterstitial?
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    
    /// output:
    let interstitialOutput: PublishSubject<IMInterstitial> = .init()
    let willDismissAdOutput:  PublishSubject<IMInterstitial> = .init()
    let didDismissAdOutput:  PublishSubject<IMInterstitial> = .init()
    var config: LocalAdvertise?
    var isPresent: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    convenience init(_ config: LocalAdvertise) {
        self.init()
        self.interstitial = IMInterstitial(placementId: Int64(config.ad_position_id) ?? 0, delegate: self)
        self.interstitial?.load()
        self.config = LocalAdvertise(config)
    }
    
    deinit {
        print("IMRewardVideoViewModel -- deinit")
    }
}

extension IMRewardVideoViewModel: IMInterstitialDelegate {
    
    public func interstitialDidReceiveAd(_ interstitial: IMInterstitial!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
    }

    public func interstitialDidFinishLoading(_ interstitial: IMInterstitial!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
        interstitialOutput.on(.next(interstitial))
        adLoadedNotification(config)
    }

    public func interstitial(_ interstitial: IMInterstitial!, didFailToLoadWithError error: IMRequestStatus!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
        NSLog("Interstitial ad failed to load with error %@", error)
        errorNotification(config) { [weak self] in
            if let weakSelf = self {
               weakSelf.interstitialOutput.on(.error(error))
            }
        }
       
    }
  
    public func interstitialWillPresent(_ interstitial: IMInterstitial!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
        isPresent.accept(true)
        adExposedNotification(config)
    }
  
    public func interstitialDidPresent(_ interstitial: IMInterstitial!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
    }
    
    public func interstitial(_ interstitial: IMInterstitial!, didFailToPresentWithError error: IMRequestStatus!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
    }
  
    public func interstitialWillDismiss(_ interstitial: IMInterstitial!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
        if isPresent.value {
              willDismissAdOutput.onNext(interstitial)
             NotificationCenter.default.post(name: Notification.Name.Advertise.inVideoViewModelWillDismiss, object: config)
        }
    }
   
    public func interstitialDidDismiss(_ interstitial: IMInterstitial!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
        if isPresent.value {
             didDismissAdOutput.onNext(interstitial)
        }
    }
   
    public func interstitial(_ interstitial: IMInterstitial!, didInteractWithParams params: [AnyHashable : Any]!) {
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
    }
  
    public func userWillLeaveApplication(from interstitial: IMInterstitial!){
        adClickNotification(config)
    }
    
}
