//
//  BURewardVideoViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class BURewardVideoViewModel: NSObject, Advertiseable {
    fileprivate var rewardedVideoAd: BURewardedVideoAd!
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let rewardVideoAdOutput: PublishSubject<BURewardedVideoAd> = .init()
    let willDismissAdOutput:  PublishSubject<BURewardedVideoAd> = .init()
    var config: LocalAdvertise?
    var isPresent: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let bag = DisposeBag()
    
    convenience init(_ config: LocalAdvertise) {
        self.init()
        let model = BURewardedVideoModel()
        model.userId = me.user_id ?? "123"
        model.isShowDownloadBar = true
        rewardedVideoAd = BURewardedVideoAd(slotID: config.ad_position_id, rewardedVideoModel: model)
        rewardedVideoAd.delegate = self
        self.config = LocalAdvertise(config)
        rewardedVideoAd.loadData()
    }
    
    deinit {

        debugPrint("BURewardVideoViewModel - deinit")
    }
}


extension BURewardVideoViewModel: BURewardedVideoAdDelegate {
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: BURewardedVideoAd) {
        rewardVideoAdOutput.onNext(rewardedVideoAd)
        adLoadedNotification(config)
    }
    
    func rewardedVideoAdVideoDidLoad(_ rewardedVideoAd: BURewardedVideoAd) {
        
    }
    
    func rewardedVideoAdDidVisible(_ rewardedVideoAd: BURewardedVideoAd) {
         isPresent.accept(true)
        adExposedNotification(config)
    }
    
    func rewardedVideoAdDidClick(_ rewardedVideoAd: BURewardedVideoAd) {
        adClickNotification(config)
    }
    
    func rewardedVideoAdWillVisible(_ rewardedVideoAd: BURewardedVideoAd) {
       
    }
    
    func rewardedVideoAdDidClose(_ rewardedVideoAd: BURewardedVideoAd) {
        if isPresent.value {
            willDismissAdOutput.onNext(rewardedVideoAd)
            NotificationCenter.default.post(name: Notification.Name.Advertise.inVideoViewModelWillDismiss, object: config)
        }
    }
    
    func rewardedVideoAd(_ rewardedVideoAd: BURewardedVideoAd, didFailWithError error: Error) {
        errorNotification(config) { [weak self] in
            if let weakSelf = self {
                weakSelf.rewardVideoAdOutput.on(.error(error))
            }
        }
    }
    
    func rewardedVideoAdDidPlayFinish(_ rewardedVideoAd: BURewardedVideoAd, didFailWithError error: Error) {

    }
    
    func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: BURewardedVideoAd) {
        
    }
    
    func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: BURewardedVideoAd, verify: Bool) {
        
    }
}
