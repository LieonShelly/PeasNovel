//
//  ReadLongPressCursorView.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReadLongPressCursorView: UIView {
    var color: UIColor = UIColor.theme {
        didSet {
            setNeedsDisplay()
        }
    }
    var isTorB: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        let content = UIGraphicsGetCurrentContext()
        color.set()
        let rectW = bounds.width / 2
        content?.addRect(CGRect(x: (bounds.width - rectW) / 2, y: (isTorB ? 1: 0), width: rectW, height: bounds.height - 1))
        content?.fillPath()
        if isTorB {
            content?.addEllipse(in: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width))
        } else {
            content?.addEllipse(in: CGRect(x: 0, y: bounds.height - bounds.width, width: bounds.width, height: bounds.width))
        }
        color.set()
        content?.fillPath()
    }

}
