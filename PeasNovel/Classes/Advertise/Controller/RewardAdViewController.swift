//
//  RewardAdViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import PKHUD
import RxCocoa
import Alamofire

class RewardAdViewController: BaseViewController {
    private var isPresent: Bool = false
    
    convenience init(_ viewModel: RewardAdViewModel) {
        self.init(nibName: "RewardAdViewController", bundle: nil)
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
        view.backgroundColor = UIColor.clear
        HUD.show(.progress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func config(_ viewModel: RewardAdViewModel) {
        
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period:  RxTimeInterval.seconds(10), scheduler: MainScheduler.instance)
            .skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self]_ in
                guard let weakSelf = self else {
                    return
                }
                guard  weakSelf.isPresent == false else {
                    return
                }
                HUD.hide(animated: true)
                weakSelf.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name.Advertise.loadFail, object: viewModel.config)
                })
                
            })
            .disposed(by: bag)
        
        viewModel.adOutput
            .subscribe(onNext: { [weak self](temp) in
                guard let weakSelf = self else {
                    return
                }
                HUD.hide()
                weakSelf.isPresent = true
                NotificationCenter.default.post(name: NSNotification.Name.Advertise.rewardVideoLoadSuccess, object: viewModel.config)
                switch temp.adType {
                case .inmobi(let rewardVideo):
                    if let rewardVideo = rewardVideo as? IMInterstitial, let weakSelf = self {
                        rewardVideo.show(from: weakSelf)
                    }
                case .todayHeadeline(let rewardVideo):
                    if let rewardVideo = rewardVideo as? BURewardedVideoAd, let weakSelf = self {
                        rewardVideo.show(fromRootViewController: weakSelf)
                    }
                default:
                    if let weakSelf = self {
                         weakSelf.dismiss(animated: true, completion: nil)
                    }
                }
                }, onError: {[weak self] _ in
                    guard let weakSelf = self else {
                        return
                    }
                    HUD.hide(animated: true)
                    weakSelf.dismiss(animated: true, completion: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.Advertise.loadFail, object: viewModel.config)
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
                    NotificationCenter.default.post(name: NSNotification.Name.Advertise.rewardVideoAdWillDismiss, object: config)
                })
            })
            .disposed(by: bag)
        
    }
}

