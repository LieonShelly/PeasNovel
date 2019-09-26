//
//  ReaerPopMenuViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PKHUD

struct PopMenuItem {
    var icon: String!
    var nname: String!
}

class ReaerPopMenuViewController: BaseViewController {
    @IBOutlet weak var popHeight: NSLayoutConstraint!
    @IBOutlet weak var containerTop: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var coverBtn: UIButton!
    var topInset: CGFloat = 100
    let bookDetailOutput: PublishSubject<BookDetailViewModel> = .init()
    let reportOutput: PublishSubject<ChapterReportViewModel> = .init()
    let catelogOutput: PublishSubject<BookCatalogViewModel> = .init()
    let downloadOutput: PublishSubject<ChooseChapterViewModel> = .init()
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coverBtn?.rx.tap.mapToVoid()
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
      
    }
    
    convenience init(_ viewModel: ReaderPopMenuViewModel) {
        self.init(nibName: "ReaerPopMenuViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: { [weak self](_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        
    }
    
    private func config(_ viewModel: ReaderPopMenuViewModel) {
        tableView.registerNibWithCell(PopMenuTableViewCell.self)
        let items = [
                PopMenuItem(icon: "z", nname: "加入书架"),
                PopMenuItem(icon: "q", nname: "书籍详情"),
                PopMenuItem(icon: "error", nname: "章节报错"),
                PopMenuItem(icon: "download", nname: "下    载"),
                PopMenuItem(icon: "reader_cate", nname: "目    录")
        ]
        tableView.separatorColor = UIColor(0xE5E5E5).withAlphaComponent(0.3)
        popHeight.constant = CGFloat(items.count) * 44.0
        view.layoutIfNeeded()
        Observable.just(items)
            .bind(to: tableView.rx.items(cellIdentifier: String(describing: PopMenuTableViewCell.self), cellType: PopMenuTableViewCell.self)) { (row, element, cell) in
                cell.icon.image = UIImage(named: element.icon)
                cell.label.text = element.nname
                cell.separatorInset = .zero
                cell.selectionStyle = .none
            }
            .disposed(by: bag)
        
        tableView.delegate = self
        
        tableView.rx.modelSelected(PopMenuItem.self)
            .filter { $0.nname == "加入书架"}
            .mapToVoid()
            .bind(to: viewModel.addBookshelfAction)
            .disposed(by: bag)
        
        tableView.rx.modelSelected(PopMenuItem.self)
            .filter { $0.nname == "书籍详情"}
            .mapToVoid()
            .bind(to: viewModel.bookDetailInput)
            .disposed(by: bag)
        
        tableView.rx.modelSelected(PopMenuItem.self)
            .bind(to: viewModel.modelSelected)
            .disposed(by: bag)
    
        
        viewModel
            .bookDetailOutput
            .asObservable()
            .bind(to: bookDetailOutput)
            .disposed(by: bag)
        
        viewModel.catelogOutput
            .asObservable()
            .bind(to: catelogOutput)
            .disposed(by: bag)
        
        viewModel.reportOutput
            .asObservable()
            .bind(to: reportOutput)
            .disposed(by: bag)
        
        viewModel.downloadOutput
            .asObservable()
            .bind(to: downloadOutput)
            .disposed(by: bag)
        
        viewModel.isAddedStatus
            .drive(onNext: {
                if $0 {
                    HUD.flash(HUDContentType.label("加入书架成功"), delay: 2.0)
                    NotificationCenter.default.post(name: Notification.Name.Book.bookshelf, object: true)
                } else {
                      HUD.flash(HUDContentType.label("加入书架失败"), delay: 2.0)
                }
            })
        .disposed(by: bag)
        
        
    }

    
}


extension ReaerPopMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

