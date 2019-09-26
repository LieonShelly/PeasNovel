//
//  TextFolderTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class TextFolderTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentlabel: UILabel!
    @IBOutlet weak var rightVIew: UIImageView!
    @IBOutlet weak var line: UILabel!
    
    
    func config(_ model: FeedbackQuestionDetail, isFold: Bool) {
        titleLabel.text = model.question
        contentlabel.text = model.reply
        rightVIew.image = !isFold ? UIImage(named: "right_arrow"):  UIImage(named: "down_arrow")
        line.isHidden = !isFold
        contentlabel.isHidden = !isFold
        
    }
}
