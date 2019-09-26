//
//  GDTBannerTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class GDTBannerTableViewCell: UITableViewCell {
    @IBOutlet weak var closeBtn: UIButton!
    var bag = DisposeBag()
    private var bannerView: GDTUnifiedBannerView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func configBannerView(_ bannerView: GDTUnifiedBannerView) {
        if self.bannerView != nil {
            self.bannerView!.removeFromSuperview()
        }
        closeBtn.rx.tap.mapToVoid()
            .debug()
            .subscribe(onNext: { (_) in
                navigator.push(ChargeViewController(ChargeViewModel()))
            })
            .disposed(by: bag)
        bannerView.frame.origin = .zero
        bannerView.center.x = bounds.width * 0.5
        contentView.insertSubview(bannerView, belowSubview: closeBtn)
        self.bannerView = bannerView
    }
    
}
