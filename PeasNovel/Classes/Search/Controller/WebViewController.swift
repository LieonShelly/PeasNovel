//
//  WebViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/5/15.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: BaseViewController {
    var topBannerView: UIView?
    var header: UIView?
    
    convenience init(_ viewModel: WebViewModel) {
        self.init(nibName: "WebViewController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [unowned self] in
                self.configUI()
                self.config(viewModel)
                self.loadAd(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    func config(_ viewModel: WebViewModel) {
        
        viewModel
            .request
            .subscribe(onNext: { [unowned self] in
                self.webView.load($0)
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        view.addSubview(self.webView)
    }
    
    func loadAd(_ viewModel: WebViewModel) {
      
        viewModel.bannerOutput
            .asObservable()
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let bannerView = weakSelf.setupBottombannr(config.localConfig)
                 ViewBannerSerVice.configData(config, bannerView: bannerView)
            })
            .disposed(by: bag)
        viewModel
            .bannerAdConfigOutput
            .asObservable()
            .unwrap()
            .filter { !$0.is_close}
            .filter { $0.ad_type == AdvertiseType.GDT.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let gdtViewModel = GDTBannerViewModel(config, viewController: weakSelf)
                gdtViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .GDT($0))}
                    .bind(to: viewModel.bannerOutput)
                    .disposed(by: viewModel.bag)
                viewModel.bannerViewModel = gdtViewModel
            })
            .disposed(by: bag)
        
        viewModel
            .bannerAdConfigOutput
            .asObservable()
            .unwrap()
            .filter { !$0.is_close}
            .filter { $0.ad_type == AdvertiseType.todayHeadeline.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let buViewModel = BUNativeBannerViewModel(config, viewController: weakSelf)
                buViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .todayHeadeline($0))}
                    .bind(to: viewModel.bannerOutput)
                    .disposed(by: viewModel.bag)
                viewModel.bannerViewModel = buViewModel
            })
            .disposed(by: bag)
        
    }
    
    fileprivate func setupBottombannr(_ config: LocalAdvertise) -> UIView? {
        
        guard let  bottomBanner =  ViewBannerSerVice.chooseBanner(config, bannerFrame: CGRect(x: 0, y: UIScreen.main.bounds.height - 75 - UIDevice.current.safeAreaInsets.bottom, width: UIScreen.main.bounds.width , height: 75 +  UIDevice.current.safeAreaInsets.bottom)) else {
            return nil
        }
        if topBannerView != nil {
            topBannerView?.removeFromSuperview()
        }
        if header != nil {
            header?.removeFromSuperview()
        }
        topBannerView = bottomBanner
        header = UIView()
        header!.backgroundColor = UIColor.white
        view.addSubview(header!)
        header!.snp.makeConstraints {
            $0.left.right.bottom.equalTo(0)
            if #available(iOS 11.0, *) {
                $0.height.equalTo(75 + view.safeAreaInsets.bottom)
            } else {
                 $0.height.equalTo(75)
            }
        }
      
        header!.addSubview(bottomBanner)
        bottomBanner.snp.makeConstraints {
            $0.left.right.bottom.equalTo(0)
            $0.height.equalTo(75)
        }
        return bottomBanner
    }
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: CGRect.zero)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return webView
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }
    

}
