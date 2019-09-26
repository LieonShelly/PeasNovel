//
//  BookSheetViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Moya
import RxMoya

class BookSheetViewModel: NSObject {
    
    
    let viewDidLoad = PublishSubject<Void>()
    let viewWillAppear = PublishSubject<Bool>()
    let itemSelected = PublishSubject<BookSheetListModel>()
    
    let sections: Driver<[SectionModel<Void, BookSheetListModel>]>
    let sheetName: Driver<String?>
    let toReader: Observable<BookInfo>
    let bag = DisposeBag()
    
    init(_ bookSheet: BookSheetModel, provider: MoyaProvider<BookInfoService> = MoyaProvider<BookInfoService>()) {        
        toReader = itemSelected
            .map{
                let info = BookInfo()
                info.book_id = $0.book_id
                info.content_id = $0.content_id
                return info
        }
        
        itemSelected
            .subscribe(onNext: {
                print("============= print \($0.book_id)")
                BookInfo.didSelected(for: $0.book_id, date: $0.last_chapter_time)
            })
            .disposed(by: bag)
        
        sections = Observable
            .merge(viewWillAppear.mapToVoid(), viewDidLoad)
            .map{ bookSheet }
            .map{ $0.book_lists }
            .unwrap()
            .map{
                [SectionModel<Void, BookSheetListModel>(model: (), items: $0)]
            }
            .asDriver(onErrorJustReturn: [])
        
        sheetName = viewDidLoad
            .map{ bookSheet }
            .map{ $0.boutique_title }
            .asDriver(onErrorJustReturn: nil)
        
    }

}
