//
//  ReaderViewModel.swift
//  Arab
//
//  Created by weicheng wang on 2018/10/9.
//  Copyright © 2018年 kanshu.com. All rights reserved.
//  阅读器的ViewModel

import UIKit
import Moya
import RxMoya
import RxCocoa
import RxSwift
import RealmSwift
import Alamofire
import PKHUD

class ReaderViewModel: Advertiseable {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let navItemTouched: PublishSubject<Int> = .init()
    let addBookshelf: PublishSubject<Void> = .init()
    var bannerViewModel: Advertiseable?
    let currentReadChapterCount = BehaviorRelay(value: 0)
    let progressSliderValueInput: PublishSubject<Int> = .init()
    let removeBookInput: PublishSubject<Void> = .init()
    let addBookMarkInput: PublishSubject<DZMReadRecordModel> = .init()
    let noAdBtnInput: PublishSubject<Void> = .init()
    let reloadAdConfigInput: PublishSubject<Void> = .init()
    
    /// output
    let popController: PublishSubject<String> = .init()
    let fullscreenAdOutput: BehaviorRelay<AdPosition> = .init(value: AdPosition.none)
    let allLocalChapterInfo: BehaviorRelay<[LocalReaderChapterInfo]> = .init(value: [])
    let progressSliderValueOutput: PublishSubject<LocalReaderChapterInfo> = .init()
    let bookMarks: BehaviorRelay<[DZMReadMarkModel]> = .init(value: [])
    let chargeOutput: PublishSubject<ChargeViewModel> = .init()
    let chargeAlertOutput: PublishSubject<ChargeAlertViewModel> = .init()
    let bannerOutput = BehaviorSubject<LocalTempAdConfig?>.init(value: nil)
    let bannerConfigOutput: BehaviorRelay<LocalAdvertise?> = .init(value: nil)
    let listenBookAlertViewModel: Observable<ListenBookAlertViewModel>
    let listenBookOutput: PublishSubject<Void> = .init()

    /// 常量
    let readModel: DZMReadModel 
    var bag = DisposeBag()
    let readerMode: BehaviorRelay<ReaderMode> = .init(value: ReaderMode.advertise)

    init(_ readModel: DZMReadModel, provider: MoyaProvider<BookReaderService> = MoyaProvider<BookReaderService>()) {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let dbChapterInfo: BehaviorRelay<[LocalReaderChapterInfo]> = .init(value: [])
        let allLocalChapterInfo = self.allLocalChapterInfo

        self.readModel = readModel
        let bookMarks = self.bookMarks
        
        
        /// 书籍详情
        let bookDetail = BehaviorRelay<BookDetailModel>(value: BookDetailModel())
        let detailProvider = MoyaProvider<BookInfoService>()
        
         viewDidLoad.map{ false }
            .flatMap{
                detailProvider
                    .rx
                    .request(.catalog(readModel.bookID, page: 1, order: $0))
                    .model(BookCatalogResponse.self)
                    .asObservable()
                }
            .map { $0.data }
            .unwrap()
            .map { $0.first }
            .unwrap()
            .subscribe(onNext: { (cateLog) in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                let record = LocalBookLatestCateLog(cateLog)
                try? realm.write {
                    realm.add(record, update: .all)
                }
            })
            .disposed(by: bag)
        

        viewDidLoad
            .flatMap { _ in
                detailProvider
                    .rx
                    .request(.detail(readModel.bookID))
                    .model(BookDetailResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.data }
            .unwrap()
            .bind(to: bookDetail)
            .disposed(by: bag)
        
        
        let listenBookData =  navItemTouched.filter {$0 == 1}
            .filter { _ in
                if let net = NetworkReachabilityManager(), !net.isReachable {
                    HUD.flash(.label("网络已断开"), delay: 2)
                    return false
                }
                return true
            }
            .flatMap { _ in
                provider.rx.request(.listenBook)
                    .model(ListenBookServerResponse.self)
                    .asObservable()
                    .map {$0.data }
                    .catchError { _ in Observable.just(nil)}
            }
            .map { (data) -> Bool  in
                if let todayListenChapterCount = ListenBookAdModel.todayListenChapterCount(), todayListenChapterCount < 5  {
                    return true
                }
                if !me.isLogin {
                    return false
                }
                guard let cur_time = data?.cur_time,  let listen = data?.listen,  let ad = data?.ad
                    else {
                    return false
                }
                if ad.vip.rawValue == VIPType.none.rawValue {
                    if  (listen.ad_end_time ?? 0) > cur_time {
                        return true
                    } else {
                        return false
                    }
                } else {
                    if (ad.ad_end_time ?? 0) > cur_time {
                        return true
                    } else {
                        return false
                    }
                }
            }
        
        listenBookAlertViewModel = listenBookData.filter { $0 == false}
            .mapToVoid()
            .map{ _ in ListenBookAlertViewModel() }

        listenBookData.filter { $0 == true}
            .mapToVoid()
            .bind(to: listenBookOutput)
            .disposed(by: bag)
        
        navItemTouched
            .filter{ $0 == 0 }  // 返回按钮
            .asObservable()
            .withLatestFrom(bookDetail)
            .subscribe(onNext: { [weak self](bookDetail) in
                if let weakSelf = self, bookDetail.book_info == nil || (bookDetail.book_info?.join_bookcase ?? false) == true {
                    weakSelf.popController.onNext("")
                }
            })
            .disposed(by: bag)
        
        
        navItemTouched
            .filter{ $0 == 0 }  // 返回按钮
            .asObservable()
            .filter {_ in (bookDetail.value.book_info?.join_bookcase ?? true) == false}
            .flatMap { _ in
                DefaultWireframe.shared.promptFor(title: "是否加入书架", message: "", cancelAction: "取消", actions: ["加入"])
            }
            .flatMap({ (title) -> Observable<String> in
                if title == "加入" {
                    return detailProvider.rx
                        .request(BookInfoService.add(readModel.bookID, 0))
                        .model(NullResponse.self)
                        .asObservable()
                        .catchError {_ in Observable.never()}
                        .map { $0.status?.code }
                        .debug()
                        .map { $0 == 0 ? "加入书架成功": "加入书架失败"}
                }
                return Observable.just("")
            })
            .bind(to: popController)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Book.bookshelf)
            .subscribe(onNext: { (_) in
                bookDetail.value.book_info?.join_bookcase = true
            })
            .disposed(by: bag)
        
        popController.asObservable()
            .filter{ $0 == "加入书架成功"}
            .mapToVoid()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Book.bookshelf, object: true)
            })
            .disposed(by: bag)
    
        
          /// 本地化章节信息
        viewDidLoad.asObservable()
            .flatMap {
                provider.rx.request(.getAllChapter(["book_id": readModel.bookID]))
                    .model(AllChapterResponse.self)
                    .asObservable()
            }
            .map { $0.data }
            .unwrap()
            .filter { !$0.isEmpty }
            .mapMany { LocalReaderChapterInfo($0) }
            .map { $0.sorted(by: { (chapter0, chapter1) -> Bool in
                return chapter1.order > chapter0.order
                })}
            .bind(to: dbChapterInfo)
            .disposed(by: bag)
        
      
        
        dbChapterInfo.asObservable()
            .bind(to: allLocalChapterInfo)
            .disposed(by: bag)
    
        
        dbChapterInfo.asObservable()
            .filter { !$0.isEmpty }
            .subscribe(onNext: { (records) in
                let boookIds = records.map { $0.book_id }
                let preSesults = realm.objects(LocalReaderChapterInfo.self).filter(NSPredicate(format: "NOT book_id IN %@ ", boookIds))
                try? realm.write {
                    realm.delete(preSesults)
                }
                try? realm.write {
                    realm.add(records, update: .all)
                }
            })
            .disposed(by: bag)
        
        /// 无网络情况下从本地获取
        let manager = NetworkReachabilityManager()
        Observable.just(manager?.isReachable)
            .unwrap()
            .filter { $0 == false }
            .flatMap { _ in
                Observable.array(from: realm.objects(LocalReaderChapterInfo.self).filter(NSPredicate(format: "book_id = %@", readModel.bookID)).sorted(byKeyPath: "order", ascending: true))
            }
            .bind(to: allLocalChapterInfo)
            .disposed(by: bag)
        
      /// 拖动进度
        progressSliderValueInput.asObservable()
            .map { $0 }
            .debug()
            .map {(order) -> LocalReaderChapterInfo? in
                if let index =  allLocalChapterInfo.value.lastIndex(where: {$0.order == order}) {
                    return allLocalChapterInfo.value[index]
                } else if order == 0 { // 扉页,进度条的内容显示第一章
                    let info =  allLocalChapterInfo.value.first
                    return info
                }
                return nil
            }
            .debug()
            .unwrap()
            .bind(to: progressSliderValueOutput)
            .disposed(by: bag)
        
        /// 获取书签
        viewDidLoad.asObservable()
            .map {  readModel.readMarkModels }
            .bind(to: bookMarks)
            .disposed(by: bag)
        
        // 删除书签
        removeBookInput.asObservable()
            .debug()
            .map { $0 }
            .subscribe(onNext: { (_) in
                bookMarks.accept([])
                readModel.removeAllReadMark()
            })
            .disposed(by: bag)
        
        /// 添加书签
        addBookMarkInput.asObservable()
            .map { $0 }
            .subscribe(onNext: { (record) in
                readModel.addMark(readRecordModel: record)
                bookMarks.accept(readModel.readMarkModels)
            })
            .disposed(by: bag)
        
        loadAd(realm: realm)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate, object: nil)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.loadAd(realm: realm)
            })
            .disposed(by: bag)
        
        Observable.merge(viewWillDisappear.asObservable().mapToVoid(),
                         NotificationCenter.default.rx.notification(Notification.Name.Book.didLoadReaderLastPage).mapToVoid()
            )
            .mapToVoid()
            .subscribe(onNext: addReadRecord)
            .disposed(by: (UIApplication.shared.delegate as! AppDelegate).bag)
        
        Observable.merge(viewWillDisappear.asObservable().mapToVoid(),
                         NotificationCenter.default.rx.notification(Notification.Name.Book.didLoadReaderLastPage).mapToVoid()
            )
            .subscribe(onNext: reportReadingTime)
            .disposed(by: bag)
        
        
        Observable.merge(reloadAdConfigInput.asObservable(),
                          viewDidLoad.asObservable()
                    )
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                let config = AdvertiseService.advertiseConfig(AdPosition.readerBottomBanner)
                weakSelf.bannerConfigOutput.accept(config)
                debugPrint("bottomBanner -  weakSelf.bannerConfigOutput.accept(config)")
                weakSelf.clearErrorLog(config)
            })
            .disposed(by: bag)
        
    }
    
    
    func addReadRecord() {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let dzRecord = DZMReadRecordModel.readRecordModel(bookID: readModel.bookID)
        if let bookTitle = dzRecord.readChapterModel?.bookInfo?.book_title,
            let bookId =  dzRecord.readChapterModel?.bookInfo?.book_id,
            let cover_url = dzRecord.readChapterModel?.bookInfo?.cover_url {
            let recentlyRecord = ReadRecord()
            recentlyRecord.book_id = bookId
            recentlyRecord.book_name = bookTitle
            recentlyRecord.cover_url = cover_url
            recentlyRecord.create_time = Date().timeIntervalSince1970
            recentlyRecord.content_id = dzRecord.readChapterModel?.id ?? ""
            recentlyRecord.writing_process = Int(dzRecord.readChapterModel?.bookInfo?.writing_process ?? "-1") ?? -1
            try? realm.write {
                realm.add(recentlyRecord, update: .all)
            }
            NotificationCenter.default.post(name: NSNotification.Name.Book.existReader, object: recentlyRecord)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name.Book.existReader, object: nil)
        }
    }
    
    func reportReadingTime() {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        /// 上报阅读时长
        let reportProvider = MoyaProvider<StatisticService>()
        let reportReadingTime = Observable.just(0)
            .asObservable()
            .mapToVoid()
            .debug()
            .map { realm.objects(OneBookReadingTime.self).first }
            .unwrap()
            .map { Int(floor($0.readingDuration / 60.0))}
            .flatMap {
                reportProvider.rx.request(.readTime($0))
                    .model(NullResponse.self)
                    .asObservable()
        }
        
        reportReadingTime
            .map { $0.status }
            .unwrap()
            .map { $0.code }
            .filter { $0 == 0}
            .subscribe(onNext: { (_) in
                /// 上报成功，本地清0
                let record = OneBookReadingTime()
                try? realm.write {
                    realm.add(record, update: .all)
                }
            })
            .disposed(by:  (UIApplication.shared.delegate as! AppDelegate).bag)
    }
    
    
    fileprivate func loadAd(realm: Realm) {
        /// 没有记录 -- 弹框
        noAdBtnInput.asObservable()
            .map { ReaderFiveChapterNoAd.isShowAlert() }
            .filter { $0 == true }
            .debug()
            .map { _ in ChargeAlertViewModel()}
            .bind(to: chargeAlertOutput)
            .disposed(by: bag)
        
        /// 有记录在当天 -- 跳充值页
        noAdBtnInput.asObservable()
            .map { ReaderFiveChapterNoAd.isShowAlert() }
            .filter { $0 == false }
            .map {_ in ChargeViewModel() }
            .debug()
            .bind(to: chargeOutput)
            .disposed(by: bag)
        
        let bannerOutput = self.bannerOutput
        let readerBottomAdConfig = AdvertiseService.advertiseConfig(AdPosition.readerBottomBanner)
        let readerMode = self.readerMode
        bannerConfigOutput.accept(readerBottomAdConfig)
        bannerConfigOutput.asObservable()
            .debug()
            .unwrap()
            .withLatestFrom(readerMode.asObservable(), resultSelector: { ($0, $1)})
//            .filter { $0.1.rawValue == ReaderMode.advertise.rawValue }
            .debug()
            .filter { !$0.0.is_close}
            .debug()
            .filter { $0.0.ad_type == AdvertiseType.inmobi.rawValue }
            .debug()
            .map { $0.0 }
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                debugPrint("bottomBanner - IMBannerViewModel")
                let imBannerViewModel = IMBannerViewModel(config, isAutoRefresh: true)
                imBannerViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .inmobi($0))}
                    .bind(to: bannerOutput)
                    .disposed(by: weakSelf.bag)
                weakSelf.bannerViewModel = imBannerViewModel
            })
            .disposed(by: bag)
        
        /// 监听banner广告循环加载
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.bannerNeedRefresh)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerBottomBanner.rawValue }
            .filter { _ in  readerMode.value.rawValue == ReaderMode.advertise.rawValue  }
            .mapToVoid()
            .debug()
            .map { AdvertiseService.advertiseConfig(AdPosition.readerBottomBanner)}
            .debug()
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)
        
        /// 非每5章节底部广告
        let bannerConfigOutput = self.bannerConfigOutput
        currentReadChapterCount.asObservable()
            .debug()
            .filter {_ in readerBottomAdConfig?.is_close == false}
            .filter { $0 != 0 }
            .filter { $0 % 5 != 0 }
            .filter { _ in  readerMode.value.rawValue == ReaderMode.advertise.rawValue  }
            .map { _ in AdvertiseService.advertiseConfig(AdPosition.readerBottomBanner) }
            .unwrap()
            .filter({ (config) -> Bool in
                guard let currentConfig = try? bannerOutput.value() else {
                    return false
                }
                return config.ad_position != currentConfig?.localConfig.ad_position
            })
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)

        /// 每5章节低部广告要切换
        let readerPer5BottomAdConfig = AdvertiseService.advertiseConfig(AdPosition.readerPer5PgeBottomBanner)
        currentReadChapterCount.asObservable()
            .filter {_ in readerPer5BottomAdConfig?.is_close == false }
            .filter { $0 != 0 }
            .filter { $0 % 5 == 0 }
            .debug()
            .map { _ in AdvertiseService.advertiseConfig(AdPosition.readerPer5PgeBottomBanner) }
            .unwrap()
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)
        
        /// banner 广告加载（首选position_id）失败， 加载second_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerBottomBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)
        
        /// banner 广告加载（second_postion_id）失败, 加载third_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerBottomBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)
        
        viewDidLoad.asObservable()
            .subscribe(onNext: {
                let record = FullScreenBookReadingTime()
                try? realm.write {
                    realm.add(record, update: .all)
                }
            })
            .disposed(by: bag)

        /// 一定时间内，非强制，全屏广告(需要验证是否有效阅读时长)
        let minutes = CommomData.share.switcherConfig.value?.ad_minute ?? 0
         viewDidLoad
            .map { _ in CommomData.share.switcherConfig.value }
            .unwrap()
            .filter {_ in (AdvertiseService.advertiseConfig(AdPosition.readerFullScreenVideo)?.is_close ?? true) == false}
            .filter { $0.ad_type.rawValue == SwitcherAdType.unforceVideo.rawValue }
            .mapToVoid()
            .flatMap {
                Observable<Int>.interval(RxTimeInterval.seconds(10), scheduler: MainScheduler.instance)
            }
            .skip(1)
            .debug()
            .subscribeOn(MainScheduler.instance)
            .filter {_ in UIViewController.current() is ReaderController}
            .filter({ _ -> Bool in
                guard let time = realm.objects(FullScreenBookReadingTime.self).first else {
                    return false
                }
               return Int(time.readingDuration) > minutes * 60
            })
            .flatMap { _ in
                ReaderRestWireFrame.shared.promptFor(title: nil, message: "阅读时长已经超过了\(minutes)分钟，是否要休息一下", cancelAction: "继续阅读", actions: ["好的"])
            }
            .filter { $0 == NSLocalizedString("好的", comment: "")}
            .map {_ in AdPosition.readerFullScreenVideo}
            .bind(to: fullscreenAdOutput)
            .disposed(by: bag)
        
        
        /// 一定时间内，强制，全屏广告(需要验证是否有效阅读时长)
        viewDidLoad
            .map { _ in CommomData.share.switcherConfig.value }
            .unwrap()
            .debug()
            .filter {_ in (AdvertiseService.advertiseConfig(AdPosition.readerFullScreenVideo)?.is_close ?? true) == false}
            .filter { $0.ad_type.rawValue == SwitcherAdType.forceVideo.rawValue }
            .mapToVoid()
            .flatMap {
                Observable<Int>.interval(RxTimeInterval.seconds(10), scheduler: MainScheduler.instance)
            }
            .debug()
            .skip(1)
            .filter({ endTime -> Bool in
                guard let time = realm.objects(FullScreenBookReadingTime.self).first else {
                    return false
                }
                return Int(time.readingDuration) > minutes * 60
            })
            .observeOn(MainScheduler.instance)
            .filter {_ in UIViewController.current() is ReaderController}
            .flatMap { _ in
                ReaderRestWireFrame.shared.promptAlert(title: "", message: "阅读时长已经超过了\(minutes)分钟，是否要休息一下")
            }
            .filter { $0 == NSLocalizedString("好的", comment: "")}
            .map {_ in AdPosition.readerFullScreenVideo}
            .debug()
            .bind(to: fullscreenAdOutput)
            .disposed(by: bag)
        

        /// 看了激励视频，免5章节广告
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerRewardVideoAd.rawValue }
            .asObservable()
            .mapToVoid()
            .subscribe(onNext: ReaderFiveChapterNoAd.addShowAlertCount)
            .disposed(by: bag)
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerRewardVideoAd.rawValue }
            .map { _ in ReaderMode.noAdvertise}
            .bind(to: readerMode)
            .disposed(by: bag)
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.show)
            .map { _ in ReaderMode.advertise}
            .bind(to: readerMode)
            .disposed(by: bag)
        
        ///  上报看了激励视频，免5章节广告
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .mapToVoid()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.readerFiveChapterNoAd, object: nil)
            })
            .disposed(by: bag)
        
        /// 检查是否看了激励视频广告，如果看了，则退出阅读器 更新记录，下次进入阅读器会继续出现广告
        popController
            .asObservable()
            .mapToVoid()
            .filter { ReaderFiveChapterNoAd.isReadFiveAd()}
            .mapToVoid()
            .subscribe(onNext: ReaderFiveChapterNoAd.deleteRecord)
            .disposed(by: bag)
        
        /// 游客听书资格清空
        Observable.merge(popController.asObservable().mapToVoid(),
                         viewDidLoad.asObservable(),
                         NotificationCenter.default.rx.notification(Notification.Name.Book.didLoadReaderLastPage).mapToVoid()
            )
            .asObservable()
            .map { _ in 1000 }
            .subscribe(onNext: ListenBookAdModel.addListenChapterCount)
            .disposed(by: bag)

        /// 看了听书的激励视频广告
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerViedeoAdListenBook.rawValue }
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.listenBookOutput.onNext(())
            })
            .disposed(by: bag)
        
        /// 看了听书的激励视频广告
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerViedeoAdListenBook.rawValue }
            .map { _ in 1 }
            .subscribe(onNext:  ListenBookAdModel.addWatchNum)
            .disposed(by: bag)
        
        viewDidLoad.asObserver()
            .subscribe(onNext: clearFlag)
            .disposed(by: bag)
        
    }
    
    
    func clearFlag() {
    }
    deinit {
        debugPrint("ReaderViewModel deinit!!!")
    }
}



enum ReaderMode: Int {
    case noAdvertise = 1
    case advertise = 0
}
