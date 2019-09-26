//
//  FeedbackTextInputTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FeedbackTextInputTableViewCell: UITableViewCell {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textFieldContainer: UIView!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textFieldContainer.layer.borderColor = UIColor.lightGray.cgColor
        textFieldContainer.layer.borderWidth = 1
          textFieldContainer.layer.cornerRadius = 5
    }

}
