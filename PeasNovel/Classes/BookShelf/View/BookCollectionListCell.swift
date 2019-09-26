//
//  BookCollectionListCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookCollectionListCell: UICollectionViewCell {

    @IBOutlet weak var imgContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet var bookLmageView: [UIImageView]!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var flurView: UIView!
    @IBOutlet weak var selectButton: UIButton!
    
    func set(_ model: BookInfo, isFlur: Bool = false) {
        titleLabel.text = model.boutique_title
        var count: Int = 0
        for (idx, item) in (model.book_lists ?? []).enumerated() {
            let url = URL(string: item.cover_url ?? "")
            if idx < 4 {
                bookLmageView[idx].kf.setImage(with: url, placeholder: UIImage())
            }
            if let _ = DZMReadRecordModel.readRecordModel(bookID: item.book_id).readChapterModel?.order {
                count += 1
            } else if let c_order = item.c_order, Int(c_order) != 1 {
                 count += 1
            }
        }
        subTitleLabel.text = count > 0 ? "已读\(count)本": "未读"
        let badge = model.book_lists?.filter{ $0.isUpdate }.count ?? 0
        badgeLabel.isHidden = (badge <= 0)
        badgeLabel.text = "\(badge)"
        let img = UIImage(named: model.isSelected ? "finish2": "finish")
        selectButton.setBackgroundImage(img, for: .disabled)
        flurView.isHidden = !isFlur
    }

}
