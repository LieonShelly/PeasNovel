//
//  RecentlyViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/5/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD
import RxCocoa
import RxSwift

/// 最近阅读
class RecentlyViewController: BaseViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    let longPressAction: PublishSubject<IndexPath> = .init()
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<Void, BookInfo>>(configureCell: { (dataSource, collectionView, ip, model) -> UICollectionViewCell in
        let cell = collectionView.dequeueCell(TopImageDownTextDetailCollectionViewCell.self, for: ip)
        cell.set(model)
        return cell
    })
    
    convenience init(_ viewModel: RecentlyViewModel) {
        self.init(nibName: "RecentlyViewController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.configUI()
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        self.rx
            .viewWillAppear
            .bind(to: viewModel.viewWillAppear)
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    fileprivate func config(_ viewModel: RecentlyViewModel) {
        
        collectionView
            .rx
            .modelSelected(BookInfo.self)
            .bind(to: viewModel.itemSelected)
            .disposed(by: bag)
        
        collectionView
            .mj_header
            .rx
            .start
            .bind(to: viewModel.headerRefresh)
            .disposed(by: bag)
        
        collectionView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
        longPressAction
            .bind(to: viewModel.longPressAction)
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: {
                if DZMReadRecordModel.readRecordModel(bookID: $0.book_id).readChapterModel != nil {
                     BookReaderHandler.jump($0.book_id)
                } else {
                    BookReaderHandler.jump($0.book_id, contentId: $0.content_id, toReader: true)
                }
               
            })
            .disposed(by: bag)
        
        viewModel
            .handlerViewModel
            .subscribe(onNext: {  [weak self] in
                let vc = BookshelfHandlerController($0)
                self?.present(vc, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        viewModel
            .section
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        viewModel
            .endRefresh
            .drive(collectionView.mj_header.rx.end)
            .disposed(by: bag)
        
        viewModel
            .endRefresh
            .drive(collectionView.mj_footer.rx.end)
            .disposed(by: bag)
        
        viewModel
            .endMoreDaraRefresh
            .drive(collectionView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
        
        viewModel
            .activityOutput
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel
            .errorOutput
            .drive(HUD.flash)
            .disposed(by: bag)
    }
    
    fileprivate func configUI() {
        
        collectionView.registerNibWithCell(TopImageDownTextDetailCollectionViewCell.self)
        
        collectionView.mj_header = RefreshHeader()
        collectionView.mj_footer = RefreshFooter()
        
        collectionView.delegate = self
        title = "最近阅读"
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        longPress.minimumPressDuration = 1
        longPress.delaysTouchesBegan = true
        longPress.delaysTouchesEnded = false
        self.collectionView.addGestureRecognizer(longPress)
        
    }
    
    @objc private func longPressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began { return }
        
        let point = sender.location(in: self.collectionView)
        
        if let ip = self.collectionView.indexPathForItem(at: point) {
            longPressAction.on(.next(ip))
        }
    }
    
}

extension RecentlyViewController: UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 14, left: 14, bottom: 30, right: 14)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 40
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 14 * 2  - 18 * 2) / 3.0001
        return CGSize(width: width, height: width*4/3 + 10 + 24 + 6 + 16 + 10)
    }
}
