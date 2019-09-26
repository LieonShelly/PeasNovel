//
//  SearchViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxMoya
import Moya
import RxDataSources
import RxCocoa
import RxRealm
import RealmSwift
import TagListView

class SearchViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let historyClearAction: PublishSubject<Void> = .init()  // 清除历史记录
    
    let inputText: PublishSubject<String> = .init()
    let searchAction: PublishSubject<String?> = .init()
    let textFieldActive: PublishSubject<Void> = .init()
    let firstItemAction: PublishSubject<Int> = .init()
    let netSearchAction: PublishSubject<Int> = .init()
    let sogouSearchAction:  PublishSubject<Void> = .init()
    let hotItemSelected: PublishSubject<SearchHotModel> = .init()
    let itemDidSelected: PublishSubject<Any> = .init()
    var bannerViewModel: Advertiseable?
    let footerRefresh: PublishSubject<Void> = .init()
    let fuzzyInput: PublishSubject<String> = .init()
    
    /// output
    let searchText: Driver<String>
    let itemOutput: Observable<BookInfo>    // cell点击输出
    let sections: Driver<[SectionModel<String?, Any>]>
    let endMoreDaraRefresh: Driver<Bool>    // 上拉加载结束
    let defaultKeyword: Observable<String>
    let catalogViewModel: Observable<BookCatalogViewModel>
    let webViewModel: Observable<WebViewModel>
    let sogouViewModel: Observable<SogouWebViewModel>
    let bannerOutput = PublishSubject<LocalTempAdConfig>.init()
    var bannerConfigoutput: BehaviorRelay<LocalAdvertise?> = BehaviorRelay(value: nil)
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let tipHud: Driver<HUDValue>
    let fuzzyResults = BehaviorRelay<[BookInfo]>(value: [])
    
    let bag = DisposeBag()
    
    init(_ provider: MoyaProvider<SearchService> = MoyaProvider<SearchService>(),
         bookInfoProvider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let sectionsData: BehaviorRelay<[SectionModel<String?, Any>]> = BehaviorRelay(value: [])
        activityDriver = activityIndicator.asDriver()
        errorDriver = errorTracker.asDriver()
        
        let pageVariable = BehaviorRelay<(Int, Int)>(value: (1,1))  // curr_page, total_page
        let dataVariable = BehaviorRelay<[BookInfo]>(value: [])
        let fuzzyRes = PublishSubject<SearchResponse>.init()
        
        endMoreDaraRefresh = pageVariable
            .asObservable()
            .map{ $0.0 < $0.1 }
            .asDriver(onErrorJustReturn: false)
        ////////////
        let realm = try! Realm()
        let keywords = realm
            .objects(SearchKeyModel.self)
            .sorted(byKeyPath: "date", ascending:false)
        
        let searchHotRequest = viewDidLoad
            .flatMap{
                provider
                    .rx
                    .request(.searchHot)
                    .model(SearchHotResponse.self)
                    .trackError(errorTracker)
                    .catchError {_ in Observable.never()}
            }
            .asObservable()
            .map{ $0.data?.first }
            .unwrap()
            .share(replay: 1)
            .startWith(SearchHotData())
        
        defaultKeyword = searchHotRequest
            .map{ $0.list?.first?.title }
            .unwrap()
            .startWith("")
        
        let searchKeywords = Observable // searchAction
            .merge(
                hotItemSelected.map{ $0.title },
                searchAction
            )
            .map{ ($0 ?? "").trimmingCharacters(in: .whitespaces) }
            .withLatestFrom(defaultKeyword, resultSelector: { ($0, $1) })
            .map{ ($0.0.length > 0) ? $0.0: $0.1 }
            .share(replay: 1)
        
        /// 获取了结果，清空模糊搜索结果
        dataVariable.asObservable()
            .map {_ in [] }
            .bind(to: fuzzyResults)
            .disposed(by: bag)
    
        
//        /// 手动关键字
        fuzzyInput
            .asObservable()
            .filter { !$0.isEmpty }
            .flatMap{
                provider
                    .rx
                    .request(.search($0, 1))
                    .model(SearchResponse.self)
                    .asObservable()
                    .catchError {Observable.just(SearchResponse.commonError($0))}
            }
            .bind(to: fuzzyRes)
            .disposed(by: bag)
        
        fuzzyRes.asObservable()
            .map { $0.data }
            .unwrap()
            .bind(to: fuzzyResults)
            .disposed(by: bag)
        
        let moreDataRefresh = footerRefresh
            .withLatestFrom(pageVariable.asObservable())
            .map{ ($0.0 < $0.1) ? $0.0+1 : 1 }
            .withLatestFrom(searchKeywords, resultSelector: { ($1, $0) })
            .flatMap{
                provider
                    .rx
                    .request(.search($0.0, $0.1))
                    .model(SearchResponse.self)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .catchError {_ in Observable.never()}
            }
            .share(replay: 1)
        /// 更多数据刷新结果
        moreDataRefresh
            .map{ $0.data }
            .unwrap()
            .withLatestFrom(dataVariable.asObservable(), resultSelector: { $1 + $0 })
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        let defaultRequest = searchKeywords
            .flatMap{
                provider
                    .rx
                    .request(.search($0, 1))
                    .model(SearchResponse.self)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .catchError {_ in Observable.never()}
            }
            .share(replay: 1)
        
        defaultRequest
            .map{ $0.data ?? [] }
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        Observable
            .merge(defaultRequest, moreDataRefresh)
            .map{ ($0.cur_page, $0.total_page) }
            .bind(to: pageVariable)
            .disposed(by: bag)
        
        let historyResult = Observable
            .array(from: keywords)
        // 空白页面，搜索热词和历史搜索
        let searchHotResult = Observable
            .combineLatest(searchHotRequest, historyResult)
            .map{ result -> [SectionModel<String?, Any>] in
                var sections = [SectionModel<String?, Any>(model: result.0.name, items: [result.0.list ?? []])]
                if result.1.count > 0 {
                    sections.append(SectionModel<String?, Any>(model: "历史搜索", items: [result.1]))
                }
                return sections
        }
        historyClearAction
            .map{ keywords }
            .subscribe(realm.rx.delete())
            .disposed(by: bag)
        
        // 输入框激活，变回搜索热词和历史搜索 searchHotResult
        let beginAction = textFieldActive
            .withLatestFrom(searchHotResult)
        
        let webSwitchResult = viewDidLoad
            .flatMap{
                provider
                    .rx
                    .request(.searchWebSwitch)
                    .model(SearchWebSwitchResponse.self)
                    .trackError(errorTracker)
                    .catchError {_ in Observable.never()}
            }
            .asObservable()
            .map{ $0.data }
            .unwrap()
            .debug()
//            .map{ $0 == 2 }
            .share(replay: 1)
        
        let noResultRecommend = viewDidLoad
            .flatMap {
                provider.rx.request(.searchRecommend)
                    .model(SearchResponse.self)
                    .asObservable()
            }
            .map { $0.data }
            .unwrap()
            .debug()
        
        let searchResult = dataVariable
            .asObservable()
            .withLatestFrom(webSwitchResult, resultSelector: { ($0, $1) })
            .withLatestFrom(noResultRecommend, resultSelector: { ($0, $1)})
            .map{ (switchAndRecommend, list) -> [SectionModel<String?, Any>] in
                if switchAndRecommend.1.search == 2 {
                    var tmp = switchAndRecommend.0
                    let webSection = SectionModel<String?, Any>(model: "网页搜索", items: [switchAndRecommend.1])
                    let recommendSection = SectionModel<String?, Any>(model: "猜你喜欢", items: list)
                    if let retModel = tmp.first {
                        let retSection = SectionModel<String?, Any>(model: nil, items: [retModel])
                        tmp.removeFirst()
                        let moreSection = SectionModel<String?, Any>(model: nil, items: tmp)
                        return [retSection, webSection, moreSection]
                    }else{
                        return [webSection, recommendSection]
                    }
                } else if !switchAndRecommend.0.isEmpty {
                    return [SectionModel<String?, Any>(model: nil, items: switchAndRecommend.0)]
                } else {
                     return [SectionModel<String?, Any>(model: nil, items: []),
                             SectionModel<String?, Any>(model: "猜你喜欢", items: list)]
                }
        }
        
        Observable
            .merge(searchResult, searchHotResult, beginAction)
            .bind(to: sectionsData)
            .disposed(by: bag)
        
        sections = sectionsData.asObservable()
            .skip(1)
            .asDriver(onErrorJustReturn: [])
        
        
        // 第一本书阅读按钮点击
        let firstBookRead = firstItemAction
            .filter{ $0 == 2 }
            .withLatestFrom(dataVariable.asObservable())
            .map{ $0.first }
            .unwrap()
        
        catalogViewModel = firstItemAction
            .debug()
            .filter{ $0 == 1 }
            .debug()
            .withLatestFrom(dataVariable.asObservable())
            .map{ $0.first?.book_id }
            .unwrap()
            .map{ BookCatalogViewModel($0) }
        
        let bookInfoProvider = MoyaProvider<BookInfoService>()
        
        let addBookshelfRequest = firstItemAction
            .filter{ $0 == 0 }
            .withLatestFrom(dataVariable.asObservable())
            .map{ $0.first?.book_id }
            .unwrap()
            .flatMap{
                bookInfoProvider
                    .rx
                    .request(.add($0, 0))
                    .model(NullResponse.self)
                    .trackActivity(activityIndicator)
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.status }
            .unwrap()
        
        tipHud = addBookshelfRequest
            .map{ $0.code == 0 ? HUDValue(.label("已加入书架")): HUDValue(.label( $0.msg ?? "加入书架失败")) }
            .asDriver(onErrorJustReturn: HUDValue(.label("网络异常，请重试")))
        
        addBookshelfRequest
            .map{ $0.code == 0 }
            .withLatestFrom(dataVariable.asObservable())
            .map{ ret -> [BookInfo] in
                ret.first?.join_bookcase = true
                return ret
            }
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        addBookshelfRequest
            .map{ $0.code == 0 }
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Book.addbookshelf, object: nil)
            })
            .disposed(by: bag)
        
        itemOutput = Observable
            .merge(
                itemDidSelected
                    .asObservable()
                    .map{ $0 as? BookInfo}
                    .unwrap(),
                firstBookRead)
            .asObservable()
            .debug()
        
        webViewModel = netSearchAction
            .map{
                if $0 == 0 {
                    return "https://m.so.com/s?q="
                }else if $0 == 1 {
                    return "https://m.baidu.com/s?wd="
                }else {
                    return "https://m.sm.cn/s?q="
                }
            }
            .withLatestFrom(searchKeywords, resultSelector: { $0 + $1})
            .map{ $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) }
            .unwrap()
            .map{ URL(string: $0)}
            .map{ WebViewModel($0) }
     
        sogouViewModel =
         sogouSearchAction
            .map{
               return "https://wap.sogou.com/web/sl?bid=youhessyouhess_1sogou-appi-c1fcffd51eb7c38b&keyword="
            }
            .withLatestFrom(searchKeywords, resultSelector: { $0 + $1 + " 小说"})
            .map{ $0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) }
            .unwrap()
            .map{ URL(string: $0)}
            .withLatestFrom(searchKeywords, resultSelector: {($0, $1)})
            .map{ SogouWebViewModel($0, title: $1) }
        
        
        searchAction
            .unwrap()
            .map{ $0.trimmingCharacters(in: .whitespaces) }
            .filter{ $0.length > 0 }
            .map{ SearchKeyModel($0) }
            .subscribe(realm.rx.add(update: true))
            .disposed(by: bag)
        
        searchText = searchKeywords
            .asDriver(onErrorJustReturn: "")
        
        
     

        /// 上报搜索
        searchKeywords
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.search, object: $0)
            })
            .disposed(by: bag)
        
        
        viewWillAppear
            .asObservable()
            .map {_ in "YM_POSITION6_DD"}
            .subscribe(onNext: {
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.pageExposure, object: $0)
            })
            .disposed(by: bag)
        
        
        loadAd()
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate)
            .subscribe(onNext: { [weak self](_) in
                self?.loadAd()
            })
            .disposed(by: bag)
        
    }
    
    
    
    func loadAd() {
        
        /// banner 广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.searchPageTopBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: bannerConfigoutput)
            .disposed(by: bag)
        
        /// banner 广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.searchPageTopBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .bind(to: bannerConfigoutput)
            .disposed(by: bag)
        
        /// 搜索页顶部广告
        let banerAdConfig = AdvertiseService.advertiseConfig(AdPosition.searchPageTopBanner)
        bannerConfigoutput.accept(banerAdConfig)
        let bannerOutput = self.bannerOutput
        bannerConfigoutput.asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.inmobi.rawValue }
            .filter { !$0.is_close}
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let imBannerViewModel = IMBannerViewModel(config)
                imBannerViewModel.nativeAdOutput
                    .map { LocalTempAdConfig(config, adType:.inmobi($0)) }
                    .bind(to: bannerOutput)
                    .disposed(by: weakSelf.bag)
                weakSelf.bannerViewModel = imBannerViewModel
            })
            .disposed(by: bag)
        
    }
    
    deinit {
        debugPrint("deinit- GDTBannerViewModel")
    }
    
}

