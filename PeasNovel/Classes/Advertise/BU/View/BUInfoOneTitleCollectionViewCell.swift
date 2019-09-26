//
//  BUInfoOneTitleCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BUInfoOneTitleCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
    @IBOutlet weak var adImage: UIImageView!
    var buRelatedView: BUNativeAdRelatedView!
    @IBOutlet weak var logView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        showAllSubViews(false)
        buRelatedView = BUNativeAdRelatedView()
        if let log = buRelatedView.logoImageView {
            log.size = CGSize(width: 20, height: 20)
            logView.addSubview(log)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func config(_ native: BUNativeAd) {
        showAllSubViews(true)
        titleLabel.text = native.data?.adTitle
        adImage.kf.setImage(with: URL(string: native.data?.imageAry.first?.imageURL ?? ""))
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                navigator.pushChargeVC()
            })
            .disposed(by: bag)
        native.registerContainer(contentView, withClickableViews: [adImage])
        buRelatedView.refreshData(native)
        print("interactionType:\(native.data?.interactionType.rawValue)")
    }
    
    private func showAllSubViews(_ isShow: Bool = true) {
        self.isUserInteractionEnabled = true
        for subView in subviews {
            subView.isHidden = !isShow
            subView.isUserInteractionEnabled = true
        }
    }
    

}
