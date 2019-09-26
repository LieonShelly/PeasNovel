//
//  BookMallSectionView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BookMallSectionView: UICollectionReusableView {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var btn: UIButton!

    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var arrow: UIImageView!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func moreBtnMode() {
        moreBtn.isHidden = false
        arrow.isHidden = false
        icon.isHidden = true
        btn.isHidden = true
    }

    func refreshMode() {
        moreBtn.isHidden = true
        arrow.isHidden = true
        icon.isHidden = false
        btn.isHidden = false
    }
    
    
    func noMode() {
        moreBtn.isHidden = true
        arrow.isHidden = true
        icon.isHidden = true
        btn.isHidden = true
    }
    
    func onlyTitle(_ title: String?) {
        moreBtn.isHidden = true
        arrow.isHidden = true
        icon.isHidden = true
        btn.isHidden = true
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor(0x333333)
        label.text = title
    }
    
}
