//
//  InsetsLabel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

@IBDesignable
class InsetsLabel: UILabel {
    
    @IBInspectable
    public var edgeInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            self.layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        edgeInsets = UIEdgeInsets.zero
//    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetsRect = bounds.inset(by: self.edgeInsets)
        var rect = super.textRect(forBounds: insetsRect,
                                     limitedToNumberOfLines: numberOfLines)
        rect.origin.x -= self.edgeInsets.left
        rect.origin.y -= self.edgeInsets.top
        rect.size.width = self.edgeInsets.left + self.edgeInsets.right + rect.width
        rect.size.height = self.edgeInsets.top + self.edgeInsets.bottom + rect.height
        return rect
    }
    
    override func drawText(in rect: CGRect) {
        let insetsRect = rect.inset(by: self.edgeInsets)
        super.drawText(in: insetsRect)
    }

}
