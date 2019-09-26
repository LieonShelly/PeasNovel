//
//  BookMallRecommendViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import JXSegmentedView
import PKHUD

class BookMallRecommendViewController: BaseViewController {
    var viewModel: BookMallRecommendViewModel!
    let bgView = UIView()
    var outterContentInset: UIEdgeInsets = .zero
    @IBOutlet weak var collectionView: UICollectionView!
    let rankInput: PublishSubject<Void> = .init()
    let categoryInput: PublishSubject<Void> = .init()
    let bookListInput: PublishSubject<Void> = .init()
    let newBookInput: PublishSubject<Void> = .init()
    let finishInput: PublishSubject<Void> = .init()
    let ajustFavorOutput: PublishSubject<Void> = .init()
    let specialRecommendRefreshInput: PublishSubject<String> = .init()
    let otherRecommendRefreshInput: PublishSubject<String> = .init()
    let bookTapInput: PublishSubject<RecommendBook> = .init()
    let jumpURLInput: PublishSubject<String?> = .init()
    let recommendPositionMoreInput: PublishSubject<RecommendPosition> = .init()
    let recommendPositionInput: PublishSubject<RecommendPosition> = .init()
    @IBOutlet weak var backTopBtn: DismissBtn!
    
    
    lazy var  dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<BookMallRecomendUIType, RecommendBook>>(configureCell:  { [weak self](dataSource, collectionView, indexPath, item) -> UICollectionViewCell in
        let uiType = dataSource.sectionModels[indexPath.section].model
        switch uiType {
        case .banner(let banners):
            let cell = collectionView.dequeueCell(BookMallBannerCollectionViewCell.self, for: indexPath)
            let urls = banners.map {$0.img_url ?? ""}
            if let weakSelf = self {
                cell.didSelected = { index in
                    weakSelf.jumpURLInput.onNext(banners[index].jump_url)
                }
            }
            let colors = banners.map { $0.color ?? "" }
            cell.config(urls, colors: colors)
            return cell
        case .categoryBtn:
            let cell = collectionView.dequeueCell(BookMallBtnCollectionViewCell.self, for: indexPath)
            if let weakSelf = self {
                cell.btns[0].rx.tap.mapToVoid().bind(to: weakSelf.rankInput).disposed(by: cell.bag)
                cell.btns[1].rx.tap.mapToVoid().bind(to: weakSelf.categoryInput).disposed(by: cell.bag)
                cell.btns[2].rx.tap.mapToVoid().bind(to: weakSelf.bookListInput).disposed(by: cell.bag)
                cell.btns[3].rx.tap.mapToVoid().bind(to: weakSelf.newBookInput).disposed(by: cell.bag)
                cell.btns[4].rx.tap.mapToVoid().bind(to: weakSelf.finishInput).disposed(by: cell.bag)
            }
            return cell
        case .specialRecommend:
            if indexPath.item == 0 {
                let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                var categoryText = item.category_id_2?.name ?? ""
                if categoryText.isEmpty {
                    categoryText = item.category_id_1?.name ?? ""
                }
                cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name, categoryText: categoryText, processText: item.writing_process.desc)
                return cell
            } else {
                let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                cell.config(item.cover_url, title: item.book_title)
                cell.imageContainerHeight.constant = 115
                return cell
            }
        case .adjustReadFavor:
            let cell = collectionView.dequeueCell(ImageCollectionViewCell.self, for: indexPath)
            if let weakSelf = self {
                cell.tap?.rx.event.mapToVoid()
                    .bind(to: weakSelf.ajustFavorOutput)
                    .disposed(by: cell.bag)
            }
         
            return cell
        case .recommendPosition(let postion):
            let styleType = postion.style
            switch styleType {
            case .bottomThreeImage:
                let cell = collectionView.dequeueCell(BookListBottomCollectionViewCell.self, for: indexPath)
                let urls =  item.content?.map {  $0.cover_url ?? ""}  ?? []
                cell.config(urls, text: item.title)
//                if let weakSelf = self {
//                    cell.tapBtn.rx.tap.map { postion }
//                        .debug()
//                        .bind(to:weakSelf.recommendPositionInput).disposed(by: cell.bag)
//                }
                return cell
            case .leftImageRightText:// 本周主打，最后一个item是广告
                if  let localTempAdConfig = item.localTempAdConfig {
                    let cell = BookMallAdService.chooseCell(localTempAdConfig, collectionView: collectionView, indexPath: indexPath, didTapAd:{
                    
                    })
                    return cell
                } else {
                    let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                    var categoryText = item.category_id_2?.name ?? ""
                    if categoryText.isEmpty {
                        categoryText = item.category_id_1?.name ?? ""
                    }
                    cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name, categoryText: categoryText, processText: item.writing_process.desc)
                    return cell
                }
            case .leftThreeImage: /// 推荐书单，最后一个item是广告
                if  let localTempAdConfig = item.localTempAdConfig {
                    let cell = BookMallAdService.chooseCell(localTempAdConfig, collectionView: collectionView, indexPath: indexPath, didTapAd:{
                    })
                    return cell
                } else {
                    let cell = collectionView.dequeueCell(BookListRightCollectionViewCell.self, for: indexPath)
                    let urls = [item.title_small_img1 ?? "", item.title_small_img2 ?? "", item.title_small_img3 ?? ""]
                    cell.config(urls, title: item.title, desc: "精心推荐" + (item.book_title_info ?? ""))
                    return cell
                }
            case .commonCategory:
                let cell = collectionView.dequeueCell(BookMallContainerCollectionViewCell.self, for: indexPath)
                cell.config(postion.bookinfo ?? [])
                if let weakSelf = self {
                    cell.bookTapInput.bind(to:weakSelf.bookTapInput).disposed(by: cell.bag)
                }
                return cell
            case .topImageBottomText:
                let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                cell.config(item.cover_url, title: item.book_title)
                cell.imageContainerHeight.constant = 147
                return cell
            case .rightOrTopImage:
                if indexPath.item == 0 {
                    let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                    var categoryText = item.category_id_2?.name ?? ""
                    if categoryText.isEmpty {
                        categoryText = item.category_id_1?.name ?? ""
                    }
                    cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name, categoryText: categoryText, processText: item.writing_process.desc)
                    return cell
                } else {
                    if  let localTempAdConfig = item.localTempAdConfig {
                        let cell = BookMallAdService.chooseCell(localTempAdConfig, collectionView: collectionView, indexPath: indexPath, didTapAd:{
                        })
                        return cell
                    } else {
                        let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                        cell.config(item.cover_url, title: item.book_title)
                        cell.imageContainerHeight.constant = 147
                        return cell
                    }
                }
            default:
                break
            }
            
        case .otherRecommendCategoryBookList:
            
            guard let wanrenzhixuanAdConfig = AdvertiseService.advertiseConfig(AdPosition.wanrenzhixuanInnfoStream),
                !wanrenzhixuanAdConfig.is_close, let weakSelf = self else {
                    /// 无广告
                    if indexPath.item < 8 {
                        if let localTempAdConfig = item.localTempAdConfig {
                            let cell = BookMallAdService.chooseCell(localTempAdConfig, collectionView: collectionView, indexPath: indexPath, didTapAd:{
                            })
                            return cell
                        } else if indexPath.item >= 0 && indexPath.item < 5 {
                            let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                            var categoryText = item.category_id_2?.name ?? ""
                            if categoryText.isEmpty {
                                categoryText = item.category_id_1?.name ?? ""
                            }
                            cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name, categoryText: categoryText, processText: item.writing_process.desc)
                            return cell
                        } else {
                            let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                            cell.config(item.cover_url, title: item.book_title)
                            return cell
                        }
                    } else {
                        let rate = indexPath.item % 8
                        if let localTempAdConfig = item.localTempAdConfig {
                            let cell = BookMallAdService.chooseCell(localTempAdConfig, collectionView: collectionView, indexPath: indexPath, didTapAd:{
                            })
                            return cell
                        } else if rate >= 0 && rate < 5 {
                            let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                            var categoryText = item.category_id_2?.name ?? ""
                            if categoryText.isEmpty {
                                categoryText = item.category_id_1?.name ?? ""
                            }
                            cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name, categoryText: categoryText, processText: item.writing_process.desc)
                            return cell
                        } else {
                            let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                            cell.config(item.cover_url, title: item.book_title)
                            return cell
                        }
                    }
            }
            /// 有广告
            let tailStr = String(indexPath.item)
            let lastNumStr = String(tailStr.last!)
            let style = weakSelf.wanUIStyle(indexPath)
            switch style {
            case WanrenUIType.fiveStyle:
                let cell = collectionView.dequeueCell(BookLeftCoverRightTextCell.self, for: indexPath)
                var categoryText = item.category_id_2?.name ?? ""
                if categoryText.isEmpty {
                    categoryText = item.category_id_1?.name ?? ""
                }
                cell.config(item.cover_url, title: item.book_title, desc: item.book_intro, name: item.author_name, categoryText: categoryText, processText: item.writing_process.desc)
                return cell
            case .threeStyle:
                let cell = collectionView.dequeueCell(BookTopImageCollectionViewCell.self, for: indexPath)
                cell.config(item.cover_url, title: item.book_title)
                return cell
            case .oneAdStyle:
                if let localTempAdConfig = item.localTempAdConfig {
                    let cell = BookMallAdService.chooseCell(localTempAdConfig, collectionView: collectionView, indexPath: indexPath, didTapAd:{
                    })
                    return cell
                }
            default:
                break
            }
        }
        let cell = collectionView.dequeueCell(UICollectionViewCell.self, for: indexPath)
        return cell
    }, configureSupplementaryView: { [weak self](dataSource, collectionView, kind, indexPath) in
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableView(BookMallSectionView.self, ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
            header.moreBtnMode()
            let uiType = dataSource.sectionModels[indexPath.section].model
            switch uiType {
            case .specialRecommend:
                 header.label.text = uiType.title
                 header.refreshMode()
                 if let weakSelf = self {
                    header.btn.rx.tap.map {"jingxuan_zhongbangtuijian"}.bind(to: weakSelf.specialRecommendRefreshInput).disposed(by: header.bag)
                 }
                
            case .recommendPosition(let postion):
                let styleType = postion.style
                switch styleType {
                case .leftImageRightText:
                    header.label.text = postion.title
                    header.refreshMode()
                    if let weakSelf = self {
                        header.btn.rx.tap.map {postion.type_name ?? ""}.bind(to: weakSelf.otherRecommendRefreshInput).disposed(by: header.bag)
                    }
                case .leftThreeImage:
                   header.label.text = postion.title
                    header.noMode()
                case .topImageBottomText:
                     header.label.text = postion.title
                     header.refreshMode()
                     if let weakSelf = self {
                        header.btn.rx.tap.map {postion.type_name ?? ""}.bind(to: weakSelf.otherRecommendRefreshInput).disposed(by: header.bag)
                    }
                case .rightOrTopImage:
                    header.label.text = postion.title
                default:
                    break
                }
                if let weakSelf = self {
                    header.moreBtn.rx.tap.map {postion}.bind(to: weakSelf.recommendPositionMoreInput).disposed(by: header.bag)
                }
                
            case .otherRecommendCategoryBookList:
                header.label.text = uiType.title
                header.noMode()
            default:
                break
            }
            return header
        }
        let reuseView = collectionView.dequeueReusableView(UICollectionReusableView.self, ofKind: kind, for: indexPath)
        return reuseView
    })
    
    
    convenience init(_ viewModel: BookMallRecommendViewModel, contentInset: UIEdgeInsets) {
        self.init(nibName: "BookMallRecommendViewController", bundle: nil)
        self.outterContentInset = contentInset
        self.rx.viewDidLoad
            .subscribe(onNext: { () in
                 self.config(viewModel, contentInset: contentInset)
            })
        .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        self.rx
            .viewDidAppear
            .bind(to: viewModel.viewDidAppear)
            .disposed(by: bag)
        
        self.rx
            .viewDidDisappear
            .bind(to: viewModel.viewDidDisappear)
            .disposed(by: bag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    fileprivate func config(_ viewModel: BookMallRecommendViewModel, contentInset: UIEdgeInsets) {
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        backTopBtn.isHidden = true
        collectionView.contentInset = contentInset
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
        collectionView.registerNibWithCell(GDTNativeExpressAdCollectionViewCell.self)
        collectionView.registerNibWithCell(BUNativeFeedCollectionViewCell.self)
        collectionView.registerClassWithCell(UICollectionViewCell.self)
        viewModel.dataSources
                .asObservable()
                .bind(to: collectionView.rx.items(dataSource: dataSource))
                .disposed(by: bag)
        
        collectionView.rx.setDelegate(self).disposed(by: bag)
        
        backTopBtn.btnAction = { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallBackTop, object: nil)
                let mjHeight: CGFloat = 0
                weakSelf.collectionView.setContentOffset(CGPoint(x: 0, y: -weakSelf.collectionView.contentInset.top - mjHeight), animated: true)
                weakSelf.backTopBtn.hidden(true)
            }
    
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
        
      finishInput.asObservable()
            .bind(to: viewModel.finishInput)
            .disposed(by: bag)
        
        rankInput.asObservable()
            .bind(to: viewModel.rankInput)
            .disposed(by: bag)
        
        categoryInput.asObservable()
            .bind(to: viewModel.categoryInput)
            .disposed(by: bag)
        
        bookListInput.asObservable()
            .bind(to: viewModel.bookListInput)
            .disposed(by: bag)
        
        newBookInput.asObservable()
            .bind(to: viewModel.newBookInput)
            .disposed(by: bag)
        
        specialRecommendRefreshInput.asObservable()
            .bind(to: viewModel.specialRecommendRefreshInput)
            .disposed(by: bag)
        
        otherRecommendRefreshInput.asObservable()
            .bind(to: viewModel.otherRecommendRefreshInput)
            .disposed(by: bag)
        
        bookTapInput.asObservable()
            .bind(to: viewModel.bookTapInput)
            .disposed(by: bag)
        
        recommendPositionInput.asObservable()
            .bind(to: viewModel.recommendPositionInput)
            .disposed(by: bag)
        
        collectionView.rx.modelSelected(RecommendBook.self)
            .filter { $0.book_id != nil }
            .bind(to: viewModel.bookTapInput)
            .disposed(by: bag)

        collectionView.rx.modelSelected(RecommendBook.self)
            .filter { $0.content != nil  }
            .filter { $0.title != nil }
            .debug()
            .bind(to: viewModel.bookTapInput)
            .disposed(by: bag)
        
        collectionView.rx.modelSelected(RecommendBook.self)
            .map {$0.jump_url}
            .unwrap()
            .filter {!$0.isEmpty}
            .bind(to: jumpURLInput)
            .disposed(by: bag)
    
       
        viewModel
            .rankViewModel
            .subscribe(onNext: {
                let vc = RankViewController($0)
                 navigator.push(vc)
            })
            .disposed(by: bag)
        
        viewModel
            .classifyViewModel
            .subscribe(onNext: {
                let vc = ClassifyViewController($0)
                 navigator.push(vc)
            })
            .disposed(by: bag)
        
        viewModel
            .bookSheetViewModel
            .subscribe(onNext: {
                let vc = BookSheetChoiceController($0)
                 navigator.push(vc)
            })
            .disposed(by: bag)
        
        viewModel
            .newBookViewModel
            .subscribe(onNext: {
                let vc = NewBookViewController($0)
                navigator.push(vc)
            })
            .disposed(by: bag)
        
        viewModel
            .finalViewModel
            .subscribe(onNext: {
                let vc = FinalViewController($0)
                navigator.push(vc)
            })
            .disposed(by: bag)
        
        viewModel.booktapOutput
            .map { $0.book_id }
            .unwrap()
            .drive(onNext: {
                BookReaderHandler.jump($0)
            })
            .disposed(by: bag)
        
        viewModel.classifyListViewModel
            .subscribe(onNext: {
                let vc = ClassifyListController($0)
                 navigator.push(vc)
            })
            .disposed(by: bag)
        
        viewModel.recommendPositionOutput
            .subscribe(onNext: {
                let vcc = RecommendPostionDetailViewController($0.0)
                vcc.title = $0.1
                navigator.push(vcc)
            })
            .disposed(by: bag)
        
        
        jumpURLInput.asObservable()
            .unwrap()
            .subscribe(onNext: {
                navigator.push($0)
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
        

        
        recommendPositionMoreInput
            .asObservable()
            .bind(to: viewModel.recommendPositionMoreInput)
            .disposed(by: bag)
        

        bgView.frame = CGRect(x: 0, y: -70, width: UIScreen.main.bounds.size.width, height: 70 )
        collectionView.insertSubview(bgView, belowSubview: collectionView.mj_header)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.UIUpdate.bookMallColorChange)
            .map {$0.object}
            .unwrap()
            .map { $0 as? UIColor }
            .subscribe(onNext: { (color) in
                UIView.animate(withDuration: 0.25, animations: {
                    self.bgView.backgroundColor = color
                })
            })
            .disposed(by: bag)
        
        ajustFavorOutput.asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: Notification.Name.UIUpdate.adjustReadFavorAction, object: nil)
            })
            .disposed(by: bag)
        
      
        
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
//             collectionView.contentInset = UIEdgeInsets(top: collectionView.contentInset.top + view.safeAreaInsets.top, left: 0, bottom: 88, right: 0)
        } else {
            
        }
        
    }
}

extension BookMallRecommendViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, AdvertiseUIInterface {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section > dataSource.sectionModels.count {
            return 0
        }
        let uiType = dataSource.sectionModels[section].model
        switch uiType {
        case .banner:
            return 0
        case .categoryBtn:
             return 0
        case .specialRecommend:
             return 16
        case .adjustReadFavor:
            return 0
        case .recommendPosition(let postion):
            let styleType = postion.style
            switch styleType {
            case .bottomThreeImage:
                 return 0
            case .leftImageRightText:
                 return 16
            case .leftThreeImage:
                return 16
            case .commonCategory:
                return 0
            case .topImageBottomText:
                return 16
            case .rightOrTopImage:
                return 16
            default:
                break
            }
            
        case .otherRecommendCategoryBookList:
            return 16
        }
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section > dataSource.sectionModels.count {
            return 0
        }
        let uiType = dataSource.sectionModels[section].model
        switch uiType {
        case .banner:
            return 0
        case .categoryBtn:
            return 0
        case .specialRecommend:
            return 10
        case .adjustReadFavor:
              return 0
        case .recommendPosition(let postion):
            let styleType = postion.style
            switch styleType {
            case .bottomThreeImage:
                return 10
            case .leftImageRightText:
                return 0
            case .leftThreeImage:
                return 0
            case .commonCategory:
                return 0
            case .topImageBottomText:
                return 16
            case .rightOrTopImage:
                return 10
            default:
                break
            }
            
        case .otherRecommendCategoryBookList:
            return 16
        }
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section > dataSource.sectionModels.count {
            return .zero
        }
        let uiType = dataSource.sectionModels[section].model
        let sectionHeaderHeight: CGFloat = 25
        switch uiType {
        case .banner:
            return .zero
        case .categoryBtn:
            return .zero
        case .specialRecommend:
              return CGSize(width: UIScreen.main.bounds.width, height: sectionHeaderHeight)
        case .adjustReadFavor:
            return .zero
        case .recommendPosition(let postion):
            let styleType = postion.style
            switch styleType {
            case .bottomThreeImage:
                return .zero
            case .leftImageRightText:
                return CGSize(width: UIScreen.main.bounds.width, height: sectionHeaderHeight)
            case .leftThreeImage:
                 return CGSize(width: UIScreen.main.bounds.width, height: sectionHeaderHeight)
            case .commonCategory:
                return .zero
            case .topImageBottomText:
                 return CGSize(width: UIScreen.main.bounds.width, height: sectionHeaderHeight)
            case .rightOrTopImage:
                 return CGSize(width: UIScreen.main.bounds.width, height: sectionHeaderHeight)
            default:
                break
            }
            
        case .otherRecommendCategoryBookList:
             return CGSize(width: UIScreen.main.bounds.width, height: sectionHeaderHeight)
        }
        return .zero
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section > dataSource.sectionModels.count {
            return .zero
        }
        let uiType = dataSource.sectionModels[section].model
        switch uiType {
        case .banner:
            return .zero
        case .categoryBtn:
            return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        case .specialRecommend:
            return UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        case .adjustReadFavor:
            return UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        case .recommendPosition(let postion):
            let styleType = postion.style
            switch styleType {
            case .bottomThreeImage:
                return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            case .leftImageRightText:
                return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            case .leftThreeImage:
                return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            case .commonCategory:
                return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0)
            case .topImageBottomText:
                return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            case .rightOrTopImage:
                return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            default:
                break
            }
            
        case .otherRecommendCategoryBookList:
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section > dataSource.sectionModels.count {
            return .zero
        }
        let uiType = dataSource.sectionModels[indexPath.section].model
        let models = dataSource.sectionModels[indexPath.section].items
        let model = models[indexPath.row]
        switch uiType {
        case .banner:
            return CGSize(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.width - 16 * 2) * 137.0 / 344.0 + 25)
        case .categoryBtn:
            return CGSize(width: UIScreen.main.bounds.width, height: 80)
        case .specialRecommend:
            if indexPath.item == 0 {
                return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
            } else {
                return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 3 * 10) / 4.0001, height: 170)
            }
        case .adjustReadFavor:
            return CGSize(width: UIScreen.main.bounds.width, height: 83)
        case .recommendPosition(let postion):
            let styleType = postion.style
            switch styleType {
            case .bottomThreeImage:
                 return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 2 * 10) / 3.0001, height: 90)
            case .leftImageRightText:
                if  let adConfig = model.localTempAdConfig, !adConfig.localConfig.is_close {
                     return infoAdLoadedRealSize(adConfig.adType)
                } else {
                    return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: 140)
                }
            case .leftThreeImage:
                if  let adConfig = model.localTempAdConfig, !adConfig.localConfig.is_close {
                    return infoAdLoadedRealSize(adConfig.adType)
                } else {
                    return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: 120)
                }
            case .commonCategory:
                return CGSize(width: (UIScreen.main.bounds.width - 16), height: 90)
            case .topImageBottomText:
                return CGSize(width: (UIScreen.main.bounds.width - 4 * 16) / 3.0001, height: 180)
            case .rightOrTopImage:
                if indexPath.item == 0 {
                    return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
                } else {
                    if  let adConfig = model.localTempAdConfig, !adConfig.localConfig.is_close {
                        return infoAdLoadedRealSize(adConfig.adType)
                    } else {
                        let width = (UIScreen.main.bounds.width - 16 * 4) / 3.01
                        let imageHeight: CGFloat = width * 147 / 110.0 + 40
                        let cellHeight: CGFloat = imageHeight + 40
                        return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 3 * 10) / 3.01, height: cellHeight)
                    }
                }
            default:
                break
            }
            
        case .otherRecommendCategoryBookList:
            let model = models[indexPath.row]
            guard let wanrenzhixuanAdConfig = AdvertiseService.advertiseConfig(AdPosition.wanrenzhixuanInnfoStream),
                !wanrenzhixuanAdConfig.is_close else {
                    if indexPath.item < 8 {
                       if indexPath.item >= 0 && indexPath.item < 5 {
                            return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
                        } else {
                            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 2 * 16) / 3.0001, height: 180)
                        }
                    } else {
                        let rate = indexPath.item % 8
                        if rate >= 0 && rate < 5 {
                            return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
                        } else if rate >= 5 && rate < 8 {
                            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 2 * 16) / 3.0001, height: 180)
                        }
                    }
                    return .zero
            }
            // 有广告
            let style = wanUIStyle(indexPath)
            switch style {
            case WanrenUIType.fiveStyle:
                return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
            case .threeStyle:
                 return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 2 * 16) / 3.0001, height: 180)
            case .oneAdStyle:
                if let localTempAdConfig = model.localTempAdConfig, !localTempAdConfig.localConfig.is_close {
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
         NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallScrollChange, object: scrollView)
        let height = -(scrollView.contentInset.top + scrollView.contentOffset.y )
        if scrollView.panGestureRecognizer.velocity(in: view).y > 0 {
            let isHidden = abs(Int(height)) < Int(view.bounds.height * 2)
            backTopBtn.hidden(isHidden)
        } else if scrollView.panGestureRecognizer.velocity(in: view).y > 0 {
            backTopBtn.hidden(true)
        }
        if height < 0 {
            return
        }
        if scrollView.mj_header.state.rawValue == 3 {
            return
        }
        bgView.frame = CGRect(x: 0,
                            y: -height - 20,
                            width: scrollView.bounds.width,
                            height: height + 20)
        
       
        
    }
    
    enum WanrenUIType {
        case none
        case fiveStyle
        case threeStyle
        case oneAdStyle
    }
    
    fileprivate func wanUIStyle(_ indexPath: IndexPath) -> WanrenUIType {
        var fiveBook0 = 1.0 +  Float(indexPath.item) / 9.0
        var fiveBook1 = 1.0 +  Float(indexPath.item - 1) / 9.0
        var fiveBook2 = 1.0 +  Float(indexPath.item - 2) / 9.0
        var fiveBook3 = 1.0 +  Float(indexPath.item - 3) / 9.0
        var fiveBook4 = 1.0 + Float(indexPath.item - 4) / 9.0
        var threeBook0 = 1.0 +  Float(indexPath.item - 5) / 9.0
        var threeBook1 = 1.0 +  Float(indexPath.item - 6) / 9.0
        var threeBook2 = 1.0 + Float(indexPath.item - 7) / 9.0
        var adBook = 1.0 + Float(indexPath.item - 8) / 9.0
        var style = WanrenUIType.none
        if fiveBook0.isInt() || fiveBook1.isInt() || fiveBook2.isInt() || fiveBook3.isInt() || fiveBook4.isInt(){
            style = .fiveStyle
        } else if threeBook0.isInt() || threeBook1.isInt() || threeBook2.isInt() {
            style = .threeStyle
        } else if adBook.isInt() {
            style = .oneAdStyle
        }
        return style
    }
    
    
}

import Foundation

extension Float {
    mutating func isInt() -> Bool {
        let num = roundf(self)
        return num - self == 0
    }
}

