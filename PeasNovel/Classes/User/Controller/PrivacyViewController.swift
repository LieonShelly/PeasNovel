//
//  PrivacyViewController.swift
//  Arab
//
//  Created by weicheng wang on 2018/12/6.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import UIKit
import PKHUD
import Moya
import WebKit

class PrivacyViewController: BaseViewController {
    
    
    var isUpdate = true
    var flag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("userPrivacy", comment: "")
        
        view.insertSubview(webView, at: 0)
        
        webView.snp.makeConstraints{
            $0.trailing.equalTo(0)
            $0.top.equalTo(0)
            $0.leading.equalTo(0)
            $0.bottom.equalTo(0)
        }
        
        guard let url = URL(string: "https://dd.xyxsc.com/doudou/message/yinsiquanzhengce/?app_id=82524829") else {
            return
        }
        load(url)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.statusBarBackgroundColor(color: UIColor.white)
        
    }
    
    func load(_ url: URL) {
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: 15)
        webView.load(request)
        PKHUD.sharedHUD.loading()
    }
    // MARK: action
//    @IBAction func retryAction(_ sender: UIButton) {
//        guard let url = URL(string: NBAPI.index) else {
//            return
//        }
//        //        loadIndicatorView.startAnimating()
//        retryButton.isHidden = true
//        load(url)
//    }
    
    // MARK: private
    private func statusBarBackgroundColor(color: UIColor) {
        guard let statusWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow else {
            return
        }
        guard let statusBar = statusWindow.value(forKey: "statusBar") as? UIView else {
            return
        }
        statusBar.backgroundColor = color
    }
    // MARK: getter
    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        config.userContentController = userContentController
        let webView = WKWebView(frame: CGRect(origin: CGPoint.zero, size: UIScreen.main.bounds.size),
                                configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        let set = WKWebsiteDataStore.allWebsiteDataTypes()
        
        return webView
    }()
}

extension PrivacyViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PKHUD.sharedHUD.dismiss()
        
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PKHUD.sharedHUD.dismiss()
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        PKHUD.sharedHUD.dismiss()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
        
    }
    
    //    webview
}

extension PrivacyViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
}

extension PrivacyViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
}
