//
//  BookMallCategoryViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/10.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import RxCocoa

class BookMallCategoryViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    /// input
    let categoryInput: PublishSubject<Category> = .init()
    let bookTapInput: PublishSubject<RecommendBook> = .init()
    let refreshInput: PublishSubject<Bool> = .init()
    var imNativeViewModels: [IMNativeViewModel] =  []
    let exceptionInput: PublishSubject<Void> = .init()
    var infoAdViewModels: [String: Advertiseable] = [:]
    /// output
    let dataSources: PublishSubject<[SectionModel<RecommnedCategoryUIType, RecommendBook>]> = .init()
    let booktapOutput: Driver<RecommendBook>
    let refreshStatusOutput: PublishSubject<RefreshStatus> = .init()
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let activityDriver: Driver<Bool>
     
    init() {
        let provider = MoyaProvider<BookMallService>()
        let otherRecommendBookResponse = BehaviorRelay<OtherRecommendBookResponse>(value: OtherRecommendBookResponse())
        let moreDataRecommendBookResponse = BehaviorRelay<OtherRecommendBookResponse>(value: OtherRecommendBookResponse())
        let otherRecommendBooks = BehaviorRelay<[RecommendBook]>(value: [])
        let metaOtherRecommendBooks = BehaviorRelay<[RecommendBook]>(value: [])
        let recomendImage = BehaviorRelay<String>.init(value: "")
        let page = BehaviorRelay<Int>.init(value: 2)
        let sections: BehaviorRelay<[SectionModel<RecommnedCategoryUIType, RecommendBook>]> = .init(value: [])
        let categorHasEmpty: BehaviorRelay<Bool> = BehaviorRelay(value: false) /// 分类是否加载完毕
        let moreBooks: BehaviorRelay<[RecommendBook]> = BehaviorRelay(value: [])
        let acitvity = ActivityIndicator()
        
        exceptionOuptputDriver = sections.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = sections.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        activityDriver = acitvity.asDriver()
        
        exceptionInput.asObservable()
            .map { true }
            .bind(to: refreshInput)
            .disposed(by: bag)
        
        Observable.combineLatest(viewDidLoad.asObservable(), categoryInput.asObservable()) { (_, input) -> Category in
            return input
        } .flatMap {
            provider.rx.request(.otherRecommendBook(["category_id_1": $0.category_id_1 ?? "", "category_id_2": $0.category_id_2 ?? "", "num": 12]))
                .model(OtherRecommendBookResponse.self)
                .asObservable()
                .catchError {_ in Observable.never()}
                .trackActivity(acitvity)
            }
            .bind(to: otherRecommendBookResponse)
            .disposed(by: bag)
        
        otherRecommendBookResponse.asObservable()
            .skip(1)
            .map {$0.data}
            .unwrap()
            .bind(to: otherRecommendBooks)
            .disposed(by: bag)
        
        otherRecommendBookResponse.asObservable()
            .skip(1)
            .map {$0.data}
            .unwrap()
            .bind(to: metaOtherRecommendBooks)
            .disposed(by: bag)
        
        otherRecommendBookResponse.asObservable()
            .skip(1)
            .map {$0.extra}
            .unwrap()
            .map { $0 as? String}
            .unwrap()
            .bind(to: recomendImage)
            .disposed(by: bag)
        
        Observable.combineLatest(otherRecommendBooks.asObservable().filter {!$0.isEmpty}, recomendImage.asObservable(), resultSelector: { (books, imageStr) -> ([RecommendBook], String) in
            return  (books, imageStr)
        })
            .map({ (lists, imageStr) -> [SectionModel<RecommnedCategoryUIType, RecommendBook>] in
                var sections: [SectionModel<RecommnedCategoryUIType, RecommendBook>] = []
                if !imageStr.isEmpty {
                    let section = SectionModel<RecommnedCategoryUIType, RecommendBook>(model: RecommnedCategoryUIType.image(imageStr), items: [RecommendBook()])
                    sections.append(section)
                }
                let section = SectionModel<RecommnedCategoryUIType, RecommendBook>(model: RecommnedCategoryUIType.book(lists), items: lists)
                sections.append(section)
                return sections
            })
            .bind(to: sections)
            .disposed(by: bag)

          sections
            .asObservable()
            .bind(to: dataSources)
            .disposed(by: bag)
        
        booktapOutput = bookTapInput.asObservable()
            .filter { $0.book_id != nil }
            .map {$0}
            .unwrap()
            .asDriverOnErrorJustComplete()
        
        
        moreBooks.asObservable()
            .subscribe(onNext: { (books) in
                otherRecommendBooks.accept(otherRecommendBooks.value + books)
                metaOtherRecommendBooks.accept(metaOtherRecommendBooks.value + books)
            })
            .disposed(by: bag)
       
        /// 下拉刷新
        refreshInput.asObservable().filter {$0 == true}
            .map {_ in 2 }
            .bind(to: page)
            .disposed(by: bag)
        
        Observable.combineLatest(refreshInput.asObservable().filter {$0 == true}, categoryInput.asObservable()) { (_, input) -> Category in
            return input
            } .flatMap {
                provider.rx.request(.otherRecommendBook(["page": 1, "category_id_1": $0.category_id_1 ?? "", "category_id_2": $0.category_id_2 ?? "", "num": 12]))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: otherRecommendBookResponse)
            .disposed(by: bag)
        
        otherRecommendBookResponse.asObservable()
            .map {_ in RefreshStatus.endHeaderRefresh }
            .bind(to: refreshStatusOutput)
            .disposed(by:  bag)
        
        page.asObservable()
            .filter {$0 == 2}
            .map {_ in RefreshStatus.endFooterRefresh }
            .bind(to: refreshStatusOutput)
            .disposed(by:  bag)
        
        /// 上拉加载 -- 先加载后台传的书
        Observable.combineLatest( refreshInput.asObservable().filter {$0 == false}.filter {_ in categorHasEmpty.value == false }, categoryInput.asObservable()) { (_, input) -> (Int, Category) in
            return (page.value, input)
            } .flatMap {
                provider.rx.request(.otherRecommendBook(["page": $0.0, "category_id_1": $0.1.category_id_1 ?? "", "category_id_2": $0.1.category_id_2 ?? "", "num": 12]))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: moreDataRecommendBookResponse)
            .disposed(by: bag)
        
        
        moreDataRecommendBookResponse.asObservable()
            .map { $0.data }
            .unwrap()
            .subscribe(onNext: {[weak self] (books) in
                guard let weakSelf = self else {
                    return
                }
                if books.isEmpty {
                    /// 后台传的书加载完了，马上加载书库的
                    categorHasEmpty.accept(true)
                    weakSelf.refreshInput.onNext(false)
                } else {
                     page.accept(page.value + 1)
                     moreBooks.accept(books)
                     weakSelf.refreshStatusOutput.onNext(RefreshStatus.endFooterRefresh)
                }
            }, onError: {[weak self]  (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.refreshStatusOutput.onNext(RefreshStatus.error)
            })
            .disposed(by: bag)
        
        
        /// 加载更多 - 万人之选
        let wanrenzhixuanBookListRes = BehaviorRelay<OtherRecommendBookResponse>(value: OtherRecommendBookResponse())
        
        Observable.combineLatest( refreshInput.asObservable().filter {$0 == false}.filter { _ in categorHasEmpty.value == true},
                                  categoryInput.asObservable()) { (_, input) -> (Int, Category) in
                return (page.value, input)
            }
            .flatMap {
                provider.rx.request(.otherRecommendCategoryBookList(["page": $0.0,
                                                                     "num": 12,
                                                                     "category_id_1": $0.1.category_id_1 ?? "",
                                                                     "category_id_2": $0.1.category_id_2 ?? ""]))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
            }
            .bind(to: wanrenzhixuanBookListRes)
            .disposed(by: bag)

        
        wanrenzhixuanBookListRes.asObservable()
            .map {$0.data }
            .unwrap()
            .subscribe(onNext: { [weak self](books) in
                guard let weakSelf = self else {
                    return
                }
                if books.isEmpty {
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.noMoreData)
                } else {
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.endFooterRefresh)
                    moreBooks.accept(books)
                    page.accept(page.value + 1)
                }
                }, onError: { [weak self]_ in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.error)
            })
            .disposed(by: bag)
        
        loadAd(metaOtherRecommendBooks: metaOtherRecommendBooks,
               otherRecommendBooks: otherRecommendBooks)
        
        
        /// 广告配置更新了
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate)
            .map {_ in true }
            .bind(to: refreshInput)
            .disposed(by: bag)
        
        
    
    }
    
    fileprivate func loadAd(metaOtherRecommendBooks: BehaviorRelay<[RecommendBook]>,
                            otherRecommendBooks:  BehaviorRelay<[RecommendBook]>) {
        struct Keys {
            static let adIndex = "adIndex"
            static let weekMainLoad = "weekMainLoad"
        }
        /// 广告
        var adIndexs: [Int] = [6] /// 获取需要插入广告的位置,初始值为6
        metaOtherRecommendBooks.asObservable()
            .skip(1)
            .subscribe(onNext: { [weak self](bookList) in
                guard let weakSelf = self, let adConfig = AdvertiseService.advertiseConfig(AdPosition.userCategoryInfoStream), !adConfig.is_close else {
                    return
                }
                /// 是否是下拉刷新
                if  otherRecommendBooks.value.count <= 12 {
                    adIndexs = [6]
                }
                let delta = 7
                let adStartIndex = adIndexs.last ?? 6
                var startIndex = adIndexs.count
                for index in ( 0 ..< bookList.count ){
                    let insertIndex = adStartIndex + delta * index
                    if  insertIndex <= otherRecommendBooks.value.count && !adIndexs.contains(insertIndex) {
                        adIndexs.append(insertIndex)
                    }
                }
                let endIndex = adIndexs.count - 1
                if startIndex > endIndex {
                    startIndex = (endIndex - 1) > 0 ? (endIndex - 1): 0
                }
                let newAdindexs = Array(adIndexs[(startIndex) ... endIndex])
                for(_, adIndex) in newAdindexs.enumerated() {
                    let adBook = RecommendBook()
                    adBook.book_id = "advetise" + String(Date().timeIntervalSince1970)
                    let insertIndex = adIndex
                    if otherRecommendBooks.value.count > insertIndex {
                        otherRecommendBooks.insert(adBook, at: insertIndex)
                    }
                    let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(insertIndex)])
                    AdvertiseService.createInfoStreamAdOutput(adConfig,adUIConfigure: uiConfig, configure: { (adViewModel) in
                        weakSelf.infoAdViewModels["\(insertIndex)"] = adViewModel
                    }).catchError { _ in Observable.never() }
                        .subscribe(onNext: { (adtemp) in
                            if let adIndex = otherRecommendBooks.value.lastIndex(where: { $0.book_id == adBook.book_id}) {
                                adBook.localTempAdConfig = adtemp
                                var data = otherRecommendBooks.value
                                data[adIndex] = adBook
                                otherRecommendBooks.accept(data)
                            }
                        })
                        .disposed(by: weakSelf.bag)
                }
            })
            .disposed(by: bag)
        
        /// 广告加载失败:
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.userCategoryInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + "\(index)"] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        var data = otherRecommendBooks.value
                        if index < data.count {
                            let book = data[index]
                            book.localTempAdConfig = tempConfig
                            otherRecommendBooks.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)

         /// 广告加载失败:
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.userCategoryInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + "\(index)"] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        var data = otherRecommendBooks.value
                        if index < data.count {
                            let book = data[index]
                            book.localTempAdConfig = tempConfig
                            otherRecommendBooks.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)
        
    
    }
    
}

//extension BookMallCategoryViewModel: AdvertiseUIInterface {
//
//    func infoAdSize(_ type: AdvertiseType?) -> CGSize {
//        guard let type = type else {
//            return .zero
//        }
//        switch type {
//        case .inmobi:
//            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 120)
//        case .GDT:
//            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16) + 50)
//        case .todayHeadeline:
//            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 80)
//        default:
//            return .zero
//        }
//    }
//}

enum RecommnedCategoryUIType {
    case image(String)
    case book([RecommendBook])
    
    var title: String {
        switch self {
        case .image:
            return "image"
        case .book:
            return "book"
        }
    }
}
