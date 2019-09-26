//
//  ReaderContainerViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/31.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReaderContainerViewController: BaseViewController {

    convenience init(_ viewModel: ReaderContainerViewModel) {
        self.init()
        
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        self.rx
            .viewWillAppear
            .bind(to: viewModel.viewWillAppear)
            .disposed(by: bag)
        
        self.rx
            .viewWillDisappear
            .bind(to: viewModel.viewWillDisappear)
            .disposed(by: bag)
        
    }
    
}
