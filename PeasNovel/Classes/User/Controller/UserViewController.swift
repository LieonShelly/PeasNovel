//
//  UserViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import PKHUD
import RealmSwift

class UserViewController: BaseViewController {
    @IBOutlet weak var contactBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    fileprivate lazy var headerView: UserInfoView = {
        let headerView = UserInfoView.loadView()
        return headerView
    }()
    
    let dataSource = RxTableViewSectionedReloadDataSource<UserPageSection>(configureCell: { (_, tv, ip, model) -> UITableViewCell in
        let cell = tv.dequeueCell(UserTableViewCell.self, for: ip)
        
        cell.set(model.title, iconName: model.iconName)
        
        return cell
    })
    
    convenience init(_ viewModel: UserViewModel) {
        self.init(nibName: "UserViewController", bundle: nil)
      
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
        
        
        self.rx
            .viewDidAppear
            .bind(to: viewModel.viewDidAppear)
            .disposed(by: bag)
        
        self.rx
            .viewDidDisappear
            .bind(to: viewModel.viewDidDisappear)
            .disposed(by: bag)
    }
    
    
    func config(_ viewModel: UserViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        let header = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 190))
        headerView.frame = header.bounds
        header.addSubview(headerView)
        tableView.tableHeaderView = header
        tableView.registerNibWithCell(UserTableViewCell.self)
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: bag)
        
        headerView.loginBtn.rx.tap
            .asObservable()
            .map {UserPageModel("", title: "登录")}
            .bind(to: viewModel.itemDidSelectedInput)
            .disposed(by: bag)
        
        headerView.nameBtn.rx.tap
            .asObservable()
            .bind(to: viewModel.headerIconInput)
            .disposed(by: bag)
        
        headerView.iconBtn.rx.tap
            .asObservable()
            .bind(to: viewModel.headerIconInput)
            .disposed(by: bag)
        
        tableView.rx.modelSelected(UserPageModel.self)
            .bind(to: viewModel.itemDidSelectedInput)
            .disposed(by: bag)
        
        viewModel
            .sections
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel.phoneNumViewModel
            .subscribe(onNext: { [weak self] loginVm in
                let vcc = LoginViewController(loginVm)
                self?.navigationController?.pushViewController(vcc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel.loginOutput
            .subscribe(onNext: { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                if let existedRecord = realm.objects(FlashLoginTime.self).first,
                    existedRecord.loginNum >= 10,
                    existedRecord.loginTime >= Date().todayStartTime.timeIntervalSince1970,
                    existedRecord.loginTime < Date().todayEndTime.timeIntervalSince1970 {
                    viewModel.otherLoginInput.onNext(())
                    return
                }
                let baseUIConfigure = CLUIConfigure()
                let iconTop: Double = Double(100.0.fitScale)
                let iconheight: Double = 82
                let phonumTop: Double = 25 + iconTop + iconheight
                let phoneNumHeight: Double = 25
                let logintBtnTop: Double = 36 +  phoneNumHeight + phonumTop
                let logiBtnHeight: Double = 45
                let bottomViewTop: Double = logiBtnHeight + logintBtnTop + 10
                let title = "手机号快速登录"
                let titleAttr = NSMutableAttributedString(string: title)
                titleAttr.setAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 21)], range: NSRange(location: 0, length: 7))
                titleAttr.setAttributes([NSAttributedString.Key.foregroundColor: UIColor(0x333333)], range: NSRange(location: 0, length: 7))
                baseUIConfigure.cl_navigation_attributesTitleText = titleAttr
                baseUIConfigure.cl_navigation_tintColor = UIColor.black
                let backItem = UIBarButtonItem(image: UIImage(named: "back"), style: UIBarButtonItem.Style.plain, target: nil, action: nil)
                backItem.rx.tap
                    .mapToVoid()
                    .subscribe(onNext: { (_) in
                        weakSelf.presentedViewController?.dismiss(animated: true, completion: nil)
                    })
                    .disposed(by: weakSelf.bag)
                baseUIConfigure.cl_navigation_leftControl = backItem

                baseUIConfigure.clLogoImage = UIImage(named: "flash_logo")!
                baseUIConfigure.clLogoOffsetY = NSNumber(floatLiteral: Double(iconTop))
                baseUIConfigure.clLoginBtnHeight = NSNumber(floatLiteral: Double(iconheight))
                
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
                    view.backgroundColor = UIColor.white
                    let bottomView = FlashLoginBottomView.loadView()
                    view.addSubview(bottomView)
                    bottomView.snp.makeConstraints({
                        $0.left.right.equalTo(0)
                        $0.height.equalTo(155)
                        $0.top.equalTo(bottomViewTop)
                    })
                    bottomView.otherBtn.rx.tap
                        .mapToVoid()
                        .subscribe(onNext: {[weak self] (_) in
                            self?.presentedViewController?.dismiss(animated: true, completion: {
                                viewModel.otherLoginInput.onNext(())
                            })
                        })
                        .disposed(by: self!.bag)
                    
                }
                
                CLShanYanSDKManager.quickAuthLogin(with: baseUIConfigure, timeOut: 5, complete: { (result) in
                    if let error = result.error as NSError?,  error.code != 1011 {
                        if let presenterVC = self?.presentedViewController {
                            presenterVC.dismiss(animated: true, completion: {
                                viewModel.otherLoginInput.onNext(())
                            })
                        } else {
                            viewModel.otherLoginInput.onNext(())
                        }
                    } else {
                        guard let data = result.data as? [String: Any],
                            let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                            let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8 ) else {
                                return
                        }
                        viewModel.flashDataInput.onNext(jsonStr)
                    }
                })
            })
            .disposed(by: bag)
        
        viewModel.readFavorOutput
            .subscribe(onNext: { [weak self] in
                self?.present(NavigationViewController(rootViewController: ReadFavorViewController($0)), animated: true)
            })
              .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Account.update)
            .subscribe(onNext: {[weak self] (_) in
                self?.headerView.config()
            })
            .disposed(by: bag)
        
        viewModel.downloadCenterOutput
            .subscribe(onNext: {[weak self] (vm) in
                self?.navigationController?.pushViewController(DownlodCenterViewController(vm), animated: true)
            })
            .disposed(by: bag)
        
        viewModel.feedbackOutput
            .subscribe(onNext: {[weak self] (vm) in
                self?.navigationController?.pushViewController(FeedbackViewController(vm), animated: true)
            })
            .disposed(by: bag)
        
        viewModel.chargeOutput
            .subscribe(onNext: {[weak self] (vm) in
                self?.navigationController?.pushViewController(ChargeViewController(vm), animated: true)
            })
            .disposed(by: bag)
        
        viewModel.userInfoViewModel
            .subscribe(onNext: {[weak self] (vm) in
                self?.navigationController?.pushViewController(UserProfileViewController(vm), animated: true)
            })
            .disposed(by: bag)
        
        
        viewModel
            .settingViewModel
            .subscribe(onNext: { [unowned self] in
                let vc = SettingViewController($0)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        contactBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                let vcc = ContactServiceAlertViewController()
                vcc.modalPresentationStyle = .custom
                vcc.modalTransitionStyle = .crossDissolve
                navigator.present(vcc)
            })
            .disposed(by: bag)

        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
            tableView.contentInset.top =  -view.safeAreaInsets.top
            tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 190 + view.safeAreaInsets.top)
        } else {
            tableView.contentInset.top =  0
        }
    }
}


extension UserViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      
    }
}


