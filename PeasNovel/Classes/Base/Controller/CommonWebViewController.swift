//
//  CommonWebViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/31.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import WebKit

class CommonWebViewController: BaseViewController {
    var topBannerView: UIView?
    let header = UIView()
    convenience init(_ viewModel: WebViewModel) {
        self.init(nibName: "CommonWebViewController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [unowned self] in
                self.configUI()
                self.config(viewModel)
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

