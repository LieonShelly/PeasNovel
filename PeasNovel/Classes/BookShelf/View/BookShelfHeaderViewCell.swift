//
//  BookShelfHeaderViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookShelfHeaderViewCell: UICollectionViewCell {

    @IBOutlet weak var cover: UIImageView!
    @IBOutlet weak var bookNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var adBtn: UIButton!
    @IBOutlet weak var searchBtn: UIButton!
    @IBOutlet weak var msgBtn: UIButton!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var badgeLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
