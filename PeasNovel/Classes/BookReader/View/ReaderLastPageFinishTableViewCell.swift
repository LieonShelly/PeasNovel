//
//  ReaderLastPageFinishTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class ReaderLastPageFinishTableViewCell: UITableViewCell {
  @IBOutlet var btns: [UIButton]!
    
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configRx()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configRx()
    }
    
    func configRx() {
        bag = DisposeBag()
    }
    


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
