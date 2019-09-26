//
//  Refresh.swift
//  Arab
//
//  Created by lieon on 2018/9/13.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import MJRefresh
import Alamofire
import RxSwift
import RxCocoa

protocol RefreshPageComponent {
    var page: Int { get set }
}


enum RefreshStatus {
    case none
    case beingHeaderRefresh
    case endHeaderRefresh
    case beingFooterRefresh
    case endFooterRefresh
    case noMoreData
    case error
    
}


class RefreshHeader: MJRefreshStateHeader {
    let bag = DisposeBag()
    fileprivate lazy var activityView: UIActivityIndicatorView = UIActivityIndicatorView()
    override var state: MJRefreshState {
        didSet {
            activityView.isHidden = false
            switch state {
            case .idle:
                 activityView.stopAnimating()
                break
            case .pulling:
                let feedback = UIImpactFeedbackGenerator()
                feedback.impactOccurred()
                activityView.stopAnimating()
                break
            case .refreshing:
                activityView.startAnimating()
                break
            default:
                break
            }
        }
    }
    
    
    override func prepare() {
        super.prepare()
        stateLabel.isHidden = true
        lastUpdatedTimeLabel.isHidden = true
        mj_h = 50
        activityView.color = UIColor.theme
        addSubview(activityView)
        
        NotificationCenter.default.rx.notification(Notification.Name.Network.networkChange, object: nil)
            .subscribe(onNext: { [weak self](_) in
                self?.endRefreshing()
            })
            .disposed(by: bag)

    }
    
    override func placeSubviews() {
        super.placeSubviews()
        activityView.center = CGPoint(x: mj_w * 0.5, y: mj_h * 0.5)
    }
    
}

class RefreshFooter: MJRefreshAutoFooter {
    let bag = DisposeBag()
    lazy var loading: RefreshFooterStatusView = RefreshFooterStatusView.loadView()
    override var state: MJRefreshState {
        didSet {
            debugPrint("RefreshFooter State:", state.rawValue)
            switch state {
            case .idle:
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
                let manager = NetworkReachabilityManager()
                if let isReachable = manager?.isReachable, isReachable {
                    loading.label.text = NSLocalizedString("loadingTitle", comment: "")
                    loading.startAnimation()
                } else {
                    state = .idle
                }
            case .noMoreData:
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
}


extension Reactive where Base: UIScrollView {
    var mj_RefreshStatus: Binder<RefreshStatus> {
        return Binder<RefreshStatus>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            switch value {
            case .beingHeaderRefresh:
                control.mj_header.beginRefreshing()
            case .endHeaderRefresh:
                control.mj_header.endRefreshing()
            case .beingFooterRefresh:
                control.mj_footer.beginRefreshing()
            case .endFooterRefresh:
                control.mj_footer.endRefreshing()
            case .noMoreData:
                control.mj_footer.endRefreshingWithNoMoreData()
            default:
                break
            }
        })
    }
}
