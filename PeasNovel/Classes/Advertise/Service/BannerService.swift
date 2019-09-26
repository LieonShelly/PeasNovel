//
//  CollectionCellBannerService.swift
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
import UIKit

class CollectionCellBannerService {
    
    static func chooseCell(_ config: LocalTempAdConfig, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            if let _ = Int64(config.localConfig.ad_position_id), let nativeAd = nativeAd as? IMNative {
                let cell = collectionView.dequeueCell(IMBannerCollectionViewCell.self, for: indexPath)
                cell.configBanner(nativeAd)
                return cell
            }
        default:
            break
        }
        return collectionView.dequeueCell(UICollectionViewCell.self, for: indexPath)
    }
}

class TableViewCellInfoService {
    static func chooseCell(_ config: LocalTempAdConfig, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            if let _ = Int64(config.localConfig.ad_position_id), let nativeAd = nativeAd as? IMNative {
                let cell = tableView.dequeueCell(IMInfoTableViewCell.self, for: indexPath)
                cell.config(nativeAd)
                return cell
            }
        case .GDT(let nativeAd):
            if let expressAdView = nativeAd as? GDTNativeExpressAdView {
                let cell = tableView.dequeueCell(GDTExpressAdTableViewCell.self, for: indexPath)
                cell.config(expressAdView)
                return cell
            } 
        case .todayHeadeline(let nativeAd):
            if let nativeAd = nativeAd as? BUNativeAd {
                let cell = tableView.dequeueCell(BUNativeFeedTableViewCell.self, for: indexPath)
                cell.config(nativeAd)
                return cell
            }
        default:
            break
        }
        return tableView.dequeueCell(UITableViewCell.self, for: indexPath)
    }
}


class TableViewCellBannerService {
    
    static func chooseCell(_ config: LocalTempAdConfig, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            if let _ = Int64(config.localConfig.ad_position_id), let nativeAd = nativeAd as? IMNative {
                let cell = tableView.dequeueCell(IMBannerTableViewCell.self, for: indexPath)
                cell.configBanner(nativeAd)
                return cell
            }
        case .GDT(let gdtView):
            if let gdtView = gdtView as? GDTUnifiedBannerView {
                let cell = tableView.dequeueCell(GDTBannerTableViewCell.self, for: indexPath)
                cell.configBannerView(gdtView)
                return cell
            }
        case .todayHeadeline(let nativeAd):
            if let nativeAd = nativeAd as? BUNativeAd {
                let cell = tableView.dequeueCell(BUBannerTableViewCell.self, for: indexPath)
                cell.config(nativeAd)
                return cell
            }
        default:
            break
        }
        return tableView.dequeueCell(UITableViewCell.self, for: indexPath)
    }
}


class ViewBannerSerVice {
    static func chooseBanner(_ inputconfig: LocalAdvertise?, bannerFrame: CGRect) -> UIView? {
        guard let config = inputconfig else {
            return nil
        }
        guard !config.is_close else {
            return nil
        }
        guard let adType = AdvertiseType(rawValue: config.ad_type) else {
            return nil
        }
        switch adType {
        case .inmobi:
            let bannerView = IMBannerView.loadView()
            bannerView.frame = bannerFrame
            return bannerView
        case .todayHeadeline:
            let bannerView = BUNativeBannerView.loadView()
             bannerView.frame = bannerFrame
            return bannerView
        case .GDT:
            let bannerView = GDTBannerView.loadView()
            bannerView.frame = bannerFrame
            return bannerView
        default:
            return nil
        }
    }
    
    @discardableResult
    static func configData(_ config: LocalTempAdConfig, bannerView: UIView?) -> LocalTempAdConfig {
        bannerView?.isHidden = false
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            guard let banner = bannerView as? IMBannerView, let nativeAd = nativeAd as? IMNative else {
                return config
            }
            banner.config(nativeAd)
        case .todayHeadeline(let nativeAd):
            guard let banner = bannerView as? BUNativeBannerView, let nativeAd = nativeAd as? BUNativeAd else {
                return config
            }
            banner.config(nativeAd)
        case .GDT(let gdtBannerView):
            guard let banner = bannerView as? GDTBannerView, let gdtBanner = gdtBannerView as? GDTUnifiedBannerView  else {
                return config
            }
            banner.configBannerView(gdtBanner)
        default:
            break
        }
        return config
    }
}

/// 信息流广告视图
class ViewInfoService {
    static func chooseBanner(_ config: LocalAdvertise, viewFrame: CGRect) -> UIView? {
        guard let adType = AdvertiseType(rawValue: config.ad_type), !config.is_close else {
            return nil
        }
        switch adType {
        case .inmobi:
            let bannerView = IMInfoView.loadView()
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
            guard let banner = view as? IMInfoView, let nativeAd = nativeAd as? IMNative else {
                return
            }
            banner.config(nativeAd)
        default:
            break
        }
    }
    
}





class CollectionCellOneTitleService {
    
    static func chooseCell(_ config: LocalTempAdConfig, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            if let _ = Int64(config.localConfig.ad_position_id), let nativeAd = nativeAd as? IMNative {
                let cell = collectionView.dequeueCell(IMInfoOneTitleCollectionViewCell.self, for: indexPath)
                cell.config(nativeAd)
                return cell
            }
        case .GDT(let nativeAd):
            if let nativeAd = nativeAd as? GDTNativeExpressAdView {
                let cell = collectionView.dequeueCell(GDTOneImageNativeExpressCollectionViewCell.self, for: indexPath)
                cell.config(nativeAd)
                return cell
            } 
        case .todayHeadeline(let nativeAd):
            if let nativeAd = nativeAd as? BUNativeAd {
                let cell = collectionView.dequeueCell(BUInfoOneTitleCollectionViewCell.self, for: indexPath)
                cell.config(nativeAd)
                return cell
            }
        default:
            break
        }
        return collectionView.dequeueCell(UICollectionViewCell.self, for: indexPath)
    }
}
