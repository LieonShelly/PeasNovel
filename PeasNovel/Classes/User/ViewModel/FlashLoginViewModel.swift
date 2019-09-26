//
//  FlashLoginViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxMoya
import UIKit

class FlashLoginViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    
    /// input:
    let loginBtnInput: PublishSubject<FlashLoginViewController> = .init()
    let otherLoginBtnInput: PublishSubject<Void> = .init()
    
    /// output:
    let preGetPhoneNumOuput: BehaviorRelay<String> = BehaviorRelay<String>(value: "")
    

    init() {
        let activity = ActivityIndicator()
        let loginResult: PublishSubject<UserResponse> = .init()
        let provider = MoyaProvider<UserCenterService>()
        viewDidLoad
            .flatMap { _  -> Observable<String> in
                return Observable<String>.create({ (observer) -> Disposable in
                    CLShanYanSDKManager.preGetPhonenumber({ (result) in
                        guard let data = result.data as? [String: Any] else {
                            observer.onNext("")
                            return
                        }
                        debugPrint("FlashLoginViewModel - preGetPhonenumber:\(data)")
                    })
                    return Disposables.create()
                })
        }
        .bind(to: preGetPhoneNumOuput)
        .disposed(by: bag)
        
        loginBtnInput.asObservable()
            .flatMap { vc -> Observable<String> in
                return Observable<String>.create({ (observer) -> Disposable in
                    let baseUIConfigure = CLUIConfigure()
                    let iconTop: Double = Double(100.0.fitScale)
                    let iconheight: Double = 82
                    let phonumTop: Double = 25 + iconTop + iconheight
                    let phoneNumHeight: Double = 25
                    let logintBtnTop: Double = 36 +  phoneNumHeight + phonumTop
                    let logiBtnHeight: Double = 45
                    let bottomViewTop: Double = logiBtnHeight + logintBtnTop + 10
                    
                    baseUIConfigure.clLogoImage = UIImage(named: "logo")!
                    baseUIConfigure.clLogoOffsetY = NSNumber(floatLiteral: Double(iconTop))
                    baseUIConfigure.clLoginBtnHeight = NSNumber(floatLiteral: Double(iconheight))
                    baseUIConfigure.clLogoCornerRadius = 41
                    
                    baseUIConfigure.clPhoneNumberOffsetY = NSNumber(floatLiteral: Double(phonumTop))
                     baseUIConfigure.clPhoneNumberHeight = NSNumber(floatLiteral: Double(phoneNumHeight))
                    
                    baseUIConfigure.clLoginBtnText = "本机号码一键登录"
                    baseUIConfigure.clLoginBtnOffsetY = NSNumber(floatLiteral: Double(logintBtnTop))
                     baseUIConfigure.clLoginBtnHeight = NSNumber(floatLiteral: Double(logiBtnHeight))
                    baseUIConfigure.clLoginBtnTextColor = UIColor.white
                    baseUIConfigure.clLoginBtnTextFont = UIFont.boldSystemFont(ofSize: 21)
                    baseUIConfigure.clLoginBtnBgColor = UIColor.theme
                    baseUIConfigure.clLoginBtnWidth = NSNumber(floatLiteral: Double(UIScreen.main.bounds.width - 16 * 2))
                    baseUIConfigure.clLoginBtnHeight = NSNumber(floatLiteral: logiBtnHeight)
                    baseUIConfigure.clLoginBtnCornerRadius = 22.5
                    
                    baseUIConfigure.viewController = vc
                    baseUIConfigure.customAreaView = { view in
                        view.backgroundColor = UIColor.red
                        let bottomView = FlashLoginBottomView.loadView()
                        view.addSubview(bottomView)
                        bottomView.snp.makeConstraints({
                            $0.left.right.equalTo(0)
                            $0.height.equalTo(155)
                            $0.top.equalTo(bottomViewTop)
                        })
                    }

                    CLShanYanSDKManager.quickAuthLogin(with: baseUIConfigure, timeOut: 5, complete: { (result) in
                        if let error = result.error {
                            observer.onError(error)
                        } else {
                            guard let data = result.data as? [String: Any],
                                let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                               let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8 ) else {
                                return
                            }
                            debugPrint("FlashLoginViewModel - quickAuthLogin:\(jsonStr)")
                            observer.onNext(jsonStr)
                        }
                    })
                    return Disposables.create()
                })
        }
            .flatMap {
                provider.rx.request(.flashLoing(["shan_yan": $0]))
                    .asObservable()
                    .userResponse()
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
    }
}
