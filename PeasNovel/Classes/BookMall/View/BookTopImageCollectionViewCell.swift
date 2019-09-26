//
//  BookTopImageCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookTopImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    

    func config(_ imageURLStr: String?, title: String?)  {
        if let url = URL(string: imageURLStr ?? "") {
            imageView.kf.setImage(with: url, placeholder: UIImage())
        } else {
            imageView.image = nil
        }
        label.text = title
    }
}
