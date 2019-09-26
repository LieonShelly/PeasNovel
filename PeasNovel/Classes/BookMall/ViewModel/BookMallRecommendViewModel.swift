//
//  BookMallRecommendViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import RxCocoa

class BookMallRecommendViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewDidAppear: PublishSubject<Bool> = .init()
    let viewDidDisappear: PublishSubject<Bool> = .init()
    
    let bag = DisposeBag()
    let dataSources: PublishSubject<[SectionModel<BookMallRecomendUIType, RecommendBook>]> = .init()
    /// input
    let changeRecommendInput: PublishSubject<String> = .init()
    let rankInput: PublishSubject<Void> = .init()
    let categoryInput: PublishSubject<Void> = .init()
    let bookListInput: PublishSubject<Void> = .init()
    let newBookInput: PublishSubject<Void> = .init()
    let finishInput: PublishSubject<Void> = .init()
    let specialRecommendRefreshInput: PublishSubject<String> = .init()
    let otherRecommendRefreshInput: PublishSubject<String> = .init()
    let bookTapInput: PublishSubject<RecommendBook> = .init()
    let refreshInput: PublishSubject<Bool> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    let recommendPositionMoreInput: PublishSubject<RecommendPosition> = .init()
    let recommendPositionInput: PublishSubject<RecommendPosition> = .init()
    var userCategorylistsInput: BehaviorRelay<[Category]> = BehaviorRelay(value: [])
    var infoAdViewModels: [String: Advertiseable] = [:]
    /// output
    let rankViewModel: Observable<RankViewModel>
    let classifyViewModel: Observable<ClassifyViewModel>
    let bookSheetViewModel: Observable<BookSheetChoiceViewModel>
    let newBookViewModel: Observable<NewBookViewModel>
    let finalViewModel: Observable<FinalViewModel>
    let bookDetailOutput: PublishSubject<Void> = .init()
    let booktapOutput: Driver<RecommendBook>
    let classifyListViewModel: Observable<ClassifyListViewModel>
    let refreshStatusOutput: PublishSubject<RefreshStatus> = .init()
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let recommendPositionOutput: PublishSubject<(RecommendPositionDetailViewModel, String)> = .init()
    let dataEmpty: Driver<Bool>
    let activityDriver: Driver<Bool>
    
    
    init() {
        
        let provider = MoyaProvider<BookMallService>()
        let bannerAndSepicalResponse = BehaviorRelay<BannerAndSpecialRecommnedResponse>(value: BannerAndSpecialRecommnedResponse())
        let recommnedPostionsResponse = BehaviorRelay<RecommendPositionResponse>(value: RecommendPositionResponse())
        let otherRecommendCategoryBookListRes = BehaviorRelay<OtherRecommendBookResponse>(value: OtherRecommendBookResponse())
        let moreOtherRecommendCategoryBookListRes = BehaviorRelay<OtherRecommendBookResponse>(value: OtherRecommendBookResponse())
        let banners = BehaviorRelay<[Banner]>(value: [])
        let specialRecommends = BehaviorRelay<[RecommendBook]>(value: [])
        let recommendPositions = BehaviorRelay<[RecommendPosition]>(value: [])
        let metaRecommendPositions = BehaviorRelay<[RecommendPosition]>(value: [])
        let otherRecommendCategoryBookList = BehaviorRelay<[RecommendBook]>(value: [])
        let metaOtherRecommendCategoryBookList = BehaviorRelay<[RecommendBook]>(value: [])
        let metaMoreOtherRecommendCategoryBookList = BehaviorRelay<[RecommendBook]>(value: [])
        let page = BehaviorRelay<Int>.init(value: 2)
        let sections = BehaviorRelay<[SectionModel<BookMallRecomendUIType, RecommendBook>]>.init(value: [])
        let acitvity = ActivityIndicator()
        
       dataEmpty = sections.asObservable()
        .map { $0.isEmpty }
        .asDriver(onErrorJustReturn: true)
        
        activityDriver = acitvity.asDriver()
        
        viewDidLoad.flatMap { _ in
            provider.rx.request(.bannerAndSpecialRecommend)
                .model(BannerAndSpecialRecommnedResponse.self)
                .asObservable()
                .catchError {Observable.just(BannerAndSpecialRecommnedResponse.commonError($0))}
                .trackActivity(acitvity)
            }
            .bind(to: bannerAndSepicalResponse)
            .disposed(by: bag)
        
        viewDidLoad.flatMap { _ in
            provider.rx.request(.recommendPostion)
                .model(RecommendPositionResponse.self)
                .asObservable()
                .catchError {Observable.just(RecommendPositionResponse.commonError($0))}
            }
            .bind(to: recommnedPostionsResponse)
            .disposed(by: bag)
        
        viewDidLoad.flatMap { _ in
            provider.rx.request(.otherRecommendCategoryBookList(["page": 1, "num": "24"]))
                .model(OtherRecommendBookResponse.self)
                .asObservable()
                .catchError {Observable.just(OtherRecommendBookResponse.commonError($0))}
            }
            .bind(to: otherRecommendCategoryBookListRes)
            .disposed(by: bag)
        
       
        bannerAndSepicalResponse.asObservable()
            .map {$0.data?.lunbotu}
            .unwrap()
            .bind(to: banners)
            .disposed(by: bag)
        
        bannerAndSepicalResponse.asObservable()
            .map {$0.data?.jingxuan_zhongbangtuijian}
            .unwrap()
            .bind(to: specialRecommends)
            .disposed(by: bag)
        
        recommnedPostionsResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .bind(to: metaRecommendPositions)
            .disposed(by: bag)
        
        metaRecommendPositions.asObservable()
            .bind(to: recommendPositions)
            .disposed(by: bag)

        let otherChangeResponse = BehaviorRelay<[RecommendBook]>(value: [])
        /// 本周主打换一换的结果
        let weekMainLoadChangeResponse = BehaviorRelay<[RecommendBook]>(value: [])
        /// 猜你喜欢换一换的结果
        let guessLikeChangeResponse = BehaviorRelay<[RecommendBook]>(value: [])
        let specialPage = BehaviorRelay(value: 2)
        
        specialRecommendRefreshInput
            .flatMap {
                provider.rx.request(.changeRecommend(["type_name": $0, "page": "\(specialPage.value)"]))
                .model(OtherRecommendBookResponse.self)
                .asObservable()
                .catchError {_ in Observable.never()}
            }
            .map {$0.data}
            .unwrap()
            .bind(to: specialRecommends)
            .disposed(by: bag)
        
        specialRecommends.asObservable().skip(2)
            .filter {!$0.isEmpty }
            .map { _ in specialPage.value + 1}
            .bind(to: specialPage)
            .disposed(by: bag)
        
        specialRecommends.asObservable().skip(1)
            .filter {$0.isEmpty }
            .map { _ in 1}
            .bind(to: specialPage)
            .disposed(by: bag)
        
        let weekMaiLoadPage = BehaviorRelay(value: 2)
        let guessLikePage = BehaviorRelay(value: 2)

        otherRecommendRefreshInput
            .filter { $0 == "jingxuan_benzhouzhuda"}
            .flatMap {
                provider.rx.request(.changeRecommend(["type_name": $0, "page": "\(weekMaiLoadPage.value)"]))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map {$0.data}
            .unwrap()
            .bind(to: weekMainLoadChangeResponse)
            .disposed(by: bag)
        
        otherRecommendRefreshInput
            .filter { $0 == "jingxuan_cainixihuan"}
            .flatMap {
                provider.rx.request(.changeRecommend(["type_name": $0, "page": "\(guessLikePage.value)"]))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map {$0.data}
            .unwrap()
            .bind(to: guessLikeChangeResponse)
            .disposed(by: bag)
        
        guessLikeChangeResponse.asObservable()
            .bind(to: otherChangeResponse)
            .disposed(by: bag)
        
        
        weekMainLoadChangeResponse.asObservable()
            .bind(to: otherChangeResponse)
            .disposed(by: bag)
        
        weekMainLoadChangeResponse.asObservable().skip(1)
             .filter {!$0.isEmpty }
            .map { _ in weekMaiLoadPage.value + 1}
            .bind(to: weekMaiLoadPage)
            .disposed(by: bag)
        
        weekMainLoadChangeResponse.asObservable().skip(1)
            .filter {$0.isEmpty }
            .map { _ in 1}
            .bind(to: weekMaiLoadPage)
            .disposed(by: bag)
        
        
        guessLikeChangeResponse.asObservable().skip(1)
            .filter {!$0.isEmpty }
            .map { _ in guessLikePage.value + 1}
            .bind(to: guessLikePage)
            .disposed(by: bag)
        
        guessLikeChangeResponse.asObservable().skip(1)
            .filter {$0.isEmpty }
            .map { _ in 1}
            .bind(to: guessLikePage)
            .disposed(by: bag)
        
        Observable.combineLatest(otherRecommendRefreshInput.asObservable(), otherChangeResponse.asObservable()) { (inputTypeName, bookList) -> (Int, RecommendPosition)? in
            for(index, model) in recommendPositions.value.enumerated() {
                if model.type_name == inputTypeName {
                    model.bookinfo = bookList
                    return (index, model)
                }
            }
            return nil
        }
            .unwrap()
            .subscribe(onNext: { (arg0) in
                let (index, refreshPostion) = arg0
                var data = recommendPositions.value
                data[index] = refreshPostion
                recommendPositions.accept(data)
            })
            .disposed(by: bag)
        
        exceptionInput.asObservable()
            .map { true }
            .bind(to: refreshInput)
            .disposed(by: bag)
        
        exceptionOuptputDriver = sections.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        rankViewModel = rankInput
            .map{ RankViewModel () }
        
        classifyViewModel = categoryInput
            .map{ ClassifyViewModel() }
        
        bookSheetViewModel = bookListInput
            .map{ BookSheetChoiceViewModel() }
        
        newBookViewModel = newBookInput
            .map{ NewBookViewModel() }
        
        finalViewModel = finishInput
            .map{ FinalViewModel() }
        
        booktapOutput = bookTapInput.asObservable()
            .filter { $0.book_id != nil }
            .map { $0 }
            .unwrap()
            .asDriverOnErrorJustComplete()
        
        classifyListViewModel = bookTapInput
            .asObservable()
            .filter { $0.category_count_title != nil }
            .map({ (book) -> ClassifyModel in
                 let model = ClassifyModel()
                model.category_id = book.category_id
                model.name = book.name
                return model
            })
            .map{ ClassifyListViewModel($0) }
        
        ///  刷新
        NotificationCenter.default.rx
            .notification(Notification.Name.UIUpdate.readFavorDidChange)
            .subscribe(onNext: { (_) in
                specialPage.accept(2)
                self.refreshInput.onNext(true)
            })
            .disposed(by: bag)
        
        refreshInput.asObservable()
            .filter { $0 == true }
            .flatMap { _ in
                provider.rx.request(.bannerAndSpecialRecommend)
                    .model(BannerAndSpecialRecommnedResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: bannerAndSepicalResponse)
            .disposed(by: bag)
        
        refreshInput.asObservable()
            .filter { $0 == true }
            .flatMap { _ in
                provider.rx.request(.recommendPostion)
                    .model(RecommendPositionResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: recommnedPostionsResponse)
            .disposed(by: bag)
        
        refreshInput.asObservable()
            .filter { $0 == true }
            .flatMap { _ in
                provider.rx.request(.otherRecommendCategoryBookList(["page": 1, "num": "24"]))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: otherRecommendCategoryBookListRes)
            .disposed(by: bag)
        
        otherRecommendCategoryBookListRes.asObservable()
            .map { $0.data}
            .unwrap()
            .bind(to: metaOtherRecommendCategoryBookList)
            .disposed(by: bag)
        
        metaOtherRecommendCategoryBookList
            .asObservable()
            .bind(to: otherRecommendCategoryBookList)
            .disposed(by: bag)
        
    
        refreshInput.asObservable()
            .filter { $0 == true }
            .map {_ in 2}
            .bind(to: page)
            .disposed(by: bag)
        
        page.asObservable()
            .filter {$0 == 2}
            .map {_ in RefreshStatus.endFooterRefresh }
            .bind(to: refreshStatusOutput)
            .disposed(by:  bag)
        
        Observable.combineLatest(bannerAndSepicalResponse.asObservable(), recommnedPostionsResponse.asObservable(), otherRecommendCategoryBookListRes.asObservable()) { (_, _, _) -> RefreshStatus in
            return .endHeaderRefresh
        }
            .bind(to: refreshStatusOutput)
            .disposed(by:  bag)
        
        /// 加载更多
        refreshInput.asObservable()
            .filter { $0 == false }
            .flatMap { _ in
                provider.rx.request(.otherRecommendCategoryBookList(["page": page.value, "num": "24"]))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
            }
            .bind(to: moreOtherRecommendCategoryBookListRes)
            .disposed(by: bag)
        
        let moreOtherRecommendCategoryBookList: BehaviorRelay<[RecommendBook]> = BehaviorRelay(value: [])
        moreOtherRecommendCategoryBookList.asObservable()
            .subscribe(onNext: { (books) in
                otherRecommendCategoryBookList.accept(otherRecommendCategoryBookList.value + books)
            })
            .disposed(by: bag)
        
        metaMoreOtherRecommendCategoryBookList
            .asObservable()
            .bind(to: moreOtherRecommendCategoryBookList)
            .disposed(by: bag)
        
        moreOtherRecommendCategoryBookListRes.asObservable()
            .map {$0.data }
            .unwrap()
            .subscribe(onNext: { [weak self](books) in
                guard let weakSelf = self else {
                    return
                }
                if books.isEmpty {
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.noMoreData)
                } else {
                    metaMoreOtherRecommendCategoryBookList.accept(books)
                    page.accept(page.value + 1)
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.endFooterRefresh)
                }
            }, onError: { [weak self]_ in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.refreshStatusOutput.onNext(RefreshStatus.error)
            })
            .disposed(by: bag)

        bookTapInput.asObservable()
            .map { $0.title }
            .unwrap()
            .filter { $0 == "精选好书"}
            .map { (RecommendPositionDetailViewModel(["type_name": "jingxuanhaoshu"]), $0)}
            .bind(to: recommendPositionOutput)
            .disposed(by: bag)
        
        bookTapInput.asObservable()
            .map { $0.title }
            .unwrap()
            .filter { $0 == "爆红完本"}
            .map {(RecommendPositionDetailViewModel(["type_name": "baohongwanben"]) , $0)}
            .bind(to: recommendPositionOutput)
            .disposed(by: bag)
        
        bookTapInput.asObservable()
            .map { $0.title }
            .unwrap()
            .filter { $0 == "终极诱惑"}
            .map { (RecommendPositionDetailViewModel(["type_name": "zhongjiyouhuo"]), $0)}
            .bind(to: recommendPositionOutput)
            .disposed(by: bag)
        
       

        Observable.combineLatest(viewDidLoad.asObservable(), banners.asObservable(), specialRecommends.asObservable(), recommendPositions.asObservable(), otherRecommendCategoryBookList.asObservable()) { (_, bannerList, specialRecommendList, recommendPositionsList, otherRecommendList) -> [SectionModel<BookMallRecomendUIType, RecommendBook>] in
            var dataSources = [SectionModel<BookMallRecomendUIType, RecommendBook>]()
            if !bannerList.isEmpty {
                dataSources.append(SectionModel<BookMallRecomendUIType, RecommendBook>(model: .banner(bannerList), items: [RecommendBook()]))
            }
            dataSources.append(SectionModel<BookMallRecomendUIType, RecommendBook>(model: .categoryBtn, items: [RecommendBook()]))
            if !specialRecommendList.isEmpty {
                dataSources.append(SectionModel<BookMallRecomendUIType, RecommendBook>(model: .specialRecommend(specialRecommendList), items: specialRecommendList))
            }
            dataSources.append(SectionModel<BookMallRecomendUIType, RecommendBook>(model: .adjustReadFavor, items: [RecommendBook()]))
            for postion in recommendPositionsList {
                if case RecommendPositionUIStyle.commonCategory = postion.style {
                    dataSources.append(SectionModel<BookMallRecomendUIType, RecommendBook>(model: .recommendPosition(postion), items: [RecommendBook()]))
                } else {
                    dataSources.append(SectionModel<BookMallRecomendUIType, RecommendBook>(model: .recommendPosition(postion), items: postion.bookinfo ?? []))
                }
                
            }
            dataSources.append(SectionModel<BookMallRecomendUIType, RecommendBook>(model: .otherRecommendCategoryBookList(otherRecommendList), items: otherRecommendList ))
            return dataSources
            }
            .bind(to: sections)
            .disposed(by: bag)
        
        sections
            .asObservable()
            .bind(to: dataSources)
            .disposed(by: bag)
        
        loadAd(metaRecommendPositions: metaRecommendPositions,
               recommendPositions: recommendPositions,
               metaMoreOtherRecommendCategoryBookList: metaMoreOtherRecommendCategoryBookList,
               otherRecommendCategoryBookList: otherRecommendCategoryBookList,
               metaOtherRecommendCategoryBookList: metaOtherRecommendCategoryBookList,
               page: page)

        
        /// 广告配置更新了
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate)
            .map {_ in true }
            .bind(to: refreshInput)
            .disposed(by: bag)
        
        
    }
    
    struct Keys {
        static let adIndex = "adIndex"
        static let weekMainLoad = "weekMainLoad"
    }
    
    fileprivate func loadAd(metaRecommendPositions: BehaviorRelay<[RecommendPosition]>,
                            recommendPositions: BehaviorRelay<[RecommendPosition]>,
                            metaMoreOtherRecommendCategoryBookList: BehaviorRelay<[RecommendBook]>,
                            otherRecommendCategoryBookList: BehaviorRelay<[RecommendBook]>,
                            metaOtherRecommendCategoryBookList: BehaviorRelay<[RecommendBook]>,
                            page: BehaviorRelay<Int>) {
        
       
        metaRecommendPositions.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                guard let weekMainLoadInAdConfig = AdvertiseService.advertiseConfig(AdPosition.weekMainLoadInfoStream),
                !weekMainLoadInAdConfig.is_close else {
                    return
                }
                guard let index = recommendPositions.value.lastIndex(where: {$0.title == "本周主打"}) else {
                    return
                }
                let postion = recommendPositions.value[index]
                let adbook = RecommendBook()
                postion.bookinfo?.append(adbook)
                var data = recommendPositions.value
                data[index] = postion
                recommendPositions.accept(data)
                let uiConfig = BookInfoAdConfig([Keys.adIndex: index])
                AdvertiseService.createInfoStreamAdOutput(weekMainLoadInAdConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    debugPrint("weekMainLoadInAdConfig:\(self!.infoAdViewModels)")
                    self?.infoAdViewModels[uiConfig.viewModelCacheKey(weekMainLoadInAdConfig) + Keys.weekMainLoad] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        adbook.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        data[index] = postion
                        recommendPositions.accept(data)
                    }, onError: { (error) in

                    })
                    .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)

        metaRecommendPositions.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                guard let boutiqueBookListAdConfig = AdvertiseService.advertiseConfig(AdPosition.recommendBookListInfoStream),
                    !boutiqueBookListAdConfig.is_close else {
                        return
                }
                guard let index = recommendPositions.value.lastIndex(where: {$0.title == "推荐书单"})  else {
                    return
                }
                let postion = recommendPositions.value[index]
                let adbook = RecommendBook()
                postion.bookinfo?.append(adbook)
                var data = recommendPositions.value
                data[index] = postion
                recommendPositions.accept(data)
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                AdvertiseService.createInfoStreamAdOutput(boutiqueBookListAdConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    self?.infoAdViewModels[uiConfig.viewModelCacheKey(boutiqueBookListAdConfig) + "推荐书单"] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        adbook.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        data[index] = postion
                        recommendPositions.accept(data)
                    }, onError: { (error) in
                        
                    })
                    .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)
        

        metaRecommendPositions.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                guard let userCatrgoryAdConfig = AdvertiseService.advertiseConfig(AdPosition.boutiqueCategoryInfoStream),
                    !userCatrgoryAdConfig.is_close else {
                        return
                }
                for (index, category) in weakSelf.userCategorylistsInput.value.enumerated() {
                    if (index > 0 && (index + 1) % 2 == 0) || index == 1 {
                        guard let index = recommendPositions.value.lastIndex(where: {$0.title == category.short_name}) else {
                            return
                        }
                        let postion = recommendPositions.value[index]
                        let adbook = RecommendBook()
                        postion.bookinfo?.append(adbook)
                        var data = recommendPositions.value
                        data[index] = postion
                        recommendPositions.accept(data)
                        let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                        AdvertiseService.createInfoStreamAdOutput(userCatrgoryAdConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                            self?.infoAdViewModels[uiConfig.viewModelCacheKey(userCatrgoryAdConfig) + (category.short_name ?? "")] = viewModel
                        })
                            .catchError {_ in Observable.never() }
                            .subscribe(onNext: { (tempConfig) in
                                adbook.localTempAdConfig = tempConfig
                                var data = recommendPositions.value
                                data[index] = postion
                                recommendPositions.accept(data)
                            }, onError: { (error) in
                                
                            })
                            .disposed(by: weakSelf.bag)
                    }
                }
                
            })
            .disposed(by: bag)
        
        
        /// viewDidload 或者 刷新时会执行
        var adIndexs: [Int] = [8] /// 获取需要插入广告的位置,初始值为8
        metaOtherRecommendCategoryBookList.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self](bookList) in
                guard let weakSelf = self else {
                    return
                }
                guard let wanrenzhixuanAdConfig = AdvertiseService.advertiseConfig(AdPosition.wanrenzhixuanInnfoStream),
                    !wanrenzhixuanAdConfig.is_close else {
                        return
                }

               adIndexs = [8]
                let delta = 9
                let adStartIndex = adIndexs.last ?? 8
                let startIndex = adIndexs.count - 1
                for index in ( 0 ..< bookList.count ){
                    let insertIndex = adStartIndex + delta * index
                    if  insertIndex <= otherRecommendCategoryBookList.value.count && !adIndexs.contains(insertIndex) {
                        adIndexs.append(insertIndex)
                    }
                }
                let endIndex = adIndexs.count - 1
                let newAdindexs = Array(adIndexs[(startIndex) ... endIndex])
                for(_, adIndex) in newAdindexs.enumerated() {
                    let book = RecommendBook()
                    book.book_id = "advetise" + String(Date().timeIntervalSince1970)
                    let insertIndex = adIndex
                    if otherRecommendCategoryBookList.value.count > insertIndex {
                        let currentBook = otherRecommendCategoryBookList.value[insertIndex]
                        if !(currentBook.book_id?.starts(with: "advetise") ?? false) {
                            otherRecommendCategoryBookList.insert(book, at: insertIndex)
                        }
                    }
                    let uiConfig = BookInfoAdConfig([Keys.adIndex: insertIndex])
                    AdvertiseService.createInfoStreamAdOutput(wanrenzhixuanAdConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                        self?.infoAdViewModels[uiConfig.viewModelCacheKey(wanrenzhixuanAdConfig) + "\(insertIndex)"] = viewModel
                    }).catchError {_ in Observable.never() }
                        .subscribe(onNext: { (tempConfig) in
                            if let adIndex = otherRecommendCategoryBookList.value.lastIndex(where: { $0.book_id == book.book_id}) {
                                book.localTempAdConfig = tempConfig
                                var data = otherRecommendCategoryBookList.value
                                data[adIndex] = book
                                otherRecommendCategoryBookList.accept(data)
                            }
                        }, onError: { (error) in
                            
                        })
                        .disposed(by: weakSelf.bag)
                }
                
            })
            .disposed(by: bag)
        
        
        metaMoreOtherRecommendCategoryBookList.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self](bookList) in
                guard let weakSelf = self else {
                    return
                }
                guard let wanrenzhixuanAdConfig = AdvertiseService.advertiseConfig(AdPosition.wanrenzhixuanInnfoStream),
                    !wanrenzhixuanAdConfig.is_close else {
                        return
                }
                let delta = 9
                let adStartIndex = adIndexs.last ?? 8
                let startIndex = adIndexs.count - 1
                for index in ( 0 ..< bookList.count ){
                    let insertIndex = adStartIndex + delta * index
                    if  insertIndex <= otherRecommendCategoryBookList.value.count && !adIndexs.contains(insertIndex) {
                        adIndexs.append(insertIndex)
                    }
                }
                let endIndex = adIndexs.count - 1
                let newAdindexs = Array(adIndexs[(startIndex) ... endIndex])
                for(_, adIndex) in newAdindexs.enumerated() {
                    let book = RecommendBook()
                    /// 给每个广告书籍赋值一个假的bookid
                    book.book_id = "advetise" + String(Date().timeIntervalSince1970)
                    let insertIndex = adIndex
                    if otherRecommendCategoryBookList.value.count > insertIndex {
                        let currentBook = otherRecommendCategoryBookList.value[insertIndex]
                        if !(currentBook.book_id?.starts(with: "advetise") ?? false) {
                            otherRecommendCategoryBookList.insert(book, at: insertIndex)
                        }
                        
                    }
                    let uiConfig = BookInfoAdConfig([Keys.adIndex: insertIndex])
                    AdvertiseService.createInfoStreamAdOutput(wanrenzhixuanAdConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                        self?.infoAdViewModels[uiConfig.viewModelCacheKey(wanrenzhixuanAdConfig) + "\(insertIndex)"] = viewModel
                    })
                        .catchError {_ in Observable.never() }
                        .subscribe(onNext: { (tempConfig) in
                            if let adIndex = otherRecommendCategoryBookList.value.lastIndex(where: { $0.book_id == book.book_id}) {
                                book.localTempAdConfig = tempConfig
                                var data = otherRecommendCategoryBookList.value
                                data[adIndex] = book
                                otherRecommendCategoryBookList.accept(data)
                            }
                        }, onError: { (error) in

                        })
                        .disposed(by: weakSelf.bag)
                }
                
            })
            .disposed(by: bag)
        
        
        /// 本周主打广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.weekMainLoadInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type

                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + Keys.weekMainLoad] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        let postion = recommendPositions.value[index]
                        let adbook = postion.bookinfo?.last
                        adbook?.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        if index < data.count {
                            data[index] = postion
                            recommendPositions.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                
            })
            .disposed(by: bag)

        /// 本周主打广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.weekMainLoadInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                
                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + Keys.weekMainLoad] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        let postion = recommendPositions.value[index]
                        let adbook = postion.bookinfo?.last
                        adbook?.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        if index < data.count {
                            data[index] = postion
                            recommendPositions.accept(data)
                        }
                    }, onError: { (error) in
                        
                    })
                    .disposed(by: weakSelf.bag)
                
            })
            .disposed(by: bag)

        /// 推荐书单
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.recommendBookListInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type

                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                     weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + "推荐书单"] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        let postion = recommendPositions.value[index]
                        let adbook = postion.bookinfo?.last
                        adbook?.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        if index < data.count {
                            data[index] = postion
                            recommendPositions.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                
            })
            .disposed(by: bag)
        
        /// 推荐书单
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.recommendBookListInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + "推荐书单"] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        let postion = recommendPositions.value[index]
                        let adbook = postion.bookinfo?.last
                        adbook?.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        if index < data.count {
                            data[index] = postion
                            recommendPositions.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                
            })
            .disposed(by: bag)
        
        /// 用户分类
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.boutiqueCategoryInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                
                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + "推荐书单"] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        let postion = recommendPositions.value[index]
                        let adbook = postion.bookinfo?.last
                        adbook?.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        if index < data.count {
                            data[index] = postion
                            recommendPositions.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                
            })
            .disposed(by: bag)
        
        ///  用户分类
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.boutiqueCategoryInfoStream.rawValue else {
                    return
                }
                let uiConfig = BookInfoAdConfig([Keys.adIndex: Int(index)])
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                AdvertiseService.createInfoStreamAdOutput(newConfig, adUIConfigure: uiConfig, configure: { (viewModel) in
                    weakSelf.infoAdViewModels[uiConfig.viewModelCacheKey(newConfig) + "推荐书单"] = viewModel
                })
                    .catchError {_ in Observable.never() }
                    .subscribe(onNext: { (tempConfig) in
                        let postion = recommendPositions.value[index]
                        let adbook = postion.bookinfo?.last
                        adbook?.localTempAdConfig = tempConfig
                        var data = recommendPositions.value
                        if index < data.count {
                            data[index] = postion
                            recommendPositions.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                
            })
            .disposed(by: bag)
        
        /// 万人之选
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.wanrenzhixuanInnfoStream.rawValue else {
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
                        var data = otherRecommendCategoryBookList.value
                        if index < data.count {
                            let book = data[index]
                            book.localTempAdConfig = tempConfig
                            otherRecommendCategoryBookList.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
                
            })
            .disposed(by: bag)
        
        /// 万人之选
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .subscribe(onNext: {[weak self] (noti) in
                guard let weakSelf = self, let oldConfig = noti.object as? LocalAdvertise, let userInfo = noti.userInfo as? [String: Any], let index = userInfo[Keys.adIndex] as? Int else {
                    return
                }
                guard oldConfig.ad_position == AdPosition.wanrenzhixuanInnfoStream.rawValue else {
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
                        var data = otherRecommendCategoryBookList.value
                        if index < data.count {
                            let book = data[index]
                            book.localTempAdConfig = tempConfig
                            otherRecommendCategoryBookList.accept(data)
                        }
                    })
                    .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)


    }
     
    
}

enum BookMallRecomendUIType {
    case banner([Banner])
    case categoryBtn
    case specialRecommend([RecommendBook])
    case adjustReadFavor
    case recommendPosition(RecommendPosition)
    case otherRecommendCategoryBookList([RecommendBook])
    
    var title: String {
        switch self {
        case .banner:
            return ""
        case .categoryBtn:
            return ""
        case .specialRecommend:
            return "重磅推荐"
        case .adjustReadFavor:
            return ""
        case .recommendPosition:
            return ""
        case .otherRecommendCategoryBookList:
            return "万人之选"
        }
    }
}


class BookInfoAdConfig: AdvertiseUIInterface {
    var userInfo: [String : Any]!
    
    init(_ userInfo: [String: Any]) {
        self.userInfo = userInfo
    }
    
    func infoAdSize(_ type: AdvertiseType?) -> CGSize {
        guard let type = type else {
            return .zero
        }
        switch type {
        case .inmobi:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 120)
        case .GDT:
            return  CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16) + 50)
        case .todayHeadeline:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 80)
        default:
            return .zero
        }
    }
}
