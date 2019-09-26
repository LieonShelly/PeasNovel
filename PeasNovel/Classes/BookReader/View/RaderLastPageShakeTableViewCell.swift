//
//  RaderLastPageShakeTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RaderLastPageShakeTableViewCell: UITableViewCell {
    @IBOutlet weak var btn: UIButton!
    var bag = DisposeBag()
    @IBOutlet weak var shakingTop: UIImageView!
    @IBOutlet weak var emoji: UIImageView!
    @IBOutlet weak var shankingBottom: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        configRx()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configRx()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shakingTop.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height * 0.5)
        shankingBottom.frame = CGRect(x: 0, y: bounds.height * 0.5, width: bounds.width, height: bounds.height * 0.5)
    }

    func configRx() {
        bag = DisposeBag()
    }
    
    func configStatus(_ status: ShakingStatus) {
        emoji.image = UIImage(named: "emoji_4")
        switch status {
        case .normal:
            shakingTop.isHidden = false
            emoji.isHidden = false
            shankingBottom.isHidden = false
            shakingTop.frame.origin = .zero
            shankingBottom.frame.origin = CGPoint(x: 0, y: bounds.height * 0.5)
        case .shaking:
            shakingTop.isHidden = false
            emoji.isHidden = false
            shankingBottom.isHidden = false
        case .shakingDone(let isMatch):
            shakingTop.isHidden = false
            emoji.isHidden = false
            if isMatch {
                emoji.image = UIImage(named: "emoji_4")
            } else {
                emoji.image = UIImage(named: "emoji_1")
            }
            shankingBottom.isHidden = false
        }
    }
   
    
    func startAnima(upCompletion: (() -> Void)?, backCompletion: (() -> Void)?) {
        UIView.animate(withDuration: 1, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
             self.shakingTop.frame.origin.y = -300
             self.shankingBottom.frame.origin.y = 300
        }) { (flag) in
            if flag {
                upCompletion?()
                UIView.animate(withDuration: 1, animations: {
                    self.shakingTop.frame.origin.y = 0
                    self.shankingBottom.frame.origin.y = self.bounds.height * 0.5
                }, completion: { (flag) in
                    if flag {
                        backCompletion?()
                    }
                })
            }
        }


    }
}
