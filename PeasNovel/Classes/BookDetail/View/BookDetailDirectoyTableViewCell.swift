//
//  BookDetailDirectoyTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookDetailDirectoyTableViewCell: UITableViewCell {

    @IBOutlet weak var lastChapterLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func set(_ item: BookChapterInfo) {
        lastChapterLabel.text = item.title
        dateLabel.text = (item.createtime ?? "未") + "更新"
    }
    
}
