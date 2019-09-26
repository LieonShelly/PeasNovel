//
//  SearchFirstResultTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class SearchFirstResultTableViewCell: UITableViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var catalogButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var tagLabel: InsetsLabel!
    @IBOutlet weak var statusLabel: InsetsLabel!
    
    let buttonAction: PublishSubject<Int> = .init()
    
    var bag = DisposeBag()
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
        
        catalogButton.layer.borderColor = UIColor(0x979797).cgColor
        catalogButton.layer.borderWidth = 1
        
        addButton.layer.borderColor = UIColor(0x979797).cgColor
        addButton.layer.borderWidth = 1
        
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func set(_ model: BookInfo) {
        let url = URL(string: model.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage())
        titleLabel.text = model.book_title
        introLabel.text = model.book_intro
        authorLabel.text = model.author_name
        tagLabel.text = model.category_id_1?.short_name
        statusLabel.text = model.writing_process.desc
        addButton.isEnabled = !model.join_bookcase
        
        addButton
            .rx
            .tap
            .map{ 0 }
            .bind(to: buttonAction)
            .disposed(by: bag)
        
        catalogButton
            .rx
            .tap
            .map{ 1 }
            .bind(to: buttonAction)
            .disposed(by: bag)
        
        readButton
            .rx
            .tap
            .map{ 2 }
            .bind(to: buttonAction)
            .disposed(by: bag)
    }
    
}
