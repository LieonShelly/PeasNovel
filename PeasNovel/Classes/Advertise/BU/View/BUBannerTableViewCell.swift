//
//  BUBannerTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BUBannerTableViewCell: UITableViewCell, BUNativeProtocol {
    var loadNum: Int = 0
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var bag = DisposeBag()
    @IBOutlet weak var coverView: UIImageView!
    var isDefaultCloseAction: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    @IBOutlet weak var adwidth: NSLayoutConstraint!
    @IBOutlet weak var adHeight: NSLayoutConstraint!
    @IBOutlet weak var tapBtn: UIButton!
    @IBOutlet weak  var logView: UIView!
    var buRelatedView: BUNativeAdRelatedView!
    
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
        buRelatedView = BUNativeAdRelatedView()
        addAdLog()
    }
    
    func config(_ native: BUNativeAd) {
        loadNum += 1
        debugPrint("BUBannerTableViewCell-LoadNum:\(loadNum)")
        showAllSubViews(true)
        titleLabel.text = native.data?.adTitle
        subTitleLabel.text = native.data?.adDescription
        coverView.kf.setImage(with: URL(string: native.data?.icon.imageURL ?? ""))
        native.registerContainer(self, withClickableViews: [self.tapBtn, self.coverView, contentView])
        refreshRelatedView(native)
    }
    
    private func showAllSubViews(_ isShow: Bool = true) {
        for subView in subviews {
            subView.isHidden = !isShow
        }
    }
}
