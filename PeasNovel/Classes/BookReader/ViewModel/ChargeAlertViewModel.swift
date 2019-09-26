//
//  ChargeAlertViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/10.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation

import Foundation
import UIKit
import Moya
import RxMoya
import RxCocoa
import RxSwift
import InMobiSDK

class ChargeAlertViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let videoAdInput: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    
    init() {
       
       
    }
}
