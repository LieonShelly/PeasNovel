//
//  ListenBookAlertViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ListenBookAlertViewController: BaseViewController {
    @IBOutlet weak var adlabel1: UILabel!
    @IBOutlet weak var adlabel0: UILabel!
    @IBOutlet weak var adBtn: UIButton!
    @IBOutlet weak var coverBtn: UIButton!
    @IBOutlet weak var vipBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    @IBOutlet weak var adInputViewHeight: NSLayoutConstraint!
    @IBOutlet weak var vipTop: NSLayoutConstraint!
    @IBOutlet weak var zeroLabelHeight: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        zeroLabelHeight.constant = (CommomData.share.switcherConfig.value?.buy_vip ?? false) ? 25 : 0
    }

    convenience init(_ viewModel: ListenBookAlertViewModel) {
        self.init(nibName: "ListenBookAlertViewController", bundle: nil)
    
        self.rx.viewDidLoad
            .subscribe(onNext: { [weak self](_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }

    private func config(_ viewModel: ListenBookAlertViewModel) {
        vipBtn.setTitle(CommomData.share.switcherConfig.value?.buy_vip ?? false ? "0元免广告阅读": "购买VIP会员免广告" , for: .normal)
        vipBtn.rx.tap.map { ChargeViewModel()}
            .subscribe(onNext: {[weak self] in
                self?.navigationController?.pushViewController(ChargeViewController($0), animated: true)
            })
            .disposed(by: bag )
        
        Observable.merge( closeBtn.rx.tap.mapToVoid(),
                           coverBtn.rx.tap.mapToVoid())
            .subscribe(onNext: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.view.removeFromSuperview()
                weakSelf.removeFromParent()
            })
            .disposed(by: bag )
        
        adBtn.rx.tap.map { AdvertiseService.advertiseConfig(.readerViedeoAdListenBook)}
            .debug()
            .unwrap()
            .mapToVoid()
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self,  let vcc = RewardVideoService.chooseVC(.readerViedeoAdListenBook, isForceOpen: true) else {
                    return
                }
                weakSelf.present(vcc, animated: true, completion: nil)
            })
            .disposed(by:self.bag )
        
        viewModel.hiddenAdOutput
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (isHidden) in
                guard let weakSelf = self else {
                    return
                }
                if isHidden {
                    weakSelf.vipTop.constant = 0
                    weakSelf.adInputViewHeight.constant = 0
                    weakSelf.containerHeight.constant -= 80
                    weakSelf.adlabel0.isHidden = true
                     weakSelf.adlabel1.isHidden = true
                } else {
                    weakSelf.vipTop.constant = 30
                    weakSelf.adInputViewHeight.constant = 80
                    weakSelf.containerHeight.constant = 300
                    weakSelf.adlabel0.isHidden = false
                    weakSelf.adlabel1.isHidden = false
                }
                weakSelf.view.layoutIfNeeded()
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerViedeoAdListenBook.rawValue }
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.view.removeFromSuperview()
                weakSelf.removeFromParent()
            })
         .disposed(by: bag)
    }

}
