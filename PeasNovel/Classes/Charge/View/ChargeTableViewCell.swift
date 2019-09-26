//
//  ChargeTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class ChargeTableViewCell: UITableViewCell {
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 4
        containerView.layer.borderColor = UIColor(0xEDEDED).cgColor
        containerView.layer.borderWidth = 0.5
    }
    
    func normalStyle() {
        containerView.layer.cornerRadius = 4
        containerView.layer.borderColor = UIColor(0xEDEDED).cgColor
        containerView.layer.borderWidth = 0.5
        containerView.backgroundColor = .white
    }

    func selectedStyle() {
        containerView.layer.cornerRadius = 4
        containerView.layer.borderColor = UIColor(0xCDB081).cgColor
        containerView.layer.borderWidth = 0.5
          containerView.backgroundColor = UIColor(0xCDB081).withAlphaComponent(0.3)
    }
    
    func config(_ title: String?, subTitle: String?, isSelected: Bool) {
        titleLabel.text = title
        subTitleLabel.text = subTitle
        if isSelected {
            selectedStyle()
        } else {
            normalStyle()
        }
    }
 
    
}
