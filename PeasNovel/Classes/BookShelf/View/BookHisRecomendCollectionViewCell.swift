//
//  BookHisRecomendCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//  往期推荐

import UIKit

class BookHisRecomendCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var processLabel: InsetsLabel!
    @IBOutlet weak var categoryLabel: InsetsLabel!
    @IBOutlet weak var desclabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        processLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        processLabel.layer.cornerRadius = 3
        processLabel.layer.masksToBounds = true
        processLabel.layer.borderColor = UIColor(0x999999).cgColor
        processLabel.layer.borderWidth = 0.5
        
        categoryLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        categoryLabel.layer.cornerRadius = 3
        categoryLabel.layer.masksToBounds = true
        categoryLabel.layer.borderColor = UIColor(0x999999).cgColor
        categoryLabel.layer.borderWidth = 0.5
    }
    
    func config(_ imageURLStr: String?,
                title: String?,
                desc: String?,
                name: String?,
                categoryText: String?,
                processText: String?)  {
        if let url = URL(string: imageURLStr ?? "") {
            coverImageView.kf.setImage(with: url, placeholder: UIImage())
        } else {
            coverImageView.image = nil
        }
        nameLabel.text = name
        titleLabel.text = title
        desclabel.attributedText = desc?.withlineSpacing(8)
        processLabel.text = processText
        categoryLabel.text = categoryText
    }
    
}

