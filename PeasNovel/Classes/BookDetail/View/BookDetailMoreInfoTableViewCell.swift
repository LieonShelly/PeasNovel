//
//  BookDetailMoreInfoTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookDetailMoreInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var contentLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func set(_ item: BookLicense) {
        
        var content = "上架时间：\(item.shelves_time ?? "")\n"
        content += item.detail_text ?? ""
        contentLabel.text = content
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
