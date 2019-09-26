//
//  BUNativeFeedCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BUNativeFeedCollectionViewCell: UICollectionViewCell, BUNativeProtocol {
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var detailBtn: UIButton!
    var bag = DisposeBag()
    @IBOutlet weak var adImageHeight: NSLayoutConstraint!
    @IBOutlet weak var adImage: UIImageView!
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
        adImageHeight.constant = (UIScreen.main.bounds.width - 16 * 2) * 2.0 / 3.0
        showAllSubViews(false)
        buRelatedView = BUNativeAdRelatedView()
        addAdLog()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func config(_ native: BUNativeAd) {
        showAllSubViews(true)
        titleLabel.text = native.data?.adTitle
        subTitleLabel.text = native.data?.adDescription
        icon.kf.setImage(with: URL(string: native.data?.icon.imageURL ?? ""))
        adImage.kf.setImage(with: URL(string: native.data?.imageAry.first?.imageURL ?? ""))
        native.registerContainer(self, withClickableViews: [adImage, detailBtn, titleLabel, icon, contentView])
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                navigator.pushChargeVC()
            })
            .disposed(by: bag)
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


protocol BUNativeProtocol {
    var logView: UIView! { set get }
    var buRelatedView: BUNativeAdRelatedView! { set get  }
    
    func addAdLog()
    func refreshRelatedView(_ native: BUNativeAd)
}

extension BUNativeProtocol {
    func addAdLog() {
        if let log = buRelatedView.logoImageView {
            log.size = CGSize(width: 20, height: 20)
            logView.addSubview(log)
        }
    }
    
    func refreshRelatedView(_ native: BUNativeAd ) {
        buRelatedView.refreshData(native)
    }
    
}
