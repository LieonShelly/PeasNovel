//
//  IMReaderChapterinfoAdView.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/11.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import InMobiSDK
import RxSwift

class IMReaderChapterinfoAdView: UIView {
    var native: IMNative?
    @IBOutlet weak var adViewContainer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailBtn: UIButton!
     @IBOutlet weak var tapBtn: UIButton!
    var bag = DisposeBag()
    @IBOutlet weak var adContainerHeight: NSLayoutConstraint!
    var isDefaultCloseAction: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        detailBtn.layer.cornerRadius = 5
        detailBtn.layer.masksToBounds = true
        detailBtn.layer.borderWidth = 1
        detailBtn.layer.borderColor = UIColor(0x999999).cgColor
        adContainerHeight.constant = (UIScreen.main.bounds.width  - 16 * 2) * 2.0 / 3.0
        icon.layer.cornerRadius = 5
        icon.layer.masksToBounds = true
    }
    
    
    
    static func loadView() -> IMReaderChapterinfoAdView {
        guard let view = Bundle.main.loadNibNamed("IMReaderChapterinfoAdView", owner: nil, options: nil)?.first as? IMReaderChapterinfoAdView else {
            return IMReaderChapterinfoAdView()
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
          showAllSubViews(true)
        self.native = native
        titleLabel.text = native.adTitle
        icon.image = native.adIcon
        let width: CGFloat = UIScreen.main.bounds.width - 16 * 2
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
    
    
    private func showAllSubViews(_ isShow: Bool = true) {
        for subView in subviews {
            subView.isHidden = !isShow
        }
    }
}

