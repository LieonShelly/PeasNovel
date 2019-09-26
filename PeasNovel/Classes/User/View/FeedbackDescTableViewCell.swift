//
//  FeedbackDescTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class FeedbackDescTableViewCell: UITableViewCell {
    @IBOutlet weak var label0: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var btn: UIButton!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
        
    }
    
    func config(_ local: SwitcherConfig? = CommomData.share.switcherConfig.value)  {
        label0.text = "微信客服：" + (local?.qq ?? "")
        label2.text = "温馨提示：您的账户ID：" + (me.user_id ?? "") + "  版本：" + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "1.0.0")
    }
    
}
