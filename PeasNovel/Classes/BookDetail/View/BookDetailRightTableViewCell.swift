//
//  BookDetailRightTableViewCell.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookDetailRightTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var midImageView: UIImageView!
    @IBOutlet weak var lastImageView: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(0xD5D5D5).cgColor
    }
    
//    func set(_ item: BookSheet) {
//        let url = URL(string: item.title_big_img ?? "")
//        coverImageView.kf.setImage(with: url, placeholder: UIImage())
//        midImageView.kf.setImage(with: URL(string: item.title_small_img ?? ""), placeholder: UIImage())
//        lastImageView.kf.setImage(with: URL(string: item.title_small_img_2 ?? ""), placeholder: UIImage())
//
//        bookTitleLabel.text = item.title
//        introLabel.text = item.title_desc
//    }
    
    func set(_ item: BookSheetModel) {
        bookTitleLabel.text = item.boutique_title
        introLabel.text = item.boutique_intro
        guard let list = item.book_lists else {
            return
        }
        
        for (idx, book) in list.enumerated() {
            let url = URL(string: book.cover_url ?? "")
            if idx == 0 {
                coverImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
            }else if idx == 1 {
                midImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
            }else if idx == 2 {
                lastImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
            }else{
                return
            }
        }
    }
    
    
}
