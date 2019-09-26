//
//  BUNativeBannerView.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BUNativeBannerView: UIView, BUNativeProtocol {
    var loadNum: Int = 0
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
    @IBOutlet weak var imageView: UIImageView!
    var isDefaultCloseAction: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    @IBOutlet weak var adwidth: NSLayoutConstraint!
    @IBOutlet weak var adHeight: NSLayoutConstraint!
    @IBOutlet weak var logView: UIView!
    var buRelatedView: BUNativeAdRelatedView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let isDefaultCloseAction = self.isDefaultCloseAction
        closeBtn.rx.tap.mapToVoid()
            .debug()
            .filter { isDefaultCloseAction.value }
            .debug()
            .subscribe(onNext: { (_) in
                navigator.push(ChargeViewController(ChargeViewModel()))
            })
            .disposed(by: bag)
        adHeight.constant = 75
        adwidth.constant = (75.0 / 9 ) * 16
        buRelatedView = BUNativeAdRelatedView()
        addAdLog()
        
    }
    
    static func loadView() -> BUNativeBannerView {
        guard let view = Bundle.main.loadNibNamed("BUNativeBannerView", owner: nil, options: nil)?.first as? BUNativeBannerView else {
            return BUNativeBannerView()
        }
        view.showAllSubViews(false)
        return view
    }
    
    
    func config(_ native: BUNativeAd) {
        loadNum += 1
        debugPrint("BUNativeBannerView-LoadNum:\(loadNum)")
        showAllSubViews(true)
        titleLabel.text = native.data?.adTitle
        subTitleLabel.text = native.data?.adDescription
        imageView.kf.setImage(with: URL(string: native.data?.imageAry.first?.imageURL ?? ""))
        native.registerContainer(self, withClickableViews: [self])
        refreshRelatedView(native)
    }
    
    private func showAllSubViews(_ isShow: Bool = true) {
        self.isUserInteractionEnabled = true
        for subView in subviews {
            subView.isHidden = !isShow
            subView.isUserInteractionEnabled = true
        }
    }
}
