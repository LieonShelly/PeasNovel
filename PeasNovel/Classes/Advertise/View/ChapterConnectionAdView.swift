//
//  ChapterConnectionAdView.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ChapterConnectionAdView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    
    @IBOutlet weak var noAdBtn: UIButton!
    @IBOutlet weak var adContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        noAdBtn.layer.cornerRadius = 23
        noAdBtn.layer.masksToBounds = true
    }

}
