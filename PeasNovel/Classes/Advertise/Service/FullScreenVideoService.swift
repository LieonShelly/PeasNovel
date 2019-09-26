//
//  FullScreenVideoService.swift
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
import UIKit

/// 全屏视频广告
class FullScreenVideoService {

    static func chooseVC(_ adPostion: AdPosition) -> UIViewController? {
        guard let config = AdvertiseService.advertiseConfig(adPostion), !config.is_close else {
            return nil
        }
        let vcc = FullScreenVideoViewController(FullScreenVideoViewModel(config))
         vcc.modalPresentationStyle = .overCurrentContext
        return vcc
    }
}

/// 激励视频广告
class RewardVideoService {
    
    static func chooseVC(_ adPostion: AdPosition, isForceOpen: Bool = false) -> UIViewController? {
     
        guard let config = AdvertiseService.advertiseConfig(adPostion) else {
            return nil
        }
        var isClose = config.is_close
        if isForceOpen {
            isClose = false
        }
        guard  !isClose else {
            return nil
        }
        let vcc = RewardAdViewController(RewardAdViewModel(config))
        vcc.modalPresentationStyle = .overCurrentContext
        return vcc
    }
}
