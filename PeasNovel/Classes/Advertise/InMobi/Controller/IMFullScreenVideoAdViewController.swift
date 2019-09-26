//
//  IMFullScreenVideoAdViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/10.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa

class IMFullScreenVideoAdViewController: BaseViewController {
    var interstitial: IMInterstitial?
    let willDismissAdOutput:  PublishSubject<IMInterstitial> = .init()
    let didDismissAdOutput:  PublishSubject<IMInterstitial> = .init()
    
    convenience init(_ viewModel: IMFullScreenVideoAdViewModel) {
        self.init(nibName: "IMFullScreenVideoAdViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func config(_ viewModel: IMFullScreenVideoAdViewModel) {
        viewModel.interstitialOutput
            .subscribe(onNext: { [weak self](interstitial) in
                interstitial.show(from: self)
                }, onError: {[weak self] (error) in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.dismiss(animated: true, completion: {
                         NotificationCenter.default.post(name: NSNotification.Name.Advertise.loadFail, object: nil)
                    })
            })
            .disposed(by: bag)
        
        viewModel.willDismissAdOutput
            .subscribe(onNext: { [weak self](_) in
                self?.dismiss(animated: true, completion: {
                       NotificationCenter.default.post(name: NSNotification.Name.Advertise.rewardVideoAdWillDismiss, object: viewModel.config)
                })
            })
            .disposed(by: bag)
        
        viewModel.willDismissAdOutput
        .asObservable()
        .bind(to: willDismissAdOutput)
        .disposed(by: bag)

        viewModel.didDismissAdOutput
        .asObservable()
        .bind(to: didDismissAdOutput)
        .disposed(by: bag)
        
    }


}

