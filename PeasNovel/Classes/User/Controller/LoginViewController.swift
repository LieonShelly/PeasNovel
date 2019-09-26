//
//  LoginViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import PKHUD

class LoginViewController: BaseViewController {
   @IBOutlet weak var tableView: UITableView!
    /// input
    let phoneNumberInput: BehaviorRelay<String> = .init(value: "")
    let verifyCodeInput: BehaviorRelay<String> = .init(value: "")
    let invitateCodeInput: BehaviorRelay<String> = .init(value: "")
    let loginBtnInput: PublishSubject<Void> = .init()
    let getVerifyCodeInput: PublishSubject<Void> = .init()
    let audioCodeBtnInput: PublishSubject<Void> = .init()
    
    ///output
    let verifyCodeBtnEnable: PublishSubject<Bool> = .init()
    let loginBtnEnable: PublishSubject<Bool> = .init()
    let phoneNumberValid: PublishSubject<Bool> = .init()
    let verifyCodeValid: PublishSubject<Bool> = .init()
    
  fileprivate lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, String>>(configureCell: {[weak self] (_, tv, ip, model) -> UITableViewCell in
        if model == "手机号" {
            let cell = tv.dequeueCell(TextFieldTableViewCell.self, for: ip)
            cell.textField.placeholder = "请输入手机号"
            if let weakSelf = self {
                cell.textField.rx.text.orEmpty.map {$0}
                    .bind(to: weakSelf.phoneNumberInput)
                    .disposed(by: cell.bag)
            }
            cell.textField.rx.text.orEmpty
                .map {$0}
                .map { (text) -> String in
                    if text.count >= 11 {
                        return String(text[..<text.index(text.startIndex, offsetBy: 11)])
                        
                    }
                    return text
                }
                .bind(to: cell.textField.rx.text)
                .disposed(by: cell.bag)
            return cell
        } else if model == "验证码" {
            let cell = tv.dequeueCell(VerifyCodeTableViewCell.self, for: ip)
            cell.textField.placeholder = model
            if let weakSelf = self {
                cell.textField.rx.text.orEmpty.map {$0}
                    .bind(to: weakSelf.verifyCodeInput)
                    .disposed(by: cell.bag)
                
                cell.textField.rx.text.orEmpty
                    .map {$0}
                    .map { (text) -> String in
                        if text.count >= 4 {
                            return String(text[..<text.index(text.startIndex, offsetBy: 4)])
                            
                        }
                        return text
                    }
                    .bind(to: cell.textField.rx.text)
                    .disposed(by: cell.bag)
                
                cell.btn.rx.tap.mapToVoid()
                    .bind(to: weakSelf.getVerifyCodeInput)
                    .disposed(by: cell.bag)

            }
            return cell
            
        } else if model == "邀请码" {
            let cell = tv.dequeueCell(TextFieldTableViewCell.self, for: ip)
             cell.textField.placeholder = model
            if let weakSelf = self {
                cell.textField.rx.text.orEmpty.map {$0}
                    .bind(to: weakSelf.invitateCodeInput)
                    .disposed(by: cell.bag)
            }
            return cell
        } else if model == "语音验证码" {
            let cell = tv.dequeueCell(LabelBtnTableViewCell.self, for: ip)
            if let weakSelf = self {
                cell.btn.rx.tap
                    .bind(to: weakSelf.audioCodeBtnInput)
                    .disposed(by: cell.bag)
            }
            return cell
        } else if model == "登录" {
            let cell = tv.dequeueCell(CenterBtnTableViewCell.self, for: ip)
            if let weakSelf = self {
                cell.btn.rx.tap.mapToVoid()
                    .bind(to: weakSelf.loginBtnInput)
                    .disposed(by: cell.bag)
                
            }
            
            return cell
        }else if model == "说明" {
            let cell = tv.dequeueCell(LoginDescTableViewCell.self, for: ip)
            return cell
        }
        let cell = tv.dequeueCell(UITableViewCell.self, for: ip)
        return cell
    })
    
    convenience init(_ viewModel: LoginViewModel) {
        self.init(nibName: "LoginViewController", bundle: nil)
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
    
    
    func config(_ viewModel: LoginViewModel) {
        tableView.keyboardDismissMode = .onDrag
        title = "手机号快速登录"
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        tableView.registerNibWithCell(TextFieldTableViewCell.self)
        tableView.registerNibWithCell(LabelBtnTableViewCell.self)
        tableView.registerNibWithCell(VerifyCodeTableViewCell.self)
        tableView.registerNibWithCell(LoginDescTableViewCell.self)
        tableView.registerNibWithCell(CenterBtnTableViewCell.self)
        tableView.registerClassWithCell(UITableViewCell.self)
        
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: bag)
        
        viewModel
            .items
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        phoneNumberInput
            .asObservable()
            .map({ (text) -> String in
                if text.count >= 11 {
                    return String(text[..<text.index(text.startIndex, offsetBy: 11)])
                    
                }
                return text
            })
            .bind(to: viewModel.phoneNumberInput)
            .disposed(by: bag)
        
        verifyCodeInput
            .asObservable()
            .bind(to: viewModel.verifyCodeInput)
            .disposed(by: bag)

        getVerifyCodeInput
            .asObservable()
            .bind(to: viewModel.getVerifyCodeInput)
            .disposed(by: bag)
        
        invitateCodeInput
            .asObservable()
            .bind(to: viewModel.invitateCodeInput)
            .disposed(by: bag)
        
        audioCodeBtnInput
            .asObservable()
            .bind(to: viewModel.audioCodeBtnInput)
            .disposed(by: bag)
        
        viewModel.activityOutput
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.errorOutput
            .drive(HUD.flash)
            .disposed(by: bag)
       
        
        phoneNumberInput
            .asObservable()
            .map {$0.count >= 11}
            .bind(to: phoneNumberValid)
            .disposed(by: bag)
        
        phoneNumberValid
            .asObservable()
            .bind(to: verifyCodeBtnEnable)
            .disposed(by: bag)
        

        verifyCodeInput
            .asObservable()
            .map {$0.count >= 4}
            .bind(to: verifyCodeValid)
            .disposed(by: bag)
        
        
        Observable.combineLatest(phoneNumberValid.asObservable(), verifyCodeValid.asObservable()) {
            $0 && $1
            }
            .bind(to: loginBtnEnable)
            .disposed(by: bag)
        
        let phoneNum = phoneNumberInput
        let verifyCode = verifyCodeInput
        
        loginBtnInput
            .asObservable()
            .filter {!phoneNum.value.isEmpty && !verifyCode.value.isEmpty}
            .bind(to: viewModel.loginBtnInput)
            .disposed(by: bag)
        
        getVerifyCodeInput
            .asObservable()
            .filter {phoneNum.value.isEmpty}
            .subscribe(onNext: {
                HUD.flash(.label("手机号不能为空"), delay: 2)
            })
            .disposed(by: bag)
        
        audioCodeBtnInput
            .asObservable()
            .filter {phoneNum.value.isEmpty}
            .subscribe(onNext: {
                HUD.flash(.label("手机号不能为空"), delay: 2)
            })
            .disposed(by: bag)
        
        loginBtnInput
            .asObservable()
            .filter {phoneNum.value.isEmpty || verifyCode.value.isEmpty}
            .subscribe(onNext: {
                HUD.flash(.label("手机号或验证码不能为空"), delay: 2)
            })
            .disposed(by: bag)
        
        viewModel.pictureCaptchaOutput
            .asObservable()
            .subscribe(onNext: {[weak self]  in
                let vcc = PictureCaptchaViewController($0)
                vcc.modalPresentationStyle = .custom
                vcc.modalTransitionStyle = .crossDissolve
                self?.present(vcc, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        viewModel.mssageOutput
            .asObservable()
            .asDriverOnErrorJustComplete()
            .drive(HUD.flash)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Account.update)
            .subscribe(onNext: {[weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
                NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.loginSuccessPopBack, object: nil)
            })
            .disposed(by: bag)
    }


}
extension LoginViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let model =  try? dataSource.model(at: indexPath) as? String else {
            return 0
        }
        if model == "手机号" {
            return 58
            
        } else if model == "验证码" {
             return 58
            
        } else if model == "邀请码" {
             return 58
        } else if model == "语音验证码" {
             return 70
        } else if model == "登录" {
             return 70
        } else if model == "说明" {
              return 80
        }
        return 10
    }
}
