//
//  SettingViewModel.swift
//  ClassicalMusic
//
//  Created by lieon wang on 2019/1/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources
import Kingfisher
import RxCocoa

class SettingViewModel {
    
    let viewDidLoad: PublishSubject<Void> = .init()
    let itemSelected: PublishSubject<(String, String)> = .init()
    let bag = DisposeBag()
    let section: Observable<[SectionModel<String, (String, String)>]>
//    let qualityViewModel: Observable<QualityViewModel>
    let aboutAction: Observable<Void>
    
    init() {
    
        let sizeVar = BehaviorRelay(value: "0M")
        
        section = viewDidLoad
            // section 0
            .flatMap {
                sizeVar.asObservable()
            }
            .map{ [(NSLocalizedString("clearCache", comment: ""), $0),
                   (NSLocalizedString("about", comment: ""), "")] }
            .map{ [SectionModel(model: "section0", items: $0)]}
        
//        qualityViewModel = itemSelected
//            .filter{ $0.0 == NSLocalizedString("quality", comment: "") }
//            .map{ _ in QualityViewModel() }
//
        aboutAction = itemSelected
            .filter{ $0.0 == NSLocalizedString("about", comment: "") }
            .mapToVoid()
        
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                let str =  String(format: "%.1f", Double(size) / 1024 / 1024) +  "MB"
                sizeVar.accept(str)
            case .failure(let error):
                print(error)
            }
        }
        
        itemSelected
            .filter{ $0.0 == NSLocalizedString("clearCache", comment: "") }
            .flatMap {_, _ in
                DefaultWireframe.shared.promptFor(title: nil, message: NSLocalizedString("clearCache", comment: ""), cancelAction: NSLocalizedString("cancle", comment: ""), actions: [NSLocalizedString("enter", comment: "")])
        }
            .filter { $0 == NSLocalizedString("enter", comment: "")}
            .subscribe(onNext: { (_) in
                ImageCache.default.clearDiskCache()
                sizeVar.accept("0M")
            })
            .disposed(by: bag)
    }
    
   

}
