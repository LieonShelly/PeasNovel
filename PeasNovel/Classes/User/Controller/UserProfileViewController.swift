//
//  UserProfileViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/24.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import Photos
import CameraViewController
import RxDataSources
import RxCocoa
import PKHUD
import Moya


class UserProfileViewController: BaseViewController {
    var avatarBase64Input: PublishSubject<String> = .init()
    let avatarEdit: PublishSubject<Void> = .init()
    @IBOutlet weak var tableView: UITableView!
    let phoneNumberInput: BehaviorRelay<String> = .init(value: "")
    let nickNameInput: BehaviorRelay<String> = .init(value: "")
    let sexInput: BehaviorRelay<String> = .init(value: "")
    let registerBtnInput: PublishSubject<Void> = .init()
    
    ///output
    let verifyCodeBtnEnable: PublishSubject<Bool> = .init()
    let loginBtnEnable: PublishSubject<Bool> = .init()
    let phoneNumberValid: PublishSubject<Bool> = .init()
    let verifyCodeValid: PublishSubject<Bool> = .init()

    
    fileprivate lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<UserProfileSectionType, UserProfileUIModel>>(configureCell: {[weak self] (source, tv, ip, model) -> UITableViewCell in
        let sectionType = source.sectionModels[ip.section].model
        switch sectionType {
        case .header(let icon):
             let cell = tv.dequeueCell(HeaderIconTableViewCell.self, for: ip)
             cell.configLocal(icon)
             cell.selectionStyle = .none
             return cell
        case .profile:
            let cell = tv.dequeueCell(UserProfileTextTableViewCell.self, for: ip)
            cell.config(model.title, subTitle: model.subTitle)
            if let weakSelf = self {
                if ip.row == 0  { // "手机号"
                    var str = model.subTitle
                    if let range = Range<String.Index>(NSRange(location: 3, length: 5), in: str)  {
                        str.replaceSubrange( range, with: "xxxxx")
                    }
                    cell.config(model.title, subTitle: str)
                    cell.textField.isUserInteractionEnabled = false
                    cell.textField.rx.text.orEmpty.map {$0}
                        .bind(to: weakSelf.phoneNumberInput)
                        .disposed(by: cell.bag)
                    cell.icon.isHidden = true
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
                } else  if ip.row == 1  { /// "昵 称"
                    cell.textField.isUserInteractionEnabled = true
                    cell.textField.placeholder = "请您输入昵称"
                     cell.icon.isHidden = false
                    cell.didEndEdit
                        .asObservable()
                        .debug()
                        .bind(to: weakSelf.nickNameInput)
                        .disposed(by: cell.bag)
                } else if ip.row == 2 { //性别
                    cell.textField.isUserInteractionEnabled = false
                    cell.textField.placeholder = "请您选择性别"
                     cell.icon.isHidden = false
                }
            }
             cell.selectionStyle = .none
            return cell
        case .btn:
            let cell = tv.dequeueCell(CenterBtnTableViewCell.self, for: ip)
            cell.btn.setTitle("退出登录", for: .normal)
            if let weakSelf = self {
                cell.btn.rx.tap.mapToVoid()
                    .bind(to: weakSelf.registerBtnInput)
                    .disposed(by: cell.bag)
                
            }
             cell.selectionStyle = .none
            return cell
        }
    })
    
    
    convenience init(_ viewModel: UserProfileViewModel) {
        self.init(nibName: "UserProfileViewController", bundle: nil)
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
    

    func config(_ viewModel: UserProfileViewModel) {
        tableView.keyboardDismissMode = .onDrag
        title = "我的资料"
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        tableView.registerNibWithCell(UserProfileTextTableViewCell.self)
        tableView.registerNibWithCell(CenterBtnTableViewCell.self)
        tableView.registerClassWithCell(UITableViewCell.self)
        tableView.registerNibWithCell(HeaderIconTableViewCell.self)
        
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: bag)
        
        viewModel
            .sections
            .asObservable()
            .debug()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        tableView.rx.itemSelected
            .map { $0 }
            .filter { $0.section == 1 && $0.row == 2}
            .mapToVoid()
            .bind(to: viewModel.changeSexinput)
            .disposed(by: bag)
        
        nickNameInput.asObservable()
            .debug()
            .filter { !$0.isEmpty }
            .bind(to: viewModel.nicknameInput)
            .disposed(by: bag)
        
        registerBtnInput.asObservable()
            .subscribe(onNext: {[weak self] (_) in
                NotificationCenter.default.post(name: Notification.Name.Account.signOut, object: nil)
                let provider = MoyaProvider<UserCenterService>()
                provider
                    .rx
                    .request(.deviceLogin)
                    .asObservable()
                    .debug()
                    .userUpdate()
                    .disposed(by: self!.bag)
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
        
    
        }
    
}

extension UserProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section >=  dataSource.sectionModels.count {
            return 0
        }
        let sectionType =   dataSource.sectionModels[indexPath.section].model
        switch sectionType {
        case .header:
            return  150
        case .profile:
            return 52
        case .btn:
            return 160
        }
        
    }
}
