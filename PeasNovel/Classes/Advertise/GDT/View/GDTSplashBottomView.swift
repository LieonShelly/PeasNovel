//
//  GDTSplashBottomView.swift
//  PeasNovel
//
//  Created by lieon on 2019/7/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class GDTSplashBottomView: UIView {

    static func loadView() -> GDTSplashBottomView {
        guard let view = Bundle.main.loadNibNamed("GDTSplashBottomView", owner: nil, options: nil)?.first as? GDTSplashBottomView else {
            return GDTSplashBottomView()
        }
        view.backgroundColor = .white
        return view
    }
    

}
