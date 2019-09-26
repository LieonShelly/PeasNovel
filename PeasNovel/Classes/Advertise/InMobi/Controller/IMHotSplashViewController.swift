//
//  IMHotSplashViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import PKHUD
import RxCocoa

class IMHotSplashViewController: BaseViewController {
    @IBOutlet weak var splashContainerView: UIView!
    @IBOutlet weak var jumpBtn: UIButton!
    @IBOutlet weak var logoBottom: NSLayoutConstraint!
    
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    convenience init(_ viewModel: IMHotSplashViewModel) {
        self.init(nibName: "IMHotSplashViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
            containerHeight.constant = 74 + view.safeAreaInsets.bottom
        } else {
            containerHeight.constant = 74
        }
    }
    
    private func config(_ viewModel: IMHotSplashViewModel) {
        jumpBtn.isHidden = true
        jumpBtn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        jumpBtn.layer.cornerRadius = 15
        jumpBtn.layer.masksToBounds = true
        
        viewModel.nativeAdOutput
            .subscribe(onNext: { (natiAd) in
                self.jumpBtn.isHidden = false
                guard let adView = natiAd.primaryView(ofWidth: UIScreen.main.bounds.width) else {
                    return
                }
                UIButton.countDown(4, inputView: self.jumpBtn, countDownTitle: "跳过", normalTitle: "跳过",isEnableWhenCounting: true, countDownFinish: { [weak self]() -> (Void) in
                    self?.dismiss(animated: true, completion: nil)
                })
                self.splashContainerView.addSubview(adView)
            }, onError: { [weak self]_ in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period:  RxTimeInterval.seconds(4), scheduler: MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: {[weak self]_ in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.dismiss(animated: true, completion: nil)
             })
            .disposed(by: bag)
        
        jumpBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { [weak self] _ in
                 self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
    }
    
    
}

