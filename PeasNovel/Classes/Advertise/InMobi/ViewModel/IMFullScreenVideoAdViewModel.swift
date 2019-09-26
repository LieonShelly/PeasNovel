//
//  IMFullScreenVideoAdViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/10.
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

class IMFullScreenVideoAdViewModel: NSObject, Advertiseable {
    var interstitial: IMInterstitial?
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    
    /// output:
    let interstitialOutput: PublishSubject<IMInterstitial> = .init()
    let willDismissAdOutput:  PublishSubject<IMInterstitial> = .init()
    let didDismissAdOutput:  PublishSubject<IMInterstitial> = .init()
    var config: LocalAdvertise?
    var timer: Timer?
    var isPresent: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    convenience init(_ config: LocalAdvertise) {
        self.init()
        self.config = LocalAdvertise(config)
        self.interstitial = IMInterstitial(placementId: Int64(config.ad_position_id) ?? 0, delegate: self)
        self.interstitial?.load()
        let isPresent = self.isPresent
        let interstitialOutput = self.interstitialOutput
        
        timer = Timer(timeInterval: 5, repeats: true) {[weak self] (timer) in
            if isPresent.value == false {
               self?.errorNotification(config, errorCallBack: {
                    interstitialOutput.onError(AppError(message: "广告加载失败", code: ErrorCode.other))
                })
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
        
    }
    
    deinit {
        print("IMFullScreenVideoAdViewModel -- deinit")
        timer?.invalidate()
        timer = nil
    }
}


extension IMFullScreenVideoAdViewModel: IMInterstitialDelegate {
  
    public func interstitialDidReceiveAd(_ interstitial: IMInterstitial!) {
        /// 上报广告加载
        adLoadedNotification(config)
       
    }
   
    public func interstitialDidFinishLoading(_ interstitial: IMInterstitial!) {
        timer?.invalidate()
        timer = nil
        interstitialOutput.on(.next(interstitial))
       
    }
   
    public func interstitial(_ interstitial: IMInterstitial!, didFailToLoadWithError error: IMRequestStatus!) {
        timer?.invalidate()
        timer = nil
        self.interstitial = nil
        interstitialOutput.on(.error(error))
    }
  
    public func interstitialWillPresent(_ interstitial: IMInterstitial!) {
        isPresent.accept(true)
        NSLog("[IMFullScreenVideoAdViewModel %@]", #function)
    }
  
    public func interstitialDidPresent(_ interstitial: IMInterstitial!) {
        /// 上报广告曝光
        adExposedNotification(config)
    }
  
    public func interstitial(_ interstitial: IMInterstitial!, didFailToPresentWithError error: IMRequestStatus!) {
        errorNotification(config) { [weak self] in
            if let weakSelf = self {
                weakSelf.interstitialOutput.on(.error(error))
            }
        }
    }
  
    public func interstitialWillDismiss(_ interstitial: IMInterstitial!) {
        if isPresent.value {
            willDismissAdOutput.onNext(interstitial)
            NotificationCenter.default.post(name: Notification.Name.Advertise.inVideoViewModelWillDismiss, object: config)
        }
    }
    
    public func interstitialDidDismiss(_ interstitial: IMInterstitial!) {
        didDismissAdOutput.onNext(interstitial)
    }
   
    public func interstitial(_ interstitial: IMInterstitial!, didInteractWithParams params: [AnyHashable : Any]!) {
        
    }
  
    public func userWillLeaveApplication(from interstitial: IMInterstitial!){
        adClickNotification(config)
    }
    
    
    
}
