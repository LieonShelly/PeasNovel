//
//  BookSheetHorizontalController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD

class BookSheetHorizontalController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<Void, BookSheetListModel>>(configureCell: {_, tv, ip, model in
        let cell = tv.dequeueCell(BookDetailCoverRightCell.self, for: ip)
        cell.set(model)
        return cell
    })
    
    convenience init(_ viewModel: BookSheetDetailViewModel) {
        self.init(nibName: "BookSheetHorizontalController", bundle: nil)
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
    
    func config(_ viewModel: BookSheetDetailViewModel) {
        
        
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
        
        self.exception
            .mapToVoid()
            .bind(to: viewModel.exceptionInput)
            .disposed(by: bag)
        
        
        tableView
            .rx
            .modelSelected(BookSheetListModel.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        addButton
            .rx
            .tap
            .bind(to: viewModel.addBookshelfAction)
            .disposed(by: bag)
        
        viewModel
            .isBookshelf
            .debug()
            .drive(addButton.rx.isHidden)
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: {
                 BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
        
        viewModel
            .section
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .dataSource
            .subscribe(onNext: { [unowned self] in
                let url = URL(string: $0.boutique_img ?? "")
                self.coverImageView.kf.setImage(with: url, placeholder: UIImage())
                self.titleLabel.text = $0.boutique_title
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        
        self.title = "书单详情"
        
        tableView.registerNibWithCell(BookDetailCoverRightCell.self)
    }

}
