//
//  IMInfoCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa

class IMInfoCollectionViewCell: UICollectionViewCell {
     var native: IMNative?
    @IBOutlet weak var placeHolderVIew: UIImageView!
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var detailBtn: UIButton!
     var bag = DisposeBag()
    @IBOutlet weak var adContainerHeight: NSLayoutConstraint!
    weak var collectionView: UICollectionView?
    @IBOutlet weak var tapBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        detailBtn.layer.cornerRadius = 5
        detailBtn.layer.masksToBounds = true
        detailBtn.layer.borderColor = UIColor(0x999999).cgColor
        detailBtn.layer.borderWidth = 1
        icon.layer.cornerRadius = 3
        icon.layer.masksToBounds = true
        adContainerHeight.constant = (UIScreen.main.bounds.width - 16 * 2) * 2.0 / 3.0
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if let newSuperview = newSuperview as? UICollectionView {
            self.collectionView = newSuperview
          
            
            
        }
    }
    
    func config(_ native: IMNative, didTapAd:(() -> Void)?) {
        if self.native != nil {
            for subView in adViewContainer.subviews {
                subView.removeFromSuperview()
            }
            self.native?.recyclePrimaryView()
            self.native = nil
        }
        placeHolderVIew.isHidden = true
        self.native = native
        titleLabel.text = native.adTitle
        subTitleLabel.text = native.adDescription
        let width: CGFloat = (UIScreen.main.bounds.width) - 16 * 2
        if let adView = native.primaryView(ofWidth: width) {
            adView.origin.x = 0
            adView.origin.y = 0
            adViewContainer.addSubview(adView)
        }
        icon.image = native.adIcon
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                navigator.push(ChargeViewController(ChargeViewModel()))
            })
            .disposed(by: bag)
        
        detailBtn.rx.tap.mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                didTapAd?()
                self?.native?.reportAdClickAndOpenLandingPage()
            })
            .disposed(by: bag)
        
        tapBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.native?.reportAdClickAndOpenLandingPage()
            })
            .disposed(by: bag)
        
         tapBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                didTapAd?()
            })
            .disposed(by: bag)
        
        
    }
    
}

