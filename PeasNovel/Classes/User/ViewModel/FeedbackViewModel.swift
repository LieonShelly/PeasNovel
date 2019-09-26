//
//  FeedbackViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import RxMoya


class FeedbackViewModel {
    let sections: Driver<[SectionModel<FeedbackUIType, FeedbackQuestion>]>
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    let contentInput: BehaviorRelay<String> = .init(value: "")
    let contactInput: BehaviorRelay<String> = .init(value: "")
    let questTypeInput: BehaviorRelay<FeedbackQuestion> = .init(value: FeedbackQuestion())
    let submitBtnInput: PublishSubject<Void> = .init()
    let messageOutput: PublishSubject<HUDValue> = .init()
    let questDetailOutput: Driver<QuestionListViewModel>
    let popAction: PublishSubject<Void> = .init()
    
    init() {
        
        let questions = BehaviorRelay<[FeedbackQuestion]>.init(value: [])
        let questionResponse =  BehaviorRelay<FeedbackQuestionResponse>.init(value: FeedbackQuestionResponse())
        let provider = MoyaProvider<FeedbackService>()
        viewDidLoad.asObservable()
            .flatMap {
                provider.rx.request(.questionsList)
                    .model(FeedbackQuestionResponse.self)
                    .asObservable()
        }.bind(to: questionResponse)
            .disposed(by: bag)
        
        questionResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .bind(to: questions)
            .disposed(by: bag)
       
        sections =  questions.asObservable()
            .filter {$0.count > 0 }
            .map { (questions) -> [SectionModel<FeedbackUIType, FeedbackQuestion>] in
                let switcher = CommomData.share.switcherConfig.value
                return [
                    SectionModel<FeedbackUIType, FeedbackQuestion>(model: .normalQuesttion(questions), items: [FeedbackQuestion()]),
                    SectionModel<FeedbackUIType, FeedbackQuestion>(model: .opitionFeedback, items: [FeedbackQuestion(), FeedbackQuestion(), FeedbackQuestion()]),
                    SectionModel<FeedbackUIType, FeedbackQuestion>(model: .onlineService(switcher), items: [FeedbackQuestion()])
                ]
            }.asDriver(onErrorJustReturn: [])
       
        let contentInput = self.contentInput
        let contactInput = self.contactInput
        
        submitBtnInput.asObservable()
            .filter { contentInput.value.isEmpty}
            .map { HUDValue(.label("请输入反馈内容"))}
            .bind(to: messageOutput)
            .disposed(by: bag)
        
        let result = submitBtnInput.asObservable()
            .filter {!contentInput.value.isEmpty}
            .flatMap { _ in
                provider.rx.request(.feedback(["content": contentInput.value, "contact": contactInput.value, "phone_type": "iPhone"]))
                    .model(NullResponse.self)
                    .asObservable()
                    .catchError { Observable.just(NullResponse.commonError($0))}
            }
            .share(replay: 1)

        result
            .filter { $0.status?.code == 0 }
            .mapToVoid()
            .bind(to: popAction)
            .disposed(by: bag)
        
        result
            .map { $0.status?.code == 0 ? "提交成功":  $0.status?.msg ?? ""}
            .map {HUDValue(.label($0))}
            .bind(to: messageOutput)
            .disposed(by: bag)
        
        questDetailOutput = questTypeInput
            .asObservable()
            .filter { $0.id != nil }
            .map { QuestionListViewModel(["category_id": $0.id ?? "", "title": $0.title ?? ""])}
            .asDriverOnErrorJustComplete()
        
    }
}


enum FeedbackUIType {
    case normalQuesttion([FeedbackQuestion])
    case opitionFeedback
    case onlineService(SwitcherConfig?)
    
    var title: String {
        switch self {
        case .normalQuesttion:
            return "常见问题"
        case .opitionFeedback:
            return "意见反馈"
        case .onlineService:
            return "在线客服"
        }
    }
}
