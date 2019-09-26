//
//  ReadFavorViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import Moya
import RxMoya

class ReadFavorViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let items: Driver<[SectionModel<String, Category>]>
    let bag = DisposeBag()
    let skipBtnIput: PublishSubject<Bool> = .init()
    let itemSelectIput: PublishSubject<Category> = .init()
    let enterBtnIput: PublishSubject<Void> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    
    /// output
    let activityOutput: Driver<Bool>
    let errorOutput: Driver<HUDValue>
    let selectCounOutput: BehaviorRelay<Int> = .init(value: 0)
    let settingResult: PublishSubject<NullResponseArray> = .init()
//    let exceptionOuptputDriver: Driver<ExceptionInfo>
    
    init() {
        let activity = ActivityIndicator()
        let errorActivity = ErrorTracker()
        let userCategorylists: BehaviorRelay<[Category]> = .init(value:[])
        let lists: BehaviorRelay<[CategoryGroup]> = .init(value:[])
        let metaList: BehaviorRelay<[CategoryGroup]> = .init(value:[])
        let selectedModels: BehaviorRelay<[Category]> = .init(value:[])
        let reloadLists: BehaviorRelay<[CategoryGroup]> = .init(value:[])
        
        activityOutput = activity.asDriver()
        errorOutput = errorActivity.asDriver()
        
        
        let provider = MoyaProvider<ReadFavorService>()
        Observable.merge([viewDidLoad.asObservable(),
                          exceptionInput.asObservable().filter {_ in me.user_id != nil }.filter {_ in (me.user_id?.isEmpty ?? true) == false}.mapToVoid(),
                          NotificationCenter.default.rx.notification(Notification.Name.Account.update).mapToVoid()])
        .flatMap {
            provider.rx.request(.categoryList)
                .model(ReadFavorResponse.self)
                .trackActivity(activity)
                .catchError({ (error) -> Observable<ReadFavorResponse> in
                    return Observable.just(ReadFavorResponse.commonError(error))
                })
            }
            .map {$0.data}
            .unwrap()
            .bind(to: metaList)
            .disposed(by: bag)
        
        /// 定时重新加载的依据
        metaList.asObservable()
            .bind(to: reloadLists)
            .disposed(by: bag)
        
        Observable.merge([viewDidLoad.asObservable(),
                          exceptionInput.asObservable().filter {_ in me.user_id != nil }.filter {_ in (me.user_id?.isEmpty ?? true) == false}.mapToVoid(),
                          NotificationCenter.default.rx.notification(Notification.Name.Account.update).mapToVoid()])
            .asObservable()
            .flatMap { _ in
                provider.rx.request(.getSeetings)
                    .model(UserReadFavorResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map {$0.data}
            .unwrap()
            .bind(to: userCategorylists)
            .disposed(by: bag)
     
        
        /// 无用户ID，点击重新加载，或者点击跳过
        let loginProvider =  MoyaProvider<UserCenterService>()
        Observable.merge([skipBtnIput.filter { $0 == true }.mapToVoid(),
                          exceptionInput.asObservable().filter {_ in me.user_id == nil }.filter {_ in (me.user_id?.isEmpty ?? true) == true}])
            .filter {_ in me.user_id == nil }
            .flatMap { _ in
                loginProvider
                    .rx
                    .request(.deviceLogin)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .debug()
            .userUpdate()
            .disposed(by: bag)
        
        
        let adprovider =  MoyaProvider<AdvertiseConfigService>()
        let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
        
         /// 有用户ID，点击重新加载，或者点击跳过
        Observable.merge([skipBtnIput.filter { $0 == true }.mapToVoid(),
                          exceptionInput.asObservable().filter {_ in me.user_id == nil }.filter {_ in (me.user_id?.isEmpty ?? true) == true}])
            .filter {_ in (me.user_id?.isEmpty ?? true) == false}
            .flatMap { _ in
                adprovider
                    .rx
                    .request(.configList)
                    .model(AdvertiseConfigResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
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
            .filter { !$0.isEmpty }
            .subscribe(onNext: { (locals) in
                if locals.isEmpty {
                    if let records = realm?.objects(LocalAdvertise.self) {
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
        
        Observable.combineLatest(metaList.asObservable(), userCategorylists.asObservable()) { (metaData, userSettinngs) -> [CategoryGroup] in
            for userCate in userSettinngs {
                for group in metaData {
                    if let cateList = group.category, let index = cateList.index(where: {$0.category_id_1 == userCate.category_id_1 && $0.category_id_2 == userCate.category_id_2}) {
                        cateList[index].isSelected = true
                    }
                }
            }
            return metaData
        }.bind(to: lists)
            .disposed(by: bag)
        
        items = lists.asObservable()
                .skip(1)
                .mapMany {SectionModel<String, Category>(model: $0.name ?? "", items: $0.category ?? [])}
                .asDriver(onErrorJustReturn: [])
        
        
        itemSelectIput.subscribe(onNext: { (selected) in
            var listData = lists.value
            for (index, value) in lists.value.enumerated() {
                let group = value
                if var groupCategory = value.category {
                    for (modeIndex, model) in groupCategory.enumerated() {
                        if model.id == selected.id {
                            selected.isSelected = !selected.isSelected
                            groupCategory[modeIndex] = selected
                            group.category = groupCategory
                            listData[index] = group
                            lists.accept(listData)
                        }
                    }
                }
            }
        })
            .disposed(by: bag)
        
        lists.asObservable()
            .skip(1)
            .map { (groups) -> [Category] in
                var selects: [Category] = []
                for (_, value) in groups.enumerated() {
                    if let groupCategory = value.category {
                        for (_, model) in groupCategory.enumerated() {
                            if model.isSelected == true {
                               selects.append(model)
                            }
                        }
                    }
                }
            return selects
        }
        .bind(to: selectedModels)
        .disposed(by: bag)
        
            
        selectedModels.asObservable()
        .map {$0.count}
        .bind(to: selectCounOutput)
        .disposed(by: bag)
        
        enterBtnIput.asObservable()
            .filter {selectedModels.value.isEmpty}
            .map { _ -> NullResponseArray in
                let response = NullResponseArray()
                let status = ReponseResult()
                status.code = -1
                status.msg = "选择分类不能为空"
                response.data = []
                response.status = status
                return response
            }
            .bind(to: settingResult)
            .disposed(by: bag)
        
        enterBtnIput.asObservable()
            .filter {!selectedModels.value.isEmpty}
            .map {selectedModels.value}
            .mapMany {$0.id ?? ""}
            .map {$0.joined(separator: ",")}
            .flatMap {
                provider.rx.request(.upsertOrRemove(["ids": $0]))
                .model(NullResponseArray.self)
                .trackActivity(activity)
                .catchError {_ in Observable.never()}
            }
            .bind(to: settingResult)
            .disposed(by: bag)
        
        settingResult.subscribe(onNext: { (_) in
            NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.readFavorDidChange, object: nil)
        })
            .disposed(by: bag)
        
        /// 如果显示异常，则每秒重新加载一次
        Observable<Int>
            .interval(RxTimeInterval.seconds(1), scheduler: ConcurrentMainScheduler.instance)
            .flatMap { _ in
                reloadLists.asObservable()
            }
            .filter { $0.isEmpty }
            .mapToVoid()
            .debug()
            .bind(to: exceptionInput)
            .disposed(by: bag)
        
        //  上报
        itemSelectIput.subscribe(onNext: { (selected) in
            if let value = selected.pvuv_key {
                let value = value + "_DD"
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: value)
            }
        })
            .disposed(by: bag)
        
        
        skipBtnIput.asObservable()
            .mapToVoid()
            .map {"YDPH_POSITION21_DD"}
            .subscribe(onNext: { (selected) in
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: selected)
        })
            .disposed(by: bag)
        
        enterBtnIput.asObservable()
            .map {"YDPH_POSITION22_DD"}
            .subscribe(onNext: { (selected) in
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: selected)
            })
            .disposed(by: bag)
    }
    
    deinit {
        debugPrint("ReadFavorViewModel-deinit")
    }
}
