//
//  UserInfoView.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/27.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class UserInfoView: UIView {
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var iconBtn: UIButton!
    @IBOutlet weak var nameBtn: UIButton!
    var bag = DisposeBag()
    @IBOutlet weak var loginBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        coverView.layer.masksToBounds = true
        coverView.layer.cornerRadius = 56 * 0.5
        config()
        
//    Notification.Name.Account.clear
        NotificationCenter.default.rx.notification(Notification.Name.Account.clear, object: nil)
            .subscribe(onNext: { (_) in
                self.config()
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Account.update, object: nil)
            .subscribe(onNext: { (_) in
                self.config()
            })
            .disposed(by: bag)
    }
    
    
    class func loadView() -> UserInfoView {
        let nib = UINib(nibName: "UserInfoView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).last as? UserInfoView else {
         return   UserInfoView()
        }
        
        return view
    }
    
    func config() {
        if me.isLogin {
            titleLabel.text = me.nickname ?? ""
            subTitleLabel.text = "豆豆ID:" + ( me.user_id ?? "")
            if let url =  URL(string: me.headimgurl ?? "") {
                 coverView.kf.setImage(with: url, placeholder: UIImage())
            } else if let hoder = UIImage(named: me.sex.iconName ) {
                coverView.image = hoder
            } else {
                coverView.image = UIImage(named: "secret")
            }
            subTitleLabel.isHidden = false
            loginBtn.isHidden = true
        } else {
            titleLabel.text = "游客模式"
            subTitleLabel.isHidden = true
            loginBtn.isHidden = false
            coverView.image = UIImage(named: "secret")
        }
    }
}


