//
//  UserTableViewCell.swift
//  ClassicalMusic
//
//  Created by lieon on 2019/1/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    func set(_ title: String?, iconName: String?) {
        titleLabel.text = title
        iconImageView.image = UIImage(named: iconName ?? "")
    }
    
}
