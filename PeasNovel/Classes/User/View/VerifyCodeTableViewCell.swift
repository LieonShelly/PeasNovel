//
//  VerifyCodeTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class VerifyCodeTableViewCell: UITableViewCell {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var btn: UIButton!
    var bag = DisposeBag()
    
    @IBOutlet weak var audioBtn: UIButton!
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()

    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        btn.isHidden = false
        audioBtn.isHidden = true

        NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.getVerifyCodeSuccess)
            .map { $0.object as? CodeType }
            .filter { $0?.rawValue == CodeType.text.rawValue}
            .subscribe(onNext: {[weak self] (_) in
                self?.btn.isHidden = false
                self?.audioBtn.isHidden = true
                UIButton.countDown(60, inputView: self!.btn, countDownTitle: "S", normalTitle: "获取验证码", completion: { flag in
                        if flag == true {
                            self?.btn.isHidden = false
                            self?.audioBtn.isHidden = true
                        }
                    })
            })
             .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.getVerifyCodeSuccess)
            .map { $0.object as? CodeType }
            .filter { $0?.rawValue == CodeType.audio.rawValue}
            .subscribe(onNext: {[weak self] (_) in
                self?.btn.isHidden = true
                self?.audioBtn.isHidden = false
                UIButton.countDown(60, inputView: self!.audioBtn, countDownTitle: "S", normalTitle: "获取验证码", completion: { flag in
                    if flag == true {
                        self?.btn.isHidden = false
                        self?.audioBtn.isHidden = true
                    }
                })
            })
            .disposed(by: bag)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
