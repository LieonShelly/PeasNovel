//
//  BookShelfViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import Moya
import RxMoya
import Alamofire

class BookShelfViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewDidAppear: PublishSubject<Bool> = .init()
    let viewDidDisappear: PublishSubject<Bool> = .init()
    let recentlyBook: PublishSubject<Void> = .init()
    let recentlyMore: PublishSubject<Void> = .init()
    let searchAction: PublishSubject<Void> = .init()
    let msgAction: PublishSubject<Void> = .init()
    let adAction: PublishSubject<Void> = .init()    // 免广告
    let itemSelected: PublishSubject<BookInfo> = .init()
    let longPressAction: PublishSubject<IndexPath> = .init()
    let sectionMore: PublishSubject<String> = .init()
    let headerRefresh: PublishSubject<Void> = .init()
    let footerRefresh: PublishSubject<Void> = .init()
    var infoAdViewModels: [String: Advertiseable] = [:]
    let exceptionInput: PublishSubject<Void> = .init()
    let recommendSelected: PublishSubject<BookInfo> = .init()
    let bookColllectionSelected: PublishSubject<BookInfo> = .init()
    
    /// output
    let itemOutput: Observable<BookInfo>    // cell点击输出
    let recentBookOutput: Observable<BookInfo>
    let sectionAction: Observable<Int>
    let endRefresh: Driver<Void>            // 下拉刷新结束
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let activityOutput: Driver<Bool>
    let errorOutput: Driver<HUDValue>
    let items: Driver<[SectionModel<String, Any>]>
    let recently: BehaviorRelay<BookInfo?> = .init(value: nil)
    let recommend: BehaviorRelay<[BookInfo]> = .init(value: [])
    let searchViewModel: Observable<SearchViewModel>
    let handlerViewModel: Observable<BookshelfHandlerViewModel>
    let sheetViewModel: Observable<BookSheetViewModel>
    let sogouViewModel: Observable<SogouWebViewModel>
    let chargeViewModel: Observable<ChargeViewModel>
    let msgOutput: Observable<MessageViewModel>
    let recentlyViewModel: Observable<RecentlyViewModel>
    var topBannerVM: Advertiseable?
    let bag = DisposeBag()
    let topBannerConfigOuput = BehaviorSubject<LocalTempAdConfig?>.init(value: nil)
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let messageCount: BehaviorRelay<Int> = .init(value: 0)
    let bannerOutput = BehaviorRelay<LocalAdvertise?>(value: nil)
    
    init(_ provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        let activity = ActivityIndicator()
        let errorActivity = ErrorTracker()
        activityOutput = activity.asDriver()
        errorOutput = errorActivity.asDriver()
        let metaData: BehaviorRelay<[ SectionModel<String, Any>]> = BehaviorRelay(value: [])
        let datas: BehaviorRelay<[ SectionModel<String, Any>]> = BehaviorRelay(value: [])
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let historyRecommends = BehaviorRelay<[BookInfo]>(value: [])
        let pageVariable = BehaviorRelay<(Int, Int)>(value: (1,1))  // curr_page, total_page

    
        viewDidLoad.asObservable()
            .map { realm.objects(GEPushMessage.self).filter(NSPredicate(format: "status = %ld", MessageStatus.unread.rawValue))}
            .map {$0.count}
            .bind(to: messageCount)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Message.didUpdate)
            .map { _ in realm.objects(GEPushMessage.self).filter(NSPredicate(format: "status = %ld", MessageStatus.unread.rawValue))}
            .map {$0.count}
            .bind(to: messageCount)
            .disposed(by: bag)
        
        
        let bookshelfUpdate = NotificationCenter
            .default
            .rx
            .notification(Notification.Name.Book.bookshelf, object: nil)
            .mapToVoid()
        
        /// 刷新更新用户信息 - 获取阅读时间
        headerRefresh.asObservable()
            .subscribe(onNext: { (_) in
                /// 通知更新,重新获取阅读时长
                NotificationCenter.default.post(name: Notification.Name.UIUpdate.readingTime, object: nil)
            })
            .disposed(by: bag)
        
        /// 好书推荐
        let metaRecommend: BehaviorRelay<[BookInfo]> = BehaviorRelay(value: [])
        let recommendWithAd: BehaviorRelay<[BookInfo]> = BehaviorRelay(value: [])
        let goodBookPageInput: BehaviorRelay<Int> = .init(value: 1)
        Observable
            .merge(viewDidLoad,
                   headerRefresh,
                   goodBookPageInput.asObservable().filter { $0 != 1}.mapToVoid())
            .map { goodBookPageInput.value }
            .flatMap{
                provider
                    .rx
                    .request(.goodBookRecommend(["page": "\($0)"]))
                    .model(BookshelfListResponse.self)
                    .trackActivity(activity)
                    .trackError(errorActivity)
                    .catchError{_ in Observable.never() }
            }
            .map { $0.data }
            .unwrap()
            .debug()
            .bind(to: metaRecommend)
            .disposed(by: bag)
        
        /// 最近阅读
        let serverRecentReadbookRes = Observable
            .merge(viewDidLoad, headerRefresh)
            .flatMap{
                provider
                    .rx
                    .request(.recentRead)
                    .model(BookshelfInfoResponse.self)
                    .trackActivity(activity)
                    .trackError(errorActivity)
                    .catchError{_ in Observable.never() }
            }
        
        /// 收藏列表
        let favorBookRes = Observable
            .merge(viewDidLoad, bookshelfUpdate, headerRefresh, NotificationCenter.default.rx.notification(Notification.Name.Book.addbookshelf).mapToVoid())
            .flatMap{
                provider
                    .rx
                    .request(.bookshelf(page: 1))
                    .model(BookshelfListResponse.self)
                    .trackActivity(activity)
                    .catchError{_ in Observable.never() }
            }
        
        /// 往期推荐
        let hisRes =
        Observable
            .merge(viewDidLoad, headerRefresh)
            .flatMap{
                provider
                    .rx
                    .request(.historyRecommend(["page": "1"]))
                    .model(BookshelfListResponse.self)
                    .trackActivity(activity)
                    .trackError(errorActivity)
                    .catchError{_ in Observable.never() }
            }
        
        hisRes.subscribe(onNext: { (res) in
            debugPrint("historyRecommend: \(res.total_page) - \(res.cur_page)")
        })
        .disposed(by: bag)
        
        hisRes
            .map { $0.data }
            .unwrap()
            .debug()
            .bind(to: historyRecommends)
            .disposed(by: bag)
        
        endRefresh = hisRes
            .mapToVoid()
            .asDriver(onErrorJustReturn: ())
        
        /// 更多数据刷新结果
        let moreDatRefresh = footerRefresh
            .withLatestFrom(pageVariable.asObservable())
            .debug()
            .map{ ($0.0 < $0.1) ? $0.0+1 : 1 }
            .flatMap{
                provider
                    .rx
                    .request(.historyRecommend(["page": "\($0)"]))
                    .model(BookshelfListResponse.self)
            }
            .share(replay: 1)
        
       
        moreDatRefresh
            .map{ $0.data ?? [] }
            .withLatestFrom(historyRecommends.asObservable(), resultSelector: { $1 + $0 })
            .bind(to: historyRecommends)
            .disposed(by: bag)
        
        Observable
            .merge(moreDatRefresh, hisRes)
            .map{ ($0.cur_page, $0.total_page) }
            .bind(to: pageVariable)
            .disposed(by: bag)
        
        endMoreDaraRefresh = Observable
            .merge(moreDatRefresh, hisRes)
            .map{ $0.cur_page < $0.total_page }
            .debug()
            .asDriver(onErrorJustReturn: false)
        
        recentBookOutput = recentlyBook
            .withLatestFrom(recently)
            .unwrap()
       
        // 阅读器、详情页
        itemOutput = Observable.merge(itemSelected.asObservable(), bookColllectionSelected.asObservable(), recommendSelected.asObservable())
            .filter { !$0.book_id.isEmpty }
            .filter{ $0.book_type == 0 }    // 书籍type
        
        sheetViewModel = bookColllectionSelected
            .filter{ $0.book_type == 2 }    // 书单type
            .debug()
            .map{  BookSheetModel.deserialize(from: $0.toJSONString()) }
            .unwrap()
            .debug()
            .map{ BookSheetViewModel($0) }
        
        sogouViewModel = bookColllectionSelected
            .filter{ $0.book_type == 3 }    // 网页类型
            .map{ SogouWebViewModel(URL(string: $0.link ?? ""), title: $0.book_title ?? "")}
 
        
        /// 书架收藏，好书推荐点击
         Observable.merge(bookColllectionSelected.asObservable(), recommendSelected.asObservable())
            .debug()
            .subscribe(onNext: {
                BookInfo.didSelected(for: $0.book_id, date: $0.last_chapter_time)
            })
            .disposed(by: bag)
        
        recentlyViewModel = recentlyMore
            .map{_ in RecentlyViewModel() }
        
//         最近阅读数据
        serverRecentReadbookRes.asObservable()
            .filter {_ in realm.objects(ReadRecord.self).filter(NSPredicate(format: " book_id != %@ AND book_name != %@", "", "")).sorted(byKeyPath: "create_time", ascending: true).last == nil}
            .map { $0.data }
            .map{ $0?.zuijin_yuedu?.first }
            .bind(to: recently)
            .disposed(by: bag)
       
        let localRecord =  Observable
            .merge(viewWillAppear.mapToVoid(),
                   headerRefresh.mapToVoid(),
                   NotificationCenter.default.rx.notification(Notification.Name.Book.existReader).mapToVoid())
            .flatMap {
                Observable.array(from: realm.objects(ReadRecord.self).filter(NSPredicate(format: " book_id != %@ AND book_name != %@", "", "")).sorted(byKeyPath: "create_time", ascending: true))
            }
            .map { $0.last }
            .map { record -> BookInfo? in
                if let record = record, !record.book_id.isEmpty {
                    let bookInfo = BookInfo(record)
                    return bookInfo
                }
                return nil
            }
        
       localRecord
            .filter { $0 != nil}
            .bind(to: recently)
            .disposed(by: bag)
        
        localRecord
            .filter { $0 == nil }
            .unwrap()
            .mapToVoid()
            .flatMap { _ in
                provider
                    .rx
                    .request(.recentRead)
                    .model(BookshelfInfoResponse.self)
                    .asObservable()
                    .catchError{_ in Observable.never() }
            }
            .map {$0.data}
            .map { $0?.zuijin_yuedu?.first}
            .bind(to: recently)
            .disposed(by: bag)
        
        metaRecommend.asObservable()
            .filter { !$0.isEmpty }
            .bind(to: recommend)
            .disposed(by: bag)
        
        recommendWithAd.asObservable()
            .filter { !$0.isEmpty }
            .bind(to: recommend)
            .disposed(by: bag)
        
        // 更多
        sectionAction = sectionMore
            .debug()
            .filter{ $0 == "书架收藏" }
            .debug()
            .map{_ in 0 }
        
        //  好书推荐换一换
        sectionMore.filter { $0 == "好书推荐"}
            .map { _ in goodBookPageInput.value + 1}
            .debug()
            .bind(to: goodBookPageInput)
            .disposed(by: bag)
        
        // 搜索
        searchViewModel = searchAction
            .map{ SearchViewModel() }
        
        handlerViewModel = longPressAction
            .mapToVoid()
            .withLatestFrom(favorBookRes.asObservable().map { $0.data }.unwrap().asObservable())
            .map{ BookshelfHandlerViewModel($0) }
        
        chargeViewModel = adAction
            .map{ ChargeViewModel() }
       
        msgOutput = msgAction
            .map {MessageViewModel()}

        Observable
            .combineLatest(favorBookRes.asObservable().map { $0.data }.unwrap().map { Array($0[0 ..< ($0.count >= 8 ? 8: $0.count )])},
                           recommend.asObservable().filter { !$0.isEmpty }.debug(),
                           historyRecommends.asObservable().debug())
            .map{
                [
                    SectionModel<String, Any>(model: "书架收藏", items: $0.0.count > 0 ? [$0.0]: []),
                    SectionModel<String, Any>(model: "好书推荐", items: $0.1.count > 0 ? [$0.1]: []),
                    SectionModel<String, Any>(model: "往期推荐", items: $0.2),
                ]
            }
            .debug()
            .bind(to: metaData)
            .disposed(by: bag)
        
        viewWillAppear
            .mapToVoid()
            .withLatestFrom(metaData.asObservable())
            .bind(to: datas)
            .disposed(by: bag)
        
        metaData
            .asObservable()
            .bind(to: datas)
            .disposed(by: bag)
        
        items = datas
            .asObservable()
            .asDriverOnErrorJustComplete()

        
        exceptionOuptputDriver = datas.asObservable()
            .skip(1)
            .map { $0.count }
            .map {  ExceptionInfo.commonRetry($0) }
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
     /// 有用户ID直接加载书架
        exceptionInput.asObservable()
            .filter {_ in me.user_id != nil }
            .filter {_ in (me.user_id?.isEmpty ?? true) == false}
            .subscribe(onNext: { [weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.headerRefresh.onNext(())
//                weakSelf.loadAd(metaData, datas, metaRecommend: metaRecommend)
                 NotificationCenter.default.post(name: NSNotification.Name.Advertise.configNeedUpdate, object: nil)
            })
            .disposed(by: bag)
        
        /// 无用户ID
        exceptionInput.asObservable()
            .filter {_ in me.user_id == nil }
            .filter {_ in (me.user_id?.isEmpty ?? true) == true}
            .subscribe(onNext: { (_) in
               NotificationCenter.default.post(name: NSNotification.Name.Account.deviceLogin, object: nil)
            })
            .disposed(by: bag)
        
        let userProvider = MoyaProvider<UserCenterService>()
        headerRefresh.asObservable()
            .flatMap { _ in
                userProvider
                    .rx
                    .request(.userInfo)
            }
            .userUpdate()
            .disposed(by: bag)
        
        /// 上报
        report()
        /// 广告
        loadAd(metaData, datas, metaRecommend: metaRecommend)
        
        
    }
    
    
    fileprivate func loadAd(_ metaData: BehaviorRelay<[SectionModel<String, Any>]>,
                                  _ finalDatas: BehaviorRelay<[ SectionModel<String, Any>]>,
                                  metaRecommend: BehaviorRelay<[BookInfo]> ) {

        let topBannerConfigOuput = self.topBannerConfigOuput
        
    
         Observable.merge(viewDidLoad.asObservable(), headerRefresh.asObservable(), NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate).mapToVoid())
            .filter {_ in AdvertiseService.advertiseConfig(.bookShelfTop) != nil }
            .map { AdvertiseService.advertiseConfig(.bookShelfTop) }
            .filter { $0?.is_close == false}
            .unwrap()
            .debug()
            .bind(to: bannerOutput)
            .disposed(by: bag)
        
        /// banner 加载广告
        bannerOutput
            .asObservable()
            .unwrap()
             .observeOn(MainScheduler.instance)
            .filter { $0.ad_type == AdvertiseType.inmobi.rawValue}
            .subscribe(onNext: { [weak self] topbannerConfig in
                guard let weakSelf = self else {
                    return
                }
                let topInmobiViewModel = IMBannerViewModel(topbannerConfig)
                topInmobiViewModel.nativeAdOutput
                    .asObservable()
                    .subscribe(onNext: { (nativeAd) in
                        let temConfig = LocalTempAdConfig(topbannerConfig, adType: LocalAdvertiseType.inmobi(nativeAd))
                        topBannerConfigOuput.onNext(temConfig)
                    }, onError: { (error) in
                        do {
                            let current = try topBannerConfigOuput.value()
                            if current  == nil {
                                topBannerConfigOuput.onError(error)
                            }
                        } catch {
                            topBannerConfigOuput.onError(error)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                weakSelf.topBannerVM = topInmobiViewModel
            })
            .disposed(by: bag)
        
        /// banner 广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.bookShelfTop.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: bannerOutput)
            .disposed(by: bag)

        let sj1ImNative: BehaviorRelay<LocalTempAdConfig> = BehaviorRelay(value: LocalTempAdConfig())
        let sj2ImNative: BehaviorRelay<LocalTempAdConfig> = BehaviorRelay(value: LocalTempAdConfig())
      
        let adUIConfig = BookSlefAdConfig()

        metaRecommend.asObservable()
            .debug()
            .filter { !$0.isEmpty }
            .mapToVoid()
            .flatMap({  [weak self] _ -> Observable<LocalTempAdConfig> in
                guard let recommendAdConfig1 = AdvertiseService.advertiseConfig(.bookShelfEditBookSJ_1), !recommendAdConfig1.is_close else {
                    return Observable.just(LocalTempAdConfig())
                }
                return  AdvertiseService.createInfoStreamAdOutput(recommendAdConfig1, adUIConfigure: adUIConfig, configure: { (viewModel) in
                    self?.infoAdViewModels[recommendAdConfig1.ad_position_id] = viewModel
                }).catchError {_ in Observable.never()}
            })
            .bind(to: sj1ImNative)
            .disposed(by: bag)
        
        
        metaRecommend.asObservable()
            .filter { !$0.isEmpty }
            .flatMap ({ [weak self] _  -> Observable<LocalTempAdConfig> in
                guard let recommendAdConfig2 = AdvertiseService.advertiseConfig(.bookShelfEditBookSJ_2), !recommendAdConfig2.is_close else {
                    return Observable.just(LocalTempAdConfig())
                }
                return  AdvertiseService.createInfoStreamAdOutput(recommendAdConfig2, adUIConfigure: adUIConfig, configure: { (viewModel) in
                    self?.infoAdViewModels[recommendAdConfig2.ad_position_id] = viewModel
                }).catchError {_ in Observable.never()}
            })
             .observeOn(MainScheduler.instance)
            .bind(to: sj2ImNative)
            .disposed(by: bag)
        
        Observable.zip([sj1ImNative.asObservable(), sj2ImNative.asObservable()])
            .withLatestFrom(metaRecommend.asObservable()) { (ads, books) -> [BookInfo] in
                let imAdConfig1 = ads.first
                let imAdConfig2 = ads.last
                let book1 = BookInfo()
                book1.localTempAdConfig = imAdConfig1
                
                let book2 = BookInfo()
                book2.localTempAdConfig = imAdConfig2
                
                var newBooks = books
                if newBooks.count > 4 && !(book1.localTempAdConfig?.localConfig.ad_position_id.isEmpty ?? false) {
                    newBooks.insert(book1, at: 4)
                }
                if !(book2.localTempAdConfig?.localConfig.ad_position_id.isEmpty ?? false) {
                    if newBooks.count > 7 {
                        newBooks.insert(book2, at: 7)
                    } else {
                        newBooks.append(book2)
                    }
                }
               
                return newBooks
            }
        .bind(to: recommend)
        .disposed(by: bag)
        
    
        
        /// 信息流广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.bookShelfEditBookSJ_1.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .flatMap { [weak self] config in
              return  AdvertiseService.createInfoStreamAdOutput(config, adUIConfigure: adUIConfig, configure: { (viewModel) in
                    self?.infoAdViewModels[config.ad_position_id] = viewModel
                }).catchError {_ in Observable.never()}
            }
            .bind(to: sj1ImNative)
            .disposed(by:bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.bookShelfEditBookSJ_2.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .flatMap { [weak self] config in
                return  AdvertiseService.createInfoStreamAdOutput(config, adUIConfigure: adUIConfig, configure: { (viewModel) in
                    self?.infoAdViewModels[config.ad_position_id] = viewModel
                }).catchError {_ in Observable.never()}
            }
            .bind(to: sj2ImNative)
            .disposed(by:bag)
    }
    
    fileprivate func report() {
        viewDidAppear
            .asObservable()
            .map {_ in "YM_POSITION1_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.pageExposure, object: $0)
            })
            .disposed(by: bag)
        
        adAction.asObservable()
            .map {"MIANGUANGGAO_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: $0)
            })
            .disposed(by: bag)
        
        searchAction.asObservable()
            .map {"SJSS_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: $0)
            })
            .disposed(by: bag)
        
        msgAction.asObservable()
            .map {"SJMESSAGE_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: $0)
            })
            .disposed(by: bag)
        
        recentlyBook.asObservable()
            .map {"SJMOREZJYD_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: $0)
            })
            .disposed(by: bag)
        
        recentlyMore.asObservable()
            .map {"SJZJYD_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: $0)
            })
            .disposed(by: bag)
    }
    
}

struct BookSlefAdConfig: AdvertiseUIInterface {
    
    func infoAdSize(_ type: AdvertiseType?) -> CGSize {
        guard let type = type else {
            return .zero
        }
        switch type {
        case .inmobi:
            return ContainerCollectionViewCell.UISize.adSize
        case .GDT:
            return ContainerCollectionViewCell.UISize.adSize
        case .todayHeadeline:
            return ContainerCollectionViewCell.UISize.adSize
        default:
            return .zero
        }
    }
}

