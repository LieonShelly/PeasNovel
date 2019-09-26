//
//  SettingViewController.swift
//  ClassicalMusic
//
//  Created by weicheng wang on 2019/1/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class SettingViewController: BaseViewController {

    
    @IBOutlet weak var tableView: UITableView!
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, (String, String)>>(configureCell: {_, tv, ip, model in
        let cell = tv.dequeueCell(SettingTableViewCell.self, for: ip)
        cell.set(model.0, info: model.1)
        return cell
    })
    
    convenience init(_ viewModel: SettingViewModel) {
        self.init(nibName: "SettingViewController", bundle: nil)
        
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
    
    private func config(_ viewModel: SettingViewModel) {
        
        tableView.registerNibWithCell(SettingTableViewCell.self)
        
        tableView
            .rx
            .modelSelected((String, String).self)
            .bind(to: viewModel.itemSelected)
            .disposed(by: bag)
        
        viewModel
            .section
            .bind(to: self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
//        
//        viewModel
//            .qualityViewModel
//            .subscribe(onNext: {
//                let vc = QualityViewController($0)
//                self.navigationController?.pushViewController(vc, animated: true)
//            })
//            .disposed(by: bag)
        
        viewModel
            .aboutAction
            .subscribe(onNext: { [unowned self] in
                let vc = AboutViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("setting", comment: "")
        // Do any additional setup after loading the view.
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 18))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

}
