//
//  TextViewTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TextViewTableViewCell: UITableViewCell {
    var bag = DisposeBag()
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewContainer: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        textViewContainer.layer.cornerRadius = 5
        textViewContainer.layer.borderColor = UIColor.lightGray.cgColor
        textViewContainer.layer.borderWidth = 1
        placeholderLabel.attributedText = "您遇到什么问题了？或者有什么建议，欢迎您反馈给我们。谢谢您的宝贵意见".withlineSpacing(8)
        configRx()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
        configRx()
    }
    
   private func configRx() {
        textView.rx.text.orEmpty.map { $0 }
            .map {!$0.isEmpty}
            .bind(to: placeholderLabel.rx.isHidden)
            .disposed(by: bag)
    
        textView.rx.setDelegate(self).disposed(by:  bag)
 
    NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .map {_ in  true}
            .bind(to: placeholderLabel.rx.isHidden)
            .disposed(by: bag)
    
    NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
        .map {_ in  !self.textView.text.isEmpty}
        .bind(to: placeholderLabel.rx.isHidden)
        .disposed(by: bag)
    
    
    }
    
}

extension TextViewTableViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
    }
}
