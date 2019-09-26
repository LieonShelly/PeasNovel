//
//  ChargeAlertViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/10.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChargeAlertViewController: BaseViewController {
    @IBOutlet weak var adBtn: UIButton!
    @IBOutlet weak var coverBtn: UIButton!
    @IBOutlet weak var vipBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    convenience init(_ viewModel: ChargeAlertViewModel) {
        self.init()
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    private func config(_ viewModel: ChargeAlertViewModel) {
        vipBtn.setTitle(CommomData.share.switcherConfig.value?.buy_vip ?? false ? "0元免广告阅读": "购买VIP会员免广告" , for: .normal)
        vipBtn.rx.tap.map { ChargeViewModel()}
            .subscribe(onNext: {[weak self] in
                self?.navigationController?.pushViewController(ChargeViewController($0), animated: true)
            })
            .disposed(by: bag )
        
        coverBtn.rx.tap.mapToVoid()
            .subscribe(onNext: {[weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag )
        
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: {[weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag )
        
        adBtn.rx.tap.map { AdvertiseService.advertiseConfig(.readerRewardVideoAd)}
            .unwrap()
            .filter { !$0.is_close }
            .mapToVoid()
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: false, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name.Event.dismissAdChapter, object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.Advertise.presentRewardVideoAd, object: nil)
                })
            })
            .disposed(by:self.bag )
    
       
    }

}
