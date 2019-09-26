//
//  RankTableViewCell.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class RankTableViewCell: UITableViewCell {
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var tagLabel: InsetsLabel!
    @IBOutlet weak var statusLabel: InsetsLabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var rankImageView: UIImageView!
    @IBOutlet var avatarImageViews: [UIImageView]!
    @IBOutlet weak var rankLabel: UILabel!
    
    @IBOutlet weak var tipsBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var isBottomShow: Bool {
        get {
            return !bottomView.isHidden
        }
        set {
            bottomView.isHidden = !newValue
            bottomConstraint.constant = newValue ? 55 :10
        }
    }
    
    var isStatusShow: Bool {
        get {
            return !statusLabel.isHidden
        }
        set {
            statusLabel.isHidden = !newValue
            tagLabel.isHidden = !newValue
            tipsBottomConstraint.constant = newValue ? -40 :-10
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tagLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        tagLabel.layer.cornerRadius = 2
        tagLabel.layer.masksToBounds = true
        tagLabel.layer.borderColor = UIColor(0x999999).cgColor
        tagLabel.layer.borderWidth = 0.5
        
        statusLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        statusLabel.layer.cornerRadius = 2
        statusLabel.layer.masksToBounds = true
        statusLabel.layer.borderColor = UIColor(0x999999).cgColor
        statusLabel.layer.borderWidth = 0.5
        
        avatarImageViews.forEach {
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = 11
            $0.layer.borderColor = UIColor.white.cgColor
            $0.layer.borderWidth = 1
        }
    }

    /// 绑定数
    func set(_ item: RankModel, intro: String?, tip: String?, rank: Int) {
        let url = URL(string: item.cover_url ?? "")
        coverImageView.kf.setImage(with: url, placeholder: UIImage(named: "Group"))
        titleLabel.text = item.book_title
        introLabel.text = intro//item.book_intro
        tipLabel.text = tip
        tagLabel.text = item.category_id_1?.short_name
        statusLabel.text = "\(item.writing_process.desc)"
        rankLabel.text = String(format: "%02d", rank+1)
        switch rank+1 {
        case 1:
            rankImageView.image = UIImage(named: "paihangbang")?.image(WithTint: UIColor(0xFF5A41))
        case 2:
            rankImageView.image = UIImage(named: "paihangbang")?.image(WithTint: UIColor(0xFFA021))
        case 3:
            rankImageView.image = UIImage(named: "paihangbang")?.image(WithTint: UIColor(0xE3B271))
        default:
            rankImageView.image = UIImage(named: "paihangbang")
        }
        
        avatarImageViews.forEach{
            $0.isHidden = true
        }
        
        guard let users = item.collect_user else {
            return
        }
        
        for (idx, user) in users.enumerated() {
            if idx >= avatarImageViews.count { return }
            let url = URL(string: user.headimgurl ?? "")
            avatarImageViews[idx].kf.setImage(with: url, placeholder: UIImage(named: "Group"))
            avatarImageViews[idx].isHidden = false
        }
    }
    
    
    
}
