//
//  DescOptionTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class DescOptionTableViewCell: UITableViewCell {
    @IBOutlet weak var byn: UIButton!
    @IBOutlet weak var label: UILabel!
    
    func config(_ model: ChapterReportOption) {
        byn.isSelected = model.isSelected
        label.text = model.title
    }
}
