//
//  QuestionListViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxMoya

class QuestionListViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    let itemSelectInput: PublishSubject<FeedbackQuestionDetail> = .init()
    let messageOutput: PublishSubject<HUDValue> = .init()
    let items: Driver<[SectionModel<String, FeedbackQuestionDetail>]>
    let questions = BehaviorRelay<[FeedbackQuestionDetail]>.init(value: [])
    let itemsSelted: PublishSubject<IndexPath> = .init()
    let title: Observable<String>
    
    init( _ param: [String: String]) {
       let questions = self.questions
        let questionResponse =  BehaviorRelay<FeedbackQuestionDetailResponse>.init(value: FeedbackQuestionDetailResponse())
        let provider = MoyaProvider<FeedbackService>()
        
        title = Observable.just(param["title"] ?? "")
        
        viewDidLoad.asObservable()
            .flatMap { _ in
                provider.rx.request(FeedbackService.questionDetailList(param))
                    .model(FeedbackQuestionDetailResponse.self)
                    .asObservable()
            }.bind(to: questionResponse)
            .disposed(by: bag)
        
        questionResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .bind(to: questions)
            .disposed(by: bag)
        
        items =  questions.asObservable()
            .skip(1)
             .map { [SectionModel<String, FeedbackQuestionDetail>(model: "", items: $0)] }
             .asDriver(onErrorJustReturn: [])
        
        itemsSelted.asObservable()
            .map { $0.row }
            .subscribe(onNext: { (index) in
                questions.value[index].isSelected =  !questions.value[index].isSelected 
            })
            .disposed(by: bag)
        
        
    }
}
