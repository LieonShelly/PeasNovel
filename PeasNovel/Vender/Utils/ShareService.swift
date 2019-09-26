//
//  ShareService.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import PKHUD
import Kingfisher
import RxCocoa

class ShareService {
    
    let bag = DisposeBag()
    
   func share(_ platform: SSDKPlatformType, text: String?, imageURLStr: String? = nil, urlStr: String?, title: String?) {

        let params = NSMutableDictionary()
        guard let urlStr1 = urlStr,  let url = URL(string: urlStr1) else {
            HUD.flash(HUDContentType.label("分享链接不能为空"), delay: 2.0)
            return
        }
        
        guard let imageURLStr1 = imageURLStr, let imageURL = URL(string: imageURLStr1) else {
             HUD.flash(HUDContentType.label("分享的标题图片不能为空"), delay: 2.0)
             return
        }
        let imageURLRx = BehaviorRelay(value: imageURL)
        imageURLRx.asObservable()
                  .downlaodImage()
                  .unwrap()
            .subscribe(onNext: { (shareImage) in
                let shareImages = [shareImage]
                params.ssdkSetupShareParams(byText: text, images: shareImages, url:url, title: title, type: .auto)
                ShareSDK.share(platform, parameters: params) { (state, _, entity, eror) in // SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity,  NSError *error\
                     NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.shared, object: entity, userInfo: ["type": platform])
                    switch state {
                    case .success:
                        NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.shareSuccess, object: entity, userInfo: ["type": platform])
                        HUD.flash(HUDContentType.label("分享成功"), delay: 2.0)
                    case .fail:
                        print("fail:", eror?.localizedDescription ?? "")
                        HUD.flash(HUDContentType.label("分享失败"), delay: 2.0)
                    case .cancel:
                        print("cancle")
                        HUD.flash(HUDContentType.label("分享取消"), delay: 2.0)
                    default:
                        break
                    }
                }
            })
    .disposed(by: bag)
        
      
    }
}



class ShareResponse: BaseResponse<ShareModel> {}


class ShareModel: Model {
    var title: String?
    var title_url: String?
    var text: String?
    var img_url: String?
    var url: String?
    var share_id: String?
    
}
