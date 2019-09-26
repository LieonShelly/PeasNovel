//
//  FullScreenVideoViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import PKHUD
import RxCocoa

class FullScreenVideoViewController: BaseViewController {
    private var isPresent: Bool = false
    
    convenience init(_ viewModel: FullScreenVideoViewModel) {
        self.init(nibName: "FullScreenVideoViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HUD.show(.progress)
        view.backgroundColor = UIColor.clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func config(_ viewModel: FullScreenVideoViewModel) {
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period:  RxTimeInterval.seconds(10), scheduler: MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: {[weak self]_ in
                guard let weakSelf = self else {
                    return
                }
                guard  weakSelf.isPresent == false else {
                    return
                }
                HUD.hide()
                weakSelf.dismiss(animated: true, completion: {
                     NotificationCenter.default.post(name: NSNotification.Name.Advertise.loadFail, object: nil)
                })
            })
            .disposed(by: bag)

        viewModel.adOutput
            .debug()
            .subscribe(onNext: { [weak self](temp) in
                HUD.hide()
                guard let weakSelf = self else {
                    return
                }
                weakSelf.isPresent = true
                switch temp.adType {
                case .inmobi(let rewardVideo):
                    if let rewardVideo = rewardVideo as? IMInterstitial {
                        rewardVideo.show(from: self!)
                    }
                case .GDT(let rewardVideo):
                    if let rewardVideo = rewardVideo as? GDTRewardVideoAd {
                        rewardVideo.show(fromRootViewController: self!)
                    }
                case .todayHeadeline(let rewardVideo):
                    if let rewardVideo = rewardVideo as? BUFullscreenVideoAd, let weakSelf = self {
                        rewardVideo.show(fromRootViewController: weakSelf)
                    }
                default:
                    weakSelf.dismiss(animated: true, completion: nil)
                }
                },  onError: {[weak self] _ in
                    guard let weakSelf = self else {
                        return
                    }
                    HUD.hide(animated: true)
                    weakSelf.dismiss(animated: true, completion:  {
                         NotificationCenter.default.post(name: NSNotification.Name.Advertise.loadFail, object: nil)
                    })
                   
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.inVideoViewModelWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.dismiss(animated: true, completion: {
                })
            })
            .disposed(by: bag)

    }
}


