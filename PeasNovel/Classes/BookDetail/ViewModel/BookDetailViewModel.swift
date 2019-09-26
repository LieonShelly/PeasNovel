//
//  BookDetailViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import Moya
import RxMoya
import RxCocoa

class BookDetailViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let openIntroAction: PublishSubject<Bool> = .init()
    let addBookshelfAction: PublishSubject<Void> = .init()
    let downloadAction: PublishSubject<Void> = .init()
    let freeReadAction: PublishSubject<Void> = .init()
    let itemSelected: PublishSubject<Any> = .init()
    var bannenrViewModel: Advertiseable?
    let bannerOutput = PublishSubject<LocalTempAdConfig?>.init()
    
    /// output
    let section: PublishSubject<[SectionModel<String, Any>]> = .init()
    let bookReader: Observable<(BookInfo, Bool)>
    let lastestChapter: Observable<BookChapterInfo>
    let catalogViewModel: Observable<BookCatalogViewModel>
    let bookSheetDetail: Observable<BookSheetDetailViewModel>
    let isAddedStatus: Driver<Bool>
    let isDownloadedStatus: Driver<Bool>
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let coverImage: Driver<UIImage>
    let bag = DisposeBag()
    let downloadOutput: Driver<ChooseChapterViewModel>
    let bannerConfigoutput: BehaviorRelay<LocalAdvertise?> = BehaviorRelay(value: nil)
    
    init(_ bookId: String, provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
       
        activityDriver = activityIndicator.asDriver()
        errorDriver = errorTracker.asDriver()
        
        let dataVariable = BehaviorRelay<BookDetailModel>(value: BookDetailModel())
        
        viewDidLoad
            .flatMap {
                provider
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
            
        let dataUpdate = dataVariable.asObservable().mapToVoid()
        
         Observable
            .merge(dataUpdate, openIntroAction.mapToVoid())
            .withLatestFrom(dataVariable.asObservable())
            .map{
                var sections = [
                    SectionModel<String, Any>(model: "", items: [$0.book_info ?? ""]),
                    SectionModel<String, Any>(model: "", items: [$0.last_chapter_info ?? ""]),
                    SectionModel<String, Any>(model: "看了这本书的人还在看", items: $0.like_book ?? [])
                ]
                if let sheet = $0.like_shudan, sheet.count > 0 {
                    sections.append(SectionModel<String, Any>(model: "包含此书的书单", items: $0.like_shudan ?? []))
                }
                if let origin = $0.cp_info?.origin_company?.removeSpaceHeadAndTailPro, origin.length > 0 {
                    sections.append(SectionModel<String, Any>(model: "图书更多信息", items: [$0.cp_info ?? ""]))
                }
                
                return sections
            }
        .bind(to: section)
        .disposed(by: bag)
        
        coverImage = dataVariable
            .asObservable()
            .map{ $0.book_info?.cover_url }
            .unwrap()
            .map{ URL(string: $0) }
            .unwrap()
            .downlaodImage()
            .unwrap()
            .asDriver(onErrorJustReturn: UIImage())
        
        let addBookshelf = addBookshelfAction
            .asObserver()
            .flatMap{
                provider.rx
                    .request(.add(bookId, 0))
                    .model(NullResponse.self)
                    .trackActivity(activityIndicator)
                    .catchError {_ in Observable.never()}
                
            }
            .map{ $0.status?.code }
            .unwrap()
            .share(replay: 1)
        // 是否加入书架
        let joinBookshelf = dataVariable
            .asObservable()
            .map{ $0.book_info?.join_bookcase }
            .unwrap()
            .map{ $0 }
        
        /// 监听阅读器是存在加入书架
        let outterAddBookShelf = NotificationCenter.default.rx.notification(Notification.Name.Book.bookshelf)
            .map { $0.object as? Bool }
            .unwrap()
        
        isAddedStatus = Observable
            .merge(joinBookshelf, outterAddBookShelf, addBookshelf.map{ $0 == 0 })
            .asDriver(onErrorJustReturn: false)
        
        addBookshelf
            .filter{ $0 == 0 }
            .subscribe(onNext: { _ in
                NotificationCenter.default.post(name: NSNotification.Name.Book.bookshelf, object: nil)
            })
            .disposed(by: bag)
        
        
        
        isDownloadedStatus = downloadAction
            .asObservable()
            .map{ true }
            .asDriver(onErrorJustReturn: true)
        
        catalogViewModel = itemSelected
            .map{ ($0 as? BookChapterInfo)?.book_id }
            .unwrap()
            .map{ BookCatalogViewModel($0) }
        
        lastestChapter = itemSelected
            .map{ ($0 as? BookChapterInfo) }
            .unwrap()
        
        bookSheetDetail = itemSelected
            .map{ ($0 as? BookSheetModel) }
            .unwrap()
            .map{ BookSheetDetailViewModel($0) }
        
        downloadOutput = downloadAction
            .asObservable()
            .map { ChooseChapterViewModel(bookId)}
            .asDriverOnErrorJustComplete()
        
        let justToReader: Observable<(BookInfo, Bool)> = freeReadAction
            .withLatestFrom(dataVariable.asObservable())
            .map{ $0.book_info }
            .unwrap()
            .map{ ($0, true) }
        
        let readerParase: Observable<(BookInfo, Bool)> = itemSelected
            .map{ ($0 as? BookInfoSimple)?.book_id }
            .unwrap()
            .map{
                let info = BookInfo()
                info.book_id = $0
                return (info, false)
            }
        
        bookReader = Observable<(BookInfo, Bool)>
            .merge(readerParase, justToReader)
        
    
        
        Observable.combineLatest(Observable
            .merge(dataUpdate,
                   openIntroAction.mapToVoid()),
                     dataVariable.asObservable(),
                     bannerOutput.asObservable()) { (_, bookDetail, adData) -> [SectionModel<String, Any>] in
                var sections = [
                    SectionModel<String, Any>(model: "", items: [bookDetail.book_info ?? ""]),
                    SectionModel<String, Any>(model: "", items: [bookDetail.last_chapter_info ?? ""]),
                    SectionModel<String, Any>(model: "看了这本书的人还在看", items: bookDetail.like_book ?? [])
                ]
                if let adData = adData  {
                    sections.insert(SectionModel<String, Any>(model: "广告", items: [adData]), at: 2)
                }
                if let sheet = bookDetail.like_shudan, sheet.count > 0 {
                    sections.append(SectionModel<String, Any>(model: "包含此书的书单", items: bookDetail.like_shudan ?? []))
                }
                if let origin = bookDetail.cp_info?.origin_company?.removeSpaceHeadAndTailPro, origin.length > 0 {
                    sections.append(SectionModel<String, Any>(model: "图书更多信息", items: [bookDetail.cp_info ?? ""]))
                }
                return sections
        }.bind(to: section)
            .disposed(by: bag)
        
        loadAd()
        
        /// 广告配置更新了
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.configDidUpdate)
            .map {_ in true }
            .subscribe(onNext: { [weak self] (_) in
                self?.loadAd()
            })
            .disposed(by: bag)
    }
    
    fileprivate func loadAd() {
        guard let bannerLocalConfig = AdvertiseService.advertiseConfig(AdPosition.bookDetailMedium), !bannerLocalConfig.is_close else {
            return
        }
        let bannerOutput = self.bannerOutput
        bannerConfigoutput.accept(bannerLocalConfig)
        bannerConfigoutput.asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.inmobi.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let imBannerViewModel = IMBannerViewModel(bannerLocalConfig)
                imBannerViewModel.nativeAdOutput
                    .subscribe(onNext: { (nativeAd) in
                            let localTemp = LocalTempAdConfig(bannerLocalConfig, adType:.inmobi(nativeAd))
                            bannerOutput.onNext(localTemp)
                        }, onError: { (error) in
                            bannerOutput.onNext(nil)
                    })
                    .disposed(by: weakSelf.bag)
                weakSelf.bannenrViewModel = imBannerViewModel
            })
            .disposed(by: bag)
      
        /// banner 广告加载失败
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.bookDetailMedium.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: bannerConfigoutput)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.bookDetailMedium.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .bind(to: bannerConfigoutput)
            .disposed(by: bag)
    }
    
    deinit {
        print("BookDetailViewModel deinit!!!")
    }
}
