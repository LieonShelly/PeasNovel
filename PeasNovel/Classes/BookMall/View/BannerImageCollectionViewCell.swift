//
//  BannerImageCollectionViewCell.swift
//  Arab
//
//  Created by lieon on 2018/10/29.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import UIKit
import FSPagerView

class BannerImageCollectionViewCell: FSPagerViewCell {
    @IBOutlet weak var containerVIew: UIView!
    @IBOutlet weak var customImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = UIColor.clear
//        customImageView.contentMode = .scaleAspectFit
//        customImageView.layer.cornerRadius = 10
//        customImageView.layer.masksToBounds = true
////        contentView.backgroundColor = .red
//        contentView.layer.shadowColor =  UIColor.clear.cgColor
//
//        containerVIew.backgroundColor = UIColor.clear
//        containerVIew.layer.shadowColor = UIColor.black.cgColor //UIColor(0x243897).cgColor
//        containerVIew.layer.shadowOffset = CGSize(width: 0, height: 0)
//        containerVIew.layer.shadowOpacity = 1
//        containerVIew.layer.shadowRadius = 9
//        containerVIew.layer.masksToBounds = false
    }
   

}
