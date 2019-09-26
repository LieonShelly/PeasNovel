//
//  ChapterReportViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//  章节报错ViewModel


import Foundation
import RxCocoa
import RxSwift
import Moya
import PKHUD

class ChapterReportViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let sections: Driver<[SectionModel<ChapterReportViewSectionType, ChapterReportOption>]>
    let commitBtnInput: PublishSubject<(String)> = .init()
    let messageOutput: Driver<HUDValue>
    let itemSelectInput: BehaviorRelay<ChapterReportOption> = .init(value: ChapterReportOption(5))
    let bag = DisposeBag()
    let commitResult = PublishSubject<NullResponse>.init()
    let selectedItemOutput: BehaviorRelay<ChapterReportOption?> = .init(value: nil)
    let outterDescInput: BehaviorRelay<String> = BehaviorRelay<String>.init(value: "")
    
    init(_ bookId: String,
         contentId: String,
         textDesc: String? = nil,
         selectIndex: Int = 5) {
        let selectedItem = ChapterReportOption(selectIndex)
        selectedItem.isSelected = true
        itemSelectInput.accept(selectedItem)
        viewDidLoad
            .map { selectedItem }
            .bind(to: selectedItemOutput)
            .disposed(by: bag)
        
        viewDidLoad
            .map { textDesc }
            .unwrap()
            .bind(to: outterDescInput)
            .disposed(by: bag)
        
        let items = [ChapterReportOption(0),
                     ChapterReportOption(1),
                     ChapterReportOption(2),
                     ChapterReportOption(3),
                     ChapterReportOption(4),
                     ChapterReportOption(5)]
        
        items[selectIndex].isSelected = true
        let sectiomDatas = BehaviorRelay.init(value: [
            SectionModel<ChapterReportViewSectionType,ChapterReportOption>(model: ChapterReportViewSectionType.desc, items: [ChapterReportOption()]),
            SectionModel<ChapterReportViewSectionType,ChapterReportOption>(model: ChapterReportViewSectionType.items(items), items: items),
            SectionModel<ChapterReportViewSectionType,ChapterReportOption>(model: ChapterReportViewSectionType.textView, items: [ChapterReportOption()]),
            SectionModel<ChapterReportViewSectionType,ChapterReportOption>(model: ChapterReportViewSectionType.commitBtn, items: [ChapterReportOption()])
            ])
        
        sections = viewDidLoad
            .asObservable()
            .flatMap {
                sectiomDatas.asObservable()
            }
            .asDriver(onErrorJustReturn: [])
        
      
        let provider = MoyaProvider<BookReaderService>()
       commitBtnInput
            .withLatestFrom(itemSelectInput, resultSelector: {($1, $0)})
            .flatMap {
                provider.rx.request(.chapterReportError([
                    "book_id": bookId,
                    "content_id": contentId,
                    "feedback_type" : "\($0.0.feedback_type)",
                    "machine": $0.0.machine,
                    "feedback_content": $0.1]))
                .model(NullResponse.self)
                .asObservable()
                .catchError({ (error) -> Observable<NullResponse> in
                    return Observable.just(NullResponse.commonError(error))
                })
            }
            .bind(to: commitResult)
            .disposed(by: bag)
        
        messageOutput = commitResult
            .map { $0.status?.code }
            .debug()
            .unwrap()
            .map { $0 == 0 ? "感谢您的反馈！": "提交失败"}
            .map { HUDValue(.label($0))}
            .asDriver(onErrorJustReturn: HUDValue(.label("")))
        
        itemSelectInput.asObservable()
            .map { (model) -> Int? in
                let index = items.firstIndex(where: { $0.feedback_type == model.feedback_type })
                return index
            }
            .unwrap()
            .subscribe(onNext: { [weak self](index) in
                var newitems = items.map({ (model) -> ChapterReportOption in
                    let model = model
                    model.isSelected = false
                    return model
                })
                newitems[index].isSelected = true
                self?.selectedItemOutput.accept(newitems[index])
                var newSections = sectiomDatas.value
                newSections[1] = SectionModel<ChapterReportViewSectionType,ChapterReportOption>(model: ChapterReportViewSectionType.items(newitems), items: newitems)
                sectiomDatas.accept(newSections)
                
            })
            .disposed(by: bag)

        
    }
    
}


enum ChapterReportViewSectionType {
    case desc
    case items([ChapterReportOption])
    case textView
    case commitBtn
    
    var title: String {
        switch self {
        case .items:
            return "反馈类型："
        default:
            return ""
        }
    }
}


class ChapterReportOption: Model {
    var feedback_type: Int = -1
    var machine: String = UIDevice.current.systemVersion
    var isSelected: Bool = false
    var title: String {
        switch self.feedback_type {
        case 0:
            return "乱码，错别字"
        case 1:
            return "章节错乱"
        case 2:
            return "排版错乱"
        case 3:
            return "内容缺失"
        case 4:
            return "不良内容"
        case 5:
            return "其他"
        default:
            return ""
        }
    }
    
   convenience init(_ type: Int) {
        self.init()
        self.feedback_type = type
    }
}
