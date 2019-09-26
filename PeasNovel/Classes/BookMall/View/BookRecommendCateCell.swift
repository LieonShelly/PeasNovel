//
//  BookRecommendCateCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookRecommendCateCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel0: UILabel!
     @IBOutlet weak var subTitleLabel1: UILabel!
    @IBOutlet weak var bgVIew: UIImageView!
    
    func config( _ urlStr: String, title: String?, subTitle: String?, desc: String?)  {
        titleLabel.text = title
        subTitleLabel0.text = subTitle
        subTitleLabel1.text = desc
        if let url = URL(string: urlStr) {
            bgVIew.kf.setImage(with: url, placeholder: UIImage())
        }
    }
}
