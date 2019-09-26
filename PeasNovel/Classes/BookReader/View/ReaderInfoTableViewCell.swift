//
//  ReaderInfoTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReaderInfoTableViewCell: UITableViewCell {
    @IBOutlet var bgLabel: [UILabel]!
    @IBOutlet weak var orginLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if DZMReadConfigure.shared().colorIndex == 5 { // 夜间
            orginLabel.textColor = DZMReadConfigure.shared().textColor
            authorLabel.textColor = DZMReadConfigure.shared().textColor
            titleLabel.textColor = DZMReadConfigure.shared().textColor
            descLabel.textColor = DZMReadConfigure.shared().textColor
            companyLabel.textColor = DZMReadConfigure.shared().textColor
        }
        orginLabel.isHidden = true
        companyLabel.isHidden = true
        bgLabel.forEach {
            $0.layer.borderWidth = 0.5
            $0.layer.borderColor = UIColor(0x999999).cgColor
        }
        contentView.backgroundColor = DZMReadConfigure.shared().readColor()
        selectionStyle = .none
    }
    
    func config(_ info: ChapterCopyRightInfo) { NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.readerChangeColor)
            .map { $0.object as? UIColor }
            .subscribe(onNext: {[weak self] (bgCLor) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.contentView.backgroundColor = bgCLor
                let textClolorIndex = DZMReadConfigure.shared().colorIndex
                if textClolorIndex == 5 { // 黑色
                    weakSelf.orginLabel.textColor = UIColor(0xAAAAAA)
                    weakSelf.authorLabel.textColor = UIColor(0xAAAAAA)
                    weakSelf.titleLabel.textColor = UIColor(0xAAAAAA)
                    weakSelf.descLabel.textColor = UIColor(0xAAAAAA)
                    weakSelf.companyLabel.textColor = UIColor(0xAAAAAA)
                } else {
                    weakSelf.orginLabel.textColor = UIColor(0x333333)
                    weakSelf.authorLabel.textColor = UIColor(0x333333)
                    weakSelf.titleLabel.textColor = UIColor(0x333333)
                    weakSelf.descLabel.textColor = UIColor(0x999999)
                    weakSelf.companyLabel.textColor = UIColor(0x333333)
                }
                
            })
            .disposed(by: bag)
        
        Observable.just(info)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](info) in
                if let origin_company = info.origin_company, let target_company =  info.target_company, !origin_company.isEmpty, !target_company.isEmpty {
                    self?.companyLabel.isHidden = false
                    self?.orginLabel.isHidden = false
                    self?.orginLabel.text = "本书由" + origin_company + "授权"
                    self?.companyLabel.text = target_company + "电子版制作与发布"
                    self?.descLabel.text = "- 版权所有 侵权必究 -"
                } else {
                    self?.companyLabel.isHidden = true
                    self?.orginLabel.isHidden = true
                    self?.descLabel.text = "- 独家版权 侵权必究 -"
                }
                self?.titleLabel.text = info.book_title
                self?.authorLabel.text = "作者：" + (info.author ?? "")
            })
            .disposed(by: bag)
    }
}
