//
//  LabelBtnTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class LabelBtnTableViewCell: UITableViewCell {
    @IBOutlet weak var btn: UIButton!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }

}
