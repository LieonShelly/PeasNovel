//
//  ReaderContainerViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/31.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class ReaderContainerViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
}
