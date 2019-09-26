//
//  BUFullScreenVideoViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class BUFullScreenVideoViewModel: NSObject, Advertiseable {
    fileprivate var fullscreenVideoAd: BUFullscreenVideoAd!
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let fullScreenVideoAdOutput: PublishSubject<BUFullscreenVideoAd> = .init()
    let willDismissAdOutput:  PublishSubject<BUFullscreenVideoAd> = .init()
    var config: LocalAdvertise?
    var timer: Timer?
    var isPresent: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let bag = DisposeBag()
    
    convenience init(_ config: LocalAdvertise) {
        self.init()
        fullscreenVideoAd = BUFullscreenVideoAd(slotID: config.ad_position_id)
        fullscreenVideoAd.delegate = self
        fullscreenVideoAd.loadData()
        self.config = LocalAdvertise(config)
        let isPresent = self.isPresent        
        timer = Timer(timeInterval: 10, repeats: false) { [weak self] (timer) in
            if isPresent.value == false {
                if let weakSelf = self  {
                    weakSelf.errorNotification(config) {
                        weakSelf.fullScreenVideoAdOutput.onError(AppError(message: "广告加载失败", code: ErrorCode.other))
                    }
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    deinit {
        debugPrint("BUFullScreenVideoViewModel - deinit")
    }
}


extension BUFullScreenVideoViewModel: BUFullscreenVideoAdDelegate {
    func fullscreenVideoMaterialMetaAdDidLoad(_ fullscreenVideoAd: BUFullscreenVideoAd!) {
        fullScreenVideoAdOutput.onNext(fullscreenVideoAd)
    }
   
    func fullscreenVideoAd(_ fullscreenVideoAd: BUFullscreenVideoAd!, didFailWithError error: Error!) {
        errorNotification(config) { [weak self] in
            if let weakSelf = self {
                weakSelf.fullScreenVideoAdOutput.on(.error(error))
            }
        }
    }
    
    func fullscreenVideoAdVideoDataDidLoad(_ fullscreenVideoAd: BUFullscreenVideoAd!) {
        adLoadedNotification(config)
    }
    
    func fullscreenVideoAdDidClickSkip(_ fullscreenVideoAd: BUFullscreenVideoAd!) {
        if isPresent.value {
            willDismissAdOutput.onNext(fullscreenVideoAd)
            NotificationCenter.default.post(name: Notification.Name.Advertise.inVideoViewModelWillDismiss, object: config)
        }
    }
    
    func fullscreenVideoAdDidVisible(_ fullscreenVideoAd: BUFullscreenVideoAd!) {
        isPresent.accept(true)
        adExposedNotification(config)
    }
    
    func fullscreenVideoAdDidClick(_ fullscreenVideoAd: BUFullscreenVideoAd!) {
        adClickNotification(config)
    }
    
    func fullscreenVideoAdDidClose(_ fullscreenVideoAd: BUFullscreenVideoAd!) {
        if isPresent.value {
            willDismissAdOutput.onNext(fullscreenVideoAd)
            NotificationCenter.default.post(name: Notification.Name.Advertise.inVideoViewModelWillDismiss, object: config)
        }
    }
}
