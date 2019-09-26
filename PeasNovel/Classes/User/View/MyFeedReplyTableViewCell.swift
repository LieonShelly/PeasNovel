//
//  MyFeedReplyTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class MyFeedReplyTableViewCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var questionDateLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var replyDateLabel: UILabel!
    @IBOutlet weak var replyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconView.layer.cornerRadius = 13
        iconView.layer.masksToBounds = true
    }

    func config(_ model: MyFeedback) {
        statusLabel.text = "已回复"
        questionDateLabel.text = model.createtime
        questionLabel.text = model.content
        replyLabel.text = model.suggest_reply?.content
        replyDateLabel.text = model.suggest_reply?.createtime
    }
}
