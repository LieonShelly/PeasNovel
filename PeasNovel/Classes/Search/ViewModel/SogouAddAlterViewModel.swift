//
//  SogouAddAlterViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation

import UIKit
import RxSwift
import WebKit
import RxCocoa
import PKHUD
import Moya

class SogouAddAlterViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    let enterBtnInput: PublishSubject<String> = .init()
    let queryResult: PublishSubject<SogouAddModel> = .init()
    let messageOutput: PublishSubject<String> = .init()
    let addResult: PublishSubject<ReponseResult> = .init()
    let inputTitle: PublishSubject<String> = .init()
    
    init(_ inputURL: String, title: String) {
        let provider = MoyaProvider<SearchService>()
        viewDidLoad
            .map { title }
            .bind(to: inputTitle)
            .disposed(by: bag)
        
        viewDidLoad
            .flatMap {
                provider.rx.request(.isAddSogouLink(["link": inputURL.addingPercentEncoding(.urlQueryAllowed), "link_type": "0"]))
                .model(SogouResponse.self)
                .asObservable()
            }
            .map { $0.data }
            .unwrap()
            .debug()
            .bind(to: queryResult)
            .disposed(by: bag)
        
        enterBtnInput.asObservable()
            .flatMap {
                provider.rx.request(.addSogouLink(["link": inputURL.addingPercentEncoding(.urlQueryAllowed),
                                                   "collect_title": $0,
                                                   "link_type": "0"]))
                    .model(SogouResponse.self)
                    .asObservable()
                    .catchError { _ in Observable.never() }
            }
            .map { $0.status }
            .unwrap()
            .bind(to: addResult)
            .disposed(by: bag)
        
        addResult
            .filter { $0.code == 0 }
            .map { _ in "成功添加到豆豆书架"}
            .bind(to: messageOutput)
            .disposed(by: bag)
        
        addResult
            .filter { $0.code != 0 }
            .map {_ in "添加到豆豆书架失败"}
            .bind(to: messageOutput)
            .disposed(by: bag)
        
        addResult.asObservable()
            .filter { $0.code == 0 }
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Book.addbookshelf, object: nil)
            })
            .disposed(by: bag)
    }
}
