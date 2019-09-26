//
//  BookDetailIntroTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class BookDetailIntroTableViewCell: UITableViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var bookTitleLabel: UILabel!
    @IBOutlet var starImageView: [UIImageView]!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var openButton: UIButton!
    
    let openAction = PublishSubject<Bool>.init()
    
    var bag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        openButton.imageView?.contentMode = .scaleAspectFit
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }

    func set(_ item: BookInfo) {
        let url = URL(string: item.cover_url ?? "")
            coverImageView.kf.setImage(with: url, placeholder: UIImage())
        bookTitleLabel.text = item.book_title
        var cateStr = ""
        if let shortName = item.category_id_1?.short_name {
            cateStr = shortName + " "
        }
        if let shortName = item.category_id_2?.short_name {
            cateStr += shortName + " "
        }
        if cateStr.length > 0 {
            cateStr += "| "
        }
        categoryLabel.text = cateStr + (item.author_name ?? "")
        statusLabel.text = "\(item.word_count)字 | \(item.writing_process.desc)"
        
        let attributedString = item.book_intro?.withlineSpacing(7)
        
        introLabel.attributedText = attributedString
        
    }
    
    @IBAction func openAction(_ sender: Any) {
        if introLabel.numberOfLines == 0 {
            introLabel.numberOfLines = 3
            UIView.animate(withDuration: 0.25) {
                self.openButton.imageView?.transform = CGAffineTransform.identity
            }
            openAction.on(.next(false))
        }else{
            introLabel.numberOfLines = 0
            UIView.animate(withDuration: 0.25) {
                self.openButton.imageView?.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi)
            }
            openAction.on(.next(true))
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
