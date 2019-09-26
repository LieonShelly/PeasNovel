
//
//  UIImageView.swift
//  Arab
//
//  Created by lieon on 2018/11/1.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

extension UIImage {
    
    class func screenshot(size: CGSize, in view: UIView) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
