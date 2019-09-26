//
//  RaderAdService.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/9.
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
import Alamofire

class ReaderAdService {
    
    static func shouldShowFullScreenAd() -> (isShow: Bool, config: LocalAdvertise?) {
        if me.isVipValid {
            return (false, nil)
        }
        if ReaderFiveChapterNoAd.isReadFiveAd() {
            return (false, nil)
        }
        let config = AdvertiseService.advertiseConfig(.readerPageFullScreenAd)
        return (!(config?.is_close ?? true), config)
    }
    
    static func shouldShowChapterpageAd() -> (isShow: Bool, config: LocalAdvertise?)  {
        if me.isVipValid {
            return (false, nil)
        }
        if ReaderFiveChapterNoAd.isReadFiveAd() {
            return (false, nil)
        }
        let config = AdvertiseService.advertiseConfig(.readerPageInfoAd)
        return (!(config?.is_close ?? true), config)
    }
    
    static func shouldShowBottomBannerAd() -> (isShow: Bool, config: LocalAdvertise?){
        if me.isVipValid {
            return (false, nil)
        }
        if ReaderFiveChapterNoAd.isReadFiveAd() {
            return (false, nil)
        }
        let config = AdvertiseService.advertiseConfig(.readerBottomBanner)
        return (!(config?.is_close ?? true), config)
    }
    
    static func shouldShowChapterConnectionAd() -> (isShow: Bool, config: LocalAdvertise?) {
        if me.isVipValid {
            return (false, nil)
        }
        if ReaderFiveChapterNoAd.isReadFiveAd() {
            return (false, nil)
        }
        let config = AdvertiseService.advertiseConfig(.readerPerPageBigPic)
        return (!(config?.is_close ?? true), config)
    }
    
    ///  每个章节的结束，或者加载上一章时，弹出广告
    static  func presentChapterConnectionAd(_ presentVC: ReaderController,
                                            title: String,
                                            isShowBotton: Bool) {
        if let chapterConnectionVc = createChapterConnectionVC(presentVC.currenntReadChapterCount.value, title: title, isShowBotton: isShowBotton)  {
            chapterConnectionVc.modalPresentationStyle = .custom
            chapterConnectionVc.modalTransitionStyle = .crossDissolve
            navigator.present(NavigationViewController(rootViewController: chapterConnectionVc))
        }
    }
    
    /// 处于免广告看五章节中。每看一章加1
    static func addWatchFiveChapterCount(_ title: String) {
        if ReaderFiveChapterNoAd.isReadFiveAd() {
            ReaderFiveChapterNoAd.addReadChapterCount(chapterTitle: title)
        }
    }
    
    static func createChapterConnectionVC(_ currenntReadChapterCount: Int,
                                          title: String,
                                         isShowBotton: Bool = false) -> UIViewController? {
        if !shouldShowChapterConnectionAd().isShow {
            return nil
        }
        /// 网络不可用直接返回
        let manager = NetworkReachabilityManager()
        guard let isReachable = manager?.isReachable, isReachable == true else {
            return nil
        }
        var chapterConnectionVc: ChapterConnectionAdViewController?
        /// 每5章的广告
        if currenntReadChapterCount % 5 == 0 && currenntReadChapterCount != 0 {
            var innfoConfig: LocalAdvertise?
            var bannerConfig: LocalAdvertise?
            if let readerPer5Config = AdvertiseService.advertiseConfig(AdPosition.readerPer5PageBigPic), !readerPer5Config.is_close {
                innfoConfig = readerPer5Config
            }
            
            if  let readerPer5BannerConfig = AdvertiseService.advertiseConfig(AdPosition.readerPer5PgeBottomBanner), !readerPer5BannerConfig.is_close {
                bannerConfig = readerPer5BannerConfig
            }
            if let innfoConfig = innfoConfig {
                if let bannerConfig = bannerConfig {
                    chapterConnectionVc = ChapterConnectionAdViewController(ChapterConnectionAdViewModel(innfoConfig, title: title), isShowBottomBanner: isShowBotton, bannerConfig: bannerConfig)
                } else {
                    chapterConnectionVc = ChapterConnectionAdViewController(ChapterConnectionAdViewModel(innfoConfig, title: title), isShowBottomBanner: isShowBotton)
                }
            }
        } else if let readerPerPageConfig = AdvertiseService.advertiseConfig(AdPosition.readerPerPageBigPic), !readerPerPageConfig.is_close {  /// 每个章节衔接页广告
            chapterConnectionVc = ChapterConnectionAdViewController(ChapterConnectionAdViewModel(readerPerPageConfig, title: title), isShowBottomBanner: isShowBotton)
        }
        return  chapterConnectionVc
    }
    
    /// 全屏广告(图片)View
    static func choosePicAdView(_ config: LocalAdvertise, viewFrame: CGRect) -> UIView? {
        guard let adType = AdvertiseType(rawValue: config.ad_type), !config.is_close else {
            return nil
        }
        switch adType {
        case .GDT:
            let bannerView = GDTNativeExpressAdInfoView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        case .todayHeadeline:
            let bannerView = BUPicView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        default:
            return nil
        }
    }
    
    /// 全屏广告(图片) - 配置数据
    static func configPicAdData(_ config: LocalTempAdConfig, view: UIView?) {
        let adType = config.adType
        switch adType {
        case .GDT(let nativeAd):
            guard let banner = view as? GDTNativeExpressAdInfoView else {
                return
            }
            guard  let nativeAd = nativeAd as? GDTNativeExpressAdView else {
                return
            }
            banner.config(nativeAd)
        case .todayHeadeline(let nativeAd):
            guard let banner = view as? BUPicView, let nativeAd = nativeAd as? BUNativeAd else {
                return
            }
            banner.config(nativeAd)
        default:
            break
        }
    }
    
}



class ReaderViewInfoService {
    

    
    static func choosePageInfoAdView(_ config: LocalAdvertise, viewFrame: CGRect) -> UIView? {
        guard let adType = AdvertiseType(rawValue: config.ad_type), !config.is_close else {
            return nil
        }
        switch adType {
        case .inmobi:
            let bannerView = IMReaderPageInfoView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        case .GDT:
            let bannerView = GDTNativeExpressAdInfoView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        case .todayHeadeline:
            let bannerView = BUNativeFeedView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        default:
            return nil
        }
    }
    
    static func configPageInfoData(_ config: LocalTempAdConfig, view: UIView?) {
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            guard let banner = view as? IMReaderPageInfoView, let nativeAd = nativeAd as? IMNative else {
                return
            }
            banner.config(nativeAd)
        case .GDT(let nativeAd):
            guard let banner = view as? GDTNativeExpressAdInfoView else {
                return
            }
            guard  let nativeAd = nativeAd as? GDTNativeExpressAdView else {
                return
            }
            banner.config(nativeAd)
        case .todayHeadeline(let nativeAd):
            guard let banner = view as? BUNativeFeedView, let nativeAd = nativeAd as? BUNativeAd else {
                return
            }
            banner.config(nativeAd)
        default:
            break
        }
    }
    
    static func chooseInfoAdView(_ config: LocalAdvertise, viewFrame: CGRect) -> UIView? {
        guard let adType = AdvertiseType(rawValue: config.ad_type), !config.is_close else {
            return nil
        }
        switch adType {
        case .inmobi:
            let bannerView = IMReaderChapterinfoAdView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        case .GDT:
            let bannerView = GDTNativeExpressAdInfoView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        case .todayHeadeline:
            let bannerView = BUNativeFeedView.loadView()
            bannerView.frame = viewFrame
            return bannerView
        default:
            return nil
        }
    }
    
    static func configData(_ config: LocalTempAdConfig, view: UIView?) {
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            guard let banner = view as? IMReaderChapterinfoAdView, let nativeAd = nativeAd as? IMNative else {
                return
            }
            banner.config(nativeAd)
        case .GDT(let nativeAd):
            guard let banner = view as? GDTNativeExpressAdInfoView else {
                return
            }
           guard  let nativeAd = nativeAd as? GDTNativeExpressAdView else {
                return
            }
            banner.config(nativeAd)
        case .todayHeadeline(let nativeAd):
            guard let banner = view as? BUNativeFeedView, let nativeAd = nativeAd as? BUNativeAd else {
                return
            }
            banner.config(nativeAd)
        default:
            break
        }
    }
    
}
