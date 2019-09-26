//
//  BaseShelfCollectionViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import StatefulViewController

class BaseShelfCollectionViewController: BaseViewController {

    deinit {
        debugPrint(type(of: self).description() + " deinit!!!")
    }
}


extension Reactive where Base: BaseShelfCollectionViewController {
    
    var exception: Binder<ExceptionInfo> {
        return Binder<ExceptionInfo>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            if control.numOfItem < 0 { control.startLoading() } // 未初始化
            control.numOfItem = value.count
            debugPrint("[BASE] 页面数据共 \(control.numOfItem) 条")
            if value.count > 0 {
                debugPrint("[BASE] 页面数据共 \(control.numOfItem) 条 大于0条，直接返回")
                return
            }
            switch value.type {
            case .none:
                /// 如果正在加载状态，跳过空白页面
                if case .loading = control.lastState { return }
                control.endLoading()
                
            case .empty:
                let emptyView = BookShelfNoContentView.loadView()
                control.emptyView = emptyView
                emptyView.addTarget(control, action: #selector(control.emptyAction))
                debugPrint("[BASE] 正在加载: \(control.lastState.rawValue)， \(control.currentState.rawValue)")
                if case .loading = control.lastState {
                    break
                }
                control.endLoading()
            case .error(let err):
                if let view = control.errorView as? PlaceholderView {
                    view.reload(nil, error: err)
                }else{
                    let errorView = EmptyPlaceholderView.error(err)
                    errorView.addTarget(control, action: #selector(control.errorAction))
                    control.emptyView = errorView
                }
                /// 如果正在加载状态，跳过空白页面
                if case .loading = control.lastState { return }
                control.endLoading(animated: true, error: err, completion: nil)
                
            case .retry(let title, desc: let desc):
                
                if let view = control.emptyView as? PlaceholderView {
                    view.reload(desc)
                }else{
                    let emptyView = EmptyPlaceholderView.empty(desc)
                    emptyView.button.setTitle( title ?? NSLocalizedString("retry", comment: ""), for: .normal)
                    emptyView.addTarget(control, action: #selector(control.retryAction))
                    emptyView.infoLabel.text = desc ?? NSLocalizedString("noData", comment: "")
                    control.emptyView = emptyView
                    
                }
                if case .loading = control.lastState {
                    break
                }
                control.endLoading()
            }
            debugPrint("[BASE] 最后状态: \(control.lastState.rawValue)")
        })
    }
}



