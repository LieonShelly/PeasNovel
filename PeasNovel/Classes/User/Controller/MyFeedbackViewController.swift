//
//  MyFeedbackViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class MyFeedbackViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    convenience init(_ viewModel: MyFeedbackViewModel) {
        self.init(nibName: "MyFeedbackViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    private func config(_ viewModel: MyFeedbackViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.estimatedRowHeight = 90
        title = "我的反馈"
        tableView.registerNibWithCell(MyFeedUnreplyTableViewCell.self)
        tableView.registerNibWithCell(MyFeedReplyTableViewCell.self)
        tableView.delegate = self
        tableView.separatorStyle = .none
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, MyFeedback>>(configureCell: { (dataSource, tableView, indexPath, item) -> UITableViewCell in
            if item.suggest_reply == nil {
                let cell = tableView.dequeueCell(MyFeedUnreplyTableViewCell.self, for: indexPath)
                cell.config(item)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueCell(MyFeedReplyTableViewCell.self, for: indexPath)
                cell.config(item)
                cell.selectionStyle = .none
                return cell
            }
        })

        viewModel.datas
            .drive(tableView.rx.items(dataSource: dataSource))
             .disposed(by: bag)

        viewModel.activityOutput
            .drive(self.rx.loading)
            .disposed(by: bag)

        viewModel.exceptionOutputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
       
        
    }
    
    
    
    
}

extension MyFeedbackViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}


