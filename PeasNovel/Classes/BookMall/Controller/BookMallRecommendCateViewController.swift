//
//  BookMallRecommendCateViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/11.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import JXSegmentedView
import RxSwift
import RxDataSources
import RxCocoa
import PKHUD

class BookMallRecommendCateViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var categoryInput: BehaviorRelay<Category> = .init(value: Category())
    var outterContentInset: UIEdgeInsets = .zero
    @IBOutlet weak var backTopBtn: DismissBtn!
    
  fileprivate lazy  var dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<RecommnedCategoryUIType, RecommendBook>>(configureCell:  {[weak self] (dataSource, collectionView, indexPath, item) -> UICollectionViewCell in
         let uiType = dataSource.sectionModels[indexPath.section].model
        switch uiType {
        case RecommnedCategoryUIType.image(let imageStr):
            let cell = collectionView.dequeueCell(ImageCollectionViewCell.self, for: indexPath)
            cell.config(imageStr)
            cell.imageView.layer.cornerRadius = 4
            cell.imageView.layer.masksToBounds = true
            cell.imageView.contentMode = .scaleAspectFill
            return cell
        case .book:
            guard let weakSelf = self, let config = AdvertiseService.advertiseConfig(AdPosition.userCategoryInfoStream), !config.is_close else {
                if indexPath.item < 6 {
                    if indexPath.item >= 0 && indexPath.item < 3 {
                        let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                        var categoryText = item.category_id_2?.name ?? ""
                        if categoryText.isEmpty {
                            categoryText = item.category_id_1?.name ?? ""
                        }
                        cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name,  categoryText: categoryText, processText: item.writing_process.desc)
                        return cell
                    } else {
                        let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                        let width = (UIScreen.main.bounds.width - 16 * 4) / 3.0001
                        let imageHeight: CGFloat = width * 147 / 110.0
                        cell.imageContainerHeight.constant = imageHeight
                        cell.config(item.cover_url, title: item.book_title)
                        return cell
                    }
                } else {
                    let rate = indexPath.item % 6
                    if rate >= 0 && rate < 3 {
                        let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                        var categoryText = item.category_id_2?.name ?? ""
                        if categoryText.isEmpty {
                            categoryText = item.category_id_1?.name ?? ""
                        }
                        cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name,  categoryText: categoryText, processText: item.writing_process.desc)
                        return cell
                    } else {
                        let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                        let width = (UIScreen.main.bounds.width - 16 * 4) / 3.0001
                        let imageHeight: CGFloat = width * 147 / 110.0
                        cell.imageContainerHeight.constant = imageHeight
                        cell.config(item.cover_url, title: item.book_title)
                        return cell
                    }
                }
            }
            /// 有广告
            let style = weakSelf.indexPathUIStyle(indexPath)
            switch style {
            case IndexPathUIType.threeHoriStyle:
                let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                var categoryText = item.category_id_2?.name ?? ""
                if categoryText.isEmpty {
                    categoryText = item.category_id_1?.name ?? ""
                }
                cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name,  categoryText: categoryText, processText: item.writing_process.desc)
                return cell
            case IndexPathUIType.threeVertiStyle:
                let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                let width = (UIScreen.main.bounds.width - 16 * 4) / 3.0001
                let imageHeight: CGFloat = width * 147 / 110.0
                cell.imageContainerHeight.constant = imageHeight
                cell.config(item.cover_url, title: item.book_title)
                return cell
            case IndexPathUIType.oneAdStyle:
                if let localAdConfig = item.localTempAdConfig {
                    let cell = BookMallAdService.chooseCell(localAdConfig,
                                                            collectionView: collectionView,
                                                            indexPath: indexPath,  didTapAd:{})
                    return cell
                }
            default:
                break
            }
        }
        let cell = collectionView.dequeueCell(UICollectionViewCell.self, for: indexPath)
        debugPrint("UICollectionViewCell:\(indexPath)")
       cell.contentView.backgroundColor = .blue
        return cell
    })
    
    convenience init(_ viewModel: BookMallCategoryViewModel, contentInset: UIEdgeInsets) {
        self.init(nibName: "BookMallRecommendCateViewController", bundle: nil)
        self.outterContentInset = contentInset
        self.rx.viewDidLoad
            .subscribe(onNext: { () in
                self.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }

    
    fileprivate func config(_ viewModel: BookMallCategoryViewModel) {
       
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        collectionView.contentInset = self.outterContentInset
        collectionView.registerNibWithCell(IMInfoCollectionViewCell.self)
        collectionView.registerNibWithCell(BookMallBannerCollectionViewCell.self)
        collectionView.registerNibWithCell(BookMallBtnCollectionViewCell.self)
        collectionView.registerNibWithReusableView(BookMallSectionView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        collectionView.registerNibWithCell(BookLeftCoverRightTextCell.self)
        collectionView.registerNibWithCell(BookTopImageCollectionViewCell.self)
        collectionView.registerNibWithCell(ImageCollectionViewCell.self)
        collectionView.registerNibWithCell(BookListBottomCollectionViewCell.self)
        collectionView.registerNibWithCell(BookListRightCollectionViewCell.self)
        collectionView.registerNibWithCell(BookRecommendCateCell.self)
        collectionView.registerNibWithCell(BookMallContainerCollectionViewCell.self)
        collectionView.registerClassWithCell(UICollectionViewCell.self)
        collectionView.registerNibWithCell(BUNativeFeedCollectionViewCell.self)
        collectionView.registerNibWithCell(GDTNativeExpressAdCollectionViewCell.self)
        backTopBtn.hidden(true)
        backTopBtn.btnAction = { [weak self] in
            guard let weakSelf = self else {
                return
            }
            NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallBackTop, object: nil)
            let mjHeight: CGFloat = 0
            weakSelf.collectionView.setContentOffset(CGPoint(x: 0, y: -weakSelf.collectionView.contentInset.top - mjHeight), animated: true)
            weakSelf.backTopBtn.hidden(true)
        }
        
        
        viewModel.dataSources
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
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
        
        collectionView.rx.setDelegate(self).disposed(by: bag)
     
        
        categoryInput.asObservable()
                .skip(1)
                .debug()
                .bind(to: viewModel.categoryInput)
                .disposed(by: bag)
        
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
        
        collectionView.mj_header = RefreshHeader(refreshingBlock: {
            viewModel.refreshInput.onNext(true)
        })
        
        viewModel.refreshStatusOutput
            .asObservable()
            .bind(to: collectionView.rx.mj_RefreshStatus)
            .disposed(by: bag)

 
    }
}


extension BookMallRecommendCateViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, AdvertiseUIInterface {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section > dataSource.sectionModels.count {
            return .zero
        }
        let uiType = dataSource.sectionModels[section].model
        switch uiType {
        case .image:
            return UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        case .book:
            return UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section > dataSource.sectionModels.count {
            return .zero
        }
        let uiType = dataSource.sectionModels[indexPath.section].model
        let item = dataSource.sectionModels[indexPath.section].items[indexPath.row]
        switch uiType {
        case .image:
            let width = UIScreen.main.bounds.width - 16 * 2
            let height = width * 108 / 342.0
            return CGSize(width: width, height: height)
        case .book:
            guard let config = AdvertiseService.advertiseConfig(AdPosition.userCategoryInfoStream), !config.is_close else {
                if indexPath.item < 6 {
                    if indexPath.item >= 0 && indexPath.item < 3 {
                        return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
                    } else {
                        let width = (UIScreen.main.bounds.width - 16 * 4) / 3.0001
                        let imageHeight: CGFloat = width * 147 / 110.0 + 55
                        let cellHeight: CGFloat = imageHeight
                        return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 3 * 10) / 3.0001, height: cellHeight)
                    }
                } else {
                    let rate = indexPath.item % 6
                    if rate >= 0 && rate < 3 {
                        return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
                    } else {
                        let width = (UIScreen.main.bounds.width - 16 * 4) / 3.0001
                        let imageHeight: CGFloat = width * 147 / 110.0 + 55
                        let cellHeight: CGFloat = imageHeight
                        return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 3 * 10) / 3.0001, height: cellHeight)
                    }
                }
            }
            /// 有广告
            let style = indexPathUIStyle(indexPath)
            switch style {
            case IndexPathUIType.threeHoriStyle:
                return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
            case IndexPathUIType.threeVertiStyle:
                let width = (UIScreen.main.bounds.width - 16 * 4) / 3.0001
                let imageHeight: CGFloat = width * 147 / 110.0 + 55
                let cellHeight: CGFloat = imageHeight
                return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 3 * 10) / 3.0001, height: cellHeight)
            case IndexPathUIType.oneAdStyle:
                if let localTempAdConfig = item.localTempAdConfig {
                    return infoAdLoadedRealSize(localTempAdConfig.adType)
                }
            default:
                break
            }
        }
        return .zero
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if  !scrollView.isDragging {
            backTopBtn.fireTimer()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isDragging {
            backTopBtn.fireTimer()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = -(scrollView.contentInset.top + scrollView.contentOffset.y )
        if scrollView.panGestureRecognizer.velocity(in: view).y > 0 {
            let isHidden = abs(Int(height)) < Int(view.bounds.height * 2)
            backTopBtn.hidden(isHidden)
        } else if scrollView.panGestureRecognizer.velocity(in: view).y < 0 {
            backTopBtn.hidden(true)
        }
        NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallScrollChange, object: scrollView)
    }
    
    
   fileprivate enum IndexPathUIType {
        case none
        case threeHoriStyle
        case threeVertiStyle
        case oneAdStyle
    }
    
    fileprivate func indexPathUIStyle(_ indexPath: IndexPath) -> IndexPathUIType {
        let delta: Float = 7.0
        var threeHoriBook0 = 1.0 +  Float(indexPath.item) / delta
        var threeHoriBook1 = 1.0 +  Float(indexPath.item - 1) / delta
        var threeHoriBook2 = 1.0 +  Float(indexPath.item - 2) / delta
        
        var threeVertiBook0 = 1.0 +  Float(indexPath.item - 3) / delta
        var threeVertiBook1 = 1.0 +  Float(indexPath.item - 4) / delta
        var threeVertiBook2 = 1.0 + Float(indexPath.item - 5) / delta
        
        var adBook = 1.0 + Float(indexPath.item - 6) / delta
        
        var style = IndexPathUIType.none
        if threeHoriBook0.isInt() || threeHoriBook1.isInt() || threeHoriBook2.isInt() {
            style = .threeHoriStyle
        } else if threeVertiBook0.isInt() || threeVertiBook1.isInt() || threeVertiBook2.isInt() {
            style = .threeVertiStyle
        } else if adBook.isInt() {
            style = .oneAdStyle
        }
        return style
    }
    
}

