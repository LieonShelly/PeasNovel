//
//  MessageTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var conntentLabel: UILabel!
    @IBOutlet weak var imageBrowser: ImageListView!
    @IBOutlet weak var imageBrowserHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconView.layer.cornerRadius = 13
        iconView.layer.masksToBounds = true
    }
    
    func config(_ msg: GEPushMessage) {
        iconView.image = UIImage(named: "logo")
        titleLabel.text = msg.title
        conntentLabel.text = msg.content
        dateLabel.text = Date(timeIntervalSince1970: Double(msg.createtime)).withFormat("yyyy-MM-dd HH:mm")
        
        let imageURLStrs = [msg.img_url] + msg.chilid_messages.map { $0.img_url }
        if !imageURLStrs.isEmpty {
            let imageURLs = imageURLStrs.filter { !$0.isEmpty}.map { URL(string: $0)!}
            imageBrowser.config(imageURLs.count) { (imageView, index) in
                imageView?.kf.setImage(with: imageURLs[index])
            }
            let height = ImageListView.caculateHeight(imageURLs)
            if height != imageBrowserHeight.constant {
                imageBrowserHeight.constant = height
                contentView.layoutIfNeeded()
            }
        } else {
            imageBrowserHeight.constant = 0
        }
        
        
    }

}
