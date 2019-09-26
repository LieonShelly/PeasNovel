//
//  ClassifyListViewModel.swift
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

class ClassifyListViewModel: NSObject {
    
    let identify: String
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let exceptionInput: PublishSubject<Void> = .init()
    let subViewModels: Observable<[ClassifyListChildViewModel]>
    let exceptionOuptputDriver: Driver<ExceptionInfo>
    let dataEmpty: Driver<Bool>
    let activityDriver: Driver<Bool>
    
    init(_ model: ClassifyModel, provider: MoyaProvider<BookInfoService>? = nil) {
        let acitvity = ActivityIndicator()
        self.identify = model.name ?? ""
        if model.next_category == nil {
            let provider = MoyaProvider<BookInfoService>()
            subViewModels = Observable.merge([exceptionInput.asObservable(), viewDidLoad.asObservable()]) 
                .flatMap{ _ in
                    provider
                        .rx
                        .request(.childClassify(["category_id_1":model.category_id ?? ""]))
                        .model(ClassifyModelReponse.self)
                        .trackActivity(acitvity)
                }
                .map{ $0.data }
                .unwrap()
                .map {$0.next_category}
                .unwrap()
                .map {   $0.map {ClassifyListChildViewModel($0)}}
        } else {
            subViewModels = viewDidLoad
                .map{ model }
                .map{ $0.next_category }
                .unwrap()
                .map{ models -> [ClassifyListChildViewModel] in
                    models.map{
                        ClassifyListChildViewModel($0)
                    }
            }
        }
       
        exceptionOuptputDriver = subViewModels.asObservable()
            .map {$0.count }
            .map{ ExceptionInfo.commonRetry($0)}
            .asDriver(onErrorJustReturn: ExceptionInfo.commonRetry(0))
        
        dataEmpty = subViewModels.asObservable()
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
        
        activityDriver = acitvity.asDriver()
        
    }
    


}
