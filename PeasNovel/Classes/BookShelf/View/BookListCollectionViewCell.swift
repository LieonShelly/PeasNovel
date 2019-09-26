//
//  BookListCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var badgeLabel: UILabel!
    
    @IBOutlet var bookLmageView: [UIImageView]!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var flurView: UIView!
    @IBOutlet weak var selectButton: UIButton!
    
    func set(_ model: BookInfo, isFlur: Bool = false) {
        titleLabel.text = model.boutique_title
        for (idx, item) in (model.book_lists ?? []).enumerated() {
            let url = URL(string: item.cover_url ?? "")
            if idx >= 4 { break }
            bookLmageView[idx].kf.setImage(with: url, placeholder: UIImage())
        }
        let timestamp = UserDefaults.standard.double(forKey: model.book_id)
        let badge = model.book_lists?.filter{ $0.isUpdate }.count ?? 0
        print("isUpdate-timestamp：\(timestamp) - isUpdate:\(model.isUpdate) - badge:\(badge)")
        badgeLabel.isHidden = (badge <= 0)
        badgeLabel.text = "\(badge)"
        let img = UIImage(named: model.isSelected ? "finish2": "finish")
        selectButton.setBackgroundImage(img, for: .disabled)
        flurView.isHidden = !isFlur
    }

}
