//
//  BaseViewController.swift
//  Arab
//
//  Created by lieon on 2018/9/17.
//  Copyright © 2018年 kanshu.com. All rights reserved.
//

import UIKit
import RxSwiftExt
import RxSwift
import RxCocoa
import StatefulViewController
import RxDataSources
import Moya
import RxMoya
import Alamofire
import JXSegmentedView

enum ExceptionType {
    case none
    case empty(String?)
    case error(Error?)
    case retry(btnTitle:String?, desc: String?)
    
    var desc: String {
        switch self {
        case .none:
            return "none"
        case .empty:
            return "empty"
        case .error:
            return "error"
        case .retry(btnTitle: _, desc: _):
            return "retry"

        }
    }
}

struct ExceptionInfo {
    var type: ExceptionType
    var image: UIImage?
    var count: Int = 0
    
    init(_ count: Int = 0,
         type: ExceptionType = .none,
         image: UIImage? = nil) {
        self.count = count
        self.type = type
        self.image = image
    }
    
    static func commonRetry(_ count: Int) -> ExceptionInfo {
       return ExceptionInfo(count, type:  ExceptionType.retry(btnTitle: NSLocalizedString("reload", comment: ""), desc: NSLocalizedString("requestFail", comment: "")), image: UIImage.noContentImage)
    }
    
    static func commonEmpty(_ count: Int) -> ExceptionInfo {
        return ExceptionInfo(count, type:  ExceptionType.empty("没有内容"), image: UIImage.noContentImage)
    }
}

class BaseViewController: UIViewController {
    
    var bag = DisposeBag()
    
    let exception: PublishSubject<ExceptionType> = .init()
    var numOfItem = -1
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupInitialViewState()
    }
    
    @objc  func retryAction() {
        if let view = emptyView as? PlaceholderView {
            exception.on(.next(.retry(btnTitle: view.button.title(for: .normal), desc: view.infoLabel.text)))
        }else{
            exception.on(.next(.retry(btnTitle: nil, desc: nil)))
        }
    }
    
    @objc func emptyAction() {
        exception.on(.next(.empty(nil)))
    }
    
    @objc func errorAction() {
        exception.on(.next(.error(nil)))
    }
    
    deinit {
        debugPrint(type(of: self).description() + " deinit!!!")
    }
}

extension BaseViewController: StatefulViewController {
    
    func hasContent() -> Bool {
        return numOfItem > 0
    }
}

extension Reactive where Base: BaseViewController {
    
    var loading: Binder<Bool> {
        return Binder<Bool>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            if value {
                control.startLoading()
                if control.numOfItem < 0 { control.numOfItem = 0 }  // 初始化
                debugPrint("[BASE] 请求数据: \(control.lastState.rawValue)")
            }else if case .loading = control.lastState {
                control.endLoading()
                debugPrint("[BASE] 请求完毕: \(control.lastState.rawValue)")
            }
        })
    }
    
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
                
            case .empty(let text):
                if let view = control.emptyView as? PlaceholderView {
                    view.reload(text)
                }else{
                    let emptyView = EmptyPlaceholderView.empty(text)
                    emptyView.infoLabel.text = text ?? NSLocalizedString("noData", comment: "")
                    control.emptyView = emptyView
                    
                }
                debugPrint("[BASE] 正在加载: \(control.lastState.rawValue)， \(control.currentState.rawValue)")
                /// 如果正在加载状态，跳过空白页面
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


extension BaseViewController: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        return view
    }
}
