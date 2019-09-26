//
//  IMInfoTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/10.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa


class IMInfoTableViewCell: UITableViewCell {
    var native: IMNative?
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailBtn: UIButton!
    var bag = DisposeBag()
    @IBOutlet weak var tapbtn: UIButton!
    @IBOutlet weak var adContainerHeight: NSLayoutConstraint!
    
    
    fileprivate func placeHolderMode() {
        titleLabel.isHidden = true
        subTitleLabel.isHidden = true
        detailBtn.isHidden = true
        adViewContainer.isHidden = true
        closeBtn.isHidden = true
        tapbtn.isHidden = true

    }
    
    
    fileprivate func adMode() {
        titleLabel.isHidden = false
        subTitleLabel.isHidden = false
        detailBtn.isHidden = false
        adViewContainer.isHidden = false
        closeBtn.isHidden = false
        tapbtn.isHidden = false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        detailBtn.layer.cornerRadius = 5
        detailBtn.layer.masksToBounds = true
        detailBtn.layer.borderColor = UIColor(0x999999).cgColor
        detailBtn.layer.borderWidth = 1
        placeHolderMode()
    }
    
    
    
    func config(_ native: IMNative) {
        if self.native != nil {
            for subView in adViewContainer.subviews {
                subView.removeFromSuperview()
            }
            self.native?.recyclePrimaryView()
            self.native = nil
        }
        adMode()
        self.native = native
        titleLabel.text = native.adTitle
        subTitleLabel.text = native.adDescription
        let width: CGFloat = UIScreen.main.bounds.width - 16 * 2
        if let adView = native.primaryView(ofWidth: width) {
            adView.origin.y = 0
            adView.origin.x = 0
            adViewContainer.addSubview(adView)
        }

        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                navigator.push(ChargeViewController(ChargeViewModel()))
            })
            .disposed(by: bag)
        
        tapbtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.native?.reportAdClickAndOpenLandingPage()
            })
            .disposed(by: bag)
        
        detailBtn.rx.tap.mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                self?.native?.reportAdClickAndOpenLandingPage()
            })
            .disposed(by: bag)
        if adContainerHeight.constant != (UIScreen.main.bounds.width - 16 * 2) * 2.0 / 3.0 {
            adContainerHeight.constant = (UIScreen.main.bounds.width - 16 * 2) * 2.0 / 3.0
            layoutIfNeeded()
        }
    }
    
}
