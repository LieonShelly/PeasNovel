//
//  ReaderController.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import RxSwift
import Moya
import RxMoya
import PKHUD
import RxCocoa
import YYText
import RealmSwift
import MediaPlayer
import Alamofire

class ReaderController: BaseViewController {
    var readModel:DZMReadModel!
    private(set) var readMenu: ReaderMenuController?
    private(set) var pageViewController: UIPageViewController?
    private(set) var coverController: DZMCoverController?
    private(set) var currentReadViewController: ReaderViewController?
    var tempNumber: NSInteger = 1
    let navigationItemTouched: PublishSubject<Int> = .init()
    let currenntReadChapterCount = BehaviorRelay(value: 0)
    let progressSliderValueInput: PublishSubject<Int> = .init()
    let progressSliderLastValueInput: PublishSubject<Int> = .init()
    let allLocalChapterInfo: BehaviorRelay<[LocalReaderChapterInfo]> = .init(value: [])
    var bottomBannerData: LocalTempAdConfig?
    let readerMode: BehaviorRelay<ReaderMode> = .init(value: ReaderMode.advertise)
    var backTaskID = UIBackgroundTaskIdentifier.invalid
    fileprivate var pageNum: BehaviorRelay<Int> = .init(value: 0)
    fileprivate var startTime: Double = 0
    fileprivate var endTime: Double = 0
    fileprivate lazy var leftBtn: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = UIColor.clear
        return btn
    }()
    fileprivate lazy var rightBtn: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = UIColor.clear
        return btn
    }()
    struct UISize {
        static var bannerHeight: CGFloat = 75 +  UIDevice.current.safeAreaInsets.bottom {
            didSet {
                if oldValue != bannerHeight {
                    debugPrint("bottomBanner - bannerHeight: - oldValue - \(oldValue) - bannerHeight:\(bannerHeight)")
                    NotificationCenter.default.post(name: NSNotification.Name.Book.bottomBannerHeightDidChange, object: bannerHeight)
                }
            }
        }
        static let adBannerHeight: CGFloat = 75 +  UIDevice.current.safeAreaInsets.bottom
        static let noAdBannerHeight: CGFloat = 0
    }
    
    convenience init(_ viewModel: ReaderViewModel) {
        self.init()
        readModel = viewModel.readModel
        UISize.bannerHeight = ReaderAdService.shouldShowBottomBannerAd().isShow ? UISize.adBannerHeight: UISize.noAdBannerHeight
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
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
            .viewWillDisappear
            .bind(to: viewModel.viewWillDisappear)
            .disposed(by: bag)
        
    }
    
    func config(_ viewModel: ReaderViewModel) {
        view.backgroundColor = DZMReadConfigure.shared().readColor()
        readMenu = ReaderMenuController(vc: self, delegate: self)
        view.insertSubview(leftBtn, belowSubview: readMenu!.bottomView)
        view.insertSubview(rightBtn, belowSubview: readMenu!.bottomView)
        readMenu?.bringSubToFont()
        leftBtn.snp.makeConstraints {
            $0.left.equalTo(0)
            $0.width.equalTo(40)
            $0.top.equalTo(0)
            $0.height.equalTo(GetReadTableViewFrame().height)
            
        }
        rightBtn.snp.makeConstraints {
            $0.right.equalTo(0)
            $0.width.equalTo(40)
            $0.top.equalTo(0)
            $0.height.equalTo(GetReadTableViewFrame().height)
        }
        
        Observable.merge(NotificationCenter.default.rx.notification(Notification.Name.Book.readerViewHandling)
                            .map { $0.object as? Bool }.unwrap()
                         )
            .map { !$0 }
            .bind(to: leftBtn.rx.isEnabled)
            .disposed(by: bag)
        
        Observable.merge(NotificationCenter.default.rx.notification(Notification.Name.Book.readerViewHandling)
                        .map { $0.object as? Bool }.unwrap().map { !$0 }
            )
            .bind(to: rightBtn.rx.isEnabled)
            .disposed(by: bag)
        
        
        NotificationCenter.default.rx.notification(Notification.Name.Book.readerViewClickReportError)
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                let vcc = ChapterErrorReportViewController(ChapterReportViewModel(weakSelf.readModel.bookID, contentId: weakSelf.readModel.readRecordModel.readChapterModel?.id ?? "", textDesc: UIPasteboard.general.string, selectIndex: 0))
                weakSelf.navigationController?.pushViewController(vcc, animated: true)
            })
            .disposed(by: bag)
        
        
        let nextPageInput: PublishSubject<Void> = .init()
        leftBtn.rx.tap
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                let vcc = weakSelf.getAboveReadViewController()
                weakSelf.setViewController(displayController: vcc, isAbove: true, animated: true)
                weakSelf.addPage()
            })
            .disposed(by:  bag)
        
        Observable.merge(rightBtn.rx.tap.mapToVoid(), nextPageInput.asObservable())
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                if weakSelf.readModel.readRecordModel != nil  {
                    let vcc = weakSelf.getBelowReadViewController()
                    weakSelf.setViewController(displayController: vcc, isAbove: false, animated: true)
                }
                weakSelf.addPage()
            })
            .disposed(by:  bag)
    
        readModel.readRecordModel.readChapterModel?.sepearatePage()
        creatPageController(getCurrentReadViewController(isUpdateFont: true, isSave: true))
        
        navigationItemTouched
            .bind(to: viewModel.navItemTouched)
            .disposed(by: bag)
        
        viewModel
            .popController
            .subscribe(onNext: { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                viewModel.reportReadingTime()
                viewModel.addReadRecord()
               let reader = weakSelf.navigationController?.popViewController(animated: true)
                guard  let readerVC = reader as? BaseViewController else {
                    return
                }
                readerVC.bag = DisposeBag()
                viewModel.bag = DisposeBag()
            })
            .disposed(by: bag)
        
        viewModel
            .popController
            .filter { !$0.isEmpty }
            .subscribe(onNext: {
                HUD.flash(HUDContentType.label($0), delay: 2.0)
            })
            .disposed(by: bag)
        
    
        let allLocalChapterInfo = self.allLocalChapterInfo
        
        currenntReadChapterCount.asObservable()
            .debug()
            .bind(to: viewModel.currentReadChapterCount)
            .disposed(by: bag)
        
        progressSliderValueInput.asObservable()
            .debug()
            .bind(to: viewModel.progressSliderValueInput)
            .disposed(by: bag)
        
        viewModel.allLocalChapterInfo.asObservable()
            .bind(to: allLocalChapterInfo)
            .disposed(by: bag)
        
        viewModel.allLocalChapterInfo
            .asObservable()
            .subscribe(onNext: {[weak self] (chapter) in
                guard let weakSelf = self, let last = chapter.last  else {
                    return
                }
                weakSelf.readMenu?.progressView.slider.minimumValue = 0
                weakSelf.readMenu?.progressView.slider.maximumValue = Float(last.order)
                weakSelf.readMenu?.progressView.sliderUpdate()
            })
            .disposed(by: bag)
        
        
        viewModel.progressSliderValueOutput
            .subscribe(onNext: {[weak self] (info) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.readMenu?.progressView.titleLabel.text = info.title
            })
            .disposed(by: bag)
        
        progressSliderLastValueInput
            .asObservable()
            .debug()
            .map {(order) -> LocalReaderChapterInfo? in
                if let index =  allLocalChapterInfo.value.lastIndex(where: {$0.order == order}) {
                    return allLocalChapterInfo.value[index]
                } else if order == 0 { /// 滑动到了扉页
                    let first = LocalReaderChapterInfo()
                    first.content_id = ReaderSpecialChapterValue.firstPageValue
                    return first
                }
                return nil
            }
            .unwrap()
            .map { $0.content_id }
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] (content_id) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.goToChapter(chapterID: content_id)
            })
            .disposed(by: bag)
        
        readMenu!.bookMarkView.addBtn
            .rx.tap
            .map { viewModel.readModel.readRecordModel }
            .map({ (record) -> DZMReadRecordModel? in
                if record?.readChapterModel?.id == ReaderSpecialChapterValue.firstPageValue {
                    HUD.flash(HUDContentType.label("扉页不能加入到书签"), delay: 2)
                    return nil
                }
                return record
            })
            .unwrap()
            .bind(to: viewModel.addBookMarkInput)
            .disposed(by: bag)
        
        readMenu!.bookMarkView.clearBtn
            .rx.tap
            .mapToVoid()
            .bind(to: viewModel.removeBookInput)
            .disposed(by: bag)
        
        
        viewModel.bookMarks
            .asObservable()
            .bind(to: readMenu!.bookMarkView.tableView.rx.items(cellIdentifier: String(describing: BookMarkTableViewCell.self), cellType: BookMarkTableViewCell.self)) { (row, element, cell) in
                var index = 10
                if index >= element.content.count {
                    index =  element.content.count - 1
                }
                cell.label?.text = element.name + " " +  element.content[ ..<element.content.index( element.content.startIndex, offsetBy: 10)]
                cell.contentView.backgroundColor = UIColor(0x222222)
                cell.selectionStyle = .none
            }
            .disposed(by: bag)
        
        readMenu!.bookMarkView.tableView
            .rx.modelSelected(DZMReadMarkModel.self)
            .filter { !$0.id.isEmpty }
            .filter { $0.location != nil}
            .subscribe(onNext: { [weak self] (mark) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.goToChapter(chapterID: mark.id, toPage: viewModel.readModel.readRecordModel.readChapterModel?.page(location: mark.location.intValue) ?? 0)
            })
            .disposed(by: bag)
        
       
        viewModel.fullscreenAdOutput
            .asObservable()
            .skip(1)
            .debug()
            .map {  FullScreenVideoService.chooseVC($0) }
            .debug()
            .unwrap()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
               if UIViewController.current() is ReaderController {
                    weakSelf.present($0, animated: true, completion: nil)
                }
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Advertise.presentRewardVideoAd)
            .map {_ in AdvertiseService.advertiseConfig(.readerRewardVideoAd)}
            .unwrap()
            .filter { !$0.is_close }
            .subscribe(onNext: { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                if let vcc = RewardVideoService.chooseVC(.readerRewardVideoAd) {
                    weakSelf.present(vcc, animated: true, completion: nil)
                }
            })
            .disposed(by: bag )
        
        func watchFiveChapter() {
            let weakSelf = self
            func wathcAd() {
                weakSelf.readModel.readRecordModel.readChapterModel?.sepearatePage()
                weakSelf.readModel.readRecordModel.page = 0
                weakSelf.currentReadViewController?.readRecordModel =  weakSelf.readModel.readRecordModel
                viewModel.reloadAdConfigInput.onNext(())
                if !ReaderAdService.shouldShowBottomBannerAd().isShow {
                    weakSelf.readMenu?.bottomBanner?.removeFromSuperview()
                    weakSelf.readMenu?.bottomBanner = nil
                }
                weakSelf.creatPageController(getCurrentReadViewController())
            }
            guard let readChapterModel = weakSelf.readModel.readRecordModel.readChapterModel else {
                return
            }
            UISize.bannerHeight = UISize.noAdBannerHeight
            if readChapterModel.id == ReaderSpecialChapterValue.firstPageValue, let nextChapterId = readChapterModel.next_chapter?.content_id, !nextChapterId.isEmpty {
                weakSelf.goToChapter(chapterID: nextChapterId, toPage: 0, completeHandler:wathcAd)
            } else if readChapterModel.id == ReaderSpecialChapterValue.chapterConnectionId, let nextChapterId = readChapterModel.next_chapter?.content_id, !nextChapterId.isEmpty {
                weakSelf.goToChapter(chapterID: nextChapterId, toPage: 0, completeHandler:wathcAd)
            } else if readChapterModel.id == ReaderSpecialChapterValue.chapterConnectionId, let preChapterId = readChapterModel.last_chapter?.content_id, !preChapterId.isEmpty {
                weakSelf.goToChapter(chapterID: preChapterId, toPage: ReaderSpecialChapterValue.lastPageValue, completeHandler:wathcAd)
            } else {
               wathcAd()
            }
        }
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerRewardVideoAd.rawValue }
            .mapToVoid()
            .subscribe(onNext: watchFiveChapter)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Event.readerScrollinng)
            .map { $0.object as? DZMReadRecordModel}
            .unwrap()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] record in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.currentReadViewController?.statusBar.readRecordModel = record
            })
            .disposed(by: bag )

        viewModel.chargeOutput
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.pushViewController(ChargeViewController($0), animated: true)
            })
            .disposed(by: bag)
        
        viewModel.chargeAlertOutput
            .subscribe(onNext: { [weak self] in
                let vcc = ChargeAlertViewController($0)
                let nav = NavigationViewController(rootViewController: vcc)
                nav.modalPresentationStyle = .overCurrentContext
                guard let weakSelf = self else {
                    return
                }
                weakSelf.present(nav, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        /// 阅读器内点击了关闭广告
        NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.readerCloseAd)
            .mapToVoid()
            .debug()
            .bind(to: viewModel.noAdBtnInput)
            .disposed(by: bag )
        
        // 刷新下阅读器
        NotificationCenter.default.rx.notification(Notification.Name.Event.reloadReader)
            .mapToVoid()
            .subscribe(onNext: { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.reloadReader(viewModel)
            })
            .disposed(by: bag )
        

        viewModel.bannerOutput
            .asObservable()
            .debug()
            .unwrap()
            .subscribe(onNext: { [weak self](config) in
                    guard let weakSelf = self else {
                        return
                    }
                    let bannerView = weakSelf.setupBottombanner(config.localConfig, viewModel: viewModel)
                    weakSelf.bottomBannerData = ViewBannerSerVice.configData(config, bannerView: bannerView)
                }, onError: {[weak self] _ in
                    guard let weakSelf = self else {
                        return
                    }
                    UISize.bannerHeight = UISize.noAdBannerHeight
            })
            .disposed(by: bag)
        
        viewModel.bannerConfigOutput
            .asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.GDT.rawValue }
            .debug()
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                debugPrint("bottomBanner - GDTBannerViewModel")
                let gdtViewModel = GDTBannerViewModel(config, outterConfig: weakSelf, viewController: weakSelf)
                gdtViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .GDT($0))}
                    .bind(to: viewModel.bannerOutput)
                    .disposed(by: viewModel.bag)
                viewModel.bannerViewModel = gdtViewModel
            })
            .disposed(by: bag)
        
        viewModel.bannerConfigOutput
            .asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.todayHeadeline.rawValue }
            .debug()
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                debugPrint("bottomBanner - BUNativeBannerViewModel")
                let buViewModel =  BUNativeBannerViewModel(config, isAutoRefresh: true, viewController: weakSelf)
                buViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .todayHeadeline($0))}
                    .bind(to: viewModel.bannerOutput)
                    .disposed(by: viewModel.bag)
                viewModel.bannerViewModel = buViewModel
            })
            .disposed(by: bag)
        
        viewModel.readerMode
            .asObservable()
            .observeOn(MainScheduler.instance)
            .filter { $0.rawValue == ReaderMode.noAdvertise.rawValue }
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                viewModel.bannerViewModel = nil
                weakSelf.readMenu?.bottomBanner?.removeFromSuperview()
                weakSelf.readMenu?.bottomBanner = nil
            })
            .disposed(by: bag)
        
        viewModel.readerMode
            .asObservable()
            .bind(to: readerMode)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.allTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerBottomBanner.rawValue }
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                if ReaderController.UISize.bannerHeight != UISize.noAdBannerHeight {
                    ReaderController.UISize.bannerHeight = UISize.noAdBannerHeight
                    weakSelf.reloadReader(viewModel)
                }
            })
            .disposed(by: bag)
      
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.rewardVideoLoadSuccess)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerRewardVideoAd.rawValue }
            .map {_ in 0 }
            .bind(to: currenntReadChapterCount)
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(Notification.Name.Book.didChangeChapter)
            .map { $0.object as? String }
            .unwrap()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](name) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.currenntReadChapterCount.accept(weakSelf.currenntReadChapterCount.value + 1)
                ReaderAdService.presentChapterConnectionAd(weakSelf , title: name, isShowBotton: true)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Book.chapaterIsLastpage)
            .mapToVoid()
            .delay(RxTimeInterval.milliseconds(200), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.endTime = Date().timeIntervalSince1970
                weakSelf.addPage()
                StatisticHandler.userReadActionParam["read_consume_time"] = "\(weakSelf.endTime - weakSelf.startTime)"
                StatisticHandler.userReadActionParam["page_num"] = "\(weakSelf.pageNum.value)"
                StatisticHandler.userReadActionParam["content_id"] = weakSelf.readModel.readRecordModel.readChapterModel?.id ?? ""
                StatisticHandler.userReadActionParam["book_id"] = weakSelf.readModel.bookID
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.userReadAction, object:  StatisticHandler.userReadActionParam)
                 weakSelf.startTime = Date().timeIntervalSince1970
            })
            .disposed(by: bag)
        
        Observable.merge(NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.shared).mapToVoid())
            .subscribe(onNext: { [weak self] in
                if let weakSelf = self {
                    weakSelf.readMenu?.menuSH(isShow: false)
                }
            })
            .disposed(by: bag)
        
        viewModel.listenBookOutput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self](vm) in
                listenBook()
                showListenBookMenu()
            })
             .disposed(by: bag)
        
        func listenBook() {
            let weakSelf = self
            guard let readChapterModel = weakSelf.readModel.readRecordModel.readChapterModel else {
                return
            }
            if readChapterModel.id == ReaderSpecialChapterValue.firstPageValue, let nextChapterId = readChapterModel.next_chapter?.content_id {
                weakSelf.goToChapter(chapterID: nextChapterId, toPage: 0, completeHandler: {
                    if let pageModels = weakSelf.readModel.readRecordModel.readChapterModel?.pageModels {
                        SpeechManager.share.startTasks(pageModels)
                    }
                })
            } else {
                let currentPage = weakSelf.readModel.readRecordModel.page
                let endIndex = readChapterModel.pageModels.count - 1
                if endIndex > currentPage {
                    let pageModels = readChapterModel.pageModels[currentPage ... endIndex]
                    SpeechManager.share.startTasks(Array(pageModels))
                } else if currentPage == endIndex {
                     SpeechManager.share.startTasks([readChapterModel.pageModels[currentPage]])
                }
            }
        }
        
        func showListenBookMenu() {
            readMenu?.menuSH(isShow: false)
            let vcc = ListenBookMenuViewController(ListenBookMenuViewModel())
            vcc.modalTransitionStyle = .crossDissolve
            vcc.modalPresentationStyle = .custom
            present(vcc, animated: true, completion: nil)
        }
        
        viewModel.listenBookAlertViewModel
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (vm) in
                guard let weakSelf = self else {
                    return
                }
                for childVC in weakSelf.children where  childVC is ListenBookAlertViewController {
                    childVC.view.removeFromSuperview()
                    childVC.removeFromParent()
                }
                let vcc = ListenBookAlertViewController(vm)
                weakSelf.addChild(vcc)
                vcc.view.frame = weakSelf.view.bounds
                weakSelf.view.addSubview(vcc.view)
                vcc.view.alpha = 0
                weakSelf.view.bringSubviewToFront(vcc.view)
                UIView.animate(withDuration: 0.25, animations: {
                    vcc.view.alpha = 1
                })
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Book.ListenBook.onePageListenEnd)
            .map { $0.object as? ChapterPageModel }
            .unwrap()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](currentPage) in
                guard let weakSelf = self else {
                    return
                }
                let type = currentPage.type
                switch type {
                case .text:
                    nextPageInput.onNext(())
                case .fullScreenAd:
                    let page = currentPage.page
                    weakSelf.readModel.readRecordModel.page = page
                    nextPageInput.onNext(())
                }
            })
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(Notification.Name.Book.ListenBook.oneChapterListenEnd)
            .debug()
            .map { $0.object as? ChapterPageModel }
            .unwrap()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (pageModel) in
                guard let weakSelf = self,  let chapter = weakSelf.readModel.readRecordModel.readChapterModel else {
                    return
                }
                if !me.isLogin {
                    if let todayListenChapterCount = ListenBookAdModel.todayListenChapterCount(), todayListenChapterCount + 1 >= 5 {
                        HUD.flash(HUDContentType.label("听书5章结束"), delay: 3)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4, execute: {
                            SpeechManager.share.stopAllTask()
                        })
                         ListenBookAdModel.addListenChapterCount()
                        return
                    }
                    ListenBookAdModel.addListenChapterCount()
                } else if !me.isVipValid {
                    HUD.flash(HUDContentType.label("VIP过期"), delay: 3)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4, execute: {
                        SpeechManager.share.stopAllTask()
                    })
                    return
                }
                if let nextChapterId = chapter.next_chapter?.content_id,
                    !nextChapterId.isEmpty,
                    let title = chapter.next_chapter?.title {
                    weakSelf.goToChapter(chapterID: nextChapterId, toPage: 0, completeHandler: {
                        if let pageModels = weakSelf.readModel.readRecordModel.readChapterModel?.pageModels {
                             SpeechManager.share.startTasks(pageModels)
                        }
                        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyArtist] = title
                    })
                } else {
                     SpeechManager.share.stopAllTask()
                }
            })
            .disposed(by: bag)
        
        
        func showErrorAlert() {
            let alertView = ListenBokkAlert()
            alertView.modalPresentationStyle = .custom
            alertView.modalTransitionStyle = .crossDissolve
            alertView.cancleAction = {
                SpeechManager.share.stopAllTask()
            }
            alertView.closeAction = {
                SpeechManager.share.stopAllTask()
            }
            alertView.enterAction = {
                listenBook()
                showListenBookMenu()
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
                self.present(alertView, animated: true, completion: nil)
            })
        }
       
        NotificationCenter.default.rx.notification(Notification.Name.Book.ListenBook.showErrorAlert)
            .mapToVoid()
            .subscribe(onNext: showErrorAlert)
            .disposed(by: bag)
      
        NotificationCenter.default.rx.notification(Notification.Name.Book.ListenBook.statusCallback)
            .map { $0.object as? SpeechManager.Stattus}
            .unwrap()
            .subscribe(onNext: {[weak self] (status) in
                guard let weakSelf = self else {
                    return
                }
                switch status {
                case .playBegin:
                    DispatchQueue.main.async {
                        if  weakSelf.currentReadViewController?.tableView.isScrollEnabled ?? true {
                            weakSelf.currentReadViewController?.tableView.isScrollEnabled = false
                        }
                    }
                case .stop:
                    DispatchQueue.main.async {
                        weakSelf.currentReadViewController?.tableView.isScrollEnabled = true
                        HUD.flash(HUDContentType.label("已退出语言朗读"), delay: 2)
                    }
                default:
                    break
                }
                
            })
            .disposed(by: bag)
       
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate)
            .mapToVoid()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.reloadReader(viewModel)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Book.bottomBannerHeightDidChange)
            .mapToVoid()
            .skip(1)
            .observeOn(MainScheduler.instance)
            .map { viewModel }
            .subscribe(onNext: reloadBottombanner)
            .disposed(by: bag)
        
        setupNowPlayingAudioInfo(viewModel)
        addPlayingAudioNotify()
    }
    
    fileprivate func layoutContainerView() {
        let height = UIScreen.main.bounds.height - UISize.bannerHeight
        if pageViewController != nil {
            if pageViewController!.view.frame.height != height {
                pageViewController!.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
                view.setNeedsLayout()
            }
        } else if coverController != nil {
            if coverController!.view.frame.height != height {
                coverController!.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
                coverController!.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
                view.setNeedsLayout()
            }
        }
    }
    
    fileprivate func reloadBottombanner(_ viewModel: ReaderViewModel) {
        if UISize.bannerHeight == UISize.adBannerHeight { /// 显示
            viewModel.readerMode.accept(.advertise)
            viewModel.reloadAdConfigInput.onNext(())
        } else {
            readMenu?.bottomBanner?.removeFromSuperview()
            readMenu?.bottomBanner = nil
            viewModel.readerMode.accept(.noAdvertise)
        }
        layoutContainerView()
        readModel.readRecordModel.readChapterModel?.sepearatePage()
        if readModel.readRecordModel != nil {
            currentReadViewController?.readRecordModel = readModel.readRecordModel
        }
        creatPageController(getCurrentReadViewController())
    }
    
    fileprivate func reloadReader(_ viewModel: ReaderViewModel) {
        layoutContainerView()
        let weakSelf = self
        viewModel.reloadAdConfigInput.onNext(())
        if !ReaderAdService.shouldShowBottomBannerAd().isShow {
            weakSelf.readMenu?.bottomBanner?.removeFromSuperview()
            weakSelf.readMenu?.bottomBanner = nil
        } else {
            viewModel.readerMode.accept(.advertise)
        }
        readModel.readRecordModel.readChapterModel?.sepearatePage()
        if readModel.readRecordModel != nil {
            currentReadViewController?.readRecordModel = readModel.readRecordModel
        }
        creatPageController(getCurrentReadViewController())
    }
    

    fileprivate func removeBottombanner() {
        if readMenu?.bottomBanner != nil {
            readMenu?.bottomBanner?.isHidden = true
            view.setNeedsLayout()
        }
    }
    
    fileprivate func setupBottombanner(_ config: LocalAdvertise, viewModel: ReaderViewModel) -> UIView? {
        guard ReaderAdService.shouldShowBottomBannerAd().isShow else {
            return nil
        }
        if UISize.bannerHeight != UISize.adBannerHeight {
            UISize.bannerHeight = UISize.adBannerHeight
            layoutContainerView()
        }
        guard let  bottomBanner = ViewBannerSerVice.chooseBanner(config, bannerFrame: CGRect(x: 0, y: UIScreen.main.bounds.height - UISize.bannerHeight, width: UIScreen.main.bounds.width , height: UISize.bannerHeight)) else {
            return nil
        }
        if readMenu?.bottomBanner != nil {
           readMenu?.bottomBanner?.removeFromSuperview()
        }
        bottomBanner.backgroundColor = DZMReadConfigure.shared().readColor()
        if let bottom = bottomBanner as? IMBannerView {
            bottom.isDefaultCloseAction.accept(false)
            bottom.closeBtn.rx.tap.mapToVoid()
                .subscribe(onNext: { (_) in
                    NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
                })
                .disposed(by: bag)
        }
        if let bottom = bottomBanner as? BUNativeBannerView {
            bottom.isDefaultCloseAction.accept(false)
            bottom.closeBtn.rx.tap.mapToVoid()
                .subscribe(onNext: { (_) in
                    NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
                })
                .disposed(by: bag)
        }
        readMenu?.bottomBanner = bottomBanner
        view.insertSubview(bottomBanner, belowSubview: readMenu!.bottomView)
        currenntReadChapterCount.asObservable()
            .map {_ in false }
            .bind(to: readMenu!.bottomBanner!.rx.isHidden)
            .disposed(by: bag)
        readMenu?.bringSubToFont()
        return bottomBanner
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startTime = Date().timeIntervalSince1970
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarStyle(.default, animated: true)
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.fade)
        if SpeechManager.share.isRunning {
            SpeechManager.share.stopAllTask()
        }
    }
    

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
 
    /// 浮层
    private func checkGuideMask() {
        let key = UserDefaults.standard.bool(forKey: Constant.UserDefaultsKey.novelReaderGuidePage)
        if key { return }
        if let view = ReaderCoverView.loadNib() {
            UIApplication.shared.keyWindow?.addSubview(view)
            view.alpha = 0
            UIView.animate(withDuration: 0.25, animations: {
                view.alpha = 1
            }, completion: nil)
            UserDefaults.standard.set(true, forKey: Constant.UserDefaultsKey.novelReaderGuidePage   )
            UserDefaults.standard.synchronize()
        }
    }
    
    func creatPageController(_ displayController:UIViewController?) {
        if pageViewController != nil {
            pageViewController?.view.removeFromSuperview()
            pageViewController?.removeFromParent()
            pageViewController = nil
        }
        if coverController != nil {
            coverController?.view.removeFromSuperview()
            coverController?.removeFromParent()
            coverController = nil
        }
        let height = UIScreen.main.bounds.height - UISize.bannerHeight
        let effect = DZMReadConfigure.shared().effectType
        if effect == DZMRMEffectType.simulation.rawValue { // 仿真
            let options = [UIPageViewController.OptionsKey.spineLocation : NSNumber(value: UIPageViewController.SpineLocation.min.rawValue)]
            pageViewController = UIPageViewController(transitionStyle:.pageCurl,
                                                      navigationOrientation:.horizontal,
                                                      options: options)
            pageViewController!.delegate = self
            pageViewController!.dataSource = self
            pageViewController!.isDoubleSided = true
            pageViewController!.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
            view.insertSubview(pageViewController!.view, at: 0)
            addChild(pageViewController!)
            let direction = UIPageViewController.NavigationDirection.forward
            pageViewController!.setViewControllers((displayController != nil ? [displayController!] : nil), direction: direction, animated: false, completion: nil)
            for ges in pageViewController!.gestureRecognizers {
                if ges is UITapGestureRecognizer {//  ges is UIPanGestureRecognizer
                    ges.delegate = self
                }
            }
        } else if effect ==  DZMRMEffectType.leftRightScroll.rawValue  {
            let options = [UIPageViewController.OptionsKey.spineLocation : NSNumber(value: UIPageViewController.SpineLocation.none.rawValue)]
            pageViewController = UIPageViewController(transitionStyle:.scroll,
                                                      navigationOrientation:.horizontal,
                                                      options: options)
            pageViewController!.delegate = self
            pageViewController!.dataSource = self
            pageViewController!.isDoubleSided = false
            pageViewController!.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
            view.insertSubview(pageViewController!.view, at: 0)
            addChild(pageViewController!)
            let direction = UIPageViewController.NavigationDirection.forward
            pageViewController!.setViewControllers((displayController != nil ? [displayController!] : nil), direction: direction, animated: false, completion: nil)
            for ges in pageViewController!.gestureRecognizers {
                if ges is UITapGestureRecognizer {//  ges is UIPanGestureRecognizer
                    ges.delegate = self
                }
            }
        } else {
            coverController = DZMCoverController()
            if DZMReadConfigure.shared().effectType == DZMRMEffectType.none.rawValue {
                coverController!.openAnimate = false
                coverController!.panEnabled = true
            } else {
                coverController!.panEnabled = true
                coverController!.openAnimate = true
            }
            coverController!.delegate = self
            coverController!.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
            view.insertSubview(coverController!.view, at: 0)
            addChild(coverController!)
            coverController!.setController(displayController)
           
        }
        currentReadViewController = displayController as? ReaderViewController
        view.bringSubviewToFront(leftBtn)
        view.bringSubviewToFront(rightBtn)
        readMenu?.bringSubToFont()
        view.backgroundColor =  DZMReadConfigure.shared().readColor()
    }
    
    func setViewController(displayController:UIViewController?, isAbove: Bool, animated: Bool) {
        if displayController != nil {
            if let pageViewController = pageViewController {
                let direction = isAbove ? UIPageViewController.NavigationDirection.reverse : UIPageViewController.NavigationDirection.forward
                if pageViewController.isDoubleSided {
                    pageViewController.setViewControllers([displayController!, readBGController(displayController!.view)], direction: direction, animated: animated, completion: { [weak self] flag  in
                        if flag {
                            if let weakSelf = self, let raderVC = displayController as? ReaderViewController {
                                weakSelf.readRecordUpdate(readRecordModel: raderVC.readRecordModel)
                                if let title = weakSelf.readModel.readRecordModel.readChapterModel?.name {
                                    ReaderAdService.addWatchFiveChapterCount(title)
                                }
                            }
                        }
                    })
                } else {
                    pageViewController.setViewControllers([displayController!], direction: direction, animated: animated, completion: { [weak self] flag  in
                        if flag {
                            if let weakSelf = self, let raderVC = displayController as? ReaderViewController {
                                weakSelf.readRecordUpdate(readRecordModel: raderVC.readRecordModel)
                                if let title = weakSelf.readModel.readRecordModel.readChapterModel?.name {
                                    ReaderAdService.addWatchFiveChapterCount(title)
                                }
                            }
                        }
                    })
                }
                return
            }
            if coverController != nil {
                coverController?.setController(displayController!, animated: animated, isAbove: isAbove)
                if let raderVC = displayController as? ReaderViewController {
                     readRecordUpdate(readRecordModel: raderVC.readRecordModel)
                }
                return
            }
            creatPageController(displayController!)
        }

    }
    
    private func readBGController(_ targetView:UIView? = nil) -> BackgroundViewController {
        
        let vc = BackgroundViewController()
        
        vc.targetView = targetView ?? getCurrentReadViewController()?.view
        
        return vc
    }
    
    deinit {
        readModel = nil
        currentReadViewController = nil
    }
}


extension ReaderController: DZMReadMenuDelegate {


    func readMenuClickSetuptColor(readMenu: ReaderMenuController, index: NSInteger, color: UIColor) {
        DZMReadConfigure.shared().colorIndex = index
        readMenu.bottomBanner?.backgroundColor = DZMReadConfigure.shared().readColor()
        readModel.readRecordModel.readChapterModel?.sepearatePage()
        if readModel.readRecordModel != nil {
            currentReadViewController?.readRecordModel = readModel.readRecordModel
        }
        readMenu.lightView?.normalStyle()
        creatPageController(getCurrentReadViewController())
        NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.readerChangeColor, object: DZMReadConfigure.shared().readColor())
    }
    
    func readMenuClickSetuptEffect(readMenu: ReaderMenuController, index: NSInteger) {
        if  DZMReadConfigure.shared().effectType != index {
            DZMReadConfigure.shared().effectType = index
            readModel.readRecordModel.readChapterModel?.sepearatePage()
            if readModel.readRecordModel != nil {
                currentReadViewController?.readRecordModel = readModel.readRecordModel
            }
            creatPageController(getCurrentReadViewController())
        }
    }
    
    func readMenuClickSetuptFont(readMenu: ReaderMenuController, index: NSInteger) {
        
        DZMReadConfigure.shared().fontType = index
        readModel.readRecordModel.readChapterModel?.sepearatePage()
        if readModel.readRecordModel != nil {
            currentReadViewController?.readRecordModel = readModel.readRecordModel
        }
        creatPageController(getCurrentReadViewController(isUpdateFont: true, isSave: true))
    }
    
    func readMenuClickSetuptFontSize(readMenu: ReaderMenuController, fontSize: CGFloat) {
        readModel.readRecordModel.readChapterModel?.sepearatePage()
        if readModel.readRecordModel != nil {
            currentReadViewController?.readRecordModel = readModel.readRecordModel
        }
        creatPageController(getCurrentReadViewController(isUpdateFont: true, isSave: true))
    }
    
    func readMenuClickPreviousChapter(readMenu: ReaderMenuController) {
        
        if readModel != nil, let lastChapterId = readModel.readRecordModel.readChapterModel?.lastChapterId, !lastChapterId.isEmpty {
            let _ = goToChapter(chapterID: lastChapterId)
        } else {
            HUD.flash(.label("已经是第一章了"), delay: 2)
        }
    }
    
    func readMenuClickNextChapter(readMenu: ReaderMenuController) {
        
        if readModel != nil, let nextChapterId = readModel.readRecordModel.readChapterModel?.nextChapterId, !nextChapterId.isEmpty{
            let _ = goToChapter(chapterID: nextChapterId)
        } else {
            HUD.flash(.label("已经是最后一章了"), delay: 2)
        }
    }
    
    func readMenuClickChapterList(readMenu: ReaderMenuController, readChapterListModel: DZMReadChapterListModel) {
        
        let _ = goToChapter(chapterID: readChapterListModel.id)
    }
    
    func readMenuClickLightButton(readMenu: ReaderMenuController, isDay: Bool) {
        
        if isDay {
            DZMReadConfigure.shared().colorIndex = 1
        } else {
            DZMReadConfigure.shared().colorIndex = 5 /// 夜间模式
        }
        readModel.readRecordModel.readChapterModel?.sepearatePage()
        if readModel.readRecordModel != nil {
            currentReadViewController?.readRecordModel = readModel.readRecordModel
        }
        creatPageController(getCurrentReadViewController())
        readMenu.bottomBanner?.backgroundColor = DZMReadConfigure.shared().readColor()
    }
    
    func readMenuWillShowOrHidden(readMenu: ReaderMenuController, isShow: Bool) {
        pageViewController?.tapGestureRecognizerEnabled = !isShow
        if isShow {
            readMenu.bottomView.bookMarkBtn.isSelected = readModel.checkMark()
        }else{
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    func readMenuDidShowOrHidden(readMenu: ReaderMenuController, isShow: Bool) {
        if isShow {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    func readMenuClickBackButton(readMenu: ReaderMenuController, button: UIButton) {
        
        navigationItemTouched.on(.next(0))
    }
    
    func readMenuCatelogButton(readMenu: ReaderMenuController, button: UIButton) {
        navigationItemTouched.on(.next(1))
    }
    
}


extension ReaderController: DZMCoverControllerDelegate {
    
    public func coverController(_ coverController: DZMCoverController, currentController: UIViewController?, finish isFinish: Bool) {
        if isFinish {
            if let title = readModel.readRecordModel.readChapterModel?.name {
                ReaderAdService.addWatchFiveChapterCount(title)
            }
            if let currentReadViewController = currentController as? ReaderViewController {
                self.currentReadViewController = currentReadViewController
                readRecordUpdate(readRecordModel: currentReadViewController.readRecordModel)
            } else {
                readRecordUpdate(readRecordModel: readModel.readRecordModel)
            }
            if DZMReadConfigure.shared().effectType == DZMRMEffectType.translation.rawValue {
                addPage()
            }
        }
    }
    
    public func coverController(_ coverController: DZMCoverController, willTransitionToPendingController pendingController: UIViewController?) {
        
        readMenu?.menuSH(isShow: false)
    }
    
    public func coverController(_ coverController: DZMCoverController, getAboveControllerWithCurrentController currentController: UIViewController?) -> UIViewController? {
        
        return getAboveReadViewController()
    }
    
    public func coverController(_ coverController: DZMCoverController, getBelowControllerWithCurrentController currentController: UIViewController?) -> UIViewController? {
        
        return getBelowReadViewController()
    }
}

extension ReaderController: UIPageViewControllerDelegate {

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            addPage()
            if let currentReadViewController = pageViewController.viewControllers?.first as? ReaderViewController {
                self.currentReadViewController = currentReadViewController
                readRecordUpdate(readRecordModel: currentReadViewController.readRecordModel)
            } else {
                readRecordUpdate(readRecordModel: readModel.readRecordModel)
            }
            if let title = readModel.readRecordModel.readChapterModel?.name {
                ReaderAdService.addWatchFiveChapterCount(title)
            }
        }
       
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        readMenu?.menuSH(isShow: false)
    }
    
}

extension ReaderController: UIPageViewControllerDataSource {
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if pageViewController.isDoubleSided {
            tempNumber -= 1
            if abs(tempNumber) % 2 == 0 {
                return readBGController()
            } else {
                return getAboveReadViewController()
            }
        } else {
            let readerVC = getAboveReadViewController()
            return readerVC
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if pageViewController.isDoubleSided {
            tempNumber += 1
            if abs(tempNumber) % 2 == 0 {
                return readBGController()
            } else {
                return getBelowReadViewController()
            }
        } else {
            let readerVC = getBelowReadViewController()
            return readerVC
        }
       
    }
}


extension ReaderController: Advertiseable {
    var isAutoRefresh: Bool {
        return true
    }
    
    func adClickHandler(_ config: LocalAdvertise?) -> Bool {
        NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
        return true
    }
}

extension ReaderController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            return false
        }
        if gestureRecognizer is UIPanGestureRecognizer {
            if let id = readModel.readRecordModel.readChapterModel?.id, id == ReaderSpecialChapterValue.firstPageValue {
                return true
            }
           return !SpeechManager.share.isRunning
        }
        return true
    }
}

extension ReaderController {
    
    func addPage() {
        pageNum.accept(pageNum.value + 1)
    }
    
    fileprivate  func setupNowPlayingAudioInfo(_ viewModel: ReaderViewModel) {
        var songDict = [String: Any]()
        songDict[MPMediaItemPropertyTitle] = readModel.readRecordModel.readChapterModel?.bookInfo?.book_title ?? ""
        songDict[MPMediaItemPropertyArtist] = readModel.readRecordModel.readChapterModel?.name ?? ""
        songDict[MPNowPlayingInfoPropertyPlaybackRate] = 1
        let artNetwork = MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 150)) { (size) -> UIImage in
            return  UIImage(named: "logo")!
        }
        songDict[MPMediaItemPropertyArtwork] = artNetwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = songDict
        
        Observable.just(readModel.readRecordModel.readChapterModel?.bookInfo?.cover_url)
            .unwrap()
            .map {URL(string: $0)}
            .unwrap()
            .retrieveImage()
            .unwrap()
            .map { image in
                return MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 150)) { (size) -> UIImage in
                    return  image
                }}
            .subscribe(onNext: { (networkImage) in
                MPNowPlayingInfoCenter.default().nowPlayingInfo![MPMediaItemPropertyArtwork] = networkImage
            })
            .disposed(by: bag)
    }
    
    fileprivate func addPlayingAudioNotify() {
        NotificationCenter.default
            .rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                UIApplication.shared.beginReceivingRemoteControlEvents()
                weakSelf.backTaskID = weakSelf.backgroundPlayerId(weakSelf.backTaskID)
            })
            .disposed(by: bag)

    }
    
    private func backgroundPlayerId(_ playerId: UIBackgroundTaskIdentifier) -> UIBackgroundTaskIdentifier{
        var newTaskId = UIBackgroundTaskIdentifier.invalid
        newTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        if newTaskId != UIBackgroundTaskIdentifier.invalid  && playerId !=  UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(playerId)
        }
        return newTaskId
    }
    
}

enum ReaderStatus: Int {
    case none = -1
    case pagingNext = 1
    case pagingPre = 2
    case chapterAppear = 3
}
