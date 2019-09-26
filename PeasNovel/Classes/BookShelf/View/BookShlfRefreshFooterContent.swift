//
//  BookShlfRefreshFooterContent.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import MJRefresh
import Alamofire
import RxSwift
import RxCocoa


class BookShlfRefreshFooterContent: UIView {
    @IBOutlet weak var btn: UIButton!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadingMode()
    }
    
    static func loadView() -> BookShlfRefreshFooterContent {
        guard let view = Bundle.main.loadNibNamed("BookShlfRefreshFooterContent", owner: nil, options: nil)?.first as? BookShlfRefreshFooterContent else {
            return BookShlfRefreshFooterContent()
        }
        return view
    }

    
    func startAnimation() {
        imageView.isHidden = false
        let anima = CABasicAnimation(keyPath: "transform.rotation.z")
        anima.toValue = Float.pi * 2.0
        anima.duration = 2
        anima.isCumulative = true
        anima.repeatCount = Float.infinity
        imageView.layer.add(anima, forKey: "transform.rotation.z")
    }
    
    func stopAnimation() {
        imageView.isHidden = true
        if let _ = imageView.layer.animation(forKey: "transform.rotation.z") {
            imageView.layer.removeAnimation(forKey: "transform.rotation.z")
        }
    }
    
    func tapMode() {
        btn.isHidden = false
        label.isHidden = true
        imageView.isHidden = true
    }
    
    func loadingMode() {
        btn.isHidden = true
        label.isHidden = false
        imageView.isHidden = false
    }

}


class BookShelfRefreshFooter: MJRefreshAutoFooter {
    let bag = DisposeBag()
    lazy var loading: BookShlfRefreshFooterContent = BookShlfRefreshFooterContent.loadView()
    var noreDatatapAction: (() -> Void)?
    
    override var state: MJRefreshState {
        didSet {
            switch state {
            case .idle:
                loading.loadingMode()
                let manager = NetworkReachabilityManager()
                if let isReachable = manager?.isReachable, isReachable {
                    loading.label.text = NSLocalizedString("loadTitle", comment: "")
                    loading.stopAnimation()
                } else {
                    loading.label.text = NSLocalizedString("networkError", comment: "")
                    loading.stopAnimation()
                }
                break
            case .refreshing:
                 loading.loadingMode()
                let manager = NetworkReachabilityManager()
                if let isReachable = manager?.isReachable, isReachable {
                    loading.label.text = NSLocalizedString("loadingTitle", comment: "")
                    loading.startAnimation()
                } else {
                    state = .idle
                }
            case .noMoreData:
                loading.tapMode()
                loading.label.text = NSLocalizedString("noreDataTitle", comment: "")
                loading.stopAnimation()
            default:
                break
            }
        }
    }
    
    
    override func prepare() {
        super.prepare()
        mj_h = 50
        loading.frame = self.bounds
        addSubview(loading)
        loading.btn.addTarget(self, action: #selector(self.btnAction), for: .touchUpInside)
        NotificationCenter.default.rx.notification(Notification.Name.Network.networkChange, object: nil)
            .subscribe(onNext: { [weak self](_) in
                self?.endRefreshing()
            })
            .disposed(by: bag)
        
    }
    
    override func placeSubviews() {
        super.placeSubviews()
        
        loading.center = CGPoint(x: self.mj_w * 0.5, y: self.mj_h * 0.5)
    }
    
    @objc fileprivate func btnAction() {
        noreDatatapAction?()
    }
}

