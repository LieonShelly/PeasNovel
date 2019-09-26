//
//  GDTBannerViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/28.
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

class GDTBannerConfig: Advertiseable {
    var isAutoRefresh: Bool {
        return true
    }
}

class GDTBannerViewModel: NSObject, Advertiseable {
    var bannerView:GDTUnifiedBannerView!
    /// input
    let bag = DisposeBag()
    /// output
    let nativeAdOutput: PublishSubject<GDTUnifiedBannerView> = .init()
    var config: LocalAdvertise?
    var handler: Advertiseable?
    weak var holderVC: UIViewController?
    
    convenience init(_ config: LocalAdvertise,
                     outterConfig: Advertiseable? = GDTBannerConfig(),
                     viewController: UIViewController) {
        self.init()
        self.config = LocalAdvertise(config)
        bannerView = GDTUnifiedBannerView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 75)), appId: Constant.GDT.appID, placementId: config.ad_position_id, viewController: viewController)
        bannerView.delegate = self
        bannerView.loadAdAndShow()
        bannerView.autoSwitchInterval = 30
        self.holderVC = viewController
        self.handler = outterConfig
        
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period:  RxTimeInterval.seconds(30), scheduler: MainScheduler.instance)
            .filter {_ in outterConfig?.isAutoRefresh == true }
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
        debugPrint("deinit- GDTBannerViewModel")
    }
    
}

extension GDTBannerViewModel: GDTUnifiedBannerViewDelegate {
    
    func unifiedBannerViewFailed(toLoad unifiedBannerView: GDTUnifiedBannerView, error: Error) {
        debugPrint("ADERROR-GDTBannerViewModel-didFailToLoadWithError:\(error.localizedDescription)")
        handler!.errorNotification(config) {[weak self] in
            self?.nativeAdOutput.onError(error)
        }
    }
    
    func unifiedBannerViewDidLoad(_ unifiedBannerView: GDTUnifiedBannerView) {
        nativeAdOutput.onNext(bannerView)
        handler!.adLoadedNotification(config)
        handler!.adExposedNotification(config)
    }

    func unifiedBannerViewWillLeaveApplication(_ unifiedBannerView: GDTUnifiedBannerView) {
        if let config = self.config {
           handler!.adClickNotification(config)
        }
    }

    func unifiedBannerViewWillExpose(_ unifiedBannerView: GDTUnifiedBannerView) {
        
    }
    
    func unifiedBannerViewWillClose(_ unifiedBannerView: GDTUnifiedBannerView) {
        if let config = config {
            bannerView = nil
            bannerView = GDTUnifiedBannerView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 75)), appId: Constant.GDT.appID, placementId: config.ad_position_id, viewController: holderVC!)
            bannerView.delegate = self
            bannerView.loadAdAndShow()
            if !handler!.adClickHandler(config) {
                navigator.pushChargeVC()
            }
        }
    }
 
}
