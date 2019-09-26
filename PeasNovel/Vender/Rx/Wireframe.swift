//
//  Wireframe.swift
//  Arab
//
//  Created by lieon on 2018/10/22.
//  Copyright © 2018 kanshu.com. All rights reserved.
//


import RxSwift

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

enum RetryResult {
    case retry
    case cancel
}

protocol Wireframe {
    func open(url: URL)
    func promptFor( title: String?, message: String, cancelAction: String, actions: [String]) -> Observable<String>
}


class DefaultWireframe: Wireframe {
    static let shared = DefaultWireframe()
    private var isOnScreen: Bool = false
    func open(url: URL) {
       if UIApplication.shared.canOpenURL(url) {
            navigator.push(url)
        }
    }
    

    static func presentAlert( title: String, message: String) {
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "好的", style: .cancel) { _ in
        })
        navigator.present(alertView)
    }
    
    func promptFor( title: String?, message: String, cancelAction: String, actions: [String]) -> Observable<String> {
        if isOnScreen {
            return Observable.create {_ in Disposables.create()}
        }
        return Observable.create { [weak self] observer in
            guard let weakSelf = self else {
                return Disposables.create()
            }
            let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: cancelAction, style: .cancel) { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                observer.on(.next(cancelAction))
                 weakSelf.isOnScreen = false
            })
            
            for action in actions {
                alertView.addAction(UIAlertAction(title: action, style: .default) { [weak self] _ in
                    guard let weakSelf = self else {
                        return
                    }
                    observer.on(.next(action))
                     weakSelf.isOnScreen = false
                })
            }
           navigator.present(alertView)
          weakSelf.isOnScreen = true
            return Disposables.create {
                alertView.dismiss(animated:false, completion: {[weak self] in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.isOnScreen = false
                })
            }
        }
    }
    
    func promptAlert( title: String?, message: String) -> Observable<String> {
        if isOnScreen {
            return Observable.create {_ in Disposables.create()}
        }
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        return Observable.create { [weak self]observer in
            guard let weakSelf = self else {
                return Disposables.create()
            }
            alertView.addAction(UIAlertAction(title: "好的", style: .cancel) { _ in
                 observer.on(.next("好的"))
                 weakSelf.isOnScreen = false
            })
            navigator.present(alertView)
            weakSelf.isOnScreen = true
            return Disposables.create {
                alertView.dismiss(animated:false, completion: {
                    weakSelf.isOnScreen = false
                })
            }
        }
    }
    
    func promptForActionSheet( title: String?, message: String, cancelAction: String, actions: [String]) -> Observable<String> {
        return Observable.create { observer in
            let alertView = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alertView.addAction(UIAlertAction(title: cancelAction, style: .cancel) { _ in
                observer.on(.next(cancelAction))
            })
            
            for action in actions {
                alertView.addAction(UIAlertAction(title: action, style: .default) { _ in
                    observer.on(.next(action))
                })
            }
            navigator.present(alertView)
            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
            }
        }
    }
    
    
}

class ReaderRestWireFrame: Wireframe {
    static let shared = ReaderRestWireFrame()
    private var isOnScreen: Bool = false
    func open(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            navigator.push(url)
        }
    }
    
    
    func promptAlert( title: String?, message: String) -> Observable<String> {
        if isOnScreen {
            return Observable.create {_ in Disposables.create()}
        }
        return Observable.create { [weak self]observer in
            guard let weakSelf = self else {
                return Disposables.create()
            }
            let alertView = ReaderRestViewController()
            alertView.modalPresentationStyle = .custom
            alertView.modalTransitionStyle = .crossDissolve
            alertView.rx.viewDidLoad
                .asObservable()
                .subscribe(onNext: { (_) in
                    alertView.contactLabel.text = message
                    alertView.cancleBtn.isHidden = true
                    alertView.contactBtn.isHidden = true
                    alertView.faceBtn.isHidden = false
                })
                .disposed(by: alertView.bag)
            
            
            alertView.forceAction = {
                observer.onNext("好的")
                weakSelf.isOnScreen = false
            }
            alertView.closeAction = {
                weakSelf.isOnScreen = false
            }
        
            navigator.present(alertView)
             weakSelf.isOnScreen = true
            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
                 weakSelf.isOnScreen = false
            }
        }
    }
    
    func promptFor( title: String?, message: String, cancelAction: String, actions: [String]) -> Observable<String> {
        return Observable.create { observer in
            let alertView = ReaderRestViewController()
            alertView.modalPresentationStyle = .custom
            alertView.modalTransitionStyle = .crossDissolve
            alertView.rx.viewDidLoad
                .asObservable()
                .subscribe(onNext: { (_) in
                    alertView.contactLabel.text = message
                    alertView.cancleBtn.isHidden = false
                    alertView.contactBtn.isHidden = false
                    alertView.faceBtn.isHidden = true
                })
                .disposed(by: alertView.bag)
            
            alertView.cancleAction = {
                observer.onNext(cancelAction)
            }
            
            alertView.enterAction = {
                observer.onNext(actions.first ?? "")
            }
            navigator.present(alertView)
            return Disposables.create {
                alertView.dismiss(animated:false, completion: nil)
            }
        }
    }
    
}

extension RetryResult : CustomStringConvertible {
    var description: String {
        switch self {
        case .retry:
            return "Retry"
        case .cancel:
            return "Cancel"
        }
    }
}

