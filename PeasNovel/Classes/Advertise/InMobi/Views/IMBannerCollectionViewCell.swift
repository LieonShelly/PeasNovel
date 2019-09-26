//
//  IMBannerCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa

class IMBannerCollectionViewCell: UICollectionViewCell {
    var native: IMNative?
    @IBOutlet weak var tapBtn: UIButton!
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var bannerContainer: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
//       @IBOutlet weak var iconView: UIImageView!
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
        if self.native?.creativeId == native.creativeId {
            return
        }
        self.native = native
        titleLabel.text = native.adTitle
        subTitleLabel.text = native.adDescription
        let width: CGFloat = 100 //(75.0 / 3 ) * 4
        if let adView = native.primaryView(ofWidth: width) {
            adView.origin.x = 0
            adView.origin.y = (bounds.height - 50 ) * 0.5
            adViewContainer.addSubview(adView)
        }
//        iconView.image = native.adIcon
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

