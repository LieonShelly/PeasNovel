//
//  IMBannerView.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

import InMobiSDK
import RxSwift
import RxCocoa


class IMBannerView: UIView {
    var native: IMNative?
    var loadNum: Int = 0
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
    @IBOutlet weak var iconView: UIImageView!
    var isDefaultCloseAction: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    @IBOutlet weak var adwidth: NSLayoutConstraint!
    @IBOutlet weak var adHeight: NSLayoutConstraint!
    @IBOutlet weak var tapBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let isDefaultCloseAction = self.isDefaultCloseAction 
        closeBtn.rx.tap.mapToVoid()
            .filter { isDefaultCloseAction.value }
            .subscribe(onNext: { (_) in
                navigator.push(ChargeViewController(ChargeViewModel()))
            })
            .disposed(by: bag)
        adHeight.constant = 75
        adwidth.constant = (75.0 / 9 ) * 16
        
    }

    static func loadView() -> IMBannerView {
        guard let view = Bundle.main.loadNibNamed("IMBannerView", owner: nil, options: nil)?.first as? IMBannerView else {
            return IMBannerView()
        }
        view.showAllSubViews(false)
        return view
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
        debugPrint("IMBannerView-LoadNum:\(loadNum)")
        showAllSubViews(true)
        self.native = native
        titleLabel.text = native.adTitle
        subTitleLabel.text = native.adDescription
        let width: CGFloat =  (75.0 / 9 ) * 16
        if let adView = native.primaryView(ofWidth: width) {
            adView.frame.origin.x = 0
            adView.frame.origin.y = 0
            adViewContainer.addSubview(adView)
        }
        tapBtn.rx.tap
            .mapToVoid()
            .subscribe(onNext: {
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

