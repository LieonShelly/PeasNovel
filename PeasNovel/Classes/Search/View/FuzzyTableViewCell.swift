//
//  FuzzyTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class FuzzyTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    func config( _ allText: String, keyword: String) {
        let attributeStr = NSMutableAttributedString(string: allText)
        attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(0xFF5A41), range: allText.range(keyword))
        label.attributedText = attributeStr
    }
}
