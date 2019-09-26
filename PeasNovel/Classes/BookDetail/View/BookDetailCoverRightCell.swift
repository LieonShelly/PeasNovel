//
//  BookDetailCoverRightCell.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookDetailCoverRightCell: UITableViewCell {

    @IBOutlet weak var bookIntroLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet weak var statusLabel: InsetsLabel!
    @IBOutlet weak var tagLabel: InsetsLabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tagLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        tagLabel.layer.cornerRadius = 2
        tagLabel.layer.masksToBounds = true
        tagLabel.layer.borderColor = UIColor(0x999999).cgColor
        tagLabel.layer.borderWidth = 0.5
        
        statusLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        statusLabel.layer.cornerRadius = 2
        statusLabel.layer.masksToBounds = true
        statusLabel.layer.borderColor = UIColor(0x999999).cgColor
        statusLabel.layer.borderWidth = 0.5
    }
    
    func set(simple item: BookInfoSimple) {
        bookTitleLabel.text = item.book_title
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        bookIntroLabel.text = item.book_intro
        authorLabel.text = item.author_name
        statusLabel.text = item.writing_process.desc
        tagLabel.text = item.category_id_1?.short_name
        
        statusLabel.isHidden = (item.writing_process.desc.length == 0)
        tagLabel.isHidden = (item.category_id_1?.short_name?.length == 0)
    }
    
    func set(_ item: BookInfo) {
        bookTitleLabel.text = item.book_title
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        bookIntroLabel.text = item.book_intro
        authorLabel.text = item.author_name
        statusLabel.text = item.writing_process.desc
        tagLabel.text = item.category_id_1?.short_name
        
        statusLabel.isHidden = (item.writing_process.desc.length == 0)
        tagLabel.isHidden = (item.category_id_1?.short_name?.length == 0)
    }
    
    func set(_ item: BookSheetListModel) {
        bookTitleLabel.text = item.book_title
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        bookIntroLabel.text = item.book_intro
        authorLabel.text = item.author_name
        statusLabel.text = item.writing_process?.desc
        tagLabel.text = item.category_name
        
        statusLabel.isHidden = (item.writing_process?.desc.length == 0)
        tagLabel.isHidden = (item.category_name?.length == 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
