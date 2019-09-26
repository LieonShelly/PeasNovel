//
//  BUPicVIew.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//  纯图片广告View

import UIKit
import RxSwift
import RxCocoa

class BUPicView: UIView, BUNativeProtocol {
    @IBOutlet weak var logView: UIView!
    var buRelatedView: BUNativeAdRelatedView!
    @IBOutlet weak var imageView: UIImageView!
     var isDefaultCloseAction: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        buRelatedView = BUNativeAdRelatedView()
        addAdLog()
    }
    
    static func loadView() -> BUPicView {
        guard let view = Bundle.main.loadNibNamed("BUPicView", owner: nil, options: nil)?.first as? BUPicView else {
            return BUPicView()
        }
        return view
    }
    
    func config(_ native: BUNativeAd) {
        imageView.kf.setImage(with: URL(string: native.data?.imageAry.first?.imageURL ?? ""))
        native.registerContainer(self, withClickableViews: [imageView])
         refreshRelatedView(native)
    }
    
}
