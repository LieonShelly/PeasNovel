//
//  RecommendPositionDetailViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/30.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import RxCocoa

public extension BehaviorRelay where Element: RangeReplaceableCollection {
    func insert(_ subElement: Element.Element, at index: Element.Index) {
        var newValue = value
        newValue.insert(subElement, at: index)
        accept(newValue)
    }
    
    func insert(contentsOf newSubelements: Element, at index: Element.Index) {
        var newValue = value
        newValue.insert(contentsOf: newSubelements, at: index)
        accept(newValue)
    }
    
    func remove(at index: Element.Index) {
        var newValue = value
        newValue.remove(at: index)
        accept(newValue)
    }
    
}

class RecommendPositionDetailViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    /// input
    let bookTapInput: PublishSubject<RecommendBook> = .init()
    let refreshInput: PublishSubject<Bool> = .init()
    
    /// output
    let dataSources: Driver<[SectionModel<RecommendPositionDetailViewType, RecommendBook>]>
    let booktapOutput: Driver<RecommendBook>
    let refreshStatusOutput: PublishSubject<RefreshStatus> = .init()
    
    
    init(_ param: [String: String]) {
        let provider = MoyaProvider<BookMallService>()
        let otherRecommendBookResponse = BehaviorRelay<OtherRecommendBookResponse>(value: OtherRecommendBookResponse())
        let moreDataRecommendBookResponse = BehaviorRelay<OtherRecommendBookResponse>(value: OtherRecommendBookResponse())
        let otherRecommendBooks = BehaviorRelay<[RecommendBook]>(value: [])
         let page = BehaviorRelay<Int>.init(value: 2)
        viewDidLoad
            .asObservable()
            .flatMap { _ in
                provider.rx.request(BookMallService.recommendPostionDetail(param))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
                    .debug()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: otherRecommendBookResponse)
            .disposed(by: bag)
        
        otherRecommendBookResponse.asObservable()
            .skip(1)
            .map {$0.data}
            .unwrap()
            .debug()
            .bind(to: otherRecommendBooks)
            .disposed(by: bag)
    
        
        dataSources = otherRecommendBooks.asObservable()
            .filter {!$0.isEmpty}
            .map({ (lists) -> [SectionModel<RecommendPositionDetailViewType, RecommendBook>] in
                let count: Double = Double(lists.count)
                var sections: [SectionModel<RecommendPositionDetailViewType, RecommendBook>] = []
                if count <= 3 {
                     let section = SectionModel<RecommendPositionDetailViewType, RecommendBook>(model: RecommendPositionDetailViewType.horison, items:Array(lists[0 ..< 3]))
                     sections.append(section)
                } else {
                    let section = SectionModel<RecommendPositionDetailViewType, RecommendBook>(model: RecommendPositionDetailViewType.horison, items:Array(lists[0 ..< 3]))
                    sections.append(section)
                    let section1 = SectionModel<RecommendPositionDetailViewType, RecommendBook>(model: RecommendPositionDetailViewType.veritical, items:Array(lists[3 ..< lists.count]))
                    sections.append(section1)
                    
                }
                return sections
            })
            .asDriver(onErrorJustReturn: [])
        
        
        booktapOutput = bookTapInput.asObservable()
            .filter { $0.book_id != nil }
            .map {$0}
            .unwrap()
            .asDriverOnErrorJustComplete()
        
        var param = param
        /// 上拉加载
        refreshInput.asObservable().filter {$0 == false}
            .map({ (_) -> [String: String] in
                param["page"] = "\(page.value)"
                return param
            })
            .flatMap {
                provider.rx.request(.recommendPostionDetail($0))
                    .model(OtherRecommendBookResponse.self)
                    .asObservable()
                    .debug()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: moreDataRecommendBookResponse)
            .disposed(by: bag)
        
        moreDataRecommendBookResponse.asObservable()
            .map { $0.data }
            .unwrap()
            .subscribe(onNext: {[weak self] (moreBooks) in
                guard let weakSelf = self else {
                    return
                }
                if moreBooks.isEmpty {
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.noMoreData)
                } else {
                    page.accept(page.value + 1)
                   otherRecommendBooks.accept(otherRecommendBooks.value + moreBooks)
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.endFooterRefresh)
                }
                }, onError: {[weak self]  (_) in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.refreshStatusOutput.onNext(RefreshStatus.error)
            })
            .disposed(by: bag)
        
        
        
    }
}

enum RecommendPositionDetailViewType {
    case horison
    case veritical
}
