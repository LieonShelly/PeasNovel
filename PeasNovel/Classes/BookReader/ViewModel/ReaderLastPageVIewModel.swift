//
//  ReaderLastPageVIewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//


import Foundation
import Moya
import RxMoya
import RxCocoa
import RxSwift
import Realm
import RealmSwift

class ReaderLastPageViewModel: Advertiseable {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let addBookshelfAction: PublishSubject<Void> = .init()
    let bookDetailInput: PublishSubject<Void> = .init()
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let shackingInput: PublishSubject<Void> = .init()
    let updateBtnOutput: PublishSubject<Bool> = .init()
    let shakingStatus = BehaviorRelay<ShakingStatus>(value: .normal)
    var bannerViewModel: Advertiseable?
    
    /// output
    let dataDriver: Driver<[SectionModel<RaderLastPageSectionType, ReaderLastPageGuessBook>]>
    let shakingOutput: BehaviorRelay<[ReaderLastPageGuessBook]> = .init(value: [])
    let messageOutput: PublishSubject<HUDValue> = .init()
    let bannerOutput = BehaviorSubject<LocalTempAdConfig?>.init(value: nil)
    let bannerConfigOutput: BehaviorRelay<LocalAdvertise?> = .init(value: nil)
    
    init(_ param: [String: String]) {
        guard let bookId = param["book_id"]  else {
            fatalError()
        }
        guard let category_id_1 = param["category_id_1"]  else {
            fatalError()
        }
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        errorDriver = errorTracker.asDriver()
        activityDriver = activityIndicator.asDriver()
        
        let guessResponse: BehaviorRelay<ReaderLastPageGuessBookResponse> = .init(value: ReaderLastPageGuessBookResponse())
        
        let provider = MoyaProvider<BookReaderService>()
        viewDidLoad.flatMap {
            provider.rx.request(.guesLike(["category_id_1": category_id_1]))
                .model(ReaderLastPageGuessBookResponse.self)
                .trackActivity(activityIndicator)
                .catchError {_  in Observable.never() }
                .asObservable()
        }
            .bind(to: guessResponse)
            .disposed(by: bag)
        
        
        let dataVariable = BehaviorRelay<BookDetailModel>(value: BookDetailModel())
        let detailProvider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()
        let bookUpdate = BehaviorRelay(value: false)
        
        viewDidLoad
            .flatMap {
                detailProvider
                    .rx
                    .request(.detail(bookId))
                    .model(BookDetailResponse.self)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.data }
            .unwrap()
            .bind(to: dataVariable)
            .disposed(by: bag)
        
        viewDidLoad.flatMap {
            provider.rx.request(.getBookUpdateBNoti(["book_id": bookId]))
                    .model(BookUpdateResponse.self)
                    }
                .map { $0.data != nil }
                .bind(to: bookUpdate)
                .disposed(by: bag)

        
        dataDriver = Observable.combineLatest(viewDidLoad,
                                                  dataVariable.asObservable().filter {$0.book_info != nil },
                                                  guessResponse.asObservable().filter {$0.data != nil}.map {$0.data}.unwrap(),
                                                  shakingStatus.asObservable(),
                                                  bookUpdate.asObservable()) { (_, bookDetail, dataResponse, shakingStatusValue, isUpdate) -> [SectionModel<RaderLastPageSectionType, ReaderLastPageGuessBook>] in
                                                    bookDetail.isAddBookNoti = isUpdate
                                                    var sections: [SectionModel<RaderLastPageSectionType, ReaderLastPageGuessBook>] = []
                                                    sections.append(SectionModel<RaderLastPageSectionType, ReaderLastPageGuessBook>(model: RaderLastPageSectionType.bookDetail(bookDetail), items: [ReaderLastPageGuessBook()]))
                                                    sections.append(SectionModel<RaderLastPageSectionType, ReaderLastPageGuessBook>(model: RaderLastPageSectionType.shaking(shakingStatusValue), items: [ReaderLastPageGuessBook()]))
                                                    sections.append(SectionModel<RaderLastPageSectionType, ReaderLastPageGuessBook>(model: RaderLastPageSectionType.guessLike(dataResponse), items: [ReaderLastPageGuessBook()]))
                                                    return sections
                    }.asDriver(onErrorJustReturn: [])
    
    
        
        let shakingResponse = BehaviorRelay<ReaderLastPageGuessBookResponse>.init(value: ReaderLastPageGuessBookResponse())
        shackingInput
            .asObservable()
            .flatMap {
                provider.rx.request(.shaking)
                    .model(ReaderLastPageGuessBookResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
        .bind(to: shakingResponse)
        .disposed(by: bag)
        
        shakingResponse.asObservable().skip(1)
            .map {$0.data}
            .unwrap()
            .bind(to: shakingOutput)
            .disposed(by: bag)
        
        updateBtnOutput.asObservable()
            .filter { $0 == true }
            .flatMap { _ in
                provider.rx.request(.addBookUpdateBNoti(["book_id": bookId]))
                    .trackActivity(activityIndicator)
                    .model(NullResponse.self)
                    .catchError({ (error) -> Observable<NullResponse> in
                        return Observable.just(NullResponse.commonError(error))
                    })
            }
            .map { $0.status }
            .unwrap()
            .filter { $0.code == 0 }
            .map {_ in "添加更新成功" }
            .unwrap()
            .map { HUDValue.init(.label($0))}
            .bind(to: messageOutput)
            .disposed(by: bag)
        

        updateBtnOutput.asObservable()
            .filter { $0 == false }
            .flatMap { _ in
                provider.rx.request(.deleteBookUpdateNoti(["book_id": bookId]))
                    .trackActivity(activityIndicator)
                    .model(NullResponse.self)
                    .catchError({ (error) -> Observable<NullResponse> in
                        return Observable.just(NullResponse.commonError(error))
                    })
            }
            .map { $0.status?.code }
            .unwrap()
            .filter { $0 == 0}
            .map { _ in  "取消更新成功"}
            .map { HUDValue.init(.label($0))}
            .bind(to: messageOutput)
            .disposed(by: bag)
    
        let readerBottomAdConfig = AdvertiseService.advertiseConfig(AdPosition.readerBottomBanner)
        let bannerOutput = self.bannerOutput
        viewDidLoad.asObservable()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                let config = AdvertiseService.advertiseConfig(AdPosition.readerBottomBanner)
                weakSelf.clearErrorLog(config)
            })
            .disposed(by: bag)
        
        bannerConfigOutput.accept(readerBottomAdConfig)
        bannerConfigOutput.asObservable()
            .unwrap()
            .filter { !$0.is_close}
            .filter { $0.ad_type == AdvertiseType.inmobi.rawValue }
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                let imBannerViewModel = IMBannerViewModel(config, isAutoRefresh: true)
                imBannerViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .inmobi($0))}
                    .bind(to: bannerOutput)
                    .disposed(by: weakSelf.bag)
                weakSelf.bannerViewModel = imBannerViewModel
            })
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
            .asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Book.didLoadReaderLastPage, object: nil)
            })
             .disposed(by: bag)
    }
    
}

enum RaderLastPageSectionType {
    case bookDetail(BookDetailModel)
    case shaking(ShakingStatus)
    case guessLike([ReaderLastPageGuessBook])
    
}


enum ShakingStatus {
    case normal
    case shaking
    case shakingDone(Bool)
}
