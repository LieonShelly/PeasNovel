//
//  SettingTableViewCell.swift
//  ClassicalMusic
//
//  Created by weicheng wang on 2019/1/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class SettingTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var markImgView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    /// @title: 标题 @info: 副标题 @isMark: 是否显示选中图标
    func set(_ title: String?, info: String?) {
        titleLabel.text = title
        infoLabel.text = info
        
    }
    /// 是否选择模式
    func set(_ title: String?, info: String?, flag: Bool) {
        set(title, info: info)
        if flag {
            markImgView.image = UIImage(named: "icon_selected_mark")
            titleLabel.textColor = UIColor(0x333333)
        }else{
            titleLabel.textColor = UIColor(0x636363)
            markImgView.image = nil
        }
    }
    
}
