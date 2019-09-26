//
//  BookListRightCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookListRightCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet var images: [UIImageView]!
    
    @IBOutlet weak var desclabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.cornerRadius = 2
        containerView.layer.borderColor = UIColor(0xd5d5d5).cgColor
        containerView.layer.borderWidth = 0.5
    }
    func config(_ urls: [String], title: String?, desc: String?) {
        for (index, urlStr) in urls.enumerated() {
            if let url = URL(string: urlStr), index < images.count {
                images[index].kf.setImage(with: url, placeholder: UIImage())
            }
        }
        titleLabel.text = title
        desclabel.attributedText = desc?.withlineSpacing(8)
    }
}
