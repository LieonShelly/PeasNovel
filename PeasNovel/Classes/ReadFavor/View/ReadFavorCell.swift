//
//  ReadFavorCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReadFavorCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        label.layer.cornerRadius = 3
        label.layer.masksToBounds = true
        label.layer.borderColor = UIColor(0x979797).cgColor
        label.layer.borderWidth = 0.5
    }
    
    func config(_ title: String?, isSelcted: Bool)  {
        label.text = title
        if isSelcted {
            label.layer.borderColor = UIColor(0x00CF7A).cgColor
            label.textColor = UIColor(0x00CF7A)
        } else{
            label.layer.borderColor = UIColor(0x979797).cgColor
            label.textColor = UIColor(0x333333)
        }
    }

}
