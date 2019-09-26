//
//  VerticalButton.swift
//  Arab
//
//  Created by lieon on 2018/11/20.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import UIKit

class VerticalButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleLabel?.textAlignment = .center;
        self.imageView?.contentMode = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let y = contentRect.size.height * 0.6
        let w = contentRect.size.width
        let h = contentRect.size.height - y
        return CGRect(x: 0, y: y, width: w, height: h)
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let w = contentRect.width
        let h = contentRect.size.height * 0.6
        return CGRect(origin: CGPoint.zero, size: CGSize(width: w, height: h))
    }
}
