//
//  TextImageFolderTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/31.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class TextImageFolderTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentlabel: UILabel!
    @IBOutlet weak var rightVIew: UIImageView!
    @IBOutlet weak var line: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    var downloadImageHeight: CGFloat = 200
    
    func config(_ model: FeedbackQuestionDetail, isFold: Bool) {
        titleLabel.text = model.question
        contentlabel.text = model.reply
        rightVIew.image = !isFold ? UIImage(named: "right_arrow"):  UIImage(named: "down_arrow")
        line.isHidden = !isFold
        contentlabel.isHidden = !isFold
        
        if isFold {
            imageHeight.constant = downloadImageHeight
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
            imageHeight.constant = 0
        }
        if let url = URL(string: model.img_url) {
            iconView.kf.setImage(with: url) { (result) in
                switch result {
                case .failure:
                    self.downloadImageHeight = 200
                    break
                case .success(let imageValue):
                    let size = imageValue.image.size
                    let height = (UIScreen.main.bounds.width - 16 * 2 ) * size.height / size.width
                    self.downloadImageHeight = height
                }
            }
        }
        
    }
    
}
