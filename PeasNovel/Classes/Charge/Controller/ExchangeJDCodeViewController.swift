//
//  ExchangeJDCodeViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import PKHUD

class ExchangeJDCodeViewController: BaseViewController {
    @IBOutlet weak var textImputContainer: UIView!
    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var enterBtn: UIButton!
    
 
    convenience init(_ viewModel: ExchangeJDCodeViewModel) {
        self.init(nibName: "ExchangeJDCodeViewController", bundle: nil)
        
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    private func config(_ viewModel: ExchangeJDCodeViewModel) {
        title = "会员兑换"
        textImputContainer.layer.cornerRadius = 23
        textImputContainer.layer.masksToBounds = true
        enterBtn.layer.cornerRadius = 23
        enterBtn.layer.masksToBounds = true
        viewModel.activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.errorDriver
            .map {_ in HUDValue(.label("兑换码错误"))}
            .drive(HUD.flash)
            .disposed(by: bag)
        
        let textInput = self.textInput
        enterBtn.rx.tap
            .filter({ (_) -> Bool in
                if textInput?.text == nil {
                    HUD.flash(HUDContentType.label("请输入兑换码"), delay: 2)
                    return false
                } else {
                    return true
                }
            })
            .map { textInput?.text }
            .unwrap()
            .bind(to: viewModel.enterBtninput)
            .disposed(by: bag)
        
        viewModel.exchangeResult
            .filter { $0.status?.code == 0}
            .delaySubscription(RxTimeInterval.seconds(1), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
    }
}
