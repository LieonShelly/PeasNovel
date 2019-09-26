//
//  RootViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/1/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxMoya
import Moya
import RxSwiftExt
import RxCocoa
import RxRealm
import Realm
import RealmSwift


class RootViewModel {

    let viewDidLoad:        PublishSubject<Void>    = .init()
    let launchImageVM: PublishSubject<LaunchAlertViewModel> = .init()
    let bag = DisposeBag()
    
    init() {
        
        viewDidLoad.asObservable()
            .subscribe(onNext: { (_) in
                print("viewDidLoad-viewDidLoad")
            })
            .disposed(by: bag)
        
        let provider = MoyaProvider<UserCenterService>()
    
        Observable.just(me)
            .filter { $0.user_id == nil}
            .flatMap { _ in
                provider
                    .rx
                    .request(.deviceLogin)
            }
            .userUpdate()
            .disposed(by: bag)
        
        Observable.just(me)
            .map { $0.user_id}
            .unwrap()
            .filter { !$0.isEmpty }
            .flatMap { _ in
                provider
                    .rx
                    .request(.userInfo)
            }
            .userUpdate()
            .disposed(by: bag)

        NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Account.expired)
            .flatMap{_ in
                provider
                    .rx
                    .request(.defaultLogin)
            }
            .userUpdate()
            .disposed(by: bag)
        
        Observable.merge([NotificationCenter
                            .default
                            .rx
                            .notification(Notification.Name.Account.needUpdate).mapToVoid(),
                          NotificationCenter
                            .default
                            .rx
                            .notification(Notification.Name.UIUpdate.readingTime).mapToVoid(),
                          NotificationCenter
                            .default
                            .rx
                            .notification(Notification.Name.AppleIAP.chargeSuccess).mapToVoid(),
                          ])
            .flatMap{_ in
                provider
                    .rx
                    .request(.userInfo)
            }
            .userUpdate()
            .disposed(by: bag)
        
        
        NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Account.deviceLogin)
            .flatMap{_ in
                provider
                    .rx
                    .request(.deviceLogin)
            }
            .userUpdate()
            .disposed(by: bag)
        
        let adprovider =  MoyaProvider<AdvertiseConfigService>()
        let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
        
        viewDidLoad.asObservable()
            .flatMap {
                adprovider
                    .rx
                    .request(.configList)
                    .model(AdvertiseConfigResponse.self)
                    .asObservable()
        }
            .debug()
            .asObservable()
            .map { $0.data }
            .unwrap()
            .map { (configList) -> [LocalAdvertise] in
                var locals: [LocalAdvertise] = []
                for config in configList {
                    if let ad_type_lists =   config.ad_type_lists {
                        for adType in ad_type_lists {
                            locals.append(LocalAdvertise(adType, advetiseConfig: config))
                        }
                    }
                }
                return locals
            }
            .subscribe(onNext: { (locals) in
                if locals.isEmpty {
                    if let records = realm?.objects(LocalAdvertise.self), !records.isEmpty {
                        try? realm?.write {
                            records.setValue(true, forKeyPath: "is_close")
                        }
                    }
                } else {
                    let adPositions = locals.map { $0.ad_position }
                    if let closeReslut = realm?.objects(LocalAdvertise.self).filter(NSPredicate(format: "NOT ad_position IN %@", adPositions)), !closeReslut.isEmpty {
                        try? realm?.write {
                             closeReslut.setValue(true, forKeyPath: "is_close")
                        }
                    }
                    for local in locals {
                        try? realm?.write {
                            realm?.add(local, update: .all)
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name.Advertise.configDidUpdate, object: nil)
            })
            .disposed(by: bag)
        
        /// 充值成功重新拉取广告配置
        NotificationCenter
            .default
            .rx
            .notification(Notification.Name.AppleIAP.chargeSuccess)
            .debug()
            .flatMap{_ in
                adprovider
                    .rx
                    .request(.configList)
                    .model(AdvertiseConfigResponse.self)
                    .asObservable()
            }
            .map { $0.data }
            .unwrap()
            .share(replay: 1)
            .map { (configList) -> [LocalAdvertise] in
                var locals: [LocalAdvertise] = []
                for config in configList {
                    if let ad_type_lists =   config.ad_type_lists {
                        for adType in ad_type_lists {
                            locals.append(LocalAdvertise(adType, advetiseConfig: config))
                        }
                    }
                }
                return locals
            }
            .subscribe(onNext: { (locals) in
                if locals.isEmpty {
                    if let records = realm?.objects(LocalAdvertise.self), !records.isEmpty{
                        try? realm?.write {
                            records.setValue(true, forKeyPath: "is_close")
                        }
                    }
                } else {
                    let adPositions = locals.map { $0.ad_position }
                    if let closeReslut = realm?.objects(LocalAdvertise.self).filter(NSPredicate(format: "NOT ad_position IN %@", adPositions)), !closeReslut.isEmpty {
                        try? realm?.write {
                             closeReslut.setValue(true, forKeyPath: "is_close")
                        }
                    }
                    for local in locals {
                        try? realm?.write {
                            realm?.add(local, update: .all)
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name.Advertise.configDidUpdate, object: nil)
            })
            .disposed(by: bag)

      /// 用户信息更新重新拉取广告配置
        NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Account.needUpdate)
            .debug()
            .flatMap{_ in
                adprovider
                    .rx
                    .request(.configList)
                    .model(AdvertiseConfigResponse.self)
                    .asObservable()
            }
            .map { $0.data }
            .unwrap()
            .map { (configList) -> [LocalAdvertise] in
                var locals: [LocalAdvertise] = []
                for config in configList {
                    if let ad_type_lists =  config.ad_type_lists {
                        for adType in ad_type_lists {
                            locals.append(LocalAdvertise(adType, advetiseConfig: config))
                        }
                    }
                }
                return locals
            }
            .subscribe(onNext: { (locals) in
                if locals.isEmpty {
                    if let records = realm?.objects(LocalAdvertise.self), !records.isEmpty {
                        try? realm?.write {
                            records.setValue(true, forKeyPath: "is_close")
                        }
                    }
                } else {
                    let adPositions = locals.map { $0.ad_position }
                    if let closeReslut = realm?.objects(LocalAdvertise.self).filter(NSPredicate(format: "NOT ad_position IN %@", adPositions)), !closeReslut.isEmpty {
                        try? realm?.write {
                             closeReslut.setValue(true, forKeyPath: "is_close")
                        }
                    }
                    for local in locals {
                        try? realm?.write {
                            realm?.add(local, update: .all)
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name.Advertise.configDidUpdate, object: nil)
            })
            .disposed(by: bag)
        
        /// 退出登录, 更新广告配置重新拉取广告配置
        Observable.merge(NotificationCenter.default.rx.notification(Notification.Name.Advertise.configNeedUpdate))
            .flatMap{_ in
                adprovider
                    .rx
                    .request(.configList)
                    .model(AdvertiseConfigResponse.self)
                    .asObservable()
            }
            .map { $0.data }
            .unwrap()
            .map { (configList) -> [LocalAdvertise] in
                var locals: [LocalAdvertise] = []
                for config in configList {
                    if let ad_type_lists =   config.ad_type_lists {
                        for adType in ad_type_lists {
                            locals.append(LocalAdvertise(adType, advetiseConfig: config))
                        }
                    }
                }
                return locals
            }
            .subscribe(onNext: { (locals) in
                if locals.isEmpty {
                    if let records = realm?.objects(LocalAdvertise.self), !records.isEmpty {
                        try? realm?.write {
                          records.setValue(true, forKeyPath: "is_close")
                        }
                    }
                } else {
                    let adPositions = locals.map { $0.ad_position }
                    if let closeReslut = realm?.objects(LocalAdvertise.self).filter(NSPredicate(format: "NOT ad_position IN %@", adPositions)), !closeReslut.isEmpty {
                        try? realm?.write {
                             closeReslut.setValue(true, forKeyPath: "is_close")
                        }
                    }
                    for local in locals {
                        try? realm?.write {
                            realm?.add(local, update: .all)
                        }
                    }
                }
                NotificationCenter.default.post(name: Notification.Name.Advertise.configDidUpdate, object: nil)
            })
            .disposed(by: bag)
        
        
        
        NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Account.deviceLogin)
            .flatMap { _ in
                provider
                    .rx
                    .request(.deviceLogin)
            }
            .userUpdate()
            .disposed(by: bag)
        
        
        /// 获取开关配置
        let commonDataProvider = MoyaProvider<CommonDataConfigService>()
        commonDataProvider.rx.request(.switcherConfigList)
            .model(SwitcherConfigResponse.self)
            .asObservable()
            .map { $0.data }
            .unwrap()
            .bind(to: CommomData.share.switcherConfig)
            .disposed(by: bag)
        
        commonDataProvider
            .rx
            .request(CommonDataConfigService.lanuchAlert)
            .model(LaunchAlertResponse.self)
            .asObservable()
            .startWith(LaunchAlertResponse())
            .map { $0.data }
            .unwrap()
            .debug()
            .filter { $0.is_delete == false }
            .filter { _ in
                /// 没有本地记录，弹框
                guard let record = realm?.objects(LaunchAlertTime.self).first else {
                    return true
                }
                /// modify_time在今天之内，不弹框
                guard record.modify_time >= Date().todayStartTime.timeIntervalSince1970 && record.modify_time < Date().todayEndTime.timeIntervalSince1970 else {
                    return true
                }
                return false
            }
            .map { LaunchAlertViewModel($0)}
            .bind(to: launchImageVM)
            .disposed(by: bag)
        
        /// 单点登录 -- 定时拉取状态
        let ssoResponse = PublishSubject<UserSsoResponse>.init()
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period: RxTimeInterval.seconds(60), scheduler: MainScheduler.asyncInstance)
            .filter { _ in me.isLogin }
            .mapToVoid()
            .flatMap {
                provider.rx.request(.sso)
                    .model(UserSsoResponse.self)
                    .asObservable()
            }
            .bind(to: ssoResponse)
            .disposed(by: bag)
            
        Observable.merge([ssoResponse.asObservable().filter { $0.data == nil }.map {_ in "您的登录已失效，是否重新登录"}, /// 登录失效
                          ssoResponse.asObservable().map { $0.data }.unwrap().filter { $0.token != me.token && me.token != nil}.map {_ in "您的账号在其他地方登录了，是否重新登录"} /// 被挤下去了
            ])
            .subscribeOn(MainScheduler.instance)
            .flatMap {
                DefaultWireframe.shared.promptFor(title: nil, message: $0, cancelAction: "取消", actions: ["确认"])
            }
            .subscribe(onNext: { (title) in
                NotificationCenter.default.post(name: Notification.Name.Account.signOut, object: nil)
                if title == "确认" {
                   navigator.push(LoginViewController(LoginViewModel()))
                }
            })
            .disposed(by: bag)
        
        CommonDataService.loadSogouKeywords()

        
    }
  
    deinit {
        debugPrint("dealloc-RootViewModel")
    }
}

