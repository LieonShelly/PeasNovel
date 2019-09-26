//
//  ReadFavorViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

import RxSwift
import RxDataSources
import RxCocoa
import PKHUD

class ReadFavorViewController: BaseViewController {
    @IBOutlet weak var enterBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
  
    
    convenience init(_ viewModel: ReadFavorViewModel, isFirstLaunch: Bool = false) {
        self.init(nibName: "ReadFavorViewController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.config(viewModel, isFirstLaunch: isFirstLaunch)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    fileprivate func config(_ viewModel: ReadFavorViewModel, isFirstLaunch: Bool = false) {
        title = "阅读偏好"
        collectionView.keyboardDismissMode = .onDrag
        enterBtn.layer.cornerRadius = 23
        enterBtn.layer.masksToBounds = true
        collectionView.registerNibWithCell(ReadFavorCell.self)
        collectionView.registerClassWithCell(UICollectionViewCell.self)
        collectionView.registerNibWithReusableView(BookSectionHederView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        
        let rightBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 22))
        rightBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        rightBtn .setTitleColor(UIColor(0x999999), for: UIControl.State.normal)
        rightBtn .setTitle("跳过", for: .normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBtn)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Category>>(configureCell: { (dataSource, collectionView, ip, model) -> UICollectionViewCell in
            let cell = collectionView.dequeueCell(ReadFavorCell.self, for: ip)
            cell.config(model.short_name, isSelcted: model.isSelected)
            return cell
        }, configureSupplementaryView: { (data, collectionView, kind, indexPath) in
            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueReusableView(BookSectionHederView.self, ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
                 header.label.textColor = UIColor(0x999999)
                 header.label.text = data.sectionModels[indexPath.section].model
                 header.label.font = UIFont.systemFont(ofSize: 17)
                 header.btn.isHidden = true
                return header
            }
            let reuseView = collectionView.dequeueReusableView(UICollectionReusableView.self, ofKind: kind, for: indexPath)
            return reuseView
        })
        
        viewModel.items
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
       viewModel.items
            .map { $0.isEmpty }
            .drive(enterBtn.rx.isHidden)
            .disposed(by: bag)
        
        collectionView.rx.modelSelected(Category.self)
            .bind(to: viewModel.itemSelectIput)
            .disposed(by: bag)
        
        
        collectionView.rx.setDelegate(self).disposed(by: bag)
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        rightBtn.rx.tap.map{isFirstLaunch}
            .bind(to: viewModel.skipBtnIput)
            .disposed(by: bag)
        
        enterBtn.rx.tap.mapToVoid()
            .bind(to: viewModel.enterBtnIput)
            .disposed(by: bag)
        
        rightBtn.rx.tap
            .filter {_ in isFirstLaunch == false }
            .subscribe(onNext: { [weak self]() in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.dismiss(animated: true, completion: nil)
        })
            .disposed(by: bag)
        

        viewModel.settingResult
            .filter {_ in isFirstLaunch == false }
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                if $0.status?.code == 0 {
                    weakSelf.dismiss(animated: true, completion: nil)
                } else {
                    HUD.flash(.label($0.status?.msg ?? ""), delay: 2)
                }
            })
            .disposed(by: bag)
        
        
        /// 首次安装，点击跳过，无用户ID，先获取用户信息，广告信息，成功之后，再跳转
        Observable.combineLatest(rightBtn.rx.tap.filter {_ in isFirstLaunch == true },
                                 NotificationCenter.default.rx.notification(Notification.Name.Account.update).asObservable(),
                                 NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate).asObservable())
            .mapToVoid()
            .take(1)
            .subscribe(onNext: { [weak self]() in
                guard let weakSelf = self else {
                    return
                }
                NotificationCenter.default.post(name: Notification.Name.Event.reloadApp, object: weakSelf)
            })
            .disposed(by: bag)
        
        /// 首次安装，点击跳过，有用户ID，先获取，广告信息，成功之后，再跳转
        Observable.combineLatest(rightBtn.rx.tap.filter {_ in isFirstLaunch == true }.filter { me.user_id?.isEmpty == false },
                                 NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate).asObservable())
            .mapToVoid()
            .take(1)
            .subscribe(onNext: { [weak self]() in
                guard let weakSelf = self else {
                    return
                }
                NotificationCenter.default.post(name: Notification.Name.Event.reloadApp, object: weakSelf)
            })
            .disposed(by: bag)
        
        viewModel.settingResult
            .filter {_ in isFirstLaunch == true }
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                if $0.status?.code == 0 {
                    NotificationCenter.default.post(name: Notification.Name.Event.reloadApp, object: weakSelf)
                } else {
                    HUD.flash(.label($0.status?.msg ?? ""), delay: 2)
                }
            })
            .disposed(by: bag)
        
        viewModel.activityOutput
            .debug()
            .drive(self.rx.loading)
            .disposed(by: bag)

        self.exception.asObservable()
            .mapToVoid()
            .bind(to: viewModel.exceptionInput)
            .disposed(by: bag)
        
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        debugPrint(self.description + "deinit")
    }
    
}

extension ReadFavorViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 14
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 19
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
         return CGSize(width: UIScreen.main.bounds.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let rowHeight: CGFloat = 39
        let minInterSpace: CGFloat = 19
        let inset: CGFloat = 16
        return CGSize(width: (UIScreen.main.bounds.width - minInterSpace * 2 - inset * 2) / 3.0001, height: rowHeight)
    }
    
 
}

