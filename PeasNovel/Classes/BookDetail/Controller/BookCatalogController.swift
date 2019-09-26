//
//  BookCatalogController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RealmSwift

class BookCatalogController: BaseViewController {

    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toTopButton: UIButton!
    @IBOutlet weak var verticalSlider: VerticalSlider!
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<Void, BookCatalogModel>>(configureCell: {_, tv, ip, model in
        let cell = tv.dequeueCell(UITableViewCell.self, for: ip)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.textColor = UIColor(0x666666)
        cell.textLabel?.text = model.title
        cell.selectionStyle = .none
        return cell
    })
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    convenience init(_ viewModel: BookCatalogViewModel) {
        self.init(nibName: "BookCatalogController", bundle: nil)
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
    
    func config(_ viewModel: BookCatalogViewModel) {
        
        tableView
            .rx
            .modelSelected(BookCatalogModel.self)
            .bind(to: viewModel.itemSelected)
            .disposed(by: bag)
        
        tableView
            .mj_header
            .rx
            .start
            .bind(to: viewModel.headerRefresh)
            .disposed(by: bag)
        
        tableView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
        sortButton
            .rx
            .tap
            .map{ [unowned self] in self.sortButton.isSelected }
            .bind(to: viewModel.sortAction)
            .disposed(by: bag)
        
        toTopButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [weak self] in
                let ip = IndexPath(row: 0, section: 0)
                self?.tableView.scrollToRow(at: ip, at: .top, animated: true)
            })
            .disposed(by:  bag)
        
        viewModel
            .section
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .isReverse
            .drive(sortButton.rx.isSelected)
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: {
                 BookReaderHandler.jump($0.book_id, contentId: $0.content_id, toReader: true)
            })
            .disposed(by: bag)
        
        viewModel
            .toReader
            .asObservable()
            .subscribe(onNext: {info in
                ReaderAdService.addWatchFiveChapterCount(info.book_title ?? "")
            })
            .disposed(by: bag)
        
        viewModel
            .endRefresh
            .drive(tableView.mj_header.rx.end)
            .disposed(by: bag)
        
        viewModel
            .endRefresh
            .drive(tableView.mj_footer.rx.resetNoMoreData)
            .disposed(by: bag)

        viewModel
            .endMoreDaraRefresh
            .drive(tableView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
        
    }
    
    func configUI() {
        tableView.registerClassWithCell(UITableViewCell.self)
        tableView.rowHeight = 40
        tableView.estimatedRowHeight = 40
        
        tableView.delegate = self
        
        tableView.mj_header = RefreshHeader()
        tableView.mj_footer = RefreshFooter()
        
    }

}

extension BookCatalogController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height-scrollView.bounds.height <= 0 {
            verticalSlider.isHidden = true
        }else{
            verticalSlider.isHidden = false
            let offsetY = 1-scrollView.contentOffset.y/(scrollView.contentSize.height-scrollView.bounds.height)
            verticalSlider.value = offsetY
        }
    }
}
