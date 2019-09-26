//
//  GDTRewardVideoViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class GDTRewardVideoViewController: BaseViewController {
    
    convenience init(_ viewModel: GDTRewardVideoViewModel) {
        self.init(nibName: "GDTRewardVideoViewController", bundle: nil)
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
    
    private func config(_ viewModel: GDTRewardVideoViewModel) {
        viewModel.rewardVideoAdOutput
            .subscribe(onNext: { [weak self](rewardVideoAd) in
                rewardVideoAd.show(fromRootViewController: self!)
                }, onError: {[weak self] (error) in
                    guard let weakSelf = self else {
                        return
                    }
                    DefaultWireframe.shared.promptFor(title: "", message: "广告加载失败", cancelAction: "确认", actions: [])
                        .subscribe(onNext: { (_) in
                            self?.dismiss(animated: true, completion: nil)
                        })
                        .disposed(by: weakSelf.bag)
            })
            .disposed(by: bag)
        
        viewModel.willDismissAdOutput
            .subscribe(onNext: { [weak self](interstitial) in
                self?.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name.Advertise.rewardVideoAdWillDismiss, object: viewModel.config)
                })
            })
            .disposed(by: bag)
    }
}
