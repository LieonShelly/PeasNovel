//
//  UserProfileTextTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/24.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class UserProfileTextTableViewCell: UITableViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
    let didEndEdit: PublishSubject<String> = .init()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
       
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
         textField.delegate = self
    }
    
    func config(_ title: String, subTitle: String) {
        self.titleLabel.text = title
        self.textField.text = subTitle
    }


}

extension UserProfileTextTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
              didEndEdit.onNext(text)
        }
      
    }
}
