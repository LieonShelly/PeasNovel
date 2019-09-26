//
//  GDTOneImageNativeExpressCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GDTOneImageNativeExpressCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var closeBtn: UIButton!
    var bag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func config(_ expressView: GDTNativeExpressAdView) {
        let subView: UIView? = contentView.viewWithTag(1000)
        if (subView?.superview != nil) {
            subView?.removeFromSuperview()
        }
        contentView.clipsToBounds = true
        let view: GDTNativeExpressAdView = expressView
        view.tag = 1000
        view.frame.origin = .zero
        view.center.x = bounds.width * 0.5
        contentView.insertSubview(view, belowSubview: closeBtn)
        
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                navigator.pushChargeVC()
            })
            .disposed(by: bag)
    }

}
