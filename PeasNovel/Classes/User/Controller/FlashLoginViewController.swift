//
//  FlashLoginViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import RxSwift
import UIKit
import PKHUD

class FlashLoginViewController: BaseViewController {

    
    convenience init(_ viewModel: FlashLoginViewModel) {
        self.init(nibName: "FlashLoginViewController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    
    func config(_ viewModel: FlashLoginViewModel) {
        let baseUIConfigure = CLUIConfigure()
        let iconTop: Double = Double(100.0.fitScale)
        let iconheight: Double = 82
        let phonumTop: Double = 25 + iconTop + iconheight
        let phoneNumHeight: Double = 25
        let logintBtnTop: Double = 36 +  phoneNumHeight + phonumTop
        let logiBtnHeight: Double = 45
        let bottomViewTop: Double = logiBtnHeight + logintBtnTop + 10
        let title = NSMutableAttributedString(string: "手机号快速登录")
        title.setAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)], range: NSRange(location: 0, length: title.length))
        title.setAttributes([NSAttributedString.Key.foregroundColor: UIColor(0x333333)], range: NSRange(location: 0, length: title.length))
        baseUIConfigure.cl_navigation_attributesTitleText = NSAttributedString(string: "")
        baseUIConfigure.cl_navigation_tintColor = UIColor.black
        
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
        
        baseUIConfigure.viewController = self
        baseUIConfigure.customAreaView = { view in
            view.backgroundColor = UIColor.red
            let bottomView = FlashLoginBottomView.loadView()
            view.addSubview(bottomView)
            bottomView.snp.makeConstraints({
                $0.left.right.equalTo(0)
                $0.height.equalTo(155)
                $0.top.equalTo(bottomViewTop)
            })
            bottomView.otherBtn.rx.tap
                .mapToVoid()
                .subscribe(onNext: { (_) in
                    baseUIConfigure.manualDismiss = NSNumber(integerLiteral: 1)
                })
                .disposed(by: self.bag)
            
//            bottomView.otherBtn.rx.tap
//                .mapToVoid()
//                .bind(to: viewModel.otherLoginInput)
//                .disposed(by: self!.bag)
        }
        
        CLShanYanSDKManager.quickAuthLogin(with: baseUIConfigure, timeOut: 5, complete: { (result) in
            if let _ = result.error {
                HUD.flash(HUDContentType.label("登录授权失败"), delay: 2)
            } else {
                guard let data = result.data as? [String: Any],
                    let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                    let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8 ) else {
                        return
                }
                debugPrint("FlashLoginViewModel - quickAuthLogin:\(jsonStr)")
                
            }
        })

    }


}
