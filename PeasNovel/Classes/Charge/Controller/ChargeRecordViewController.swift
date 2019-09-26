//
//  ChargeRecordViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import MJRefresh

class ChargeRecordViewController: BaseViewController {
   @IBOutlet weak var tableView: UITableView!
    
   
    convenience init(_ viewModel: ChargeRecordViewModel) {
        self.init(nibName: "ChargeViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    
    
    private func config(_ viewModel: ChargeRecordViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        title = "交易记录"
        tableView.registerNibWithCell(ChargeRecordTableViewCell.self)
        tableView.rx.setDelegate(self).disposed(by: bag)
        
        viewModel.items
            .drive(tableView.rx.items(cellIdentifier:String(describing: ChargeRecordTableViewCell.self), cellType: ChargeRecordTableViewCell.self)) { (row, element, cell) in
                cell.selectionStyle = .none
                cell.config(element)
        }
        .disposed(by: bag)
        
        tableView.mj_footer = RefreshFooter(refreshingBlock: {
            viewModel.refreshInput.onNext(false)
        })
        
        tableView.mj_footer.isHidden = true
        
        viewModel.items
            .map { $0.isEmpty }
            .drive(tableView.mj_footer.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.refresStatus
            .asObservable()
            .bind(to: tableView.rx.mj_RefreshStatus)
            .disposed(by: bag)
        
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.excepotionDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
    }

}


extension ChargeRecordViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return 170
    }
}
