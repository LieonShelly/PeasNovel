//
//  BookShelfNoContentView.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookShelfNoContentView: UIView {
    @IBOutlet weak var btn: UIButton!
    
    static func loadView() -> BookShelfNoContentView {
        guard let view = Bundle.main.loadNibNamed("BookShelfNoContentView", owner: nil, options: nil)?.first as? BookShelfNoContentView else {
            return BookShelfNoContentView()
        }
        return view
    }
    
    func addTarget(_ target: Any?, action:Selector) {
        guard let target = target else {
            return
        }
        btn.isHidden = false
        btn.addTarget(target, action: action, for: .touchUpInside)
    }
}
