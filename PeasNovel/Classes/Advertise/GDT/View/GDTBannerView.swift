
//
//  GDTBannerView.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GDTBannerView: UIView {
    private var bannerView: GDTUnifiedBannerView?
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    static func loadView() -> GDTBannerView {
        guard let view = Bundle.main.loadNibNamed("GDTBannerView", owner: nil, options: nil)?.first as? GDTBannerView else {
            return GDTBannerView()
        }
        view.backgroundColor = .white
        return view
    }
    
    func configBannerView(_ bannerView: GDTUnifiedBannerView) {
        if self.bannerView != nil {
            self.bannerView!.removeFromSuperview()
        }
        bannerView.frame.origin = .zero
        addSubview(bannerView)
        self.bannerView = bannerView
    }
}

