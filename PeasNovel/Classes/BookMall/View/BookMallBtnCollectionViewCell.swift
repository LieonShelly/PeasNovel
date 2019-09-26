//
//  BookMallBtnCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class BookMallBtnCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var insetLabelWidth: NSLayoutConstraint!
    @IBOutlet var btns: [UIButton]!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let margin = 28.0.fitScale
        let centerBtnWidth: CGFloat = 56.0
        let otherBtnWidth: CGFloat = 28 * 4
        insetLabelWidth.constant = (UIScreen.main.bounds.width - margin * 2 - centerBtnWidth - otherBtnWidth) / 4.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
   

    }

}
