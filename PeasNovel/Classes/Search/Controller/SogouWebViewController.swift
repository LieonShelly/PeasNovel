//
//  SogouWebViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

class SogouWebViewController: BaseViewController {
    var topBannerView: UIView?
    var header: UIView?
    let webTitle: BehaviorRelay<String?> = .init(value: nil)
    
    convenience init(_ viewModel: SogouWebViewModel) {
        self.init(nibName: "SogouWebViewController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.configUI()
                self?.config(viewModel)
                self?.loadAd(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    func config(_ viewModel: SogouWebViewModel) {
        let  rightBtn = UIButton(type: .custom)
        rightBtn.backgroundColor = UIColor.theme
        rightBtn.layer.cornerRadius = 3
        rightBtn.layer.masksToBounds = false
        rightBtn.setTitle(" 书架", for: .normal)
        rightBtn.setImage(UIImage(named: "ic_add"), for: .normal)
        rightBtn.frame = CGRect(x: 0, y: 0, width: 70, height: 24)
       
        let backItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: nil, action: nil)
        let closeItem = UIBarButtonItem(title: "关闭", style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItems = [backItem, closeItem]
        closeItem.rx.tap
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
        
        backItem.rx.tap
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                if weakSelf.webView.canGoBack {
                    weakSelf.webView.goBack()
                }
            })
            .disposed(by: bag)
        
        webView.navigationDelegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBtn)
        view.addSubview(self.webView)
        rightBtn.rx.tap
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self, let urlStr = weakSelf.webView.url?.absoluteString else {
                    return
                }
                var title = viewModel.title
                if let currentTitle = weakSelf.webTitle.value, !currentTitle.isEmpty {
                    title = currentTitle
                }
                let vcc = SogouAlterAddViewController(SogouAddAlterViewModel(urlStr, title: title))
                vcc.modalPresentationStyle = .custom
                vcc.modalTransitionStyle = .crossDissolve
                navigator.present(vcc)
            })
            .disposed(by: bag)
        
        viewModel
            .request
            .subscribe(onNext: { [weak self] in
                self?.webView.load($0)
            })
            .disposed(by: bag)
        
        let isShowGuide = UserDefaults.standard.value(forKey: Constant.UserDefaultsKey.sogouSearchGudieGuidePage) as? Bool  ?? false
        if !isShowGuide {
            let guideView = UIView()
            guideView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            UIApplication.shared.keyWindow?.addSubview(guideView)
            let btn = UIButton(type: .custom)
            btn.setBackgroundImage(UIImage(named: "guide_sogou"), for: .normal)
            guideView.addSubview(btn)
            guideView.snp.makeConstraints { $0.edges.equalTo(0)}
            btn.snp.makeConstraints { (maker) in
                maker.top.equalTo(UIApplication.shared.statusBarFrame.height + 30)
                maker.right.equalTo(20)
            }
            btn.rx.tap
                .mapToVoid()
                .subscribe(onNext: { (_) in
                    UserDefaults.standard.set(true, forKey: Constant.UserDefaultsKey.sogouSearchGudieGuidePage)
                    UserDefaults.standard.synchronize()
                    btn.isHidden = true
                    guideView.isHidden = true
                })
                .disposed(by: bag)
        }
        
        webView.rx.observe(String.self, "title")
            .asObservable()
            .bind(to: webTitle)
            .disposed(by: bag)
    }
    
    func configUI() {
       
    }
    
    func loadAd(_ viewModel: SogouWebViewModel) {
        
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


extension SogouWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("SogouWebViewController:\(webView.url?.absoluteString ?? "") - title:\(webView.title)")
    }
}
