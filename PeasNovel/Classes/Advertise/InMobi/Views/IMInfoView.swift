//
//  IMInfoView.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa

class IMInfoView: UIView {
    var native: IMNative?
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailBtn: UIButton!
    var bag = DisposeBag()
    @IBOutlet weak var adContainerHeight: NSLayoutConstraint!
    var isDefaultCloseAction: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    @IBOutlet weak var tapBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        detailBtn.layer.cornerRadius = 5
        detailBtn.layer.masksToBounds = true
        detailBtn.layer.borderWidth = 1
        detailBtn.layer.borderColor = UIColor(0x999999).cgColor
        adContainerHeight.constant = UIScreen.main.bounds.width * 2.0 / 3.0
    }
    
    
    
    static func loadView() -> IMInfoView {
        guard let view = Bundle.main.loadNibNamed("IMInfoView", owner: nil, options: nil)?.first as? IMInfoView else {
            return IMInfoView()
        }
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
        self.native = native
        titleLabel.text = native.adTitle
        subTitleLabel.text = native.adDescription
        let width: CGFloat = UIScreen.main.bounds.width
        if let adView = native.primaryView(ofWidth: width) {
            adView.frame.origin.x = 0
            adView.frame.origin.y = 0
            adViewContainer.addSubview(adView)
            self.setNeedsLayout()
        }
        let isDefaultCloseAction = self.isDefaultCloseAction 
        closeBtn.rx.tap.mapToVoid()
             .filter { isDefaultCloseAction.value }
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
