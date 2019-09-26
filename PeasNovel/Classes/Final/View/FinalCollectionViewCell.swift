//
//  FinalCollectionViewCell.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class FinalCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagLabel: InsetsLabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tagLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        tagLabel.layer.cornerRadius = 2
        tagLabel.layer.masksToBounds = true
        tagLabel.layer.borderWidth = 0.5
        tagLabel.layer.borderColor = UIColor(0x999999).cgColor
    }
    
    func set(_ item: BookInfo) {
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        titleLabel.text = item.book_title
        tagLabel.text = item.category_id_1?.short_name
    }
    
    func set(_ title: String?, imageStr: String?, tag: String?) {
        let url = URL(string: imageStr ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        titleLabel.text = title
        tagLabel.text = tag
    }

}
