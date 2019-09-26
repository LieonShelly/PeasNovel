//
//  BookCollectionTopImageDownTextCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookCollectionTopImageDownTextCell: UICollectionViewCell {
    
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var selectedButton: UIButton!
    @IBOutlet weak var flurView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        badgeLabel.isHidden = true
        let maskPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 36, height: 17), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 2, height: 2))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = CGRect(x: 0, y: 0, width: 36, height: 17)
        maskLayer.path = maskPath.cgPath
        badgeLabel.layer.mask = maskLayer
    }
    
    func set(_ item: BookInfo, isFlur: Bool = false) {
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        titleLabel.text = item.book_title
        let img = UIImage(named: item.isSelected ? "finish2": "finish")
        selectedButton.setBackgroundImage(img, for: .disabled)
        flurView.isHidden = !isFlur
        badgeLabel.isHidden = !item.isUpdate
        if let order = DZMReadRecordModel.readRecordModel(bookID: item.book_id).readChapterModel?.order {
            subTitleLabel.text = "读至\(order == 0 ? 1: order)章"
        } else if let c_order = item.c_order, c_order != "1" {
            subTitleLabel.text = "读至\(c_order)章"
        } else {
            subTitleLabel.text = "未读"
        }
    }
    
    func set(_ item: BookSheetListModel, isFlur: Bool = false) {
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        titleLabel.text = item.book_title
        badgeLabel.isHidden = !item.isUpdate
        if let order = DZMReadRecordModel.readRecordModel(bookID: item.book_id).readChapterModel?.order {
            subTitleLabel.text = "读至\(order == 0 ? 1: order)章"
        } else if let read_info_title = item.read_info_title  {
            subTitleLabel.text = read_info_title
        } else {
            subTitleLabel.text = "未读"
        }
    }
    
}
