//
//  UINavigationController+Ex.swift
//  BookReader
//
//  Created by lieon on 2018/9/19.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    open override var prefersStatusBarHidden: Bool {
        let vc = self.topViewController
        return vc?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        let vc = self.topViewController
        return vc?.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        let vc = self.topViewController
        return vc?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
}
