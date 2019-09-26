//
//  ReaderShakingViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import Moya
import RxMoya
import RxCocoa
import RxSwift


class ReaderShakingViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let addBookshelfAction: PublishSubject<Void> = .init()
    let bookDetailInput: PublishSubject<Void> = .init()
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let outterBookList: BehaviorRelay<[ReaderLastPageGuessBook]> = .init(value: [])
    let shackingInput: PublishSubject<Void> = .init()
    var imnativeAdViewModel: IMNativeViewModel?
    var infoAdViewModels: [String: Advertiseable] = [:]
    let infoConfig: BehaviorRelay<LocalAdvertise?> = BehaviorRelay(value: nil)
    /// output
    let dataDriver: Driver<[SectionModel<String, ReaderLastPageGuessBook>]>
    
    init() {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        errorDriver = errorTracker.asDriver()
        activityDriver = activityIndicator.asDriver()
        let adConfig =  AdvertiseService.advertiseConfig(.readerShinkingInfoStream)
        let dataResponse = PublishSubject<ReaderLastPageGuessBookResponse>.init()
        let currentBookList: BehaviorRelay<[ReaderLastPageGuessBook]> = BehaviorRelay(value: [])
        
        let provider = MoyaProvider<BookReaderService>()
        
        outterBookList
            .asObservable()
            .bind(to: currentBookList)
            .disposed(by: bag)
        
        shackingInput
            .asObservable()
            .flatMap {
                provider.rx.request(.shaking)
                    .model(ReaderLastPageGuessBookResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
        }
        .bind(to: dataResponse)
        .disposed(by: bag)
        
        dataResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .filter {_ in adConfig == nil}
            .bind(to: currentBookList)
            .disposed(by: bag)
        
        dataResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .filter {_ in adConfig != nil}
            .filter {_ in adConfig!.is_close == true}
            .bind(to: currentBookList)
            .disposed(by: bag)
        
        dataResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .bind(to: currentBookList)
            .disposed(by: bag)
        
        dataDriver =  viewDidLoad
            .flatMap {
                currentBookList.asObservable()
            }
            .map {
                [SectionModel<String, ReaderLastPageGuessBook>(model: "", items: $0)]
            }
            .asDriver(onErrorJustReturn: [])
        
        let insertIndex = 3
        infoConfig.accept(adConfig)
        infoConfig.asObservable()
            .unwrap()
            .filter { !$0.is_close }
            .flatMap { [weak self] in
                return AdvertiseService.createInfoStreamAdOutput($0, adUIConfigure: self!, configure: { (adViewModel) in
                     self?.infoAdViewModels["\(insertIndex)"] = adViewModel
                }).catchError {_ in Observable.never() }
            }
            .subscribe(onNext: { (adTemConfig) in
                let adBook = ReaderLastPageGuessBook()
                adBook.locaAdTemConfig = adTemConfig
                if insertIndex >= currentBookList.value.count {
                    currentBookList.accept(currentBookList.value + [adBook])
                } else {
                    if  currentBookList.value[insertIndex].locaAdTemConfig != nil {
                        var data = currentBookList.value
                        data[insertIndex] = adBook
                        currentBookList.accept(data)
                    } else {
                        currentBookList.insert(adBook, at: insertIndex)
                    }
                    
                }
            }, onError: { _ in
                
            })
            .disposed(by: bag)
        
        dataResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .subscribe(onNext: {[weak self] (_) in
                 let adConfig =  AdvertiseService.advertiseConfig(.readerShinkingInfoStream)
                self?.infoConfig.accept(adConfig)
            })
            .disposed(by: bag)
        
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerShinkingInfoStream.rawValue }
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: infoConfig)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position ==  AdPosition.readerShinkingInfoStream.rawValue }
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .bind(to: infoConfig)
            .disposed(by: bag)
      
        
    }
    
}

extension ReaderShakingViewModel: AdvertiseUIInterface {}
