//
//  PictureCaptchaViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import RxCocoa

class PictureCaptchaViewModel {
    let viewDidLoad: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    let sliderXInput: PublishSubject<Float> = .init()
    
    let imageDataOutput: Driver<PictureCaptcha>
    
    init(_ imageWidth: Int, imageHeight: Int) {
        let provider = MoyaProvider<VerifyCodeService>()
        let imageData =  BehaviorRelay(value: PictureCaptcha())
        viewDidLoad.flatMap {
                provider
                    .rx
                    .request(.getPictureCaptcha(["width": imageWidth, "height": imageHeight]))
                    .model(PictureCaptchaResponse.self)
                    .asObservable()
                    .catchError {_ in  Observable.never()}
            }
            .map { $0.data }
            .unwrap()
            .bind(to: imageData)
            .disposed(by: bag)
        
        imageDataOutput = imageData
            .asObservable()
            .skip(1)
            .asDriverOnErrorJustComplete()
        
    }
}
