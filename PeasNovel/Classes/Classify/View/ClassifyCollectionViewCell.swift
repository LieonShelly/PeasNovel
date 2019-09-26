//
//  ClassifyCollectionViewCell.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ClassifyCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func set(_ cover: String?) {
        let url = URL(string: cover ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
    }

}
