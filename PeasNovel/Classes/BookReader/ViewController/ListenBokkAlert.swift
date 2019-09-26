//
//  ListenBokkAlert.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ListenBokkAlert: BaseViewController {
    @IBOutlet weak var cancleBtn: UIButton!
    @IBOutlet weak var enterBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    
    var enterAction: (() -> Void)?
    var cancleAction: (() -> Void)?
    var closeAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let enterAction = self.enterAction
        let cancleAction = self.cancleAction
        let closeAction = self.closeAction
        
        cancleBtn.layer.cornerRadius = 21
        cancleBtn.layer.borderColor = UIColor.theme.cgColor
        cancleBtn.layer.borderWidth = 1
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        enterBtn.layer.cornerRadius = 21
        enterBtn.layer.masksToBounds = true
        enterBtn.setTitleColor(UIColor.white, for: .normal)
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: closeAction)
            })
            .disposed(by: bag)
        
        enterBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: enterAction)
            })
            .disposed(by: bag)
        
        cancleBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: cancleAction)
            })
            .disposed(by: bag)
        
    }



}
