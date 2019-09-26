//
//  GDTNativeExpressAdView.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class GDTNativeExpressAdInfoView: UIView {

    func config(_ expressView: GDTNativeExpressAdView) {
        let subView: UIView? = viewWithTag(1000)
        if (subView?.superview != nil) {
            subView?.removeFromSuperview()
        }
        let view: GDTNativeExpressAdView = expressView
        view.tag = 1000
        view.frame.origin = .zero
        view.center.x = bounds.width * 0.5
        addSubview(view)
    }
    
    static func loadView() -> GDTNativeExpressAdInfoView {
        guard let view = Bundle.main.loadNibNamed("GDTNativeExpressAdInfoView", owner: nil, options: nil)?.first as? GDTNativeExpressAdInfoView else {
            return GDTNativeExpressAdInfoView()
        }
        return view
    }
}
