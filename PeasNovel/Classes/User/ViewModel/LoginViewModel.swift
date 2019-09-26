//
//  LoginViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxMoya


class  LoginViewModel {
    let items: Driver<[SectionModel<String, String>]>
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    /// input
    let phoneNumberInput: BehaviorRelay<String> = .init(value: "")
    let verifyCodeInput: BehaviorRelay<String> = .init(value: "")
    let invitateCodeInput: BehaviorRelay<String> = .init(value: "")
    let loginBtnInput: PublishSubject<Void> = .init()
    let getVerifyCodeInput: PublishSubject<Void> = .init()
    let audioCodeBtnInput: PublishSubject<Void> = .init()
    let pictureCacptaInput: PublishSubject<Float> = .init()
    
    /// output
    let activityOutput: Driver<Bool>
    let errorOutput: Driver<HUDValue>
    let loginSuccessOutput: PublishSubject<Void> = .init()
    let getVerifyCodeOutput: PublishSubject<NullResponse> = .init()
    let pictureCaptchaOutput: PublishSubject<PictureCaptchaViewModel> = .init()
    let mssageOutput: PublishSubject<HUDValue> = .init()
    
    init() {
        let activity = ActivityIndicator()
        let errorActivity = ErrorTracker()
        let verifyCodeProvider = MoyaProvider<VerifyCodeService>()
        let loginProvider = MoyaProvider<UserCenterService>()
        let phoneNumberInput: BehaviorRelay<String> = self.phoneNumberInput
        let verifyCodeInput: BehaviorRelay<String> =  self.verifyCodeInput
        let invitateCodeInput: BehaviorRelay<String> =  self.invitateCodeInput
        let codeType: BehaviorRelay<CodeType> = .init(value: .text)
        
        activityOutput = activity.asDriver()
        errorOutput = errorActivity.asDriver()
        
        items = Observable.just(
            [
                SectionModel<String, String>(model: "", items: [
                "手机号",
                "验证码",
                "语音验证码",
                "登录",
                "说明",
                ])
            ]
            )
        .asDriverOnErrorJustComplete()
        
        let picVM = PictureCaptchaViewModel(Int(UIScreen.main.bounds.width - 40 * 2), imageHeight: 250)
        picVM.sliderXInput
            .bind(to: pictureCacptaInput)
            .disposed(by: bag)
        
        /// 点击获取语言验证码
        audioCodeBtnInput
            .filter {!phoneNumberInput.value.isEmpty}
            .map { picVM }
            .bind(to: pictureCaptchaOutput)
            .disposed(by: bag)

        audioCodeBtnInput
            .map { CodeType.audio }
            .bind(to: codeType)
            .disposed(by: bag)

        ///  点击获取文字验证码
        getVerifyCodeInput.filter {!phoneNumberInput.value.isEmpty}
            .map { picVM }
            .bind(to: pictureCaptchaOutput)
            .disposed(by: bag)
        
        getVerifyCodeInput
            .map { CodeType.text }
            .bind(to: codeType)
            .disposed(by: bag)
        
        /// 校验图片并发送文字验证码
        pictureCacptaInput
            .asObservable()
            .filter {_ in codeType.value.rawValue == CodeType.text.rawValue }
            .flatMap {
                verifyCodeProvider.rx.request(.verifyPictureCaptcha(["x": String($0), "phone": phoneNumberInput.value]))
                .model(NullResponse.self)
                .asObservable()
                    .catchError({ (error) -> Observable<NullResponse> in
                        let response = NullResponse()
                        let status = ReponseResult()
                        response.status = status
                        status.code = -1
                        status.msg = "校验失败"
                        if let error = error as? AppError {
                            status.msg = error.message
                        }
                        return Observable.just(response)
                    })
            }
            .bind(to: getVerifyCodeOutput)
            .disposed(by: bag)
        
         /// 校验图片并发送语音验证码
        pictureCacptaInput
            .asObservable()
            .filter {_ in codeType.value.rawValue == CodeType.audio.rawValue }
            .flatMap {
                verifyCodeProvider.rx.request(.audioCodePictureCaptcha(["x": String($0), "phone": phoneNumberInput.value]))
                    .model(NullResponse.self)
                    .asObservable()
                    .catchError({ (error) -> Observable<NullResponse> in
                        let response = NullResponse()
                        let status = ReponseResult()
                        response.status = status
                        status.code = -1
                        status.msg = "校验失败"
                        if let error = error as? AppError {
                            status.msg = error.message
                        }
                        return Observable.just(response)
                    })
            }
            .bind(to: getVerifyCodeOutput)
            .disposed(by: bag)
        
        
        getVerifyCodeOutput.asObservable()
            .filter { $0.status?.code != 0}
            .map { $0.status?.msg }
            .unwrap()
            .debug()
            .map {HUDValue(.label($0))}
            .bind(to: mssageOutput)
            .disposed(by: bag)
        
        getVerifyCodeOutput.asObservable()
            .filter { $0.status?.code == 0}
            .map {_ in "验证码发送成功" }
            .debug()
            .map {HUDValue(.label($0))}
            .bind(to: mssageOutput)
            .disposed(by: bag)
        
        mssageOutput.subscribe(onNext: { (value) in
            print("message: \(value.type)")
        })
            .disposed(by: bag)
        
        /// 验证码倒计时
        getVerifyCodeOutput.asObservable()
            .filter {$0.status?.code == 0}
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.getVerifyCodeSuccess, object: codeType.value)
            })
            .disposed(by: bag)
        
        let loginResult: PublishSubject<UserResponse> = .init()
        let userSafeRatiResult: PublishSubject<UserSafeRatioResponse> = .init()
        
        /// 文字验证码验证手机号风险
        loginBtnInput
            .filter {_ in codeType.value.rawValue == CodeType.text.rawValue }
            .flatMap {
                loginProvider
                    .rx
                    .request(UserCenterService.getUserSafeRatio(["phone": phoneNumberInput.value]))
                    .model(UserSafeRatioResponse.self)
                    .asObservable()
                    .catchError({ (error) -> Observable<UserSafeRatioResponse> in
                        let response = UserSafeRatioResponse()
                        let status = ReponseResult()
                        response.status = status
                        status.code = -1
                        status.msg = "校验失败"
                        if let error = error as? AppError {
                            status.msg = error.message
                        }
                        return Observable.just(response)
                    })
            }
            .bind(to: userSafeRatiResult)
            .disposed(by: bag)
        
        
        /// 语言验证码验证不需要验证手机号风险
        loginBtnInput
            .filter {_ in codeType.value.rawValue == CodeType.audio.rawValue }
            .map {
                let res = UserSafeRatioResponse()
                res.data = UserSafeRatio()
                let status = ReponseResult()
                res.status = status
                status.code = 0
                status.msg = "校验成功"
                return res
            }
            .bind(to: userSafeRatiResult)
            .disposed(by: bag)
        
        
    userSafeRatiResult.asObservable()
            .asObservable()
            .map { $0.data?.code }
            .debug()
            .unwrap()
            .filter {$0 >= 35.0 }
            .map {_ in HUDValue(.label("该手机号存在风险，推荐使用语言验证码"))}
            .bind(to: mssageOutput)
            .disposed(by: bag)
        
     userSafeRatiResult
            .asObservable()
            .debug()
            .map { $0.data?.code }
            .unwrap()
            .filter {$0 < 35.0}
            .map { _ -> [String: Any] in
                var param = [String: Any]()
                param["phone"] = phoneNumberInput.value
                param["code"] = verifyCodeInput.value
                if !invitateCodeInput.value.isEmpty {
                    param["invitation_code"] = invitateCodeInput.value
                }
                return param
            }
            .flatMap {
                loginProvider.rx.request(.phoneNumLogin($0))
                    .asObservable()
                    .userResponse()
                    .trackError(errorActivity)
                    .trackActivity(activity)
                    .catchError {_ in Observable.never()}
            }
            .debug()
            .bind(to: loginResult)
            .disposed(by: bag)
        
        loginResult.map {$0.data}
            .unwrap()
            .subscribe(onNext: { (user) in
                NotificationCenter.default.post(name: NSNotification.Name.Account.needUpdate, object: nil, userInfo: nil)
            })
            .disposed(by: bag)
    
        errorOutput.debug().drive(onNext: { (value) in
            
        })
        .disposed(by: bag)
    }
}


enum CodeType: Int {
    case text = 0
    case audio = 1
}
