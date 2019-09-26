//
//  UserProfileViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/24.
//  Copyright © 2019 NotBroken. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa
import Moya
import RxMoya
import Photos

class UserProfileViewModel {
    let sections: BehaviorRelay<[SectionModel<UserProfileSectionType, UserProfileUIModel>]> = .init(value: [])
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewDidAppear: PublishSubject<Bool> = .init()
    let viewDidDisappear: PublishSubject<Bool> = .init()
    let itemDidSelectedInput: PublishSubject<UserPageModel> = .init()
    let bag = DisposeBag()
    let avatarBase64Input: PublishSubject<String> = .init()
    
    /// input
    let nicknameInput: BehaviorRelay<String> = .init(value: me.nickname ?? "")
    let changeSexinput: PublishSubject<Void> = .init()
    
    /// output
    let messageOutput: PublishSubject<HUDValue> = .init()
    
    init() {
        let headerIconInput: BehaviorRelay<String> = .init(value:me.sex.iconName)
        let phoneNumInput: BehaviorRelay<String> = .init(value: me.phone ?? "")
        let sexInput: BehaviorRelay<Gender> = .init(value: me.sex)
        let provider = MoyaProvider<UserCenterService>()
        
        headerIconInput
            .asObservable()
            .debug()
            .subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        
        phoneNumInput
            .asObservable()
            .debug()
            .subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        
        sexInput
            .asObservable()
            .debug()
            .subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        
        nicknameInput
            .asObservable()
             .debug()
            .subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        
        viewDidLoad
            .asObservable()
            .debug()
            .subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        

        Observable.combineLatest(viewDidLoad.asObservable(),
                                 headerIconInput.asObservable(),
                                 phoneNumInput.asObservable(),
                                 nicknameInput.asObservable(),
                                 sexInput.asObservable(), resultSelector: { (_, headerIcon, phoneNum, nicknname, sex) -> [SectionModel<UserProfileSectionType, UserProfileUIModel>] in
            let rows = [
                UserProfileUIModel("手机号", subTitle: phoneNum),
                UserProfileUIModel("昵  称", subTitle: nicknname),
                UserProfileUIModel("性  别", subTitle: sex.desc)
            ]
            let header = UserProfileSectionType.header(headerIcon)
            let profile = UserProfileSectionType.profile(rows)
            let loginBtn = UserProfileSectionType.btn
            return [
                SectionModel<UserProfileSectionType, UserProfileUIModel>(model: header, items: [UserProfileUIModel("", subTitle: "")]),
                SectionModel<UserProfileSectionType, UserProfileUIModel>(model: profile, items: rows),
                SectionModel<UserProfileSectionType, UserProfileUIModel>(model: loginBtn, items: [UserProfileUIModel("", subTitle: "")])
            ]
        })
            .debug()
            .bind(to: sections)
            .disposed(by: bag)
        
        
        
        let result = PublishSubject<NullResponse>.init()
        nicknameInput.asObservable()
            .skip(1)
            .filter {!$0.isEmpty }
            .flatMap {
                provider.rx.request(.editUserInfo(["nickname": $0]))
                    .model(NullResponse.self)
                    .asObservable()
                    .catchError { Observable.just(NullResponse.commonError($0))}
                }
            .bind(to: result)
            .disposed(by: bag)
        
        sexInput.asObservable()
            .map {$0.iconName }
            .bind(to: headerIconInput)
            .disposed(by: bag)
        
        sexInput.asObservable()
            .skip(1)
            .map { $0.rawValue }
            .filter {!$0.isEmpty }
            .flatMap {
                provider.rx.request(.editUserInfo(["sex": $0]))
                    .model(NullResponse.self)
                    .asObservable()
                    .catchError { Observable.just(NullResponse.commonError($0))}
            }
            .bind(to: result)
            .disposed(by: bag)
        
        changeSexinput.asObservable()
            .flatMap { _ in
                DefaultWireframe.shared.promptForActionSheet(title: "选择性别", message: "", cancelAction: "取消", actions: ["男", "女", "保密"])
            }
            .map { (text) -> Gender? in
                if text == "男" {
                   return Gender.male
                } else if text == "女"{
                    return Gender.female
                } else if text == "保密"{
                    return Gender.secret
                }
                return nil
            }
            .unwrap()
            .bind(to: sexInput)
            .disposed(by: bag)
        
        result.asObservable()
            .filter {$0.status?.code == 0}
            .map {_ in "用户信息更新成功"}
            .map { HUDValue(.label($0))}
            .bind(to: messageOutput)
            .disposed(by: bag)
        
        result.asObservable()
            .filter {$0.status?.code != 0}
            .map { $0.status?.msg }
            .unwrap()
            .map { HUDValue(.label($0))}
            .bind(to: messageOutput)
            .disposed(by: bag)
        
        
        /// 修改成功通知更新用户信息
        result.asObservable()
            .filter {$0.status?.code == 0}
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Account.needUpdate, object: nil)
            })
            .disposed(by: bag)


        
    }
}

enum UserProfileSectionType {
    case header(String)
    case profile([UserProfileUIModel])
    case btn
}

class UserProfileUIModel {
    var title: String
    var subTitle: String
    var iconname: String?
    
    init(_ title: String, subTitle: String, iconname: String? = nil) {
        self.title = title
        self.subTitle = subTitle
        self.iconname = iconname
    }
}



extension ObservableType where Element: PHAsset {
    
    fileprivate func imageURL() -> Observable<URL?> {
        return flatMap { model -> Observable<URL?> in
            return Observable.create { observer -> Disposable in
                
                PHImageManager
                    .default()
                    .requestImageData(for: model,
                                      options: nil,
                                      resultHandler: { (data, str, ori, info) in
                                        if let url = info?["PHImageFileURLKey"] as? URL {
                                            observer.on(.next(url))
                                        }else{
                                            observer.on(.next(nil))
                                        }
                    })
                return Disposables.create { }
            }
        }
    }
}
