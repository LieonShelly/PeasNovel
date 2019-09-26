//
//  GDTRewardVideoVIewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/5.
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

class GDTRewardVideoViewModel: NSObject, Advertiseable {
    fileprivate var rewardVideoAd:GDTRewardVideoAd!
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    
    /// output:
    let rewardVideoAdOutput: PublishSubject<GDTRewardVideoAd> = .init()
    let willDismissAdOutput:  PublishSubject<GDTRewardVideoAd> = .init()
    let didDismissAdOutput:  PublishSubject<GDTRewardVideoAd> = .init()
    var config: LocalAdvertise?
    var timer: Timer?
    var isPresent: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    convenience init(_ config: LocalAdvertise) {
        self.init()
        self.rewardVideoAd = GDTRewardVideoAd(appId: Constant.GDT.appID, placementId: config.ad_position_id)
        self.rewardVideoAd.delegate = self
        self.rewardVideoAd.load()
        self.config = config
       
        let rewardVideoAdOutput = self.rewardVideoAdOutput
        let isPresent = self.isPresent
        timer = Timer(timeInterval: 5, repeats: false) { (timer) in
            if isPresent.value == false {
                rewardVideoAdOutput.onError(AppError(message: "广告加载失败", code: ErrorCode.other))
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
        rewardVideoAd.load()
    }
    
    deinit {
        debugPrint("GDTRewardVideoVIewModel -- deinit")
        timer?.invalidate()
        timer = nil
    }
}

extension GDTRewardVideoViewModel: GDTRewardedVideoAdDelegate {
    
    func gdt_rewardVideoAdDidLoad(_ rewardedVideoAd: GDTRewardVideoAd!) {
        adLoadedNotification(config)
    }
    
    func gdt_rewardVideoAdVideoDidLoad(_ rewardedVideoAd: GDTRewardVideoAd!) {
        rewardVideoAdOutput.onNext(rewardedVideoAd)
    }
    
    func gdt_rewardVideoAdWillVisible(_ rewardedVideoAd: GDTRewardVideoAd!) {
          debugPrint("视频播放页即将打开")
         isPresent.accept(true)
    }
    
    func gdt_rewardVideoAdDidExposed(_ rewardedVideoAd: GDTRewardVideoAd!) {
        adExposedNotification(config)
    }
    
    func gdt_rewardVideoAdDidClicked(_ rewardedVideoAd: GDTRewardVideoAd!) {
        adClickNotification(config)
    }
    
    func gdt_rewardVideoAdDidClose(_ rewardedVideoAd: GDTRewardVideoAd!) {
        if isPresent.value {
            didDismissAdOutput.onNext(rewardedVideoAd)
        }
    }
    
    func gdt_rewardVideoAd(_ rewardedVideoAd: GDTRewardVideoAd!, didFailWithError error: Error!) {
        rewardVideoAdOutput.onError(error)
        errorNotification(config)
    }
    
    func gdt_rewardVideoAdDidRewardEffective(_ rewardedVideoAd: GDTRewardVideoAd!) {
        debugPrint("播放达到激励条件")
    }
    
    func gdt_rewardVideoAdDidPlayFinish(_ rewardedVideoAd: GDTRewardVideoAd!) {
        debugPrint("播放达到激励条件")
    }
    
}
