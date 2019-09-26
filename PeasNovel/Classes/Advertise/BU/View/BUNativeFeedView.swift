//
//  BUNativeFeedView.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BUNativeFeedView: UIView, BUNativeProtocol {
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var detailBtn: UIButton!
    var bag = DisposeBag()
    @IBOutlet weak var adImageHeight: NSLayoutConstraint!
    @IBOutlet weak var adImage: UIImageView!
    var isDefaultCloseAction: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    @IBOutlet weak var logView: UIView!
    var buRelatedView: BUNativeAdRelatedView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        detailBtn.layer.cornerRadius = 5
        detailBtn.layer.masksToBounds = true
        detailBtn.layer.borderColor = UIColor(0x999999).cgColor
        detailBtn.layer.borderWidth = 1
        icon.layer.cornerRadius = 3
        icon.layer.masksToBounds = true
        showAllSubViews(false)
        let isDefaultCloseAction = self.isDefaultCloseAction
        closeBtn.rx.tap.mapToVoid()
            .debug()
            .filter { isDefaultCloseAction.value }
            .debug()
            .subscribe(onNext: { (_) in
                navigator.pushChargeVC()
            })
            .disposed(by: bag)
        buRelatedView = BUNativeAdRelatedView()
        addAdLog()
    }
    
    static func loadView() -> BUNativeFeedView {
        guard let view = Bundle.main.loadNibNamed("BUNativeFeedView", owner: nil, options: nil)?.first as? BUNativeFeedView else {
            return BUNativeFeedView()
        }
        return view
    }
    
    func config(_ native: BUNativeAd) {
        showAllSubViews(true)
        titleLabel.text = native.data?.adTitle
        subTitleLabel.text = native.data?.adDescription
        icon.kf.setImage(with: URL(string: native.data?.icon.imageURL ?? ""))
        adImage.kf.setImage(with: URL(string: native.data?.imageAry.first?.imageURL ?? ""))
        native.registerContainer(self, withClickableViews: [adImage, detailBtn, titleLabel, icon])
        let originImageHeight = CGFloat(native.data?.imageAry.first?.height ?? 1)
        let originImageWidth = CGFloat(native.data?.imageAry.first?.height ?? 1)
        let currentImageHeight = (UIScreen.main.bounds.width - 16 * 2) * originImageHeight / originImageWidth * 1.0
        if adImageHeight.constant != currentImageHeight {
            adImageHeight.constant = currentImageHeight > 230 ? 230: currentImageHeight
            layoutIfNeeded()
        }
        native.registerContainer(self, withClickableViews: [adImage, detailBtn, titleLabel, subTitleLabel])
        refreshRelatedView(native)
    }
    
    private func showAllSubViews(_ isShow: Bool = true) {
        self.isUserInteractionEnabled = true
        for subView in subviews {
            subView.isHidden = !isShow
            subView.isUserInteractionEnabled = true
        }
    }
    
}
