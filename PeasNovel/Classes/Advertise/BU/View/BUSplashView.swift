//
//  BUSplashView.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BUSplashView: UIView {
    var needDismiss: (() -> Void)?
    fileprivate lazy var bottomView: GDTSplashBottomView = {
        let bottomView = GDTSplashBottomView.loadView()
        return bottomView
    }()
    
    let bottomViewHeight: CGFloat = 74 + UIDevice.current.safeAreaInsets.bottom
    var config: LocalAdvertise?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bottomView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
         bottomView.frame = CGRect(x: 0, y: bounds.height - bottomViewHeight , width: bounds.width, height: bottomViewHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(_ config: LocalAdvertise) {
        self.init()
        DispatchQueue.main.async {
            self.isHidden = true
            self.config = config
            let splashView = BUSplashAdView(slotID: config.ad_position_id, frame: CGRect(x: 0, y: 0 , width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - self.bottomViewHeight))
            splashView.tolerateTimeout = 3
            splashView.loadAdData()
            splashView.delegate = self
            self.addSubview(splashView)
            splashView.rootViewController = UIViewController.current()!
        }
    }
}

extension BUSplashView: BUSplashAdDelegate, Advertiseable {
    func splashAdDidClick(_ splashAd: BUSplashAdView) {
        adClickNotification(config)
    }
    
    func splashAdDidClose(_ splashAd: BUSplashAdView) {
        splashAd.removeFromSuperview()
        needDismiss?()
    }

    func splashAdDidLoad(_ splashAd: BUSplashAdView) {
        isHidden = false
        adLoadedNotification(config)
    }
    
    func splashAdWillVisible(_ splashAd: BUSplashAdView) {
        adExposedNotification(config)
    }
    
    func splashAd(_ splashAd: BUSplashAdView, didFailWithError error: Error) {
         isHidden = true
         removeFromSuperview()
        errorNotification(config)
        needDismiss?()
    }
    
    func splashAdWillClose(_ splashAd: BUSplashAdView) {
        isHidden = true
    }
}
