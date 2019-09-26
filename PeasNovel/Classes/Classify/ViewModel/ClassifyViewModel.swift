//
//  ClassifyViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Moya
import RxMoya

/// 书城 -> 分类
class ClassifyViewModel: NSObject {
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let itemDidSelected: PublishSubject<ClassifyModel> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    
    let sections: Driver<[SectionModel<String?, ClassifyModel>]>
    let classifyListViewModel: Observable<ClassifyListViewModel>
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let activityDriver: Driver<Bool>
    
    
    init(_ provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {
        
        let acitvity = ActivityIndicator()
        sections = Observable.merge([ exceptionInput.asObservable().mapToVoid(), viewDidLoad.asObservable()])
            .flatMap{
                provider
                    .rx
                    .request(.classify)
                    .model(ClassifyResponse.self)
                    .trackActivity(acitvity)
            }
            .map{ $0.data }
            .unwrap()
            .map{ list -> [SectionModel<String?, ClassifyModel>] in
                list.map{
                    SectionModel<String?, ClassifyModel>(model: $0.name, items: $0.list ?? [])
                }
                
            }
            .asDriver(onErrorJustReturn: [])
        
        
        exceptionOuptputDriver = sections.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = sections.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        activityDriver = acitvity.asDriver()
        
        
        classifyListViewModel = itemDidSelected
            .asObservable()
            .map{ ClassifyListViewModel($0) }
        
    }

}
