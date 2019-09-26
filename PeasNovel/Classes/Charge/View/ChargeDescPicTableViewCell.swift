//
//  ChargeDescPicTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ChargeDescPicTableViewCell: UITableViewCell {
    var bag = DisposeBag()
    @IBOutlet weak var btn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
}
