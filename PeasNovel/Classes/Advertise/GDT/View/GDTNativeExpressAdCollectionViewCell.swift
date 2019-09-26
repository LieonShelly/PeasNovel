//
//  GDTNativeExpressAdCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class GDTNativeExpressAdCollectionViewCell: UICollectionViewCell {

    func config(_ expressView: GDTNativeExpressAdView) {
        let subView: UIView? = contentView.viewWithTag(1000)
        if (subView?.superview != nil) {
            subView?.removeFromSuperview()
        }
        let view: GDTNativeExpressAdView = expressView
        view.tag = 1000
        view.frame.origin = .zero
        contentView.addSubview(view)
    }

}
