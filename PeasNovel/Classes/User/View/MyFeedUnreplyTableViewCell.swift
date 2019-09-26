//
//  MyFeedUnreplyTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class MyFeedUnreplyTableViewCell: UITableViewCell {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var questionDateLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
   
    func config(_ model: MyFeedback) {
        statusLabel.text = "未回复"
        questionDateLabel.text = model.createtime
        questionLabel.text = model.content
    }
    
}
