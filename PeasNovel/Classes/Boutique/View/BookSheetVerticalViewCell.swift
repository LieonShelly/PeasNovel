//
//  BookSheetVerticalViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import FSPagerView
import RxSwift

class BookSheetVerticalViewCell: FSPagerViewCell {
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var readCountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var cellAction: PublishSubject<(Int, BookSheetListModel)> = .init()
    
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        readButton.layer.masksToBounds = true
        readButton.layer.cornerRadius = 14
        readButton.layer.borderColor = UIColor.theme.cgColor
        readButton.layer.borderWidth = 1
        
        addButton.layer.masksToBounds = true
        addButton.layer.cornerRadius = 14
        addButton.layer.borderColor = UIColor.theme.cgColor
        addButton.layer.borderWidth = 1
        
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 4
        contentView.layer.shadowColor = UIColor(white: 0, alpha: 0.14).cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOpacity = 1
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func set(_ item: BookSheetListModel) {
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        readCountLabel.text = "\(item.total_click_num)人读过"
        titleLabel.text = item.book_title
        introLabel.attributedText = item.book_intro?.withlineSpacing(8)
        if item.is_case {
            addButton.layer.borderColor = UIColor(0x999999).cgColor
        }else{
            addButton.layer.borderColor = UIColor.theme.cgColor
        }
        addButton.isEnabled = !item.is_case
        
        
        readButton
            .rx
            .tap
            .map{ (0, item) }
            .bind(to: cellAction)
            .disposed(by: bag)
        
        addButton
            .rx
            .tap
            .map{ (1, item) }
            .bind(to: cellAction)
            .disposed(by: bag)
    }

}
