//
//  DownlodCenterViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DownlodCenterViewController: BaseViewController {
    @IBOutlet weak var lablel1: UILabel!
    @IBOutlet weak var lablel0: UILabel!
    @IBOutlet weak var tableView: UITableView!
    fileprivate let deleteInput: PublishSubject<DownloadLocalBook> = .init()
    fileprivate let reloadInput: PublishSubject<Int> = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    convenience init(_ viewModel: DownloadCenterViewModel) {
        self.init(nibName: "DownlodCenterViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }

    private func config(_ viewModel: DownloadCenterViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        let rightItem = UIBarButtonItem(title: "清空", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = rightItem
        tableView.registerNibWithCell(DownloadCenterTableViewCell.self)
        title = "下载中心"
        tableView.rx.modelSelected(DownloadLocalBook.self)
            .bind(to: viewModel.itemSelectInput)
            .disposed(by: bag)
        
        viewModel.dataDriver
            .debug()
            .drive(tableView.rx.items(cellIdentifier: String(describing: DownloadCenterTableViewCell.self), cellType: DownloadCenterTableViewCell.self)) { [weak self](row, element, cell) in
                cell.config(element)
                if let weakSelf = self {
                    cell.deletebtn.rx.tap.map { element }.bind(to: weakSelf.deleteInput).disposed(by: cell.bag)
                    cell.reloadBtn.rx.tap.map { row }.bind(to: weakSelf.reloadInput).disposed(by: cell.bag)
                }

            }
            .disposed(by: bag)
        
        tableView.rx.setDelegate(self).disposed(by: bag)

        rightItem.rx.tap
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                DefaultWireframe.shared.promptFor(title: nil, message: "确认清空下载列表", cancelAction: "不了", actions: ["确认"])
                    .filter { $0 == "确认" }
                    .mapToVoid()
                    .bind(to: viewModel.clearAllInput)
                    .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)
       
        deleteInput.asObservable()
            .subscribe(onNext: {[weak self] (book) in
                guard let weakSelf = self else {
                    return
                }
                 DefaultWireframe.shared.promptFor(title: nil, message: "确认删除", cancelAction: "不了", actions: ["确认"])
                    .filter { $0 == "确认" }
                    .subscribe(onNext: { (_) in
                        viewModel.deleteInput.onNext(book)
                    })
                    .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)

        reloadInput.asObservable()
            .bind(to: viewModel.reloadInput)
            .disposed(by: bag)

        viewModel.reloadOutput
            .drive(onNext: { [weak self](vm) in
                self?.navigationController?.pushViewController(ChooseChapterViewController(vm), animated: true)
            })
            .disposed(by: bag)
        
        viewModel.itemSelectOutput
            .drive(onNext: { [weak self](vm) in
                self?.navigationController?.pushViewController(ChooseChapterViewController(vm), animated: true)
            })
            .disposed(by: bag)
        
        
        lablel1.text = "剩余: " + FileService.freeDiskSpaceDesc()
        lablel0.text = "已用: " + FileService.usedDiskSpaceInBytes()
        
        viewModel.activityDriver
            .debug()
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.exception
            .drive(self.rx.exception)
            .disposed(by: bag)
        
      
    }
    
    
    
    
}

extension DownlodCenterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 114
    }
    
}


