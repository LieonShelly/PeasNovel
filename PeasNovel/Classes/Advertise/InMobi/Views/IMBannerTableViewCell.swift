//
//  IMBannerTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa


class IMBannerTableViewCell: UITableViewCell {
    var native: IMNative?
    @IBOutlet weak var tapBtn: UIButton!
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var bannerContainer: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    func configBanner(_ native: IMNative) {
        if self.native != nil {
            for subView in adViewContainer.subviews {
                subView.removeFromSuperview()
            }
            self.native?.recyclePrimaryView()
            self.native = nil
        }
        self.native = native
        titleLabel.text = native.adTitle
        subTitleLabel.text = native.adDescription
        let width: CGFloat = (75.0 / 3 ) * 4
        if let adView = native.primaryView(ofWidth: width) {
            adView.center = adViewContainer.center
            adViewContainer.addSubview(adView)
        }
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                navigator.push(ChargeViewController(ChargeViewModel()))
            })
            .disposed(by: bag)
        
        tapBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.native?.reportAdClickAndOpenLandingPage()
            })
            .disposed(by: bag)
    }
}

