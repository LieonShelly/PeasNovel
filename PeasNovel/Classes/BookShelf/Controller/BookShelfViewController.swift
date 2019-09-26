//
//  BookShelfViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import PKHUD


class BookShelfViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    let recommendSelected: PublishSubject<BookInfo> = .init()
    let bookColllectionSelected: PublishSubject<BookInfo> = .init()
    let bookColllectionSelectedIPFrame: PublishSubject<CGRect> = .init()
    let sectionMore: PublishSubject<String> = .init()
    let longPressAction: PublishSubject<IndexPath> = .init()
    var didScroll: ((UIScrollView) -> Void)?
    var didEndDrag: ((UIScrollView) -> Void)?
    
    lazy var dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, Any>>(configureCell: { [weak self] (dataSource, collectionView, ip, model) -> UICollectionViewCell in
        let sectionModel = dataSource.sectionModels[ip.section].model
       if sectionModel == "好书推荐", let model = model as? [BookInfo] {
            let cell = collectionView.dequeueCell(ContainerCollectionViewCell.self, for: ip)
            cell.config(model)
            if let weakSelf = self {
                cell.recommendSelected
                    .filter { !$0.book_id.isEmpty}
                    .bind(to: weakSelf.recommendSelected)
                    .disposed(by: cell.bag)
            }
             return cell
            
        } else if sectionModel == "书架收藏", let model = model as? [BookInfo] {
            let cell = collectionView.dequeueCell(BookCollectionContainerCell.self, for: ip)
    
            if let weakSelf = self {
                cell.itemSelected
                    .filter { !$0.book_id.isEmpty}
                    .bind(to: weakSelf.bookColllectionSelected)
                    .disposed(by: cell.bag)
                
                cell.seeMore
                    .map { "书架收藏" }
                    .debug()
                    .bind(to:weakSelf.sectionMore)
                    .disposed(by: cell.bag)
                
                cell
                    .selectedFrame
                    .map ( { cellFrame -> CGRect in
                        let inCollection = cell.convert(cellFrame, to: weakSelf.collectionView)
                        let originRect = weakSelf.collectionView.convert(inCollection, to: weakSelf.view)
                        let screenRect = weakSelf.view.convert(originRect, to: UIApplication.shared.keyWindow!)
                        return CGRect(origin: screenRect.origin, size: CGSize(width: BookCollectionContainerCell.UISize.cellWidth, height: BookCollectionContainerCell.UISize.cellHeight))
                    })
                    .bind(to: weakSelf.bookColllectionSelectedIPFrame)
                    .disposed(by: cell.bag)
            }
            cell.config(model)
            return cell
       } else if sectionModel == "往期推荐", let model = model as? BookInfo {
            let cell = collectionView.dequeueCell(BookHisRecomendCollectionViewCell.self, for: ip)
            var categoryText = model.category_id_2?.short_name ?? ""
            if categoryText.isEmpty {
                categoryText = model.category_id_1?.short_name ?? ""
            }
            let wordCount = Double(model.word_count).tenK
            cell.config(model.cover_url, title: model.book_title,
                        desc: model.book_intro,
                        name: (model.author_name ?? "") + " | " + wordCount + "字",
                        categoryText: categoryText,
                        processText: model.writing_process.desc)
            return cell
        }
        let cell = collectionView.dequeueCell(UICollectionViewCell.self, for: ip)
        return cell
    }, configureSupplementaryView: { [weak self] (datasource, collectionView, kind, indexPath) in
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableView(BookMallSectionView.self, ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
            let sectionTitle = datasource.sectionModels[indexPath.section].model
            header.label.text = sectionTitle
            header.btn.isHidden = (sectionTitle != "好书推荐")
            header.icon.isHidden = (sectionTitle != "好书推荐")
            if sectionTitle == "好书推荐" {
                header.refreshMode()
                if let weakSelf = self {
                    header.btn.rx.tap
                        .map { sectionTitle }
                        .bind(to:weakSelf.sectionMore)
                        .disposed(by: header.bag)
                }
            } else if sectionTitle == "往期推荐" {
                header.noMode()
            } else if sectionTitle == "书架收藏" {
                header.moreBtnMode()
                header.moreBtn.setTitle("查看更多", for: .normal)
                if let weakSelf = self {
                    header.moreBtn.rx.tap
                        .map { sectionTitle }
                        .bind(to:weakSelf.sectionMore)
                        .disposed(by: header.bag)
                }
            } else {
                  header.noMode()
            }
            return header
        }
        let reuseView = collectionView.dequeueReusableView(UICollectionReusableView.self, ofKind: kind, for: indexPath)
        return reuseView
    })
    var topBannerView: UIView?
    
    convenience init(_ viewModel: BookShelfViewModel) {
        self.init(nibName: "BookShelfViewController", bundle: nil)
     
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
        
        self.rx
            .viewDidAppear
            .bind(to: viewModel.viewDidAppear)
            .disposed(by: bag)
        
        self.rx
            .viewDidDisappear
            .bind(to: viewModel.viewDidDisappear)
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    fileprivate func config(_ viewModel: BookShelfViewModel) {
      
        self.collectionView
            .rx
            .modelSelected(BookInfo.self)
            .subscribeOn(MainScheduler.instance)
            .bind(to: viewModel.itemSelected)
            .disposed(by: bag)
        
        
        self.collectionView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
        sectionMore
            .bind(to: viewModel.sectionMore)
            .disposed(by: bag)
        
        recommendSelected
            .bind(to: viewModel.recommendSelected)
            .disposed(by: bag)
        
        bookColllectionSelected
            .debug()
            .bind(to: viewModel.bookColllectionSelected)
            .disposed(by: bag)

        longPressAction
            .bind(to: viewModel.longPressAction)
            .disposed(by: bag)
    
      
        viewModel
            .chargeViewModel
            .subscribe(onNext: { [unowned self] in
                let vc = ChargeViewController($0)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel
            .itemOutput
            .subscribe(onNext: { 
                if DZMReadRecordModel.readRecordModel(bookID: $0.book_id).readChapterModel != nil {
                    BookReaderHandler.jump($0.book_id)
                } else {
                    BookReaderHandler.jump($0.book_id, contentId: $0.content_id, toReader: true)
                }
            })
            .disposed(by: bag)
        
        viewModel
            .recentBookOutput
            .subscribe(onNext: {
                if DZMReadRecordModel.readRecordModel(bookID: $0.book_id).readChapterModel != nil {
                    BookReaderHandler.jump($0.book_id)
                } else {
                    BookReaderHandler.jump($0.book_id, contentId: $0.content_id, toReader: true)
                }
            })
            .disposed(by: bag)
        
        viewModel
            .sectionAction
            .subscribe(onNext: { _ in
                let vc = RecentHomeViewController(RecentlyViewModel())
                navigator.push(vc)
                vc.rx.viewDidAppear
                    .take(1)
                    .subscribe(onNext: { (_) in
                        vc.selectItem(1)
                    })
                    .disposed(by: vc.bag)
            })
            .disposed(by: bag)
        
        viewModel
            .items
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        viewModel
            .searchViewModel
            .subscribe(onNext: { [unowned self] in
                let vc = SearchViewController($0)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel
            .handlerViewModel
            .subscribe(onNext: {  [unowned self] in
                let vc = BookshelfHandlerController($0)
                self.navigationController?.present(vc, animated: true, completion: nil)
            })
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
            .endRefresh
            .drive(collectionView.mj_footer.rx.resetNoMoreData)
            .disposed(by: bag)
        
        viewModel
            .endMoreDaraRefresh
            .drive(collectionView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
        
        viewModel
            .errorOutput
            .drive(HUD.flash)
            .disposed(by: bag)
        
        collectionView.rx.setDelegate(self).disposed(by: bag)
        
        viewModel.msgOutput
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.pushViewController(MessageViewController($0), animated: true)
            })
            .disposed(by: bag)
     
        looaAd(viewModel)

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
    
    fileprivate func looaAd(_ viewModel: BookShelfViewModel) {

        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        viewModel
            .topBannerConfigOuput
            .asObservable()
            .unwrap()
            .subscribe(onNext: { config in
                if config.localConfig.is_close {
                    self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
                    self.topBannerView?.isHidden = true
                    self.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                } else {
                    
                    if self.topBannerView == nil {
                        self.topBannerView = ViewBannerSerVice.chooseBanner(config.localConfig, bannerFrame: CGRect(x: 0, y: 0, width: self.collectionView.bounds.width, height: 0))
                    } else {
                        self.topBannerView?.removeFromSuperview()
                        self.topBannerView = ViewBannerSerVice.chooseBanner(config.localConfig, bannerFrame: CGRect(x: 0, y: 0, width: self.collectionView.bounds.width, height: 0))
                    }
                    self.view.addSubview(self.topBannerView!)
                    self.topBannerView!.snp.makeConstraints {
                        $0.width.equalTo(self.collectionView.bounds.width)
                        $0.top.equalTo(self.view.snp.top)
                        $0.height.equalTo(75)
                    }
                    self.view.setNeedsLayout()
                    ViewBannerSerVice.configData(config, bannerView: self.topBannerView)
                    self.collectionView.contentInset = UIEdgeInsets(top: 75, left: 0, bottom: 80, right: 0)
                    self.collectionView.setContentOffset(CGPoint(x: 0, y: -75), animated: false)
                }
            },onError: { _ in
                self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
                self.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate).mapToVoid()
            .filter {_ in AdvertiseService.advertiseConfig(.bookShelfTop) != nil }
            .map { AdvertiseService.advertiseConfig(.bookShelfTop) }
            .filter { ($0?.is_close ?? false) == true}
            .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                DispatchQueue.main.async {
                    weakSelf.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
                    weakSelf.topBannerView?.isHidden = true
                    weakSelf.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                }
            })
             .disposed(by: bag)
        
        /// banner 加载GDT广告 - viewmodel 需要用 控制器初始化
        viewModel.bannerOutput
            .asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.GDT.rawValue}
            .subscribe(onNext: { [weak self] topbannerConfig in
                guard let weakSelf = self else {
                    return
                }
                let gdtViewModel = GDTBannerViewModel(topbannerConfig, viewController: weakSelf)
                gdtViewModel.nativeAdOutput
                    .asObservable()
                    .subscribe(onNext: { (nativeAd) in
                        let temConfig = LocalTempAdConfig(topbannerConfig, adType: LocalAdvertiseType.GDT(nativeAd))
                        viewModel.topBannerConfigOuput.onNext(temConfig)
                    }, onError: { (error) in
                        do {
                            let current = try viewModel.topBannerConfigOuput.value()
                            if current  == nil {
                                viewModel.topBannerConfigOuput.onError(error)
                            }
                        } catch {
                            viewModel.topBannerConfigOuput.onError(error)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                viewModel.topBannerVM = gdtViewModel
            })
            .disposed(by: bag)
        
        /// banner 加载头条广告 - viewmodel 需要用 控制器初始化
        viewModel
            .bannerOutput
            .asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.todayHeadeline.rawValue}
            .subscribe(onNext: { [weak self] topbannerConfig in
                guard let weakSelf = self else {
                    return
                }
                print("BUNativeBannerViewModel:(\(weakSelf.parent!.navigationController!))")
                let buBannerVM = BUNativeBannerViewModel(topbannerConfig, viewController: weakSelf.parent!)
                buBannerVM.nativeAdOutput
                    .asObservable()
                    .subscribe(onNext: { (nativeAd) in
                        let temConfig = LocalTempAdConfig(topbannerConfig, adType: LocalAdvertiseType.todayHeadeline(nativeAd))
                         viewModel.topBannerConfigOuput.onNext(temConfig)
                    }, onError: { (error) in
                        do {
                            let current = try viewModel.topBannerConfigOuput.value()
                            if current  == nil {
                                viewModel.topBannerConfigOuput.onError(error)
                            }
                        } catch {
                            viewModel.topBannerConfigOuput.onError(error)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                viewModel.topBannerVM = buBannerVM
            })
            .disposed(by: bag)
    }
    
    fileprivate func configUI() {
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        collectionView.registerNibWithCell(IMBannerCollectionViewCell.self)
        collectionView.registerNibWithCell(ContainerCollectionViewCell.self)
        collectionView.registerNibWithCell(TopImageDownTextCollectionViewCell.self)
        collectionView.registerNibWithCell(BookListCollectionViewCell.self)
        collectionView.registerNibWithCell(BookCollectionContainerCell.self)
        collectionView.registerNibWithCell(BookHisRecomendCollectionViewCell.self)
        collectionView.registerNibWithReusableView(BookMallSectionView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        collectionView.registerClassWithReusableView(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        collectionView.registerClassWithReusableView(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
        collectionView.registerClassWithCell(UICollectionViewCell.self)
       
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        longPress.minimumPressDuration = 1
        longPress.delaysTouchesBegan = true
        longPress.delaysTouchesEnded = false
        self.collectionView.addGestureRecognizer(longPress)
        let footer = BookShelfRefreshFooter()
        collectionView.mj_footer = footer
        footer.noreDatatapAction = {
            (UIApplication.shared.keyWindow?.rootViewController as! TabBarController).selectedIndex = 1
        }
    }
    
    @objc private func longPressAction(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began { return }
        let point = sender.location(in: self.collectionView)
        if let ip = self.collectionView.indexPathForItem(at: point) {
            if ip.section != 0 { return }
            longPressAction.on(.next(ip))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        collectionView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIDevice.current.isiPhoneXSeries ? (view.bounds.size.height -  UITabBar.height): view.bounds.size.height )
        self.collectionView.contentInset = UIEdgeInsets(top: collectionView.contentInset.top, left: 0, bottom: UITabBar.height + 80, right: 0)
    }

}

extension BookShelfViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ScaleTransitionAnimation(from: CGRect.zero, isPresent: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ScaleTransitionAnimation(from: CGRect.zero, isPresent: false)
    }
}


extension BookShelfViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section >= dataSource.sectionModels.count {
            return .zero
        }
        let sectionModel = dataSource.sectionModels[section].model
        if sectionModel == "书架收藏" {
             return UIEdgeInsets(top: 0, left: 14, bottom: 14, right: 14)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section >= dataSource.sectionModels.count {
            return 0
        }
        let sectionModel = dataSource.sectionModels[section].model
        if sectionModel == "书架收藏" {
            return 14
        }
        if sectionModel == "往期推荐" {
            return 14
        }
        return 0.0001
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section >= dataSource.sectionModels.count {
            return 0.0001
        }
        let sectionModel = dataSource.sectionModels[section].model
        if sectionModel == "书架收藏" {
            return 14
        }
      
        return 0.0001
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section >= dataSource.sectionModels.count {
            return .zero
        }
        if dataSource.sectionModels[section].items.count == 0 {
            return .zero
        }
        let sectionModel = dataSource.sectionModels[section].model

        if sectionModel == "好书推荐" {
            return CGSize(width: UIScreen.main.bounds.width, height: 56)
        }
        
        if sectionModel == "书架收藏" {
            return CGSize(width: UIScreen.main.bounds.width, height: 56)
        }
        if sectionModel == "往期推荐" {
            return CGSize(width: UIScreen.main.bounds.width, height: 56)
        }
         return .zero
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section >= dataSource.sectionModels.count {
            return .zero
        }
        if dataSource.sectionModels[indexPath.section].items.count == 0 {
            return .zero
        }
        let sectionModel = dataSource.sectionModels[indexPath.section].model
        if sectionModel == "好书推荐" {
            return CGSize(width: collectionView.bounds.width, height: ContainerCollectionViewCell.UISize.cellHeight * 2 + ContainerCollectionViewCell.UISize.minimumLineSpacing)
        } else if sectionModel == "书架收藏" {
            return CGSize(width: collectionView.bounds.width, height: BookCollectionContainerCell.UISize.cellHeight)
        } else if sectionModel == "往期推荐" {
             return CGSize(width: collectionView.bounds.width - 2 * 16, height: 140)
        }
        return .zero
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if  !scrollView.isDragging {
            didEndDrag?(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isDragging {
            didEndDrag?(scrollView)
        }
    }
}
