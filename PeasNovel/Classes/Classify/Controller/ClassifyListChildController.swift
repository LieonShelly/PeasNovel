//
//  ClassifyListChildController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD

class ClassifyListChildController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<Void, BookInfo>>(configureCell: {ds, tv, ip, model in
        let cell = tv.dequeueCell(BookDetailCoverRightCell.self, for: ip)
        cell.set(model)
        return cell
    })
    
    convenience init(_ viewModel: ClassifyListChildViewModel) {
        self.init()
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [unowned self] in
                self.configUI()
                self.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    func config(_ viewModel: ClassifyListChildViewModel) {
        
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.dataEmpty
            .drive(tableView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        tableView
            .rx
            .modelSelected(BookInfo.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        tableView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
        viewModel
            .section
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .endMoreDaraRefresh
            .drive(tableView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
        
        viewModel
            .gotoReader
            .subscribe(onNext: {
                 BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        
        tableView.registerNibWithCell(BookDetailCoverRightCell.self)
        
        tableView.mj_footer = RefreshFooter()
        
    }
}
