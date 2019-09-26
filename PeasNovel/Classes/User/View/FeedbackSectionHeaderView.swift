//
//  FeedbackSectionHeaderView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class FeedbackSectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var label: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = UIColor(0xefefef)
    }
}
