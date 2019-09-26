//
//  ReaderShareViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReaderShareViewController: BaseViewController {
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet var btn: [UIButton]!
    @IBOutlet weak var dissmissBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dissmissBtn.rx.tap
            .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
    }

    convenience init(_ viewModel: ShareViewModel) {
        self.init(nibName: "ReaderShareViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: { [weak self](_) in
                self?.config(viewModel)
            })
          .disposed(by: bag)
        
          self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        
    }
    
    private func config(_ viewModel: ShareViewModel) {
        let service = ShareService()
        Observable.merge(NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.shared).mapToVoid(),
                          btn.last!.rx.tap.mapToVoid()
                         )
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        btn.first?.rx.tap.flatMap {
                viewModel.shareResponseOutput.asObservable()
            }
            .filter {$0.data != nil }
            .map {$0.data}
            .unwrap()
            .subscribe(onNext: {
                service.share(SSDKPlatformType.subTypeWechatSession, text: $0.text, imageURLStr: $0.img_url, urlStr: $0.url, title: $0.title)
            })
            .disposed(by: bag)
        
        btn[1].rx.tap.flatMap {
            viewModel.shareResponseOutput.asObservable()
            }
            .filter {$0.data != nil }
            .map {$0.data}
            .unwrap()
            .subscribe(onNext: {
                service.share(SSDKPlatformType.subTypeWechatTimeline, text: $0.text, imageURLStr: $0.img_url, urlStr: $0.url, title: $0.title)
            })
            .disposed(by: bag)
        
        btn[2].rx.tap.flatMap {
            viewModel.shareResponseOutput.asObservable()
            }
            .filter {$0.data != nil }
            .map {$0.data}
            .unwrap()
            .subscribe(onNext: {
                service.share(SSDKPlatformType.typeQQ, text: $0.text, imageURLStr: $0.img_url, urlStr: $0.url, title: $0.title)
            })
            .disposed(by: bag)
        
        
    }
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
             bottomViewHeight.constant = view.safeAreaInsets.bottom
        } else {
            
        }
       
    }
}
