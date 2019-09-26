//
//  RankViewModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxMoya
import Moya

class RankViewModel: NSObject {

    let viewDidLoad: PublishSubject<Void> = .init()
    
    let subViewModels: Observable<[RankSubViewModel]>
    
    init(_ provider: MoyaProvider<BookInfoService>? = nil) {
        
        subViewModels = viewDidLoad
            .map{
                [RankSubViewModel("click"),RankSubViewModel("collect"),RankSubViewModel("wanben")]
        }
    }
}
