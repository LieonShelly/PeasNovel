//
//  BookSheetChoiceController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import PKHUD

class BookSheetChoiceController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    var favorAction: PublishSubject<String> = .init()
    let bookItemSelected: PublishSubject<BookSheetListModel> = .init()
    
    lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<Void, BookSheetModel>>(configureCell: {[unowned self] _, tv, ip, model in
        let cell = tv.dequeueCell(BookSheetChoiceTableViewCell.self, for: ip)
        cell.set(model)
        cell.favorAction
            .bind(to: self.favorAction)
            .disposed(by: cell.bag)
        cell.itemSelected
            .bind(to: self.bookItemSelected)
            .disposed(by: cell.bag)
        return cell
    })
    
    convenience init(_ viewModel: BookSheetChoiceViewModel) {
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
    
    func config(_ viewModel: BookSheetChoiceViewModel) {
        
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
            .modelSelected(BookSheetModel.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        favorAction
            .bind(to: viewModel.favorAction)
            .disposed(by: bag)
        
        bookItemSelected
            .bind(to: viewModel.bookItemSelected)
            .disposed(by: bag)
        
        viewModel
            .section
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .bookSheetDetail
            .subscribe(onNext: {
                navigator.push($0.router, context: $0)
            })
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: {
                BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        
        tableView.registerNibWithCell(BookSheetChoiceTableViewCell.self)
        tableView.delegate = self
        
        title = "精选书单"
        
    }
}

extension BookSheetChoiceController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(0xF4F6F9)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 5
    }
}
