//
//  TopImageDownTextCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class TopImageDownTextDetailCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    func set(_ item: BookInfo, isFlur: Bool = false) {
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        titleLabel.text = item.book_title
        if let order = DZMReadRecordModel.readRecordModel(bookID: item.book_id).readChapterModel?.order {
            detailLabel.text = "已阅读至\(order == 0 ? 1: order)章"
        } else {
             detailLabel.text = "已阅读至\(item.c_order ?? "1")章"
        }
       
    }
}
