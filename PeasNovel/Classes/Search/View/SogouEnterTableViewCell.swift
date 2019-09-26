//
//  SogouEnterTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SogouEnterTableViewCell: UITableViewCell {
    var bag = DisposeBag()
    @IBOutlet weak var btm: UIButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
}
