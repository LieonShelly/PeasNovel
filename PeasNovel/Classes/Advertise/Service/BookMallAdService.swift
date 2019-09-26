//
//  BookMallAdService.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/8.
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

class BookMallAdService {

    static func chooseCell(_ config: LocalTempAdConfig, collectionView: UICollectionView, indexPath: IndexPath, didTapAd:(() -> Void)?) -> UICollectionViewCell {
        let adType = config.adType
        switch adType {
        case .inmobi(let nativeAd):
            if let _ = Int64(config.localConfig.ad_position_id), let nativeAd = nativeAd as? IMNative{
                let cell = collectionView.dequeueCell(IMInfoCollectionViewCell.self, for: indexPath)
                cell.config(nativeAd, didTapAd:didTapAd)
                return cell
            }
        case .GDT(let nativeAd): 
            if let expressAdView = nativeAd as? GDTNativeExpressAdView {
                let cell = collectionView.dequeueCell(GDTNativeExpressAdCollectionViewCell.self, for: indexPath)
                cell.config(expressAdView)
                return cell
            } 
        case .todayHeadeline(let nativeAd):
            if let nativeAd = nativeAd as? BUNativeAd {
                let cell = collectionView.dequeueCell(BUNativeFeedCollectionViewCell.self, for: indexPath)
                cell.config(nativeAd)
                return cell
            }
        default:
            break
        }
        return collectionView.dequeueCell(UICollectionViewCell.self, for: indexPath)
    }
}
    
    



