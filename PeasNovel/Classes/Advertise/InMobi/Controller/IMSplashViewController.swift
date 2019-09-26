//
//  IMSplashViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK

class IMSplashViewController: BaseViewController {
    @IBOutlet weak var splashContainerView: UIView!
    @IBOutlet weak var jumpBtn: UIButton!
    @IBOutlet weak var logoBottom: NSLayoutConstraint!
    
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    convenience init(_ viewModel: IMSplashViewModel) {
        self.init(nibName: "IMSplashViewController", bundle: nil)
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
    
    private func config(_ viewModel: IMSplashViewModel) {
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
                UIButton.countDown(4, inputView: self.jumpBtn, countDownTitle: "跳过", normalTitle: "跳过",isEnableWhenCounting: true, countDownFinish: { () -> (Void) in
                       NotificationCenter.default.post(name: NSNotification.Name.Advertise.splashNeedDismiss, object: nil)
                })
                self.splashContainerView.addSubview(adView)
            })
            .disposed(by: bag)
        
        jumpBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { _ in
                NotificationCenter.default.post(name: NSNotification.Name.Advertise.splashNeedDismiss, object: nil)
            })
            .disposed(by: bag)
       
    }
        

}
