//
//  BookListBottomCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class BookListBottomCollectionViewCell: UICollectionViewCell {
//    @IBOutlet weak var tapBtn: UIButton!
    
    @IBOutlet weak var containerVoew: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet var images: [UIImageView]!
    var bag = DisposeBag()
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerVoew.layer.cornerRadius = 2
        containerVoew.layer.borderColor = UIColor(0xd5d5d5).cgColor
        containerVoew.layer.borderWidth = 0.5
    }

    func config(_ urls: [String], text: String?) {
        label.text = text
        for (index, urlStr) in urls.enumerated() {
            if let url = URL(string: urlStr), index < images.count {
                images[index].kf.setImage(with: url, placeholder: UIImage())
            }
        }
    }
}
