//
//  ChargeViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import PKHUD
import RealmSwift

class ChargeViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    fileprivate lazy var headerView: ChargeHeaderVIew = {
        let headerView = ChargeHeaderVIew.loadView()
        return headerView
    }()
    
    let openVipInput: PublishSubject<Void> = .init()
    let vipExchangeInput: PublishSubject<Void> = .init()
    let openJDInput: PublishSubject<Void> = .init()
    
   lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<ChargeViewSectionType, ChargeModel>>(configureCell: {[weak self](dataSoure, tableView, indexPath, element) -> UITableViewCell in
        let sectionType = dataSoure.sectionModels[indexPath.section].model
        switch sectionType {
        case .vipDesc:
            let cell = tableView.dequeueCell(ImageTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            return cell
        case .goodList:
            let cell = tableView.dequeueCell(ChargeTableViewCell.self, for: indexPath)
            cell.config(element.pay_title, subTitle: "￥ " + "\(element.pay_fee / 100)" , isSelected: element.isSelected)
             cell.selectionStyle = .none
            return cell
        case .openVip(let title):
            let cell = tableView.dequeueCell(ChargeBtnTableViewCell.self, for: indexPath)
            cell.btn.setTitle(title, for: .normal)
            if let weakSelf = self {
                cell.btn.rx.tap.bind(to: weakSelf.openVipInput).disposed(by: cell.bag)
            }
             cell.selectionStyle = .none
            return cell
        case .vipRightDesc:
            let cell = tableView.dequeueCell(ChargeDescTableViewCell.self, for: indexPath)
             cell.selectionStyle = .none
            return cell
        case .vipPicDesc:
            let cell = tableView.dequeueCell(ChargeDescPicTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            if let weakSelf = self {
                cell.btn.rx.tap.bind(to: weakSelf.openJDInput).disposed(by: cell.bag)
            }
            return cell
        }
    })
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    convenience init(_ viewModel: ChargeViewModel) {
        self.init(nibName: "ChargeViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
                self?.configUI(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }

    
    fileprivate func configUI(_ viewModel: ChargeViewModel) {
        let headerViewContainer = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 156))
        headerView.frame = headerViewContainer.bounds
        headerView.btn.rx.tap.bind(to: openVipInput).disposed(by: bag)
        headerView.vipChangeBtn.rx.tap.bind(to: vipExchangeInput).disposed(by: bag)
        headerViewContainer.addSubview(headerView)
        tableView.tableHeaderView = headerViewContainer
        let rightItem = UIBarButtonItem(title: "交易记录", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = rightItem
        rightItem.rx.tap
            .bind(to: viewModel.rightBtnInput)
            .disposed(by: bag)
        
        viewModel.chargeRecordOutput.subscribe(onNext: { [weak self] vm in
            guard let weakSelf = self else {
                return
            }
            weakSelf.navigationController?.pushViewController(ChargeRecordViewController(vm), animated: true)
        })
            .disposed(by: bag)

    }

    private func config(_ viewModel: ChargeViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        title = "VIP会员"
        tableView.registerNibWithCell(ChargeTableViewCell.self)
        tableView.registerNibWithCell(ChargeDescTableViewCell.self)
        tableView.registerNibWithCell(ImageTableViewCell.self)
        tableView.registerNibWithCell(ChargeBtnTableViewCell.self)
        tableView.registerClassWithCell(UITableViewCell.self)
        tableView.registerNibWithCell(ChargeDescPicTableViewCell.self)
        tableView.rx.setDelegate(self).disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Account.update)
            .map {_ in  me }
            .bind(to: headerView.rx.refreshUI)
            .disposed(by: bag)
        
        viewModel.items
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        tableView.rx.modelSelected(ChargeModel.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        viewModel.lgoinDriver
            .drive(onNext: {[weak self] (loginVM) in
                guard let weakSelf = self else {
                    return
                }
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                if let existedRecord = realm.objects(FlashLoginTime.self).first,
                    existedRecord.loginNum >= 10,
                    existedRecord.loginTime >= Date().todayStartTime.timeIntervalSince1970,
                    existedRecord.loginTime < Date().todayEndTime.timeIntervalSince1970 {
                    NotificationCenter.default.post(name: NSNotification.Name.Account.flashLoginFailed, object: nil)
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
                                weakSelf.navigationController?.pushViewController(LoginViewController(loginVM), animated: true)
                            })
                        })
                        .disposed(by: self!.bag)
                    
                }
                
                CLShanYanSDKManager.quickAuthLogin(with: baseUIConfigure, timeOut: 5, complete: { (result) in
                    if let error = result.error as NSError?,  error.code != 1011 {
                        if let presenterVC = self?.presentedViewController {
                            presenterVC.dismiss(animated: true, completion: {
                                weakSelf.navigationController?.pushViewController(LoginViewController(loginVM), animated: true)
                            })
                        } else {
                            weakSelf.navigationController?.pushViewController(LoginViewController(loginVM), animated: true)
                        }
                    } else {
                        guard let data = result.data as? [String: Any],
                            let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                            let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8 ) else {
                                return
                        }
                        viewModel.flashDataInput.accept(jsonStr)
                    }
                })
            })
            .disposed(by: bag)
        
        openVipInput
            .asObservable()
            .bind(to: viewModel.openVipInput)
            .disposed(by: bag)
        
        openJDInput
            .asObservable()
            .bind(to: viewModel.jdWebBtnInput)
            .disposed(by: bag)
        
        vipExchangeInput.asObservable()
            .bind(to: viewModel.exchangeBtnInput)
            .disposed(by: bag)
        
        viewModel.exchangeViewModel
            .subscribe(onNext: {[weak self] (vm) in
                guard let weakSelf = self else {
                    return
                }
                let vcc = ExchangeJDCodeViewController(vm)
                weakSelf.navigationController?.pushViewController(vcc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel.jdWebViewModel
            .subscribe(onNext: {[weak self] (vm) in
                guard let weakSelf = self else {
                    return
                }
                let vcc = CommonWebViewController(vm)
                weakSelf.navigationController?.pushViewController(vcc, animated: true)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Account.flashLoginFailed)
            .mapToVoid()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.pushViewController(LoginViewController(LoginViewModel()), animated: true)
            })
            .disposed(by: bag)
        
    }
}


extension ChargeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = dataSource.sectionModels[indexPath.section].model
        switch sectionType {
        case .vipDesc:
            return 90
        case .goodList:
            return 80
        case .openVip:
            return 100
        case .vipRightDesc:
            return 200
        case .vipPicDesc:
            return 210
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
         return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        return UIView()
    }
}
