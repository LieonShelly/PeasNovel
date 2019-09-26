//
//  HeaderIconTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/24.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class HeaderIconTableViewCell: UITableViewCell {

    @IBOutlet weak var icon: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        icon.layer.cornerRadius = 38
        icon.layer.masksToBounds = true
    }

   
    func config(_ str: String) {
        if let url = URL(string: str) {
            icon.kf.setImage(with: url)
        }
    }
    
    
    func configLocal(_ locaname: String) {
        icon.image = UIImage(named: locaname)
    }
}
