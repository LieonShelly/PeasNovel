//
//  ReaderBookIntroViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import Moya
import RxMoya
import RxCocoa
import RxSwift
import RealmSwift
import Alamofire

class ReaderBookIntroViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewDidDisappear: PublishSubject<Bool> = .init()

    let bag = DisposeBag()
    /// output
    let cpInfoOutput: Observable<ChapterCopyRightInfo>
    
    init(_ cpInfo: ChapterCopyRightInfo) {
        
        cpInfoOutput = viewDidLoad
            .asObservable()
            .map { cpInfo }
        
        viewDidLoad.asObservable()
            .asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Book.didLoadBookIntroPage, object: nil)
            })
            .disposed(by: bag)
        
        viewDidDisappear.asObservable()
            .asObservable()
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: NSNotification.Name.Book.didDisappearBookIntroPage, object: nil)
            })
            .disposed(by: bag)
    }
}
