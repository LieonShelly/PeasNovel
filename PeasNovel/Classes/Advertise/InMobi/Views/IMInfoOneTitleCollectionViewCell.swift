//
//  IMInfoOneTitleCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/14.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa

class IMInfoOneTitleCollectionViewCell: UICollectionViewCell {
    var native: IMNative?
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
    var loadNum: Int = 0
    @IBOutlet weak var tapBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        showAllSubViews(false)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func config(_ native: IMNative) {
        if self.native != nil {
            for subView in adViewContainer.subviews {
                subView.removeFromSuperview()
            }
            self.native?.recyclePrimaryView()
            self.native = nil
        }
        loadNum += 1
        debugPrint("IMInfoOneTitleCollectionViewCell-LoadNum:\(loadNum)")
        showAllSubViews(true)
        self.native = native
        titleLabel.text = native.adTitle
        let width: CGFloat = bounds.width
        if let adView = native.primaryView(ofWidth: width) {
            adView.origin.x = 0
            adView.origin.y = 0
            let adWidth = adView.frame.width
            let adHeight = adView.frame.height
            adView.frame.size.height = adViewContainer.frame.width  * adHeight / adWidth
            adViewContainer.addSubview(adView)
        }
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                navigator.push(ChargeViewController(ChargeViewModel()))
            })
            .disposed(by: bag)
        
        tapBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                native.reportAdClickAndOpenLandingPage()
            })
            .disposed(by: bag)
        
    }
    
    private func showAllSubViews(_ isShow: Bool = true) {
        for subView in subviews {
            subView.isHidden = !isShow
        }
    }
    
}

