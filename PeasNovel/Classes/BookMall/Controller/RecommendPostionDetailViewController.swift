//
//  RecommendPostionDetailViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/30.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa

class RecommendPostionDetailViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<RecommendPositionDetailViewType, RecommendBook>>(configureCell:  { (dataSource, collectionView, indexPath, model) -> UICollectionViewCell in
        let uiType = dataSource.sectionModels[indexPath.section].model
        switch uiType {
        case RecommendPositionDetailViewType.horison:
            let cell = collectionView.dequeueCell(FinalCollectionViewCell.self, for: indexPath)
            cell.set(model.book_title, imageStr: model.cover_url, tag: model.category_id_1?.name)
            return cell
        case .veritical:
            let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
            cell.config(model.cover_url, title: model.book_title, desc: model.book_intro, name: model.author_name, categoryText: model.category_id_1?.short_name ?? "", processText:  model.writing_process.desc)
            return cell
        }
    }, configureSupplementaryView: {(dataSource, collectionView, kind, indexPath) in
        let header = collectionView.dequeueReusableView(UICollectionReusableView.self, ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
        header.backgroundColor = UIColor(0xF4F6F9)
        return header
    })
    
    convenience init(_ viewModel: RecommendPositionDetailViewModel) {
        self.init(nibName: "RecommendPostionDetailViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: { () in
                self.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    
    fileprivate func config(_ viewModel: RecommendPositionDetailViewModel) {
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }

        collectionView.registerNibWithCell(FinalCollectionViewCell.self)
        collectionView.registerNibWithCell(BookMallBtnCollectionViewCell.self)
        collectionView.registerClassWithReusableView(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        collectionView.registerNibWithCell(BookLeftCoverRightTextCell.self)
        collectionView.registerNibWithCell(BookTopImageCollectionViewCell.self)
        collectionView.registerNibWithCell(ImageCollectionViewCell.self)
        collectionView.registerNibWithCell(BookListBottomCollectionViewCell.self)
        collectionView.registerNibWithCell(BookListRightCollectionViewCell.self)
        collectionView.registerNibWithCell(BookRecommendCateCell.self)
        collectionView.registerNibWithCell(BookMallContainerCollectionViewCell.self)
        collectionView.registerClassWithCell(UICollectionViewCell.self)
        viewModel.dataSources
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        collectionView.rx.setDelegate(self).disposed(by: bag)
        
        
        
        collectionView.rx.modelSelected(RecommendBook.self)
            .filter { $0.book_id != nil }
            .bind(to: viewModel.bookTapInput)
            .disposed(by: bag)
        
        viewModel.booktapOutput
            .map { $0.book_id }
            .unwrap()
            .drive(onNext: {
                 BookReaderHandler.jump($0)
            })
            .disposed(by: bag)
        
        collectionView.mj_footer = RefreshFooter(refreshingBlock: {
            viewModel.refreshInput.onNext(false)
        })
        
//        collectionView.mj_header = RefreshHeader(refreshingBlock: {
//            viewModel.refreshInput.onNext(true)
//        })
        
        viewModel.refreshStatusOutput
            .asObservable()
            .bind(to: collectionView.rx.mj_RefreshStatus)
            .disposed(by: bag)
        
    }
    
    
}


extension RecommendPostionDetailViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize(width: UIScreen.main.bounds.width, height: 6)
        }
        return .zero
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section > dataSource.sectionModels.count {
            return .zero
        }
        let uiType = dataSource.sectionModels[indexPath.section].model
        switch uiType {
        case .horison: ///
            let width = (UIScreen.main.bounds.width - 16 * 4) / 3.0001
            let imageHeight: CGFloat = width * 147 / 110.0 + 63
            return CGSize(width: (UIScreen.main.bounds.width - 16 * 4) / 3.0001, height: imageHeight)
        case .veritical:
            return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
        }
    }

}


