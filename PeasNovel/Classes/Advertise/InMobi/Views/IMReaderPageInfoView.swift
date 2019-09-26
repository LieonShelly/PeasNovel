//
//  IMReaderPageInfoView.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import InMobiSDK
import RxSwift


class IMReaderPageInfoView: UIView {

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
        icon.layer.cornerRadius = 5
        icon.layer.masksToBounds = true
        adViewContainer.clipsToBounds = true
    }
    
    static func loadView() -> IMReaderPageInfoView {
        guard let view = Bundle.main.loadNibNamed("IMReaderPageInfoView", owner: nil, options: nil)?.first as? IMReaderPageInfoView else {
            return IMReaderPageInfoView()
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
        let config = ReaderPageAdUIConfig()
        let width: CGFloat = config.infoAdSize(.inmobi).width - 10 * 2
        if let adView = native.primaryView(ofWidth: width) {
            adView.frame.origin.x = 0
            adView.frame.origin.y = 0
            adContainerHeight.constant = adView.frame.height
            adViewContainer.addSubview(adView)
            layoutIfNeeded()
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
