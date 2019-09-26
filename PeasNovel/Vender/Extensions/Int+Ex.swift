//
//  Int+Ex.swift
//  PeasNovel
//
//  Created by lieon on 2019/1/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation

extension Int {
    
    var roman: String {
        
        var num = self
        var roman = ""
        let val = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        let str = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        
        for idx in 0...val.count-1 {
            while num >= val[idx] {
                num -= val[idx]
                roman += str[idx]
            }
        }
        return roman
    }
}
