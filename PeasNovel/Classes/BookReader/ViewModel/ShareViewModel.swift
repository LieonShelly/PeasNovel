//
//  ShareViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import Moya
import RxMoya
import RxCocoa
import RxSwift


class ShareViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let shareData: BehaviorRelay<ShareModel> = .init(value: ShareModel())
    
    /// output
    let shareResponseOutput: BehaviorRelay<ShareResponse> = .init(value: ShareResponse())
    
    init(_ provider: MoyaProvider<BookReaderService> = MoyaProvider<BookReaderService>(), param: [String: String]) {
         viewDidLoad.flatMap {
            provider.rx.request(.shareContent(param))
                .model(ShareResponse.self)
                .asObservable()
            }.bind(to: shareResponseOutput)
            .disposed(by: bag)
        
        shareResponseOutput
            .asObservable()
            .map {$0.data }
            .unwrap()
            .bind(to: shareData)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.shareSuccess)
            .debug()
            .map { ($0.object as? SSDKContentEntity, $0.userInfo as? [String: Any]) }
            .debug()
            .subscribe(onNext: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                var reporParam = param
                if  let type = $0.1?["type"] as? SSDKPlatformType {
                    reporParam["share_id"] = weakSelf.shareData.value.share_id ?? ""
                    if type == SSDKPlatformType.subTypeWechatSession {
                          reporParam["share_type"] = "1"
                    } else if type == SSDKPlatformType.subTypeWechatTimeline {
                          reporParam["share_type"] = "2"
                    } else {
                          reporParam["share_type"] = "3"
                    }
                   NotificationCenter.default.post(name: NSNotification.Name.Statistic.bookShareSuccess, object: reporParam)
                }
            })
            .disposed(by: bag)
    }

}

