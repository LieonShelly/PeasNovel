//
//  AdvertiseService.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import UIKit
import Moya
import RxSwift
import RxCocoa
import RxRealm
import Realm
import RealmSwift

class AdvertiseService {
    let bag = DisposeBag()
    let adResponse = PublishSubject<AdvertiseConfigResponse>.init()
    let provider =  MoyaProvider<AdvertiseConfigService>()
    ///  input
    let advertiseExposed = PublishSubject<LocalAdvertise>()
    let advertisePostionInput: PublishSubject<AdPosition> = .init()
    /// output
    let advertisePostionOutput: PublishSubject<LocalAdvertise> = .init()
    
    init() {
        
        adResponse
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
            .filter { !$0.isEmpty }
            .subscribe(onNext: { (locals) in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                for local in locals {
                    try? realm.write {
                        realm.add(local, update: .all)
                    }
                }
            })
            .disposed(by: bag)
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        /// 曝光一次曝光数加1
        advertiseExposed.asObservable()
            .flatMap {
                Observable.just(realm.objects(LocalAdvertise.self).filter("id = %@", $0.id).first)
            }
            .unwrap()
            .subscribe(onNext: { (advertise) in
                if let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration) ,
                let localExposued = realm.objects(LocalAdvertiseExposured.self).filter("local_advertise_id = %@", advertise.id).first {
                    try? realm.write {
                        localExposued.exposured  += 1
                    }
                } else {
                    let newObj = LocalAdvertiseExposured(advertise)
                    newObj.exposured = 1
                    try? realm.write {
                        realm.add(newObj, update: .all)
                    }
                }
            })
            .disposed(by: bag)
        
        /// 广告的位置输入
        advertisePostionInput.asObservable()
        .map { AdvertiseService.advertiseConfig($0) }
        .unwrap()
        .bind(to: advertisePostionOutput)
        .disposed(by: bag)
        
        
    }
    
    func reloadConfig() {
        provider
            .rx
            .request(.configList)
            .model(AdvertiseConfigResponse.self)
            .asObservable()
            .debug()
            .bind(to: adResponse)
            .disposed(by: bag)
        
    }
    
    static func advertiseConfig(_ position: AdPosition) -> LocalAdvertise? {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let results = realm.objects(LocalAdvertise.self).filter(NSPredicate(format: "ad_position = %ld AND exposure > 0",  position.rawValue))
        var willAds: [LocalAdvertise] = []
        for result in results {
            let exposureds = realm.objects(LocalAdvertiseExposured.self).filter("local_advertise_id = %@", result.id)
            if exposureds.isEmpty {
                willAds.append(result)
            } else {
                let exposured = exposureds.first
                if exposured!.exposured >= result.exposure {

                } else {
                    willAds.append(result)
                }
            }
        }
        if willAds.isEmpty { 
            let currentExposureds = realm.objects(LocalAdvertiseExposured.self).filter("ad_position = %ld", position.rawValue)
            try? realm.write {
                currentExposureds.setValue(0, forKeyPath: "exposured")
            }
            return  results.first
        } else {
            return willAds.first
        }
    }
    
    static func loadAdvertiseConfig(_ position: AdPosition) -> (LocalAdvertise?, Realm) {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let results = realm.objects(LocalAdvertise.self).filter(NSPredicate(format: "ad_position = %ld AND exposure > 0",  position.rawValue))
        var willAds: [LocalAdvertise] = []
        for result in results {
            let exposureds = realm.objects(LocalAdvertiseExposured.self).filter("local_advertise_id = %@", result.id)
            if exposureds.isEmpty {
                willAds.append(result)
            } else {
                let exposured = exposureds.first
                if exposured!.exposured >= result.exposure {
                    
                } else {
                    willAds.append(result)
                }
            }
        }
        if willAds.isEmpty {
            let currentExposureds = realm.objects(LocalAdvertiseExposured.self).filter("ad_position = %ld", position.rawValue)
            try? realm.write {
                currentExposureds.setValue(0, forKeyPath: "exposured")
            }
            return  (results.first, realm)
        } else {
            return (willAds.first, realm)
        }
    }
}

extension AdvertiseService {
    
    static func createInfoStreamAdOutput(_ config: LocalAdvertise, adUIConfigure: AdvertiseUIInterface, configure: ((Advertiseable) -> Void)?) -> Observable<LocalTempAdConfig>  {
        return Observable<LocalTempAdConfig>.create({ (observer) -> Disposable in
            switch config.ad_type {
            case AdvertiseType.inmobi.rawValue:
                let imNativeViewModel = IMNativeViewModel(config, adUIConfig: adUIConfigure)
                configure?(imNativeViewModel)
                return imNativeViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.inmobi($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
            case AdvertiseType.GDT.rawValue:
                let gdtInfoVM = GDTExpressAdViewModel(config, adUIConfig: adUIConfigure)
                configure?(gdtInfoVM)
                return gdtInfoVM.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.GDT($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
            case AdvertiseType.todayHeadeline.rawValue:
                let buInfoVM = BUNativeFeedAdViewModel(config, adUIConfig: adUIConfigure)
                configure?(buInfoVM)
                return buInfoVM.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.todayHeadeline($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
            default:
                break
            }
            return Disposables.create()
        })
    }
    
    static func createRewardAdOutput(_ config: LocalAdvertise, adUIConfigure: AdvertiseUIInterface, configure: ((Advertiseable) -> Void)?) -> Observable<LocalTempAdConfig>  {
        return Observable<LocalTempAdConfig>.create({ (observer) -> Disposable in
            switch config.ad_type {
            case AdvertiseType.inmobi.rawValue:
                let imRewardVideoVM = IMRewardVideoViewModel(config)
                configure?(imRewardVideoVM)
                let adDispose = imRewardVideoVM.interstitialOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.inmobi($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
                  return adDispose
            case AdvertiseType.GDT.rawValue:
                let gdtRewardVM = GDTRewardVideoViewModel(config)
                configure?(gdtRewardVM)
                 let adDispose = gdtRewardVM.rewardVideoAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.GDT($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
                return adDispose
            case AdvertiseType.todayHeadeline.rawValue:
                let buInfoVM = BURewardVideoViewModel(config)
                 configure?(buInfoVM)
                let adDispose =  buInfoVM.rewardVideoAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.todayHeadeline($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
                return adDispose
            default:
                break
            }
            return Disposables.create()
        })
    }
    
    static func createFullScreenVideoAdOutput(_ config: LocalAdvertise, adUIConfigure: AdvertiseUIInterface? = nil, configure: ((Advertiseable) -> Void)?) -> Observable<LocalTempAdConfig>  {
        return Observable<LocalTempAdConfig>.create({ (observer) -> Disposable in
            switch config.ad_type {
            case AdvertiseType.inmobi.rawValue:
                let imRewardVideoVM = IMFullScreenVideoAdViewModel(config) 
                configure?(imRewardVideoVM)
                let adDispose = imRewardVideoVM.interstitialOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.inmobi($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
                return adDispose
            case AdvertiseType.todayHeadeline.rawValue:
                let buInfoVM = BUFullScreenVideoViewModel(config) 
                configure?(buInfoVM)
                let adDispose = buInfoVM.fullScreenVideoAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: LocalAdvertiseType.todayHeadeline($0))}
                    .subscribe(onNext: { (temp) in
                        temp.uiConfig = adUIConfigure
                        observer.onNext(temp)
                    }, onError: { error in
                        observer.onError(error)
                    }, onCompleted:{
                        observer.onCompleted()
                    })
                return adDispose
            default:
                break
            }
            return Disposables.create()
        })
    }
}
