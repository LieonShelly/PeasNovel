//
//  ChargeHeaderVIew.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ChargeHeaderVIew: UIView {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var whiteBg: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var triSubTitleLabel: UILabel!
    @IBOutlet weak var btn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var vipLabel: UILabel!
    @IBOutlet weak var vipChangeBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        btn.layer.cornerRadius = 15
        btn.layer.masksToBounds = true
        containerView.layer.cornerRadius = 5
        containerView.layer.masksToBounds = true
        iconView.layer.cornerRadius = 28
        iconView.layer.borderColor = UIColor.white.cgColor
        iconView.layer.borderWidth = 1
        whiteBg.backgroundColor = .clear
        vipLabel.isHidden = true
        triSubTitleLabel.isHidden = true
        vipChangeBtn.layer.cornerRadius = 15
        vipChangeBtn.layer.borderWidth = 1
        vipChangeBtn.layer.borderColor = UIColor(0x7C6031).cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let path0 = UIBezierPath()
        path0.move(to: CGPoint(x: 0, y: frame.size.height - 40))
        path0.addLine(to: CGPoint(x: 0, y: frame.size.height))
        path0.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height))
        path0.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height - 40))
        path0.addQuadCurve(to: CGPoint(x: 0, y: frame.size.height - 40), controlPoint: CGPoint(x: frame.size.width * 0.5, y: frame.size.height - 80))
        path0.close()

        let maskLayer = CAShapeLayer()
        maskLayer.frame = whiteBg.bounds
        maskLayer.path = path0.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.strokeColor = UIColor.white.cgColor
        maskLayer.lineWidth = 1
        whiteBg.layer.addSublayer(maskLayer)
       
    }

    static func loadView() -> ChargeHeaderVIew {
        guard let view = Bundle.main.loadNibNamed("ChargeHeaderVIew", owner: nil, options: nil)?.first as? ChargeHeaderVIew else {
            return ChargeHeaderVIew()
        }
        view.updateUI(me)
        return view
    }
    
    
    func updateUI( _ user: User) {
         vipLabel.isHidden = true
         triSubTitleLabel.isHidden = true
        if user.isLogin {
            if let url = URL(string: user.headimgurl ?? "") {
                iconView.kf.setImage(with: url)
            } else if let hoder = UIImage(named: user.sex.iconName ) {
                iconView.image = hoder
            }
            titleLabel.text = user.nickname
            if user.ad?.vip.rawValue == 0 || user.ad == nil { // 非会员
                subTitleLabel.text = "您还不是会员"
                 btn.isHidden = false
            } else {
                btn.isHidden = true
                vipLabel.isHidden = false
                triSubTitleLabel.isHidden = true
                subTitleLabel.text = Date(timeIntervalSince1970: Double(user.ad?.ad_end_time ?? 0)).withFormat("yyyy-MM-dd HH:mm") + "到期"
            }
        } else {
            btn.isHidden =  false
            titleLabel.text = "游客模式"
            subTitleLabel.text = "请登录后购买会员"
        }
    }
}



extension Reactive where Base: ChargeHeaderVIew {
    var refreshUI: Binder<User> {
        return Binder<User>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            control.updateUI(value)
        })
    }
}

