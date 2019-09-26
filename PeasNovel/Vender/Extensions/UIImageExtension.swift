//
//  UIImageExtension.swift
//  Arab
//
//  Created by lieon on 2018/10/29.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func scale(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    convenience init?(color hex: Int, size: CGSize = CGSize(width: 1, height: 1)) {
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor(hex).cgColor)
        context?.fill(CGRect(origin: CGPoint.zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImg = img?.cgImage else { return nil }
        self.init(cgImage: cgImg)
    }
    
    /// 更改图片颜色
    func image(WithTint color : UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(self.size)
        color.setFill()
        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
    
    static var noContentImage: UIImage? {
        return UIImage(named: "no_content")
    }
    
    static var noSingalsImage: UIImage? {
        return UIImage(named: "no_content")
    }
    
    static var noRecordsImage: UIImage? {
        return UIImage(named: "no_records")
    }
    
    static var placeholder: UIImage? {
        return UIImage(named: "placeholder")
    }
    
}
