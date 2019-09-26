//
//  BoutiqueTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BoutiqueTableViewCell: UITableViewCell {

    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        coverImageView.layer.masksToBounds = true
        coverImageView.layer.cornerRadius = 2
        imageHeight.constant = (UIScreen.main.bounds.width - 16 * 2) * 122.0 / 343.0
    }
    
    func set(_ item: BoutiqueModel) {
        let url = URL(string: item.boutique_img ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        
        let titleText = NSMutableAttributedString(string: item.boutique_title ?? "",
                                                  attributes: [NSAttributedString.Key.foregroundColor : UIColor(0x333333)])
        if let recommend = item.recommend_word {
            let flagAttrText = NSAttributedString(string: "[\(recommend)]",
                attributes: [NSAttributedString.Key.foregroundColor : UIColor(0xFF5A41)])
            titleText.insert(flagAttrText, at: 0)
        }
        
        titleLabel.attributedText = titleText
        introLabel.attributedText = item.boutique_intro?.withlineSpacing(8)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
