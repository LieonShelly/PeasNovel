//
//  ApplicationExtension.swift
//  Arab
//
//  Created by lieon on 2018/9/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    func isRtl() -> Bool {
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            return true
        }
        return false
    }
}
