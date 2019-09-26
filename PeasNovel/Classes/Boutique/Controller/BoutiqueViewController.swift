//
//  BoutiqueViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import PKHUD

class BoutiqueViewController: BaseViewController {
    @IBOutlet weak var navigationBarTop: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    let cellButtonAction: PublishSubject<String> = .init()
    
    lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Any>>(configureCell: {[weak self] _, tv, ip, model in
        if let model = model as? [BoutiqueActiveModel] {
            let cell = tv.dequeueCell(TwoBtnTableViewCell.self, for: ip)
            cell.set(model)
            if let weakSelf = self {
                cell.buttonTap
                    .bind(to: weakSelf.cellButtonAction)
                    .disposed(by: cell.bag)
            }
            return cell
        }
        if let model = model as? BoutiqueModel {
            let cell = tv.dequeueCell(BoutiqueTableViewCell.self, for: ip)
            cell.set(model)
            return cell
        }
        return UITableViewCell()
    })
    
    convenience init(_ viewModel: BoutiqueViewModel) {
        self.init(nibName: "BoutiqueViewController", bundle: nil)
        
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.configUI()
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if UIDevice.current.isiPhoneXSeries {
            navigationBarTop.constant = UIDevice.current.safeAreaInsets.top
        } else {
             navigationBarTop.constant = 20
        }
    }
    
    private func config(_ viewModel: BoutiqueViewModel) {
        
        cellButtonAction
            .bind(to: viewModel.cellBtnAction)
            .disposed(by: bag)

        searchButton
            .rx
            .tap
            .bind(to: viewModel.searchAction)
            .disposed(by: bag)
        
        tableView
            .rx
            .modelSelected(BoutiqueModel.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        self.exception
            .mapToVoid()
            .bind(to: viewModel.exception)
            .disposed(by: bag)
        
        viewModel
            .section
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .searchViewModel
            .subscribe(onNext: { [weak self] in
                let vc = SearchViewController($0)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel
            .router
            .subscribe(onNext: {
                navigator.push($0)
            })
            .disposed(by: bag)
        
        viewModel
            .bookSheetDetail
            .subscribe(onNext: {
                navigator.push($0.router, context: $0)
            })
            .disposed(by: bag)
        
        /// HUD
        viewModel
            .activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel
            .errorDriver
            .drive(HUD.flash)
            .disposed(by: bag)
        
        viewModel
            .activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel
            .exceptionDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        
        
    }
    
    private func configUI() {
        tableView.registerNibWithCell(TwoBtnTableViewCell.self)
        tableView.registerNibWithCell(BoutiqueTableViewCell.self)
        
//        self.title = "精品阅读"
        // Do any additional setup after loading the view.
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: seachButton)
    }
    
    lazy var seachButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "seach2"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        return button
    }()
}
