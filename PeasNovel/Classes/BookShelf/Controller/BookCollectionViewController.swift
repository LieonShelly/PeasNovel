//
//  BookCollectionViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD
import RxCocoa
import RxSwift

/// 书架收藏
class BookCollectionViewController: BaseShelfCollectionViewController {
    let bookColllectionSelected: PublishSubject<BookInfo> = .init()
    let bookColllectionSelectedIPFrame: PublishSubject<CGRect> = .init()
    
    @IBOutlet weak var collectionView: UICollectionView!
    let longPressAction: PublishSubject<IndexPath> = .init()
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<Void, BookInfo>>(configureCell: { (dataSource, collectionView, ip, model) -> UICollectionViewCell in
        if model.book_type == 2 {
            let cell = collectionView.dequeueCell(BookCollectionListCell.self, for: ip)
            let width = (UIScreen.main.bounds.width - 14 * 2  - 18 * 2) / 3.0001
            cell.imgContainerHeight.constant = width * 4 / 3
            cell.set(model)
            return cell
        } else if model.book_type == 3 {
            let cell = collectionView.dequeueCell(BookCollectionWebCell.self, for: ip)
            cell.set(model)
            return cell
        }  else{
            let cell = collectionView.dequeueCell(BookCollectionTopImageDownTextCell.self, for: ip)
            let width = (UIScreen.main.bounds.width - 14 * 2  - 18 * 2) / 3.0001
            cell.imageHeight.constant = width * 4 / 3
            cell.set(model)
            return cell
        }
    })
    
    convenience init(_ viewModel: BookCollectionViewModel) {
        self.init(nibName: "BookCollectionViewController", bundle: nil)
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
    
    fileprivate func config(_ viewModel: BookCollectionViewModel) {
        
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
        
        viewModel.activityOutput
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.exceptionDriver
            .drive(self.rx.exception)
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
        
        viewModel
            .sheetViewModel
            .debug()
            .withLatestFrom(bookColllectionSelectedIPFrame, resultSelector: {($0, $1)})
            .debug()
            .subscribe(onNext: { [weak self] ars in
                guard let weakSelf = self else {
                    return
                }
                let vc = BookSheetViewController(ars.0, from: ars.1)
                weakSelf.navigationController?.delegate = vc
                weakSelf.navigationController?.pushViewController(vc, animated: true)
                weakSelf.navigationController?.delegate = nil
            })
            .disposed(by: bag)
        
        viewModel
            .itemOutput
            .subscribe(onNext: {
                if DZMReadRecordModel.IsExistReadRecordModel(bookID: $0.book_id) {
                     BookReaderHandler.jump($0.book_id)
                } else {
                    BookReaderHandler.jump($0.book_id, contentId: $0.content_id, toReader: true)
                }
            })
            .disposed(by: bag)
        
        viewModel.sogouViewModel
            .subscribe(onNext: { [weak self] in
                let vcc = SogouWebViewController($0)
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.pushViewController(vcc, animated: true)
            })
            .disposed(by: bag)
    }
    
    fileprivate func configUI() {
        collectionView.registerNibWithCell(BookCollectionWebCell.self)
        collectionView.registerNibWithCell(BookCollectionListCell.self)
        collectionView.registerNibWithCell(BookCollectionTopImageDownTextCell.self)
        collectionView.mj_header = RefreshHeader()
        collectionView.mj_footer = RefreshFooter()
        collectionView.delegate = self
        
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

extension BookCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        let frame1 = collectionView.convert(cell?.frame ?? .zero, to: self.collectionView)
        let frame2 = self.collectionView.convert(frame1, to: self.view)
        let frame3 = self.view.convert(frame2, to: UIApplication.shared.keyWindow!)
        bookColllectionSelectedIPFrame.onNext(frame3)
    }
}


extension BookCollectionViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ScaleTransitionAnimation(from: CGRect.zero, isPresent: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ScaleTransitionAnimation(from: CGRect.zero, isPresent: false)
    }
}
