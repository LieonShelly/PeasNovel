//
//  FlashLoginBottomView.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class FlashLoginBottomView: UIView {
    @IBOutlet weak var otherBtn: UIButton!
    
    
    static func loadView() -> FlashLoginBottomView {
        guard let view = Bundle.main.loadNibNamed("FlashLoginBottomView", owner: nil, options: nil)?.first as? FlashLoginBottomView else {
            return FlashLoginBottomView()
        }
        return view
    }
   

}
