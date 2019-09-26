//
//  SogouAlterAddViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import PKHUD

class SogouAlterAddViewController: BaseViewController {
    @IBOutlet weak var coverBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var enterBtn: UIButton!
    @IBOutlet weak var textFieldContainer: UIView!
    @IBOutlet weak var closeArrow: UIButton!
    @IBOutlet weak var closeArrowWidth: NSLayoutConstraint!
    

    convenience init(_ viewModel: SogouAddAlterViewModel) {
        self.init(nibName: "SogouAlterAddViewController", bundle: nil)
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
    
    private func config(_ viewModel: SogouAddAlterViewModel) {
        closeBtn.layer.cornerRadius = 21
        closeBtn.layer.borderColor = UIColor.theme.cgColor
        closeBtn.layer.borderWidth = 1
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        enterBtn.layer.cornerRadius = 21
        enterBtn.layer.masksToBounds = true
        enterBtn.setTitleColor(UIColor.white, for: .normal)
        textFieldContainer.layer.cornerRadius = 3
        textFieldContainer.layer.masksToBounds = true
        textFieldContainer.layer.borderColor = UIColor(0x333333).cgColor
        textFieldContainer.layer.borderWidth = 0.5
        let textFiled = self.textField
        Observable.merge(closeBtn.rx.tap.mapToVoid(),
                         coverBtn.rx.tap.mapToVoid(),
                        viewModel.addResult.filter { $0.code == 0 }.mapToVoid()
            )
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        textField.rx.text.orEmpty
            .map { $0.isEmpty }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](isEmpty) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.closeArrowWidth.constant = isEmpty ? 0: 30
            })
            .disposed(by: bag)
        
        closeArrow.rx.tap
            .mapToVoid()
            .observeOn(MainScheduler.instance)
            .map {""}
            .bind(to: textField.rx.text)
            .disposed(by: bag)
        
      
        enterBtn.rx.tap
            .map { textFiled?.text }
            .unwrap()
            .filter({ (text) -> Bool in
                if text.isEmpty {
                    HUD.flash(.label("标题不能为空"), delay: 2)
                    return false
                }
                return true
            })
            .bind(to: viewModel.enterBtnInput)
            .disposed(by: bag)
        
        Observable.merge( viewModel.queryResult
                .asObservable()
                .map { $0.collect_title }
                .unwrap(),
                          viewModel.inputTitle)
            .filter { !$0.isEmpty }
            .bind(to: textField.rx.text)
            .disposed(by: bag)
        
        textField.rx.text.orEmpty
            .map { (text) -> String in
                if text.count >= 10 {
                    return String(text[text.startIndex ... text.index(text.startIndex, offsetBy: 9)])
                }
                return text
            }
            .bind(to: textFiled!.rx.text)
            .disposed(by: bag)
        
        viewModel.inputTitle
            .subscribe(onNext: { [weak self](title) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.textField.becomeFirstResponder()
                weakSelf.textField.text = title
            })
            .disposed(by: bag)
        
        viewModel.queryResult
            .asObservable()
            .map { $0.collect_title }
            .unwrap()
            .filter { !$0.isEmpty }
            .map { _ in "你已加入过豆豆书架"}
            .bind(to: titleLabel.rx.text)
            .disposed(by: bag)
        
        viewModel.messageOutput
            .observeOn(MainScheduler.instance)
            .asDriver(onErrorJustReturn: "")
            .map { HUDValue(HUDContentType.label($0))}
            .drive(HUD.flash)
            .disposed(by: bag)
        
       
    }
    

    

}
