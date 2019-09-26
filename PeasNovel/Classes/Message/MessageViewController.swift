//
//  MessageViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MessageViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!

    convenience init(_ viewModel: MessageViewModel) {
        self.init(nibName: "MessageViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    private func config(_ viewModel: MessageViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        title = "消息"
        tableView.registerNibWithCell(MessageTableViewCell.self)
        tableView.estimatedRowHeight = 120
        viewModel.items
            .debug()
            .drive(tableView.rx.items(cellIdentifier: String(describing: MessageTableViewCell.self), cellType: MessageTableViewCell.self)) { (row, element, cell) in
                cell.config(element)
            }
            .disposed(by: bag)
        
        viewModel.activityOutput
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.exceptionOutputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        tableView.rx.modelSelected(GEPushMessage.self)
            .asObservable()
            .map { $0.jump_url }
            .map { URL(string: $0)}
            .unwrap()
            .subscribe(onNext: {
                navigator.push($0)
            })
            .disposed(by: bag)
        
        tableView.rx.modelSelected(GEPushMessage.self)
            .bind(to: viewModel.itemDidSelect)
            .disposed(by: bag)
        
        
    }
    
    
    
    
}

extension MessageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}



