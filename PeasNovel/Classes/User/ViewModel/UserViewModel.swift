//
//  UserViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/27.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxMoya
import RealmSwift


class UserViewModel {
    let sections: Driver<[UserPageSection]>
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewDidAppear: PublishSubject<Bool> = .init()
    let viewDidDisappear: PublishSubject<Bool> = .init()
    let itemDidSelectedInput: PublishSubject<UserPageModel> = .init()
    let bag = DisposeBag()
    let headerIconInput: PublishSubject<Void> = .init()
    let flashDataInput: PublishSubject<String> = .init()
    let otherLoginInput: PublishSubject<Void> = .init()
    
    /// output
    let loginOutput: PublishSubject<FlashLoginViewModel> = .init()
    let readFavorOutput: Observable<ReadFavorViewModel>
    let feedbackOutput: Observable<FeedbackViewModel>
    let downloadCenterOutput: Observable<DownloadCenterViewModel>
    let chargeOutput: Observable<ChargeViewModel>
    let settingViewModel: Observable<SettingViewModel>
    let userInfoViewModel: Observable<UserProfileViewModel>
    let phoneNumViewModel: Observable<LoginViewModel>
    
    init() {
        let activity = ActivityIndicator()
        let loginResult: PublishSubject<UserResponse> = .init()
        let provider = MoyaProvider<UserCenterService>()
        let sectionModels = BehaviorRelay(value: [UserPageModel("mianguanggaoyuedu", title: NSLocalizedString("免广告阅读", comment: "")),
                                      UserPageModel("xiazaizhongxin", title: NSLocalizedString("下载中心", comment: "")),
                                      UserPageModel("yuedupianhao", title: NSLocalizedString("阅读偏好", comment: "")),
                                      UserPageModel("bangzhuyufankui", title: NSLocalizedString("帮助与反馈", comment: "")),
                                      UserPageModel("shezhi", title: NSLocalizedString("设置", comment: ""))])
        
        
        sections = viewDidLoad.asObservable()
            .flatMap{_ in
                sectionModels.asObservable()
            }
            .map{
                [UserPageSection($0)]
            }
            .asDriver(onErrorJustReturn: [])
        
        viewDidLoad.asObservable()
            .subscribe(onNext: { (_) in
                CLShanYanSDKManager.preGetPhonenumber(nil)
            })
            .disposed(by: bag)
        
        readFavorOutput =  itemDidSelectedInput.asObservable()
                            .filter {$0.title == NSLocalizedString("阅读偏好", comment: "")}
                            .map {_ in ReadFavorViewModel()}
        
        feedbackOutput =  itemDidSelectedInput.asObservable()
            .filter {$0.title == NSLocalizedString("帮助与反馈", comment: "")}
            .map {_ in FeedbackViewModel()}
        
        itemDidSelectedInput.asObservable()
            .filter {$0.title == "登录"}
            .map {_ in FlashLoginViewModel()}
            .bind(to: loginOutput)
            .disposed(by: bag)
        
        downloadCenterOutput = itemDidSelectedInput.asObservable()
                .filter {$0.title == NSLocalizedString("下载中心", comment: "")}
                .map {_ in DownloadCenterViewModel()}
        
        chargeOutput  = itemDidSelectedInput.asObservable()
            .filter {$0.title == NSLocalizedString("免广告阅读", comment: "")}
            .map {_ in ChargeViewModel() } 
        
        settingViewModel = itemDidSelectedInput
            .filter{ $0.title == NSLocalizedString("设置", comment: "") }
            .map{_ in SettingViewModel() }
        
        userInfoViewModel =  headerIconInput.asObservable()
            .filter { me.isLogin }
            .map {_ in UserProfileViewModel()}
        
        phoneNumViewModel = otherLoginInput.asObservable()
            .map { LoginViewModel() }
        

        headerIconInput.asObservable()
            .filter { !me.isLogin }
            .map {_ in FlashLoginViewModel()}
            .bind(to: loginOutput)
            .disposed(by: bag)
        
        flashDataInput.flatMap {
            provider.rx.request(.flashLoing(["shan_yan": $0]))
                .asObservable()
                .userResponse()
                .trackActivity(activity)
                .catchError({ (error) -> Observable<UserResponse> in
                    return Observable.just(UserResponse.commonError(error))
                })
            }
            .subscribe(onNext: { [weak self] (response) in
                guard let weakSelf = self else {
                    return
                }
                if response.status?.code == 0 {
                    loginResult.onNext(response)
                    NotificationCenter.default.post(name: NSNotification.Name.Account.flashLoginSuccess, object: nil)
                } else {
                    weakSelf.otherLoginInput.onNext(())
                }
            })
            .disposed(by: bag)
        
        loginResult.map {$0.data}
            .unwrap()
            .subscribe(onNext: { (user) in
                NotificationCenter.default.post(name: NSNotification.Name.Account.needUpdate, object: nil, userInfo: nil)
            })
            .disposed(by: bag)
        
        /// 上报
        viewDidAppear
            .asObservable()
            .map {_ in "YM_POSITION5_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.pageExposure, object: $0)
            })
            .disposed(by: bag)
    }
}
