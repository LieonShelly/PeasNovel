//
//  NewBookViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD

/// 书城 -> 新书
class NewBookViewController: BaseViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<Void, BookInfo>>(configureCell: {_, cv, ip, model in
        if ip.section == 0 {
            let cell = cv.dequeueCell(FinalCollectionViewCell.self, for: ip)
            cell.set(model)
            return cell
        }else{
            let cell = cv.dequeueCell(BookLeftCoverRightTextCell.self, for: ip)
            cell.config(model.cover_url,
                        title: model.book_title,
                        desc: model.book_intro,
                        name: model.author_name,
                        categoryText: model.category_id_1?.short_name,
                        processText:  model.writing_process.desc)
            return cell
        }
    }, configureSupplementaryView: { (ds, cv, kind, ip) in
        
        if kind == UICollectionView.elementKindSectionFooter{
            let reuseView = cv.dequeueReusableView(UICollectionReusableView.self, ofKind: kind, for: ip)
            reuseView.backgroundColor = UIColor(0xF4F6F9)
            return reuseView
        }else{
            let reuseView = cv.dequeueReusableView(UICollectionReusableView.self, ofKind: kind, for: ip)
            return reuseView
        }
    })
    
    convenience init(_ viewModel: NewBookViewModel) {
        self.init(nibName: "NewBookViewController", bundle: nil)
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
    
    func config(_ viewModel: NewBookViewModel) {
        
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.dataEmpty
            .drive(collectionView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        self.exception
            .mapToVoid()
            .bind(to: viewModel.exceptionInput)
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(BookInfo.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        collectionView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
        viewModel
            .sections
            .drive(self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .endMoreDaraRefresh
            .drive(collectionView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: {
                BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        
        self.title = "新书抢先看"
        
        collectionView.registerNibWithCell(FinalCollectionViewCell.self)
        collectionView.registerNibWithCell(BookLeftCoverRightTextCell.self)
        
        collectionView.registerClassWithReusableView(UICollectionReusableView.self,
                                                     forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
        
        collectionView.registerClassWithReusableView(UICollectionReusableView.self,
                                                     forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
        collectionView.mj_footer = RefreshFooter()
        collectionView.delegate = self
        
    }
}

extension NewBookViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 2 * 10) / 3.0001, height: 210)
        }else{
            return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
}
