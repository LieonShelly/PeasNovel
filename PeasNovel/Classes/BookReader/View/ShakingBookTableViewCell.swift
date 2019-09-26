//
//  ShakingBookTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ShakingBookTableViewCell: UITableViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    
    
    func config(_ imageURLStr: String?, title: String?, dec: String?, tag: String)  {
        if let url = URL(string: imageURLStr ?? "") {
            coverImageView.kf.setImage(with: url, placeholder: UIImage())
        } else {
            coverImageView.image = nil
        }
        titleLabel.text = title
         descLabel.attributedText = dec?.withlineSpacing(8)
         tagLabel.text = tag
    }
    
}
