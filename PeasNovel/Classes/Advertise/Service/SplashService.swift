//
//  SplashViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/6.
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
import UIKit

class SplashService {
    
    static func chooseSplashVC(_ config: LocalAdvertise) -> UIViewController? {
        guard let adType = AdvertiseType(rawValue: config.ad_type) else {
           return TabBarController()
        }
        switch adType {
        case .inmobi:
            if let _ = Int64(config.ad_position_id) {
                return IMSplashViewController(IMSplashViewModel(config))
            }
        case .todayHeadeline:
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let rootVC = TabBarController()
            appdelegate.window?.rootViewController = rootVC
            appdelegate.window?.makeKeyAndVisible()
            let splashView = BUSplashView(config)
            splashView.frame = UIScreen.main.bounds
            rootVC.view.addSubview(splashView)
            return nil
        case .GDT:
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let rootVC = GDTSplashAdViewController(config)
            appdelegate.window?.rootViewController = rootVC
            appdelegate.window?.makeKeyAndVisible()
            if let splashAd = GDTSplashAd.init(appId: Constant.GDT.appID, placementId: config.ad_position_id) {
                appdelegate.gdtSplash = splashAd
                splashAd.delegate = appdelegate
                splashAd.fetchDelay = 3
                let bottomView = GDTSplashBottomView.loadView()
                bottomView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.size.width, height: 74 + UIDevice.current.safeAreaInsets.bottom))
                let window = UIApplication.shared.keyWindow!
                splashAd.loadAndShow(in: window, withBottomView: bottomView, skip: nil)
            }
            return nil
        default:
            return TabBarController()
        }
        return TabBarController()
    }
    
    static func recordAppLeaveTime() {
        let timeInterval = Date().timeIntervalSince1970
        let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
        let record = AppTime()
        record.id = "com.youhe.peas.novel"
        record.leaveAppTime = Int(timeInterval)
        try? realm?.write {
            realm?.add(record, update: .all)
        }
    }
    
    static func displayFullScreenAd(_ application: UIApplication) {
        let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
        let currentTime = Int(Date().timeIntervalSince1970)
        guard let record = realm?.objects(AppTime.self).first else {
            return
        }
        guard currentTime - record.leaveAppTime  > 5 * 60 else {
            return
        }
        guard let config = AdvertiseService.advertiseConfig(AdPosition.fiveMinutesSplash), !config.is_close,  let adType = AdvertiseType(rawValue: config.ad_type)  else {
            return
        }
        switch adType {
        case .inmobi:
            let vcc = IMHotSplashViewController(IMHotSplashViewModel(config))
            vcc.modalPresentationStyle = .custom
            vcc.modalTransitionStyle = .crossDissolve
            navigator.present(vcc)
        case .todayHeadeline:
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                let splashView = BUSplashView(config)
                splashView.frame = UIScreen.main.bounds
                rootVC.view.addSubview(splashView)
            }
        case .GDT:
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            if let splashAd = GDTSplashAd.init(appId: Constant.GDT.appID, placementId: config.ad_position_id) {
                appdelegate.gdtSplash = splashAd
                splashAd.delegate = appdelegate.gdtFiveDelegator
                splashAd.fetchDelay = 3
                let bottomView = GDTSplashBottomView.loadView()
                bottomView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.size.width, height: 74 + UIDevice.current.safeAreaInsets.bottom))
                let window = UIApplication.shared.keyWindow!
                splashAd.loadAndShow(in: window, withBottomView: bottomView, skip: nil)
            }
        default:
            break
        }
    }
}

extension AppDelegate: GDTSplashAdDelegate, Advertiseable {
   
    func splashAdFail(toPresent splashAd: GDTSplashAd!, withError error: Error!) {
           gdtSplash = nil
        let config = AdvertiseService.advertiseConfig(AdPosition.splash)
        errorNotification(config)
        NotificationCenter.default.post(name: NSNotification.Name.Advertise.splashNeedDismiss, object: nil)
    }
    
    func splashAdExposured(_ splashAd: GDTSplashAd!) {
        let config = AdvertiseService.advertiseConfig(AdPosition.splash)
        adExposedNotification(config)
    }
    
    func splashAdSuccessPresentScreen(_ splashAd: GDTSplashAd!) {
        let config = AdvertiseService.advertiseConfig(AdPosition.splash)
        adLoadedNotification(config)
    }
    
    func splashAdWillDismissFullScreenModal(_ splashAd: GDTSplashAd!) {
        NotificationCenter.default.post(name: NSNotification.Name.Advertise.splashNeedDismiss, object: nil)
    }
    
    func splashAdWillClosed(_ splashAd: GDTSplashAd!) {
        NotificationCenter.default.post(name: NSNotification.Name.Advertise.splashNeedDismiss, object: nil)
    }
    
    func splashAdClicked(_ splashAd: GDTSplashAd!) {
        let config = AdvertiseService.advertiseConfig(AdPosition.splash)
        adClickNotification(config)
        gdtSplash = nil
    }
}



class FiveMinuteGDTFlashDelegator: NSObject, GDTSplashAdDelegate, Advertiseable  {
    
    func splashAdFail(toPresent splashAd: GDTSplashAd!, withError error: Error!) {
        (UIApplication.shared.delegate as! AppDelegate).gdtSplash = nil
         let config = AdvertiseService.advertiseConfig(AdPosition.fiveMinutesSplash)
        errorNotification(config)
    }
    
    func splashAdExposured(_ splashAd: GDTSplashAd!) {
        let config = AdvertiseService.advertiseConfig(AdPosition.fiveMinutesSplash)
        adExposedNotification(config)
    }
    
    func splashAdSuccessPresentScreen(_ splashAd: GDTSplashAd!) {
        let config = AdvertiseService.advertiseConfig(AdPosition.fiveMinutesSplash)
        adLoadedNotification(config)
    }
    
    
    func splashAdClicked(_ splashAd: GDTSplashAd!) {
        let config = AdvertiseService.advertiseConfig(AdPosition.fiveMinutesSplash)
        adClickNotification(config)
         (UIApplication.shared.delegate as! AppDelegate).gdtSplash = nil
    }
}
