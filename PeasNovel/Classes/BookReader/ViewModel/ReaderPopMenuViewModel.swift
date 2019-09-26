//
//  RaderPopMenuViewModel.swift
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


class ReaderPopMenuViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let addBookshelfAction: PublishSubject<Void> = .init()
    let bookDetailInput: PublishSubject<Void> = .init()
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let modelSelected: PublishSubject<PopMenuItem> = .init()
    
    /// output
    let bookDetailOutput: Driver<BookDetailViewModel>
    let isAddedStatus: Driver<Bool>
    let reportOutput: PublishSubject<ChapterReportViewModel> = .init()
    let catelogOutput: PublishSubject<BookCatalogViewModel> = .init()
    let downloadOutput: PublishSubject<ChooseChapterViewModel> = .init()
    
    
    init(_ bookId: String, contentId: String? = nil ) {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        errorDriver = errorTracker.asDriver()
        
        activityDriver = activityIndicator.asDriver()
       let  provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()
        isAddedStatus = addBookshelfAction
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
            .map{ $0 == 0 }
            .asDriver(onErrorJustReturn: false)
        
        bookDetailOutput = bookDetailInput.map {
                                            BookDetailViewModel(bookId)
                                            }
                                        .asDriverOnErrorJustComplete()
        
         modelSelected
            .asObservable()
            .filter { $0.nname == "章节报错"}
            .map { _ in ChapterReportViewModel(bookId, contentId: contentId ?? "1")}
            .bind(to: reportOutput)
            .disposed(by: bag)
        
        modelSelected
            .asObservable()
            .filter { $0.nname == "下    载"}
            .map { _ in ChooseChapterViewModel(bookId)}
            .bind(to: downloadOutput)
            .disposed(by: bag)
        
        modelSelected
            .asObservable()
            .filter { $0.nname == "目    录"}
            .map { _ in BookCatalogViewModel(bookId)}
            .bind(to: catelogOutput)
            .disposed(by: bag)
        
        
    }
}
