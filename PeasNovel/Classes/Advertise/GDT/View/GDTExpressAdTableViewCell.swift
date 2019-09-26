//
//  GDTExpressAdTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class GDTExpressAdTableViewCell: UITableViewCell {
    @IBOutlet weak var adContainner: UIView!
    @IBOutlet weak var adHeight: NSLayoutConstraint!
    
    func config(_ expressView: GDTNativeExpressAdView) {
        let subView: UIView? = adContainner.viewWithTag(1000)
        if (subView?.superview != nil) {
            subView?.removeFromSuperview()
        }
        let view: GDTNativeExpressAdView = expressView
        view.tag = 1000
        view.frame.origin = .zero
        view.center.x = bounds.width * 0.5
        if adHeight.constant != view.frame.height {
            adHeight.constant = view.frame.height
            layoutIfNeeded()
        }
        adContainner.addSubview(view)
    }
    
}
