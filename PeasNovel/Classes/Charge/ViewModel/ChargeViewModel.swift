//
//  ChargeViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/1/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxDataSources

// 月卡12 com.youhe.peas.novel.grade.2
// 季卡30，com.youhe.peas.novel.rmb.30
// 年卡118  com.youhe.peas.novel.rmb.118.c
// 沙箱测试： 12345678@youhe.com 12345678abcABC
/// ：https://pro.m.jd.com/mall/active/y9UueypqGjg4yrWxqXVtCq4TqL/index.html?showhead=no

class ChargeViewModel {
    let viewDidLoad: PublishSubject<Void>   = .init()
    let itemDidSelected: PublishSubject<ChargeModel> = .init()
    let items: Driver<[SectionModel<ChargeViewSectionType, ChargeModel>]>
    let bag = DisposeBag()
    let indexPathSelectInput: PublishSubject<IndexPath> = .init()
    let itemSelectInput: PublishSubject<ChargeModel> = .init()
    let activityDriver: Driver<Bool>
    let lgoinDriver: Driver<LoginViewModel>
    let openVipInput: PublishSubject<Void> = .init()
    let errorMessageOuput: PublishSubject<String> = .init()
    let flashDataInput: BehaviorRelay<String> = .init(value: "")
    let jdWebBtnInput: PublishSubject<Void> = .init()
    let jdWebViewModel: PublishSubject<WebViewModel> = .init()
    let exchangeBtnInput: PublishSubject<Void> = .init()
    let exchangeViewModel: PublishSubject<ExchangeJDCodeViewModel> = .init()
    let rightBtnInput: PublishSubject<Void> = .init()
    let chargeRecordOutput: PublishSubject<ChargeRecordViewModel> = .init()
    
    init() {
        let activity = ActivityIndicator()
        let goodsLists = BehaviorRelay<[ChargeModel]>(value: [])
        let provider = MoyaProvider<Payservice>()
        let dataResponse = PublishSubject<ChargeResponse>.init()
        let loginResult: PublishSubject<UserResponse> = .init()
        let loginObj = PublishSubject<LoginViewModel>.init()
        
        activityDriver = activity.asDriver()
        
        viewDidLoad.flatMap {
            provider.rx.request(.goodsList)
                .model(ChargeResponse.self)
                .asObservable()
            }.bind(to: dataResponse)
            .disposed(by:  bag)
        
        dataResponse.asObservable()
            .map { $0.data }
            .unwrap()
            .map({ (models) -> [ChargeModel] in
                models.first?.isSelected = true
                return models
            })
            .bind(to: goodsLists)
            .disposed(by: bag)

        items = Observable.combineLatest(viewDidLoad.asObservable(), goodsLists.asObservable().skip(1), resultSelector: { (_, lists) -> [SectionModel<ChargeViewSectionType, ChargeModel>] in
            var sections: [SectionModel<ChargeViewSectionType, ChargeModel>] = []
            if me.isLogin {
                if  me.ad?.vip.rawValue == 0 { //非会员
                    let good = ChargeModel()
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .vipPicDesc, items: [good]))
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .vipDesc, items: [good]))
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .goodList(lists), items: lists))
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .openVip("立即开通"), items: [good]))
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .vipRightDesc, items: [good]))
                    
                } else {
                    let good = ChargeModel()
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .vipPicDesc, items: [good]))
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .goodList(lists), items: lists))
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .openVip("立即开通"), items: [good]))
                    sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .vipRightDesc, items: [good]))
                }
            } else {
                let good = ChargeModel()
                sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .vipPicDesc, items: [good]))
                sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .goodList(lists), items: lists))
                sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .openVip("立即开通"), items: [good]))
                sections.append(SectionModel<ChargeViewSectionType, ChargeModel>(model: .vipRightDesc, items: [good]))
            }
            return sections
        }).asDriver(onErrorJustReturn: [])
    

        itemDidSelected
            .asObservable()
            .filter { $0.product_id != nil }
            .subscribe(onNext: { (model) in
                if let index = goodsLists.value.lastIndex(where: {$0.product_id == model.product_id } ) {
                    goodsLists.value.forEach {$0.isSelected = false}
                    model.isSelected = true
                    var data = goodsLists.value
                    data[index] = model
                    goodsLists.accept(data)
                }
            })
            .disposed(by: bag)
        
       
        lgoinDriver =  loginObj
            .asDriver(onErrorJustReturn: LoginViewModel())

        jdWebBtnInput.asObservable()
            .filter { !me.isLogin }
            .map { LoginViewModel() }
            .bind(to: loginObj)
            .disposed(by: bag)
        
        
        
        jdWebBtnInput.asObservable()
            .filter { me.isLogin }
            .map { WebViewModel(URL(string: "https://pro.m.jd.com/mall/active/y9UueypqGjg4yrWxqXVtCq4TqL/index.html?showhead=no")!)}
            .bind(to: jdWebViewModel)
            .disposed(by: bag)
        
        let exchangeBtniSTap: BehaviorRelay<Bool> = .init(value: false)
    
        Observable.merge(exchangeBtnInput.asObservable().map { true },
                         exchangeViewModel.map {_ in false}
                        )
            .bind(to: exchangeBtniSTap)
            .disposed(by: bag)

        exchangeBtnInput.asObservable()
            .filter { !me.isLogin }
            .map { LoginViewModel() }
            .bind(to: loginObj)
            .disposed(by: bag)
        
        exchangeBtnInput.asObservable()
            .filter { me.isLogin }
            .map { ExchangeJDCodeViewModel() }
            .bind(to: exchangeViewModel)
            .disposed(by: bag)
        
        openVipInput.asObservable()
            .filter { !me.isLogin }
            .map { LoginViewModel() }
            .bind(to: loginObj)
            .disposed(by: bag)

        openVipInput.asObservable()
            .filter { me.isLogin }
            .map({ (_) -> ChargeModel? in
                for good in goodsLists.value {
                    if good.isSelected {
                        return good
                    }
                }
                return nil
            })
            .filter { $0 == nil }
            .map { _ in "请选择一个充值产品"}
            .bind(to: errorMessageOuput)
            .disposed(by: bag)
        
        openVipInput.asObservable()
            .filter { me.isLogin }
            .map({ (_) -> ChargeModel? in
                for good in goodsLists.value {
                    if good.isSelected {
                        return good
                    }
                }
                return nil
            })
            .filter { $0 != nil }
            .unwrap()
            .map { $0.product_id }
            .unwrap()
            .map { ["product_dentifier": $0]}
            .bind(to: AppleIAPServeice.shared.param)
            .disposed(by: bag)
        
        openVipInput.asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.didClickCharge, object: nil)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.AppleIAP.chargeSuccess)
            .subscribe(onNext: { (_) in
                var param = [String: String]()
                if let selectIndex =  goodsLists.value.lastIndex(where: {$0.isSelected}) {
                    let selectedGoods = goodsLists.value[selectIndex]
                    param["pv_uv_page_type"] = "vip_free_ad_" + (selectedGoods.days ?? "30")
                }
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.buyVIP, object: param)
            })
            .disposed(by: bag)
        
        let loginProvider = MoyaProvider<UserCenterService>()
        flashDataInput
            .asObservable()
            .debug()
            .filter { !$0.isEmpty }
            .flatMap {
            loginProvider.rx.request(.flashLoing(["shan_yan": $0]))
                .asObservable()
                .userResponse()
                .trackActivity(activity)
                .catchError({ (error) -> Observable<UserResponse> in
                    return Observable.just(UserResponse.commonError(error))
                })
            }
            .subscribe(onNext: {[weak self] (response) in
                guard let weakSelf = self else {
                    return
                }
                if response.status?.code == 0 {
                    loginResult.onNext(response)
                    NotificationCenter.default.post(name: NSNotification.Name.Account.flashLoginSuccess, object: nil)
                    if exchangeBtniSTap.value {
                        weakSelf.exchangeBtnInput.onNext(())
                    }
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name.Account.flashLoginFailed, object: nil)
                }
            })
            .disposed(by: bag)
        
        loginResult.map {$0.data}
            .unwrap()
            .subscribe(onNext: { (user) in
                NotificationCenter.default.post(name: NSNotification.Name.Account.needUpdate, object: nil, userInfo: nil)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.loginSuccessPopBack)
            .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                if exchangeBtniSTap.value {
                    weakSelf.exchangeBtnInput.onNext(())
                }
            })
            .disposed(by: bag)
        
        rightBtnInput.asObservable()
            .filter { me.isLogin }
            .map { ChargeRecordViewModel()}
            .bind(to: chargeRecordOutput)
            .disposed(by: bag)
        
        rightBtnInput.asObservable()
            .filter { !me.isLogin }
            .map { LoginViewModel() }
            .bind(to: loginObj)
            .disposed(by: bag)
    }

}


enum ChargeViewSectionType {
    case vipPicDesc
    case vipDesc
    case goodList([ChargeModel])
    case openVip(String)
    case vipRightDesc
}
